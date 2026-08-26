from ultralytics import YOLO

def export_model():
    print("Loading YOLOv8 Nano model...")
    model = YOLO('yolov8n.pt') 
    print("Exporting model to TensorFlow Lite format...")
    model.export(format='tflite', optimize=True, half=True, imgsz=320)
    print("Export complete. Copy the .tflite file to your Android assets folder.")

if __name__ == '__main__':
    export_model()
