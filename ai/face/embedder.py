import tensorflow as tf
import numpy as np
import cv2

class FaceEmbedder:
    def __init__(self, model_path="mobilefacenet.tflite"):
        self.interpreter = tf.lite.Interpreter(model_path=model_path)
        self.interpreter.allocate_tensors()
        
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()
        
        # Get expected input shape
        shape = self.input_details[0]['shape']
        if len(shape) == 4:
            if shape[1] == 3: # NCHW
                self.input_size = (shape[2], shape[3])
                self.channel_first = True
            else: # NHWC
                self.input_size = (shape[1], shape[2])
                self.channel_first = False
        else:
            self.input_size = (112, 112) # Fallback
            self.channel_first = False

    def get_embedding(self, face_image: np.ndarray) -> np.ndarray:
        """
        Takes an RGB cropped face image, preprocesses it, and returns a normalized embedding.
        """
        # Resize to expected model input size
        resized = cv2.resize(face_image, self.input_size)
        
        # Normalize to [-1, 1]
        input_data = np.array(resized, dtype=np.float32)
        input_data = (input_data - 127.5) / 128.0
        
        # Add batch dimension
        input_data = np.expand_dims(input_data, axis=0)
        
        # Channel arrangement
        if self.channel_first:
            input_data = np.transpose(input_data, (0, 3, 1, 2))
            
        # Run inference
        self.interpreter.set_tensor(self.input_details[0]['index'], input_data)
        self.interpreter.invoke()
        
        # Get output
        embedding = self.interpreter.get_tensor(self.output_details[0]['index'])[0]
        
        # L2 Normalize the embedding for cosine similarity equivalent in FAISS FlatL2
        norm = np.linalg.norm(embedding)
        if norm > 0:
            embedding = embedding / norm
            
        return embedding
