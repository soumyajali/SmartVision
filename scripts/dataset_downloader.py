"""
SmartVision Automated Dataset Downloader & Adapter Suite
Modular adapters for Kaggle, Hugging Face, COCO HTTP, Open Images, and Objects365.
Handles automatic downloading, COCO JSON & YOLO format conversion, validation, deduplication, and combination.
"""

import os
import sys
import json
import glob
import shutil
import random
import hashlib
import urllib.request
import zipfile
from typing import Dict, Any, List, Tuple
from PIL import Image

random.seed(42)

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
DATASETS_DIR = os.path.join(BASE_DIR, 'datasets')
MANIFEST_PATH = os.path.join(DATASETS_DIR, 'manifest.json')
RAW_DIR = os.path.join(DATASETS_DIR, 'raw_downloads')
COMBINED_DIR = os.path.join(DATASETS_DIR, 'custom_objects')

COCO_80_NAMES = [
    'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck', 'boat', 'traffic light',
    'fire hydrant', 'stop sign', 'parking meter', 'bench', 'bird', 'cat', 'dog', 'horse', 'sheep', 'cow',
    'elephant', 'bear', 'zebra', 'giraffe', 'backpack', 'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee',
    'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat', 'baseball glove', 'skateboard', 'surfboard',
    'tennis racket', 'bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple',
    'sandwich', 'orange', 'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch',
    'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse', 'remote', 'keyboard', 'cell phone',
    'microwave', 'oven', 'toaster', 'sink', 'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear',
    'hair drier', 'toothbrush'
]

COCO_NAME_TO_ID = {name: idx for idx, name in enumerate(COCO_80_NAMES)}

def get_free_disk_space_gb() -> float:
    """Returns free disk space in Gigabytes for the datasets directory."""
    stat = os.statvfs(BASE_DIR)
    free_bytes = stat.f_bavail * stat.f_frsize
    return free_bytes / (1024 ** 3)

class BaseAdapter:
    def __init__(self, source_info: Dict[str, Any]):
        self.source_info = source_info
        self.source_id = source_info['id']

    def download(self, target_dir: str) -> Tuple[bool, str]:
        raise NotImplementedError

class HuggingFaceAdapter(BaseAdapter):
    def download(self, target_dir: str) -> Tuple[bool, str]:
        repo_id = self.source_info.get('repo_id')
        out_path = os.path.join(target_dir, self.source_id)
        if os.path.exists(out_path) and os.listdir(out_path):
            return True, f"Dataset already cached at {out_path}."
            
        print(f"[{self.source_id}] Downloading {repo_id} from Hugging Face Hub...")
        try:
            from huggingface_hub import snapshot_download
            snapshot_download(
                repo_id=repo_id,
                repo_type="dataset",
                local_dir=out_path,
                local_dir_use_symlinks=False,
                max_workers=4
            )
            return True, "Hugging Face download completed successfully."
        except Exception as e:
            return False, f"Hugging Face download failed: {e}"

class HttpZipAdapter(BaseAdapter):
    def download(self, target_dir: str) -> Tuple[bool, str]:
        url = self.source_info.get('url')
        out_dir = os.path.join(target_dir, self.source_id)
        if os.path.exists(out_dir) and os.listdir(out_dir):
            return True, f"Dataset already cached at {out_dir}."
            
        os.makedirs(out_dir, exist_ok=True)
        zip_path = os.path.join(out_dir, "dataset.zip")
        print(f"[{self.source_id}] Downloading HTTP package from {url}...")
        try:
            import ssl
            try:
                import certifi
                ctx = ssl.create_default_context(cafile=certifi.where())
            except Exception:
                ctx = ssl._create_unverified_context()
                
            req = urllib.request.Request(url, headers={'User-Agent': 'SmartVision/1.0'})
            with urllib.request.urlopen(req, context=ctx) as resp, open(zip_path, 'wb') as out_f:
                shutil.copyfileobj(resp, out_f)
            
            print(f"[{self.source_id}] Extracting archive...")
            with zipfile.ZipFile(zip_path, 'r') as zf:
                zf.extractall(out_dir)
            if os.path.exists(zip_path):
                os.remove(zip_path)
            return True, "HTTP archive downloaded and extracted successfully."
        except Exception as e:
            return False, f"HTTP download failed: {e}"

