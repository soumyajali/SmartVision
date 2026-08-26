from pathlib import Path


def export_tflite(model_path: str, output_path: str = 'model.tflite'):
    """Placeholder export entry point for YOLOv8 -> TensorFlow Lite conversion.

    The actual implementation should use the project’s trained PyTorch weights
    and the official Ultralytics export pipeline.
    """
    print(f"Exporting model from {model_path} to {output_path}")
    print("Use the final export command on a development machine with the proper ML dependencies.")


if __name__ == '__main__':
    export_tflite('yolov8n.pt', 'model.tflite')
