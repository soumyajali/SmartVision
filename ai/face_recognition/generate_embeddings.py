import argparse
import numpy as np
import tensorflow as tf
from PIL import Image

def generate_embedding(tflite_path, image_path):
    print(f"Loading TFLite model from {tflite_path}...")
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print(f"Loading and preprocessing image {image_path}...")
    try:
        img = Image.open(image_path).convert('RGB').resize((112, 112))
        input_data = np.array(img, dtype=np.float32)
        # Normalize to [-1, 1]
        input_data = (input_data - 127.5) / 128.0
        input_data = np.expand_dims(input_data, axis=0) # Add batch dimension [1, 112, 112, 3] or [1, 3, 112, 112]
        
        # Adjust for channel-first if needed by checking input shape
        if input_details[0]['shape'][1] == 3:
            input_data = np.transpose(input_data, (0, 3, 1, 2))

        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()

        output_data = interpreter.get_tensor(output_details[0]['index'])
        embedding = output_data[0]
        
        print("\nGenerated 512-D Embedding Vector:")
        print(embedding[:10], "... (truncated)")
        
        # Save to disk
        out_file = image_path.split('.')[0] + "_embedding.npy"
        np.save(out_file, embedding)
        print(f"Embedding saved to {out_file}")

    except Exception as e:
        print(f"Error generating embedding: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Embedding using TFLite Model")
    parser.add_argument("--model", type=str, default="mobilefacenet.tflite", help="Path to TFLite model")
    parser.add_argument("--image", type=str, required=True, help="Path to aligned 112x112 face image")
    args = parser.parse_args()
    
    generate_embedding(args.model, args.image)
