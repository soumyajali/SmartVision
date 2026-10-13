"""
SmartVision Mobile & Embedded Model Export Suite
Exports trained YOLOv8 PyTorch checkpoints to TorchScript, ONNX, and TFLite formats.
"""

import os
from pathlib import Path
from ultralytics import YOLO

def export_models(model_path: str = 'weights/smartvision_best.pt', imgsz: int = 416):
    if not os.path.exists(model_path):
        model_path = 'yolov8n.pt'
        
    print(f"Loading trained model from {model_path}...")
    model = YOLO(model_path)
    
    # 1. Native TorchScript Export (High performance mobile/C++ runtime)
    print("\n--- Exporting to TorchScript format ---")
    try:
        ts_path = model.export(format='torchscript', imgsz=imgsz)
        print(f"Successfully exported TorchScript: {ts_path}")
    except Exception as e:
        print(f"TorchScript export failed: {e}")

    # 2. ONNX Export
    print("\n--- Exporting to ONNX format ---")
    try:
        onnx_path = model.export(format='onnx', imgsz=imgsz)
        print(f"Successfully exported ONNX: {onnx_path}")
    except Exception as e:
        print(f"ONNX export notice: {e}")
        print("Note: On Python 3.14 on macOS, install ONNX runtime wheels when available: pip install onnx onnxruntime")

    # 3. TFLite Export
    print("\n--- Exporting to TensorFlow Lite format ---")
    try:
        tflite_path = model.export(format='tflite', imgsz=imgsz)
        print(f"Successfully exported TFLite: {tflite_path}")
        # Copy to app assets
        os.makedirs('app/assets', exist_ok=True)
        import shutil
        shutil.copy2(tflite_path, 'app/assets/model.tflite')
        print("Copied valid model to app/assets/model.tflite")
    except Exception as e:
        print(f"TFLite export notice: {e}")
        print("Note: TensorFlow Lite export requires tensorflow, which currently supports Python <= 3.12.")

if __name__ == '__main__':
    export_models()
