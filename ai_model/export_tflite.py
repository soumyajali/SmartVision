import os
from ultralytics import YOLO

def export_to_tflite():
    """
    Loads the PyTorch YOLOv8n model and exports it to TensorFlow Lite format.
    Optimized for mobile using float16 quantization.
    """
    model_path = os.path.join('models', 'yolov8n.pt')
    
    if not os.path.exists(model_path):
        print(f"Error: {model_path} not found. Please run download_model.py first.")
        return

    print(f"Loading PyTorch model from {model_path}...")
    model = YOLO(model_path)
    
    print("Exporting to TensorFlow Lite (Float16)...")
    # Export to TFLite format
    # format='tflite'
    # half=True (float16 quantization for faster mobile inference and smaller size)
    # int8=False (int8 requires representative dataset, float16 is easier and works well)
    model.export(format='tflite', half=True)
    
    print("Export complete. The exported model should be located in the models/ directory or next to the original .pt file.")
    print("Please copy the generated yolov8n_float16.tflite (or similarly named .tflite file) to ../assets/models/yolov8n.tflite")

if __name__ == '__main__':
    export_to_tflite()
