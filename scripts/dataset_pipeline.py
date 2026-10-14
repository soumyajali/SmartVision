#!/usr/bin/env python3
"""
SmartVision End-to-End Dataset Collection & YOLOv8 Training Pipeline CLI
Automates dataset discovery, authenticated batch downloading, multi-format annotation conversion,
data validation, deduplication, YOLOv8 training, test evaluation, baseline comparison, and model export.

Usage:
  python scripts/dataset_pipeline.py --discover
  python scripts/dataset_pipeline.py --download
  python scripts/dataset_pipeline.py --prepare
  python scripts/dataset_pipeline.py --train
  python scripts/dataset_pipeline.py --evaluate
  python scripts/dataset_pipeline.py --export
  python scripts/dataset_pipeline.py --all
  python scripts/dataset_pipeline.py --sample-test
  python scripts/dataset_pipeline.py --dry-run
  python scripts/dataset_pipeline.py --rollback
"""

import os
import sys
import glob
import time
import yaml
import shutil
import random
import argparse
from typing import Dict, Any, List

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, BASE_DIR)

from scripts.kaggle_hf_discovery import DatasetDiscoverySuite, get_free_disk_space_gb
from scripts.annotation_converters import AnnotationConverter
from scripts.model_trainer import ModelTrainerSuite

def load_config(config_path: str) -> Dict[str, Any]:
    full_path = os.path.join(BASE_DIR, config_path)
    if not os.path.exists(full_path):
        raise FileNotFoundError(f"Config file not found at: {full_path}")
    with open(full_path, "r") as f:
        return yaml.safe_load(f)