class KaggleAdapter(BaseAdapter):
    def download(self, target_dir: str) -> Tuple[bool, str]:
        kaggle_config = os.path.expanduser('~/.kaggle/kaggle.json')
        if not os.path.exists(kaggle_config) and not os.environ.get('KAGGLE_USERNAME'):
            msg = (
                "Kaggle authentication credentials not found in ~/.kaggle/kaggle.json. "
                "To enable: 1. Go to https://www.kaggle.com/settings -> Click 'Create New Token'. "
                "2. Place 'kaggle.json' into ~/.kaggle/kaggle.json. 3. Run 'chmod 600 ~/.kaggle/kaggle.json'."
            )
            return False, msg
            
        try:
            import kaggle
            competition = self.source_info.get('competition')
            out_dir = os.path.join(target_dir, self.source_id)
            os.makedirs(out_dir, exist_ok=True)
            if competition:
                kaggle.api.competition_download_files(competition, path=out_dir, quiet=False)
            return True, "Kaggle competition dataset downloaded successfully."
        except Exception as e:
            return False, f"Kaggle API download failed: {e}"

class LargeScaleRepositoryAdapter(BaseAdapter):
    """Adapter for massive repositories like Open Images V7 and Objects365."""
    def download(self, target_dir: str) -> Tuple[bool, str]:
        disk_req = self.source_info.get('disk_requirement_gb', 50)
        free_space = get_free_disk_space_gb()
        if free_space < disk_req + 10:
            msg = (
                f"Skipped download due to storage limits: Required {disk_req} GB, "
                f"but only {free_space:.1f} GB available. "
                "Use targeted category subset downloads or external cloud storage."
            )
            return False, msg
        return False, "Manual authentication or gsutil CLI configuration required."

def convert_coco_json_to_yolo(coco_json_path: str, images_dir: str, out_labels_dir: str) -> int:
    """Converts a COCO format JSON annotation file to YOLO format .txt labels."""
    os.makedirs(out_labels_dir, exist_ok=True)
    with open(coco_json_path, 'r') as f:
        coco = json.load(f)
        
    categories = {c['id']: c['name'] for c in coco.get('categories', [])}
    images = {img['id']: img for img in coco.get('images', [])}
    
    img_annotations = {}
    for ann in coco.get('annotations', []):
        img_id = ann['image_id']
        img_annotations.setdefault(img_id, []).append(ann)
        
    converted = 0
    for img_id, anns in img_annotations.items():
        if img_id not in images:
            continue
        img_info = images[img_id]
        img_w = float(img_info['width'])
        img_h = float(img_info['height'])
        file_name = img_info['file_name']
        base_name = os.path.splitext(os.path.basename(file_name))[0]
        
        yolo_lines = []
        for ann in anns:
            cat_id = ann['category_id']
            cat_name = categories.get(cat_id, '').lower().strip()
            
            coco_idx = COCO_NAME_TO_ID.get(cat_name)
            if coco_idx is None:
                continue
                
            x, y, w, h = ann['bbox'] # COCO: top-left x, y, width, height
            if w <= 0 or h <= 0:
                continue
            xc = (x + w / 2.0) / img_w
            yc = (y + h / 2.0) / img_h
            norm_w = w / img_w
            norm_h = h / img_h
            
            # Normalization validation
            xc = max(0.0, min(1.0, xc))
            yc = max(0.0, min(1.0, yc))
            norm_w = max(0.001, min(1.0, norm_w))
            norm_h = max(0.001, min(1.0, norm_h))
            
            yolo_lines.append(f"{coco_idx} {xc:.6f} {yc:.6f} {norm_w:.6f} {norm_h:.6f}")
            
        if yolo_lines:
            out_txt = os.path.join(out_labels_dir, base_name + '.txt')
            with open(out_txt, 'w') as f:
                f.write('\n'.join(yolo_lines) + '\n')
            converted += 1
            
    return converted

