"""
SmartVision Annotation Converters & Dataset Validator
Supports:
- YOLO format (.txt)
- COCO JSON format (.json)
- Pascal VOC XML format (.xml)
- Class taxonomy normalization with synonym mapping
- Image & bounding box validation (bounds, coordinates, corruption)
- Perceptual & exact duplicate detection
- Leak-free train/val/test splitting
"""

import os
import sys
import glob
import json
import shutil
import hashlib
import xml.etree.ElementTree as ET
from typing import Dict, Any, List, Tuple, Optional, Set
from PIL import Image

class AnnotationConverter:
    def __init__(self, canonical_classes: List[str], synonyms: Dict[str, str]):
        self.canonical_classes = [c.lower().strip() for c in canonical_classes]
        self.class_to_id = {c: i for i, c in enumerate(self.canonical_classes)}
        self.synonyms = {k.lower().strip(): v.lower().strip() for k, v in synonyms.items()}

    def normalize_class_name(self, raw_name: str) -> Optional[Tuple[int, str]]:
        """Maps a raw class name to canonical class ID and standardized name."""
        clean = raw_name.lower().strip().replace("-", " ").replace("_", " ")
        # Direct canonical match
        if clean in self.class_to_id:
            return self.class_to_id[clean], clean
        # Synonym match
        if clean in self.synonyms:
            canonical = self.synonyms[clean]
            if canonical in self.class_to_id:
                return self.class_to_id[canonical], canonical
        return None

    def detect_format(self, directory: str) -> str:
        """Inspects directory to detect dataset annotation format."""
        xml_files = glob.glob(os.path.join(directory, "**", "*.xml"), recursive=True)
        if len(xml_files) > 0:
            return "voc_xml"
            
        json_files = glob.glob(os.path.join(directory, "**", "*.json"), recursive=True)
        for jf in json_files:
            try:
                with open(jf, "r", encoding="utf-8", errors="ignore") as f:
                    data = json.load(f)
                    if isinstance(data, dict) and "annotations" in data and "images" in data:
                        return "coco_json"
            except Exception:
                continue
                
        txt_files = glob.glob(os.path.join(directory, "**", "*.txt"), recursive=True)
        valid_yolo_count = 0
        for tf in txt_files[:20]:
            if os.path.basename(tf).lower() in ["classes.txt", "readme.txt", "license.txt"]:
                continue
            try:
                with open(tf, "r") as f:
                    lines = [l.strip() for l in f if l.strip()]
                    if lines:
                        parts = lines[0].split()
                        if len(parts) == 5:
                            # Test if parts are numbers
                            [float(p) for p in parts]
                            valid_yolo_count += 1
            except Exception:
                continue
        if valid_yolo_count > 0:
            return "yolo_txt"
            
        return "unknown"

    def convert_voc_xml(self, xml_path: str, img_w: float, img_h: float) -> List[Tuple[int, float, float, float, float]]:
        """Parses a Pascal VOC XML file and converts bounding boxes to YOLO format."""
        yolo_boxes = []
        try:
            tree = ET.parse(xml_path)
            root = tree.getroot()
            
            # Read size if available
            size_elem = root.find("size")
            if size_elem is not None:
                w_node = size_elem.find("width")
                h_node = size_elem.find("height")
                if w_node is not None and h_node is not None and float(w_node.text) > 0:
                    img_w = float(w_node.text)
                    img_h = float(h_node.text)
            
            if img_w <= 0 or img_h <= 0:
                return []
                
            for obj in root.findall("object"):
                name_elem = obj.find("name")
                if name_elem is None or not name_elem.text:
                    continue
                mapped = self.normalize_class_name(name_elem.text)
                if mapped is None:
                    continue
                cls_id, _ = mapped
                
                bndbox = obj.find("bndbox")
                if bndbox is None:
                    continue
                xmin = float(bndbox.find("xmin").text)
                ymin = float(bndbox.find("ymin").text)
                xmax = float(bndbox.find("xmax").text)
                ymax = float(bndbox.find("ymax").text)
                
                # Sanity checks
                if xmax <= xmin or ymax <= ymin:
                    continue
                bw = (xmax - xmin) / img_w
                bh = (ymax - ymin) / img_h
                xc = (xmin + (xmax - xmin) / 2.0) / img_w
                yc = (ymin + (ymax - ymin) / 2.0) / img_h
                
                xc = max(0.0, min(1.0, xc))
                yc = max(0.0, min(1.0, yc))
                bw = max(0.001, min(1.0, bw))
                bh = max(0.001, min(1.0, bh))
                
                yolo_boxes.append((cls_id, xc, yc, bw, bh))
        except Exception:
            pass
        return yolo_boxes

    def convert_coco_json(self, json_path: str) -> Dict[str, List[Tuple[int, float, float, float, float]]]:
        """Parses COCO JSON and produces a dict mapping base image name to list of YOLO boxes."""
        results = {}
        try:
            with open(json_path, "r", encoding="utf-8", errors="ignore") as f:
                data = json.load(f)
            categories = {c["id"]: c.get("name", "") for c in data.get("categories", [])}
            images = {img["id"]: img for img in data.get("images", [])}
            
            # Map annotations
            for ann in data.get("annotations", []):
                img_id = ann.get("image_id")
                if img_id not in images:
                    continue
                img_info = images[img_id]
                file_name = img_info.get("file_name", "")
                base_name = os.path.splitext(os.path.basename(file_name))[0]
                img_w = float(img_info.get("width", 0))
                img_h = float(img_info.get("height", 0))
                if img_w <= 0 or img_h <= 0:
                    continue
                    
                cat_id = ann.get("category_id")
                raw_cat_name = categories.get(cat_id, "")
                mapped = self.normalize_class_name(raw_cat_name)
                if mapped is None:
                    continue
                cls_id, _ = mapped
                
                bbox = ann.get("bbox", [])
                if len(bbox) != 4:
                    continue
                x, y, w, h = bbox
                if w <= 0 or h <= 0:
                    continue
                    
                xc = (x + w / 2.0) / img_w
                yc = (y + h / 2.0) / img_h
                bw = w / img_w
                bh = h / img_h
                
                xc = max(0.0, min(1.0, xc))
                yc = max(0.0, min(1.0, yc))
                bw = max(0.001, min(1.0, bw))
                bh = max(0.001, min(1.0, bh))
                
                results.setdefault(base_name, []).append((cls_id, xc, yc, bw, bh))
        except Exception:
            pass
        return results

    def validate_image(self, img_path: str) -> Optional[Tuple[int, int]]:
        """Verifies image file readability and returns (width, height) or None."""
        try:
            if not os.path.exists(img_path) or os.path.getsize(img_path) == 0:
                return None
            with Image.open(img_path) as im:
                im.verify()
            with Image.open(img_path) as im:
                w, h = im.size
                if w > 0 and h > 0:
                    return w, h
        except Exception:
            return None
        return None

    def compute_image_hash(self, img_path: str) -> str:
        """Computes MD5 hash of image bytes for exact duplicate check."""
        with open(img_path, "rb") as f:
            return hashlib.md5(f.read()).hexdigest()

    def compute_dhash(self, img_path: str, hash_size: int = 8) -> int:
        """Computes difference hash (dHash) for near-duplicate image detection."""
        try:
            with Image.open(img_path) as im:
                im = im.convert("L").resize((hash_size + 1, hash_size), Image.Resampling.LANCZOS)
                pixels = list(im.getdata())
                diff = []
                for row in range(hash_size):
                    for col in range(hash_size):
                        idx = row * (hash_size + 1) + col
                        diff.append(pixels[idx] > pixels[idx + 1])
                return sum(1 << i for i, val in enumerate(diff) if val)
        except Exception:
            return 0

    def is_near_duplicate(self, dhash1: int, dhash2: int, threshold: int = 4) -> bool:
        """Hamming distance between dhashes to detect near-duplicate images."""
        if dhash1 == 0 or dhash2 == 0:
            return False
        dist = bin(dhash1 ^ dhash2).count("1")
        return dist <= threshold
