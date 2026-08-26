import faiss
import numpy as np
import json
import os

class FAISSStore:
    def __init__(self, embedding_dim=512, index_file="face_index.faiss", meta_file="face_metadata.json"):
        self.embedding_dim = embedding_dim
        self.index_file = index_file
        self.meta_file = meta_file
        
        # ID to Name mapping
        self.metadata = {} 
        
        self._load_index()

    def _load_index(self):
        if os.path.exists(self.index_file):
            self.index = faiss.read_index(self.index_file)
        else:
            # We use IndexFlatIP for Inner Product (Cosine Similarity) since vectors are L2 normalized
            self.index = faiss.IndexIDMap(faiss.IndexFlatIP(self.embedding_dim))
            
        if os.path.exists(self.meta_file):
            with open(self.meta_file, 'r') as f:
                self.metadata = {int(k): v for k, v in json.load(f).items()}

    def save(self):
        faiss.write_index(self.index, self.index_file)
        with open(self.meta_file, 'w') as f:
            json.dump(self.metadata, f)

    def add_embedding(self, embedding: np.ndarray, name: str) -> bool:
        """
        Adds a single L2-normalized embedding to the index.
        """
        if embedding.shape[0] != self.embedding_dim:
            return False
            
        # Generate new ID
        new_id = 0 if not self.metadata else max(self.metadata.keys()) + 1
        
        # FAISS expects 2D array
        emb_2d = np.expand_dims(embedding, axis=0).astype(np.float32)
        id_array = np.array([new_id], dtype=np.int64)
        
        self.index.add_with_ids(emb_2d, id_array)
        self.metadata[new_id] = name
        self.save()
        return True

    def search(self, embedding: np.ndarray, k=1, threshold=0.5):
        """
        Searches for the closest embeddings.
        Since vectors are L2 normalized and we use IndexFlatIP, the distance is cosine similarity [-1, 1].
        """
        if self.index.ntotal == 0:
            return []
            
        emb_2d = np.expand_dims(embedding, axis=0).astype(np.float32)
        distances, indices = self.index.search(emb_2d, k)
        
        results = []
        for dist, idx in zip(distances[0], indices[0]):
            if idx != -1 and dist >= threshold: # Cosine similarity threshold
                name = self.metadata.get(int(idx), "Unknown")
                results.append({"name": name, "confidence": float(dist)})
                
        return results
        
    def get_registered_faces(self):
        # Return unique names
        return list(set(self.metadata.values()))
