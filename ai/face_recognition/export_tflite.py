import argparse
import torch
import tensorflow as tf
import numpy as np
import onnx
import subprocess
try:
    from onnx_tf.backend import prepare
except ImportError:
    pass
from ultralytics import YOLO

def export_yolov8(model_name="yolov8m.pt"):
    print(f"Exporting {model_name} to TFLite (int8)...")
    # Ultralytics handles this nicely under the hood
    model = YOLO(model_name)
    model.export(format="tflite", int8=True)
    print(f"Finished exporting {model_name}.")

def export_face_model(weights_path, output_path):
    print("Converting PyTorch MobileFaceNet to TensorFlow Lite...")
    try:
        from train_arcface import MobileFaceNet
    except ImportError:
        print("train_arcface not found, skipping MobileFaceNet export.")
        return

    # 1. Load PyTorch model
    model = MobileFaceNet(embedding_size=512)
    try:
        model.load_state_dict(torch.load(weights_path, map_location=torch.device('cpu')))
    except FileNotFoundError:
        print(f"Weights file {weights_path} not found. Exporting randomly initialized model for demonstration.")
    
    model.eval()

    # 2. Export to ONNX
    dummy_input = torch.randn(1, 3, 112, 112)
    onnx_path = "mobilefacenet.onnx"
    torch.onnx.export(
        model, dummy_input, onnx_path, 
        input_names=["input"], output_names=["output"],
        opset_version=11
    )
    print("Exported to ONNX.")

    # 3. Convert ONNX to TensorFlow SavedModel
    onnx_model = onnx.load(onnx_path)
    tf_rep = prepare(onnx_model)
    saved_model_dir = "mobilefacenet_tf"
    tf_rep.export_graph(saved_model_dir)
    print("Converted ONNX to TF SavedModel.")

    # 4. Convert TF SavedModel to TFLite
    converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
    
    # Optimize for latency (float16 quantization)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    tflite_model = converter.convert()

    with open(output_path, "wb") as f:
        f.write(tflite_model)

    print(f"Successfully exported TFLite model to {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Export models to TFLite")
    parser.add_argument("--weights", type=str, default="mobilefacenet_weights.pth", help="Path to PyTorch weights")
    parser.add_argument("--output", type=str, default="mobilefacenet.tflite", help="Path for output TFLite model")
    args = parser.parse_args()
    
    export_yolov8("yolov8m.pt")
    export_face_model(args.weights, args.output)
