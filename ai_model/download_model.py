import os
from ultralytics import YOLO

def download_yolov8n():
    """
    Downloads the YOLOv8n pretrained model to the local directory.
    Ultralytics handles the download automatically when initializing the model.
    """
    model_name = 'yolov8n.pt'
    models_dir = 'models'
    
    if not os.path.exists(models_dir):
        os.makedirs(models_dir)
        
    model_path = os.path.join(models_dir, model_name)
    
    print(f"Initializing YOLOv8n... (this will download '{model_name}' if not present)")
    # Loading the model triggers the download
    model = YOLO('yolov8n.pt') 
    
    # Save a copy into our models folder if it was downloaded elsewhere (e.g., current dir)
    if os.path.exists('yolov8n.pt'):
        os.rename('yolov8n.pt', model_path)
        print(f"Model successfully saved to {model_path}")
    elif os.path.exists(model_path):
        print(f"Model already exists at {model_path}")
    else:
        print("Warning: Model might have been cached elsewhere by Ultralytics.")
        
if __name__ == '__main__':
    download_yolov8n()