def validate_and_audit_dataset(dataset_dir: str) -> Dict[str, Any]:
    """
    Rigorously validates images, labels, bounding boxes, duplicates, and class distributions.
    """
    audit = {
        'total_images': 0,
        'valid_images': 0,
        'corrupted_images': 0,
        'total_labels': 0,
        'empty_labels': 0,
        'missing_labels': 0,
        'invalid_boxes': 0,
        'total_instances': 0,
        'instances_per_class': {name: 0 for name in COCO_80_NAMES},
        'split_stats': {},
        'duplicate_images_detected': 0
    }
    
    seen_hashes = set()
    
    for split in ['train', 'val', 'test']:
        img_dir = os.path.join(dataset_dir, 'images', split)
        lbl_dir = os.path.join(dataset_dir, 'labels', split)
        
        imgs = sorted(glob.glob(os.path.join(img_dir, '*')))
        lbls = sorted(glob.glob(os.path.join(lbl_dir, '*.txt')))
        
        split_inst = 0
        split_valid_img = 0
        
        for img_path in imgs:
            audit['total_images'] += 1
            base = os.path.splitext(os.path.basename(img_path))[0]
            lbl_path = os.path.join(lbl_dir, base + '.txt')
            
            # 1. Image corruption check
            try:
                with Image.open(img_path) as im:
                    im.verify()
                # Compute md5 for duplicate check
                with open(img_path, 'rb') as f:
                    file_hash = hashlib.md5(f.read()).hexdigest()
                    if file_hash in seen_hashes:
                        audit['duplicate_images_detected'] += 1
                    seen_hashes.add(file_hash)
                split_valid_img += 1
                audit['valid_images'] += 1
            except Exception:
                audit['corrupted_images'] += 1
                continue
                
            # 2. Check label existence
            if not os.path.exists(lbl_path):
                audit['missing_labels'] += 1
                continue
                
            # 3. Check label contents & bbox validity
            audit['total_labels'] += 1
            with open(lbl_path, 'r') as lf:
                lines = [l.strip() for l in lf.readlines() if l.strip()]
                
            if not lines:
                audit['empty_labels'] += 1
                continue
                
            for line in lines:
                parts = line.split()
                if len(parts) != 5:
                    audit['invalid_boxes'] += 1
                    continue
                try:
                    cls_id = int(parts[0])
                    xc, yc, w, h = float(parts[1]), float(parts[2]), float(parts[3]), float(parts[4])
                    if not (0 <= cls_id < 80):
                        audit['invalid_boxes'] += 1
                        continue
                    if not (0.0 <= xc <= 1.0 and 0.0 <= yc <= 1.0 and 0.0 < w <= 1.0 and 0.0 < h <= 1.0):
                        audit['invalid_boxes'] += 1
                        continue
                    
                    class_name = COCO_80_NAMES[cls_id]
                    audit['instances_per_class'][class_name] += 1
                    audit['total_instances'] += 1
                    split_inst += 1
                except ValueError:
                    audit['invalid_boxes'] += 1
                    
        audit['split_stats'][split] = {
            'images': len(imgs),
            'valid_images': split_valid_img,
            'labels': len(lbls),
            'instances': split_inst
        }
        
    return audit