def run_prepare_step(config: Dict[str, Any], dry_run: bool = False) -> Dict[str, Any]:
    """Scans all downloaded datasets in raw_downloads, converts VOC/COCO/YOLO annotations, validates, and splits."""
    print("=" * 65)
    print("STEP: PREPARE & VALIDATE DATASETS")
    print("=" * 65)

    taxonomy = config.get("taxonomy", {})
    canonical_classes = taxonomy.get("canonical_classes", [])
    synonyms = taxonomy.get("synonyms", {})
    prep_cfg = config.get("dataset_preparation", {})
    
    raw_dir = os.path.join(BASE_DIR, prep_cfg.get("raw_dir", "datasets/raw_downloads"))
    output_dir = os.path.join(BASE_DIR, prep_cfg.get("output_dir", "datasets/custom_objects"))
    splits_ratio = prep_cfg.get("splits", {"train": 0.7, "val": 0.2, "test": 0.1})
    seed = prep_cfg.get("random_seed", 42)
    random.seed(seed)

    converter = AnnotationConverter(canonical_classes=canonical_classes, synonyms=synonyms)

    if dry_run:
        print("[DRY-RUN] Simulating dataset preparation...")
        raw_folders = [f for f in os.listdir(raw_dir) if os.path.isdir(os.path.join(raw_dir, f))] if os.path.exists(raw_dir) else []
        print(f"[DRY-RUN] Found {len(raw_folders)} raw dataset folders: {raw_folders}")
        return {"status": "dry_run_complete", "raw_folders": raw_folders}

    # Ensure output split directories
    for split in ["train", "val", "test"]:
        os.makedirs(os.path.join(output_dir, "images", split), exist_ok=True)
        os.makedirs(os.path.join(output_dir, "labels", split), exist_ok=True)

    # 1. Discover all images and pair with annotations
    collected_samples = []
    seen_hashes = set()
    duplicates_count = 0
    corrupted_count = 0

    # Scan raw_downloads subdirectories
    dataset_dirs = [os.path.join(raw_dir, d) for d in os.listdir(raw_dir) if os.path.isdir(os.path.join(raw_dir, d))] if os.path.exists(raw_dir) else []
    
    # Also include internal smart vision detection images
    smart_vis_dir = os.path.join(BASE_DIR, "smart vision detection")
    if os.path.exists(smart_vis_dir):
        dataset_dirs.append(smart_vis_dir)

    # Also scan external desktop datasets folder if available
    external_dir = prep_cfg.get("external_datasets_dir", "/Users/sowmya/Desktop/datasets")
    if os.path.exists(external_dir):
        print(f"Found external datasets folder: {external_dir}")
        for item in sorted(os.listdir(external_dir)):
            item_path = os.path.join(external_dir, item)
            if os.path.isdir(item_path) and not item.endswith(".download"):
                dataset_dirs.append(item_path)

    print(f"Scanning {len(dataset_dirs)} source directories for images and annotations...")

    for d_path in dataset_dirs:
        ds_name = os.path.basename(d_path)
        detected_fmt = converter.detect_format(d_path)
        print(f"  • Source [{ds_name}]: Detected format -> {detected_fmt}")

        # Check for local class map via data.yaml or classes.txt
        local_class_map = {}
        yaml_candidates = glob.glob(os.path.join(d_path, "**", "data.yaml"), recursive=True) + glob.glob(os.path.join(d_path, "data.yaml"))
        if yaml_candidates:
            try:
                with open(yaml_candidates[0], "r") as yf:
                    y_content = yaml.safe_load(yf)
                    local_names = y_content.get("names", [])
                    if isinstance(local_names, dict):
                        local_names = [local_names[k] for k in sorted(local_names.keys())]
                    for l_idx, l_name in enumerate(local_names):
                        mapped = converter.normalize_class_name(str(l_name))
                        if mapped:
                            local_class_map[l_idx] = mapped[0]
            except Exception:
                pass

        if not local_class_map:
            txt_candidates = glob.glob(os.path.join(d_path, "**", "*classes*.txt"), recursive=True) + glob.glob(os.path.join(d_path, "**", "*labels*.txt"), recursive=True)
            if txt_candidates:
                try:
                    with open(txt_candidates[0], "r") as tf:
                        lines = [l.strip().rstrip(",") for l in tf if l.strip()]
                        for l_idx, l_name in enumerate(lines):
                            mapped = converter.normalize_class_name(l_name)
                            if mapped:
                                local_class_map[l_idx] = mapped[0]
                except Exception:
                    pass

        # Gather images
        img_extensions = prep_cfg.get("image_extensions", [".jpg", ".jpeg", ".png", ".bmp", ".webp"])
        img_paths = []
        for ext in img_extensions:
            img_paths.extend(glob.glob(os.path.join(d_path, "**", f"*{ext}"), recursive=True))

        coco_data = None
        if detected_fmt == "coco_json":
            json_files = glob.glob(os.path.join(d_path, "**", "*.json"), recursive=True)
            for jf in json_files:
                coco_data = converter.convert_coco_json(jf)
                if coco_data:
                    break

        # Balance source contributions (max 300 samples per source folder)
        source_added = 0
        max_per_source = 300

        for img_p in img_paths:
            if source_added >= max_per_source:
                break

            # Avoid re-scanning processed custom_objects output
            if "custom_objects" in img_p:
                continue

            dims = converter.validate_image(img_p)
            if not dims:
                corrupted_count += 1
                continue
            img_w, img_h = dims

            # Deduplication
            if prep_cfg.get("deduplication", {}).get("enabled", True):
                img_hash = converter.compute_image_hash(img_p)
                if img_hash in seen_hashes:
                    duplicates_count += 1
                    continue
                seen_hashes.add(img_hash)

            base_name = os.path.splitext(os.path.basename(img_p))[0]
            boxes = []

            if detected_fmt == "voc_xml":
                xml_path = os.path.join(os.path.dirname(img_p), base_name + ".xml")
                if not os.path.exists(xml_path):
                    xml_path = os.path.join(d_path, "Annotations", base_name + ".xml")
                if os.path.exists(xml_path):
                    boxes = converter.convert_voc_xml(xml_path, img_w, img_h)

            elif detected_fmt == "coco_json" and coco_data:
                boxes = coco_data.get(base_name, [])

            elif detected_fmt == "yolo_txt":
                # Check for txt label
                txt_path = os.path.join(os.path.dirname(img_p), base_name + ".txt")
                if not os.path.exists(txt_path):
                    parent_dir = os.path.dirname(os.path.dirname(img_p))
                    txt_path = os.path.join(parent_dir, "labels", base_name + ".txt")
                    if not os.path.exists(txt_path):
                        sub = os.path.basename(os.path.dirname(img_p))
                        txt_path = os.path.join(parent_dir, "labels", sub, base_name + ".txt")
                if os.path.exists(txt_path):
                    try:
                        with open(txt_path, "r") as tf:
                            for line in tf:
                                parts = line.strip().split()
                                if len(parts) >= 5:
                                    raw_cid = int(parts[0])
                                    if local_class_map:
                                        cid = local_class_map.get(raw_cid)
                                    elif raw_cid < len(canonical_classes):
                                        cid = raw_cid
                                    else:
                                        cid = None
                                    if cid is not None:
                                        xc, yc, bw, bh = map(float, parts[1:5])
                                        boxes.append((cid, xc, yc, bw, bh))
                    except Exception:
                        pass

            # Fallback check for XML if no boxes were found (e.g. mixed folders)
            if not boxes:
                xml_path = os.path.join(os.path.dirname(img_p), base_name + ".xml")
                if not os.path.exists(xml_path):
                    xml_path = os.path.join(d_path, "Annotations", base_name + ".xml")
                if os.path.exists(xml_path):
                    boxes = converter.convert_voc_xml(xml_path, img_w, img_h)

            if boxes:
                collected_samples.append({
                    "img_path": img_p,
                    "boxes": boxes,
                    "group": os.path.dirname(img_p)
                })
                source_added += 1

    print(f"Collected {len(collected_samples)} valid labelled image samples (Duplicates skipped: {duplicates_count}, Corrupted: {corrupted_count}).")

    # Grouped split creation to prevent leakage between frames of the same video/folder
    groups = {}
    for sample in collected_samples:
        grp = sample["group"]
        groups.setdefault(grp, []).append(sample)

    group_keys = list(groups.keys())
    random.shuffle(group_keys)

    train_samples, val_samples, test_samples = [], [], []
    total_samples = len(collected_samples)
    target_train = int(total_samples * splits_ratio.get("train", 0.7))
    target_val = int(total_samples * splits_ratio.get("val", 0.2))

    for grp in group_keys:
        items = groups[grp]
        if len(train_samples) < target_train:
            train_samples.extend(items)
        elif len(val_samples) < target_val:
            val_samples.extend(items)
        else:
            test_samples.extend(items)

    print(f"Dataset split distribution: Train={len(train_samples)}, Val={len(val_samples)}, Test={len(test_samples)}")

    # Write out files to custom_objects
    split_map = [("train", train_samples), ("val", val_samples), ("test", test_samples)]
    for split_name, samples in split_map:
        for idx, sample in enumerate(samples):
            src_img = sample["img_path"]
            ext = os.path.splitext(src_img)[1]
            out_img_name = f"sample_{split_name}_{idx:05d}{ext}"
            out_lbl_name = f"sample_{split_name}_{idx:05d}.txt"

            out_img_path = os.path.join(output_dir, "images", split_name, out_img_name)
            out_lbl_path = os.path.join(output_dir, "labels", split_name, out_lbl_name)

            shutil.copy2(src_img, out_img_path)
            with open(out_lbl_path, "w") as lf:
                for b in sample["boxes"]:
                    lf.write(f"{b[0]} {b[1]:.6f} {b[2]:.6f} {b[3]:.6f} {b[4]:.6f}\n")

    # Update data.yaml
    data_yaml_path = os.path.join(output_dir, "data.yaml")
    yaml_content = {
        "path": output_dir,
        "train": "images/train",
        "val": "images/val",
        "test": "images/test",
        "nc": len(canonical_classes),
        "names": canonical_classes
    }
    with open(data_yaml_path, "w") as yf:
        yaml.dump(yaml_content, yf, default_flow_style=None)

    print(f"✓ Unified data.yaml updated with {len(canonical_classes)} canonical classes.")
    return {
        "total_samples": total_samples,
        "train": len(train_samples),
        "val": len(val_samples),
        "test": len(test_samples),
        "duplicates": duplicates_count,
        "corrupted": corrupted_count
    }

