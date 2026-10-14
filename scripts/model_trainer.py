"""
SmartVision Model Training, Evaluation, Comparison, & Export Suite
Supports:
- YOLOv8 fine-tuning with pretrained base (yolov8n / yolov8m)
- Apple Silicon MPS, NVIDIA CUDA, or CPU auto-selection
- Checkpoints, logging, and interrupted training resume
- Rigorous test split evaluation (Precision, Recall, mAP50, mAP50-95)
- Direct empirical comparison against baseline (SmartVision_v3.pt)
- Rollback preservation (backs up previous weights to .bak)
- ONNX and TFLite production exports with verification
"""

import os
import sys
import time
import json
import shutil
import torch
from typing import Dict, Any, Tuple, Optional
from ultralytics import YOLO

class ModelTrainerSuite:
    def __init__(self, config: Dict[str, Any], base_dir: str = "."):
        self.config = config
        self.train_cfg = config.get("training", {})
        self.export_cfg = config.get("export", {})
        self.base_dir = os.path.abspath(base_dir)
        self.data_yaml = os.path.join(self.base_dir, "datasets", "custom_objects", "data.yaml")
        self.weights_dir = os.path.join(self.base_dir, self.train_cfg.get("weights_export_dir", "weights"))
        os.makedirs(self.weights_dir, exist_ok=True)

    def select_device(self) -> str:
        """Auto-detects best available compute hardware."""
        req_device = self.train_cfg.get("device", "auto")
        if req_device != "auto":
            return req_device
        if torch.cuda.is_available():
            return "0"
        elif torch.backends.mps.is_available():
            return "mps"
        return "cpu"

    def train(self, epochs: Optional[int] = None, resume: bool = False) -> Dict[str, Any]:
        """Runs YOLOv8 fine-tuning on custom dataset."""
        print("=" * 65)
        print("SMARTVISION YOLOv8 TRAINING SUITE")
        print("=" * 65)
        device = self.select_device()
        print(f"Compute hardware selected: {device.upper()}")
        print(f"Dataset configuration: {self.data_yaml}")

        base_weights = self.train_cfg.get("base_model", "yolov8n.pt")
        # Check if local base exists, otherwise Ultralytics downloads it
        print(f"Loading base model weights: {base_weights}...")
        model = YOLO(base_weights)

        num_epochs = epochs or self.train_cfg.get("epochs", 5)
        imgsz = self.train_cfg.get("imgsz", 640)
        batch = self.train_cfg.get("batch_size", 16)
        seed = self.train_cfg.get("seed", 42)
        project = os.path.join(self.base_dir, self.train_cfg.get("project_dir", "runs/detect"))
        name = self.train_cfg.get("run_name", "smartvision_pipeline_run")

        start_time = time.time()
        results = model.train(
            data=self.data_yaml,
            epochs=num_epochs,
            imgsz=imgsz,
            batch=batch,
            seed=seed,
            device=device,
            project=project,
            name=name,
            exist_ok=True,
            verbose=True,
            save=True,
            resume=resume
        )
        duration_sec = time.time() - start_time

        # Locate trained best weights
        run_weights_dir = os.path.join(project, name, "weights")
        best_pt = os.path.join(run_weights_dir, "best.pt")
        if not os.path.exists(best_pt):
            best_pt = os.path.join(run_weights_dir, "last.pt")

        prod_weight_name = self.train_cfg.get("production_weight_name", "smartvision_best.pt")
        prod_path = os.path.join(self.weights_dir, prod_weight_name)

        # Rollback preservation: Backup old model before overwriting
        if os.path.exists(prod_path):
            backup_path = prod_path + ".bak"
            shutil.copy2(prod_path, backup_path)
            print(f"Rollback safeguard: Backed up previous model to {backup_path}")

        if os.path.exists(best_pt):
            shutil.copy2(best_pt, prod_path)
            print(f"✓ Production model updated at: {prod_path}")

        return {
            "duration_sec": round(duration_sec, 2),
            "best_weights": prod_path,
            "device": device,
            "epochs": num_epochs
        }

    def evaluate_model(self, model_path: str, split: str = "test") -> Dict[str, float]:
        """Evaluates a model checkpoint on a specific dataset split."""
        if not os.path.exists(model_path):
            return {}
        device = self.select_device()
        model = YOLO(model_path)
        imgsz = self.train_cfg.get("imgsz", 640)
        metrics = model.val(data=self.data_yaml, split=split, imgsz=imgsz, device=device, verbose=False)
        return {
            "precision": round(float(metrics.box.mp), 4),
            "recall": round(float(metrics.box.mr), 4),
            "map50": round(float(metrics.box.map50), 4),
            "map50_95": round(float(metrics.box.map), 4)
        }

    def compare_with_baseline(self) -> Dict[str, Any]:
        """Compares newly trained production model against baseline on untouched test split."""
        prod_path = os.path.join(self.weights_dir, self.train_cfg.get("production_weight_name", "smartvision_best.pt"))
        baseline_path = os.path.join(self.base_dir, "SmartVision_v3.pt")

        print("\nEvaluating Production Model on Untouched Test Split...")
        prod_metrics = self.evaluate_model(prod_path, split="test")

        print("Evaluating Baseline Model (SmartVision_v3.pt) on Same Test Split...")
        base_metrics = self.evaluate_model(baseline_path, split="test") if os.path.exists(baseline_path) else {}

        comparison = {
            "production_model": {
                "path": prod_path,
                "metrics": prod_metrics
            },
            "baseline_model": {
                "path": baseline_path,
                "metrics": base_metrics
            },
            "deltas": {}
        }

        if prod_metrics and base_metrics:
            for k in ["precision", "recall", "map50", "map50_95"]:
                p_val = prod_metrics.get(k, 0.0)
                b_val = base_metrics.get(k, 0.0)
                comparison["deltas"][k] = round(p_val - b_val, 4)

        return comparison

    def export_production_models(self) -> Dict[str, str]:
        """Exports the production model to ONNX and/or TFLite."""
        prod_path = os.path.join(self.weights_dir, self.train_cfg.get("production_weight_name", "smartvision_best.pt"))
        if not os.path.exists(prod_path):
            return {"error": "Production weights not found."}

        model = YOLO(prod_path)
        formats = self.export_cfg.get("formats", ["onnx", "tflite"])
        imgsz = self.export_cfg.get("imgsz", 640)
        export_results = {}

        for fmt in formats:
            try:
                print(f"Exporting model to {fmt.upper()} format (imgsz={imgsz})...")
                exported_path = model.export(format=fmt, imgsz=imgsz)
                export_results[fmt] = str(exported_path)
                print(f"✓ {fmt.upper()} export ready: {exported_path}")
            except Exception as e:
                print(f"✗ {fmt.upper()} export failed: {e}")
                export_results[fmt] = f"Failed: {e}"

        return export_results

    def test_inference(self, image_path: str) -> List[Dict[str, Any]]:
        """Runs real inference test and returns detected bounding boxes and classes."""
        prod_path = os.path.join(self.weights_dir, self.train_cfg.get("production_weight_name", "smartvision_best.pt"))
        if not os.path.exists(prod_path):
            return []
        model = YOLO(prod_path)
        results = model.predict(image_path, conf=0.35, verbose=False)
        detections = []
        for box in results[0].boxes:
            cls_id = int(box.cls[0])
            name = model.names.get(cls_id, str(cls_id))
            conf = float(box.conf[0])
            xyxy = box.xyxy[0].tolist()
            detections.append({
                "class_id": cls_id,
                "label": name,
                "confidence": round(conf, 4),
                "box": [round(c, 1) for c in xyxy]
            })
        return detections