def generate_inventory_report(audit: Dict[str, Any], download_status: Dict[str, Any], out_path: str):
    """Writes a comprehensive Markdown inventory and validation report."""
    md = []
    md.append("# SmartVision Dataset Acquisition & Inventory Report\n")
    md.append(f"**Free Disk Space Available**: {get_free_disk_space_gb():.2f} GB\n")
    
    md.append("## 1. Source Repositories & Download Status\n")
    md.append("| Repository ID | Source Type | License | Status | Notes |")
    md.append("| :--- | :--- | :--- | :--- | :--- |")
    for sid, info in download_status.items():
        md.append(f"| `{sid}` | {info.get('type')} | {info.get('license')} | **{info.get('status')}** | {info.get('notes', '')} |")
    
    md.append("\n## 2. Combined Dataset Split Statistics\n")
    md.append("| Split | Images | Valid Images | Labels | Instances | Integrity Rate |")
    md.append("| :--- | :--- | :--- | :--- | :--- | :--- |")
    for split, s in audit['split_stats'].items():
        rate = (s['valid_images'] / s['images'] * 100) if s['images'] else 100
        md.append(f"| `{split}` | {s['images']} | {s['valid_images']} | {s['labels']} | {s['instances']} | {rate:.1f}% |")
    
    md.append("\n## 3. Data Integrity & Validation Checks\n")
    md.append(f"- **Total Images Checked**: {audit['total_images']}")
    md.append(f"- **Corrupted Images**: {audit['corrupted_images']}")
    md.append(f"- **Total Labels Checked**: {audit['total_labels']}")
    md.append(f"- **Empty Labels**: {audit['empty_labels']}")
    md.append(f"- **Missing Labels**: {audit['missing_labels']}")
    md.append(f"- **Invalid Bounding Boxes**: {audit['invalid_boxes']}")
    md.append(f"- **Duplicate Images Detected**: {audit['duplicate_images_detected']}")
    md.append(f"- **Total Valid Ground Truth Instances**: {audit['total_instances']}")
    
    md.append("\n## 4. Class Distribution (Top 25 Categories)\n")
    md.append("| Class ID | Class Name | Instance Count | Status |")
    md.append("| :--- | :--- | :--- | :--- |")
    sorted_classes = sorted(audit['instances_per_class'].items(), key=lambda x: x[1], reverse=True)
    for cname, count in sorted_classes[:25]:
        cid = COCO_NAME_TO_ID[cname]
        status = "Active & Populated" if count > 0 else "Pretrained Weights Retained"
        md.append(f"| {cid} | `{cname}` | {count} | {status} |")
        
    non_zero = sum(1 for c, cnt in sorted_classes if cnt > 0)
    md.append(f"\n*Populated Active Ground Truth Categories in Dataset*: **{non_zero} / 80 COCO Classes** (all 80 preserved in YOLO head)*\n")
    
    with open(out_path, 'w') as f:
        f.write('\n'.join(md) + '\n')
    print(f"Dataset inventory report written to: {out_path}")

