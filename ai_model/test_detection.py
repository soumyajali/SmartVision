import numpy as np
import tensorflow as tf
from PIL import Image
import os

def load_labels(label_path):
    with open(label_path, 'r') as f:
        return [line.strip() for line in f.readlines()]

def test_tflite_model(model_path, image_path, label_path):
    if not os.path.exists(model_path):
        print(f"Error: Model not found at {model_path}")
        return
        
    if not os.path.exists(image_path):
        print(f"Error: Sample image not found at {image_path}")
        print("Please place a sample image named 'sample.jpg' in this directory.")
        return

    print("Loading labels...")
    labels = load_labels(label_path)
    
    print(f"Loading TFLite model from {model_path}...")
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Get input shape
    height, width = input_details[0]['shape'][1], input_details[0]['shape'][2]

    print(f"Model expects input shape: ({width}, {height})")
    
    # Load and preprocess image
    img = Image.open(image_path).resize((width, height))
    img_data = np.array(img, dtype=np.float32) / 255.0 # Normalize to [0, 1]
    img_data = np.expand_dims(img_data, axis=0) # Add batch dimension

    print("Running inference...")
    interpreter.set_tensor(input_details[0]['index'], img_data)
    interpreter.invoke()

    output_data = interpreter.get_tensor(output_details[0]['index'])
    
    # Output structure of YOLOv8 TFLite depends on export. 
    # Usually it's [1, 84, 8400] where 84 = 4 (bbox) + 80 (classes)
    
    print(f"Output shape: {output_data.shape}")
    
    # Simple parse for demonstration (actual parsing needs NMS which is complex in plain numpy)
    # We'll just look for the highest confidence detection
    if len(output_data.shape) == 3:
        predictions = np.squeeze(output_data).T # Transpose to [8400, 84]
        
        # Find highest score
        scores = np.max(predictions[:, 4:], axis=1)
        best_idx = np.argmax(scores)
        best_score = scores[best_idx]
        class_id = np.argmax(predictions[best_idx, 4:])
        bbox = predictions[best_idx, :4]
        
        if best_score > 0.5:
            object_name = labels[class_id]
            print("\n--- Detection Result ---")
            print(f"Object: {object_name}")
            print(f"Confidence: {best_score:.2%}")
            print(f"Bounding Box (cx, cy, w, h): {bbox}")
        else:
            print("No objects detected with confidence > 50%.")
            
if __name__ == '__main__':
    # You may need to update the model path based on what Ultralytics outputs
    model_file = os.path.join('models', 'yolov8n_saved_model', 'yolov8n_float16.tflite') 
    if not os.path.exists(model_file):
        # Fallback to current dir if export placed it there
        model_file = 'yolov8n_float16.tflite'
        
    test_tflite_model(
        model_path=model_file,
        image_path='sample.jpg', # You must provide this image
        label_path='labels.txt'
    )