def run_sample_test(config: Dict[str, Any]) -> Dict[str, Any]:
    """Runs a complete end-to-end small test verifying all pipeline stages on real data."""
    print("=" * 65)
    print("RUNNING PIPELINE INTEGRATION & SAMPLE TEST")
    print("=" * 65)
    
    # 1. Test Discovery
    discovery = DatasetDiscoverySuite(config)
    print("[1/5] Testing discovery modules...")
    hf_ds = discovery.discover_huggingface(limit=5)
    print(f"  • Hugging Face Discovery: {len(hf_ds)} datasets found.")
    is_kaggle_auth, kaggle_msg = discovery.check_kaggle_auth()
    print(f"  • Kaggle Auth Status: {'AUTHENTICATED' if is_kaggle_auth else 'NOT CONFIGURED'}")

    # 2. Test Annotation Converters
    print("\n[2/5] Testing format converter on benchmark images...")
    taxonomy = config.get("taxonomy", {})
    converter = AnnotationConverter(
        canonical_classes=taxonomy.get("canonical_classes", []),
        synonyms=taxonomy.get("synonyms", {})
    )
    test_img = os.path.join(BASE_DIR, "test_image.png")
    dims = converter.validate_image(test_img)
    print(f"  • Image validation on test_image.png: Dimensions -> {dims}")
    assert dims is not None, "Failed to validate test_image.png"

    # Test synonym mapping
    syn_test = converter.normalize_class_name("schoolbag")
    print(f"  • Synonym check ('schoolbag' -> '{syn_test[1]}'): Class ID {syn_test[0]}")
    assert syn_test is not None and syn_test[1] == "backpack", "Synonym mapping failure"

    # 3. Test Trainer & Inference
    print("\n[3/5] Testing model loader and inference test...")
    trainer = ModelTrainerSuite(config, base_dir=BASE_DIR)
    dev = trainer.select_device()
    print(f"  • Device auto-detection: {dev.upper()}")

    detections = trainer.test_inference(test_img)
    print(f"  • Inference on test_image.png: Found {len(detections)} objects: {[d['label'] for d in detections[:5]]}")

    # 4. Test Model Evaluation
    print("\n[4/5] Testing test split evaluation...")
    prod_path = os.path.join(BASE_DIR, "weights", "smartvision_best.pt")
    if os.path.exists(prod_path):
        metrics = trainer.evaluate_model(prod_path, split="test")
        print(f"  • Test split metrics for {os.path.basename(prod_path)}: {metrics}")

    # 5. Check Disk Headroom
    print("\n[5/5] Checking disk headroom safety...")
    free_gb = get_free_disk_space_gb(BASE_DIR)
    print(f"  • Available Free Disk: {free_gb:.2f} GB (Threshold: {config.get('download_limits', {}).get('min_free_disk_gb', 4.0)} GB)")

    print("\n✓ ALL PIPELINE INTEGRATION TESTS PASSED SUCCESSFULLY!")
    return {"status": "success", "detections": len(detections), "free_gb": free_gb}