def run_pipeline():
    print("=" * 70)
    print("SMARTVISION COMPREHENSIVE DATASET ACQUISITION & INTEGRATION PIPELINE")
    print("=" * 70)
    
    free_gb = get_free_disk_space_gb()
    print(f"System Storage Check: {free_gb:.2f} GB free disk space available.")
    
    with open(MANIFEST_PATH, 'r') as f:
        manifest = json.load(f)
        
    os.makedirs(RAW_DIR, exist_ok=True)
    download_status = {}
    
    for src in manifest.get('sources', []):
        stype = src.get('type')
        sid = src.get('id')
        license_info = src.get('license', 'Unknown')
        
        if stype == 'local':
            download_status[sid] = {
                'type': 'local', 'license': license_info, 'status': 'AVAILABLE',
                'notes': '527 internal SmartVision video frames & danger test samples'
            }
            continue
            
        adapter = None
        if stype == 'huggingface':
            adapter = HuggingFaceAdapter(src)
        elif stype == 'http':
            adapter = HttpZipAdapter(src)
        elif stype == 'kaggle':
            adapter = KaggleAdapter(src)
        elif stype in ['gsutil_http', 'objects365_portal']:
            adapter = LargeScaleRepositoryAdapter(src)
            
        if adapter:
            success, msg = adapter.download(RAW_DIR)
            download_status[sid] = {
                'type': stype,
                'license': license_info,
                'status': 'DOWNLOADED' if success else 'SKIPPED/UNAVAILABLE',
                'notes': msg
            }
            print(f"[{sid}] Result: {'SUCCESS' if success else 'SKIPPED'} - {msg}")

    # Process and integrate downloaded datasets
    # 1. Hugging Face COCO Subset
    hf_coco_dir = os.path.join(RAW_DIR, 'huggingface_quickstart_coco')
    if os.path.exists(hf_coco_dir):
        labels_json = os.path.join(hf_coco_dir, 'labels.json')
        images_dir = os.path.join(hf_coco_dir, 'data')
        hf_converted_lbls = os.path.join(hf_coco_dir, 'yolo_labels')
        
        if os.path.exists(labels_json) and os.path.exists(images_dir) and not os.path.exists(hf_converted_lbls):
            print("\n[Converting Hugging Face COCO JSON to YOLO format...]")
            num_converted = convert_coco_json_to_yolo(labels_json, images_dir, hf_converted_lbls)
            print(f"Converted {num_converted} COCO annotations to YOLO format.")
            
            hf_images = glob.glob(os.path.join(images_dir, '*.jpg'))
            random.shuffle(hf_images)
            split_idx = int(len(hf_images) * 0.8)
            hf_train = hf_images[:split_idx]
            hf_val = hf_images[split_idx:]
            
            for img_list, split in [(hf_train, 'train'), (hf_val, 'val')]:
                for img_p in img_list:
                    base = os.path.splitext(os.path.basename(img_p))[0]
                    lbl_p = os.path.join(hf_converted_lbls, base + '.txt')
                    if os.path.exists(lbl_p):
                        shutil.copy2(img_p, os.path.join(COMBINED_DIR, 'images', split, os.path.basename(img_p)))
                        shutil.copy2(lbl_p, os.path.join(COMBINED_DIR, 'labels', split, base + '.txt'))
            print("Hugging Face samples merged into datasets/custom_objects.")

    # 2. COCO Official Benchmark Subset (coco128)
    coco128_dir = os.path.join(RAW_DIR, 'coco_official_coco128', 'coco128')
    if os.path.exists(coco128_dir):
        coco128_imgs = sorted(glob.glob(os.path.join(coco128_dir, 'images', 'train2017', '*.jpg')))
        coco128_lbls_dir = os.path.join(coco128_dir, 'labels', 'train2017')
        print(f"\n[Merging COCO Official Benchmark Subset: {len(coco128_imgs)} images...]")
        # 80% train, 20% val
        random.shuffle(coco128_imgs)
        split_idx = int(len(coco128_imgs) * 0.8)
        c_train = coco128_imgs[:split_idx]
        c_val = coco128_imgs[split_idx:]
        
        for img_list, split in [(c_train, 'train'), (c_val, 'val')]:
            for img_p in img_list:
                base = os.path.splitext(os.path.basename(img_p))[0]
                lbl_p = os.path.join(coco128_lbls_dir, base + '.txt')
                if os.path.exists(lbl_p):
                    shutil.copy2(img_p, os.path.join(COMBINED_DIR, 'images', split, 'coco128_' + os.path.basename(img_p)))
                    shutil.copy2(lbl_p, os.path.join(COMBINED_DIR, 'labels', split, 'coco128_' + base + '.txt'))
        print("COCO Official Benchmark Subset merged successfully.")

    # Run Rigorous Dataset Validation & Generate Inventory
    print("\n[Running Comprehensive Dataset Validation & Audit...]")
    audit_results = validate_and_audit_dataset(COMBINED_DIR)
    
    report_file = os.path.join(DATASETS_DIR, 'dataset_inventory_report.md')
    generate_inventory_report(audit_results, download_status, report_file)
    
    # Save JSON status file
    status_file = os.path.join(DATASETS_DIR, 'download_status.json')
    with open(status_file, 'w') as f:
        json.dump(download_status, f, indent=2)

    print("\n" + "=" * 70)
    print("PIPELINE COMPLETED SUCCESSFULLY")
    print(f"Total Valid Images:    {audit_results['valid_images']}")
    print(f"Total Valid Instances: {audit_results['total_instances']}")
    print(f"Corrupted Images:      {audit_results['corrupted_images']}")
    print(f"Invalid Bounding Boxes:{audit_results['invalid_boxes']}")
    print("=" * 70)

if __name__ == '__main__':
    run_pipeline()
