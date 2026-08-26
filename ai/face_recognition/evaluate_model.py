import argparse
import numpy as np

def cosine_similarity(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

def evaluate_embeddings(emb1_path, emb2_path):
    print("Evaluating Cosine Similarity...")
    try:
        emb1 = np.load(emb1_path)
        emb2 = np.load(emb2_path)
        
        similarity = cosine_similarity(emb1, emb2)
        print(f"Similarity Score: {similarity:.4f}")
        
        threshold = 0.75
        if similarity >= threshold:
            print(f"Result: MATCH (>= {threshold})")
        else:
            print(f"Result: NO MATCH (< {threshold})")
            
    except FileNotFoundError as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Evaluate similarity between two embeddings")
    parser.add_argument("--emb1", type=str, required=True, help="Path to first embedding .npy")
    parser.add_argument("--emb2", type=str, required=True, help="Path to second embedding .npy")
    args = parser.parse_args()
    
    evaluate_embeddings(args.emb1, args.emb2)