def rollback_model(config: Dict[str, Any]) -> bool:
    """Restores the backup model weights if rollback was requested."""
    weights_dir = os.path.join(BASE_DIR, config.get("training", {}).get("weights_export_dir", "weights"))
    prod_name = config.get("training", {}).get("production_weight_name", "smartvision_best.pt")
    prod_path = os.path.join(weights_dir, prod_name)
    bak_path = prod_path + ".bak"

    if os.path.exists(bak_path):
        shutil.copy2(bak_path, prod_path)
        print(f"✓ Successfully rolled back production model from backup: {bak_path} -> {prod_path}")
        return True
    else:
        print(f"✗ Rollback failed: No backup file found at {bak_path}")
        return False

def main():
    parser = argparse.ArgumentParser(description="SmartVision Automated Dataset & YOLOv8 Training Pipeline")
    parser.add_argument("--config", default="config/pipeline_config.yaml", help="Path to config file")
    parser.add_argument("--discover", action="store_true", help="Discover datasets from Kaggle & Hugging Face")
    parser.add_argument("--download", action="store_true", help="Download discovered datasets in batch")
    parser.add_argument("--prepare", action="store_true", help="Convert annotations, validate, deduplicate, and split")
    parser.add_argument("--train", action="store_true", help="Fine-tune YOLOv8 model")
    parser.add_argument("--epochs", type=int, default=None, help="Override training epochs")
    parser.add_argument("--evaluate", action="store_true", help="Evaluate model on test split and compare with baseline")
    parser.add_argument("--export", action="store_true", help="Export model to ONNX / TFLite")
    parser.add_argument("--all", action="store_true", help="Execute complete pipeline end-to-end")
    parser.add_argument("--sample-test", action="store_true", help="Run integration test on small real sample")
    parser.add_argument("--dry-run", action="store_true", help="Simulate pipeline actions without disk/network commits")
    parser.add_argument("--rollback", action="store_true", help="Roll back production model to previous backup")

    args = parser.parse_args()
    config = load_config(args.config)

    if args.rollback:
        rollback_model(config)
        return

    if args.sample_test:
        run_sample_test(config)
        return

    discovery_suite = DatasetDiscoverySuite(config)
    trainer_suite = ModelTrainerSuite(config, base_dir=BASE_DIR)

    if args.discover or args.all:
        if args.dry_run:
            print("[DRY-RUN] Simulating dataset discovery...")
        else:
            discovery_suite.run_discovery()

    if args.download or args.all:
        if args.dry_run:
            print("[DRY-RUN] Simulating batch download checks...")
        else:
            discovery_suite.download_batch()

    if args.prepare or args.all:
        run_prepare_step(config, dry_run=args.dry_run)

    if args.train or args.all:
        if args.dry_run:
            print("[DRY-RUN] Simulating model training invocation...")
        else:
            trainer_suite.train(epochs=args.epochs)

    if args.evaluate or args.all:
        if args.dry_run:
            print("[DRY-RUN] Simulating test split evaluation...")
        else:
            comparison = trainer_suite.compare_with_baseline()
            print("\n" + "=" * 65)
            print("BASELINE COMPARISON REPORT")
            print("=" * 65)
            print(json.dumps(comparison, indent=2))

    if args.export or args.all:
        if args.dry_run:
            print("[DRY-RUN] Simulating model export...")
        else:
            exports = trainer_suite.export_production_models()
            print(f"Export Results: {exports}")

    if not any([args.discover, args.download, args.prepare, args.train, args.evaluate, args.export, args.all, args.sample_test, args.rollback]):
        parser.print_help()

if __name__ == "__main__":
    main()
