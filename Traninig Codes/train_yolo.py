import os
import ssl
ssl._create_default_https_context = ssl._create_unverified_context
from ultralytics import YOLO

def main():
    print("Initializing YOLOv8 Nano model...")
    # Load a model
    model = YOLO('yolov8n.pt')  # load a pretrained model (recommended for training)

    print("Starting training on coco8 dataset...")
    # Train the model using the 'coco8.yaml' dataset for 3 epochs
    # coco8 is a tiny sample of the COCO dataset built into ultralytics for testing
    results = model.train(data='coco8.yaml', epochs=3, imgsz=640)

    print("Training complete! The best weights are saved in the 'runs/detect/train/weights/' directory.")

if __name__ == '__main__':
    main()
