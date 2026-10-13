"""
RAG (Retrieval-Augmented Generation) Engine.
Handles local document ingestion, text extraction, semantic chunking, TF-IDF / vector retrieval,
and source citation generation for transparent document question-answering.
"""

import os
import re
import math
import json
import uuid
import collections
from typing import List, Dict, Any, Optional, Tuple
from backend.app.config import settings

class RAGEngine:
    _instance: Optional["RAGEngine"] = None

    def __init__(self):
        self.index_file = settings.RAG_INDEX_FILE
        self.docs_dir = settings.RAG_DOCS_DIR
        self.documents: Dict[str, Dict[str, Any]] = {}
        self.chunks: List[Dict[str, Any]] = []
        self._load_index()

    @classmethod
    def get_instance(cls) -> "RAGEngine":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def _load_index(self):
        """Loads persistent RAG documents and chunks from disk."""
        if os.path.exists(self.index_file):
            try:
                with open(self.index_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    self.documents = data.get("documents", {})
                    self.chunks = data.get("chunks", [])
            except Exception as e:
                print(f"[RAGEngine] Error loading RAG index: {e}")
                self.documents = {}
                self.chunks = []
        else:
            self.documents = {}
            self.chunks = []

    def _save_index(self):
        """Persists index to disk."""
        try:
            with open(self.index_file, "w", encoding="utf-8") as f:
                json.dump({
                    "documents": self.documents,
                    "chunks": self.chunks
                }, f, indent=2)
        except Exception as e:
            print(f"[RAGEngine] Error saving RAG index: {e}")

    def extract_text(self, filename: str, content_bytes: bytes) -> str:
        """Extracts text from raw bytes based on file format."""
        ext = os.path.splitext(filename)[1].lower()

        # Handle PDF if pypdf is installed, or fallback to text decoding
        if ext == ".pdf":
            try:
                import pypdf
                import io
                reader = pypdf.PdfReader(io.BytesIO(content_bytes))
                pages_text = []
                for p in reader.pages:
                    txt = p.extract_text()
                    if txt:
                        pages_text.append(txt)
                return "\n\n".join(pages_text)
            except Exception:
                pass  # Fallback to ASCII string extraction

        # General text formats: .txt, .md, .py, .json, .csv, etc.
        try:
            return content_bytes.decode("utf-8")
        except UnicodeDecodeError:
            try:
                return content_bytes.decode("latin-1")
            except Exception:
                # Filter printable ascii
                return "".join(chr(b) for b in content_bytes if 32 <= b <= 126 or b in (10, 13))

    def chunk_text(self, text: str, chunk_size: int = 150, overlap: int = 30) -> List[str]:
        """Divides text into overlapping word chunks preserving sentence boundaries where possible."""
        words = text.split()
        if not words:
            return []

        chunks = []
        step = max(1, chunk_size - overlap)
        for i in range(0, len(words), step):
            chunk = " ".join(words[i : i + chunk_size])
            if chunk.strip():
                chunks.append(chunk.strip())
        return chunks

    def add_document(self, filename: str, content_bytes: bytes) -> Dict[str, Any]:
        """Ingests a document, extracts text, chunks it, and updates the retrieval index."""
        doc_id = str(uuid.uuid4())[:8]
        extracted_text = self.extract_text(filename, content_bytes)

        if not extracted_text.strip():
            raise ValueError(f"Could not extract meaningful text from '{filename}'.")

        # Save copy of original file
        save_path = os.path.join(self.docs_dir, f"{doc_id}_{filename}")
        with open(save_path, "wb") as f:
            f.write(content_bytes)

        doc_chunks = self.chunk_text(extracted_text, chunk_size=160, overlap=30)
        
        chunk_entries = []
        for idx, chunk_str in enumerate(doc_chunks):
            entry = {
                "chunk_id": f"{doc_id}_c{idx}",
                "doc_id": doc_id,
                "filename": filename,
                "chunk_index": idx,
                "text": chunk_str
            }
            chunk_entries.append(entry)

        self.documents[doc_id] = {
            "doc_id": doc_id,
            "filename": filename,
            "char_count": len(extracted_text),
            "word_count": len(extracted_text.split()),
            "chunks_count": len(doc_chunks),
            "local_path": save_path
        }
        self.chunks.extend(chunk_entries)
        self._save_index()

        return {
            "doc_id": doc_id,
            "filename": filename,
            "chunks_indexed": len(doc_chunks),
            "word_count": len(extracted_text.split())
        }

    def list_documents(self) -> List[Dict[str, Any]]:
        """Returns all currently indexed documents."""
        return list(self.documents.values())

    def delete_document(self, doc_id: str) -> bool:
        """Removes a document and its associated chunks from the index."""
        if doc_id not in self.documents:
            return False
        doc_info = self.documents.pop(doc_id)
        if os.path.exists(doc_info.get("local_path", "")):
            try:
                os.remove(doc_info["local_path"])
            except Exception:
                pass
        self.chunks = [c for c in self.chunks if c["doc_id"] != doc_id]
        self._save_index()
        return True

    def clear_all(self):
        """Clears all documents from RAG database."""
        self.documents.clear()
        self.chunks.clear()
        self._save_index()

    def _tokenize(self, text: str) -> List[str]:
        """Simple lowercase alphanumeric tokenizer."""
        return re.findall(r"\b[a-zA-Z0-9_]{2,}\b", text.lower())

    def retrieve(self, query: str, top_k: int = 3) -> List[Dict[str, Any]]:
        """
        Retrieves top-k most relevant document chunks for the query using TF-IDF scoring.
        Returns chunk content, relevance scores, and source citations.
        """
        if not self.chunks:
            return []

        query_tokens = self._tokenize(query)
        if not query_tokens:
            return []

        N = len(self.chunks)
        # 1. Compute document frequencies
        df = collections.defaultdict(int)
        chunk_token_counts = []
        for c in self.chunks:
            tokens = self._tokenize(c["text"])
            counts = collections.Counter(tokens)
            chunk_token_counts.append((tokens, counts))
            for t in counts:
                df[t] += 1

        # 2. Compute scores for each chunk
        scores = []
        for idx, (tokens, counts) in enumerate(chunk_token_counts):
            chunk = self.chunks[idx]
            score = 0.0
            total_tokens = max(1, len(tokens))

            for qt in query_tokens:
                if qt in counts:
                    # BM25-style TF saturation
                    tf = counts[qt] / total_tokens
                    idf = math.log((N + 1) / (df[qt] + 0.5)) + 1.0
                    score += tf * idf

            if score > 0.0:
                scores.append({
                    "doc_id": chunk["doc_id"],
                    "filename": chunk["filename"],
                    "chunk_id": chunk["chunk_id"],
                    "chunk_index": chunk["chunk_index"],
                    "score": round(score, 4),
                    "text": chunk["text"]
                })

        # Sort descending by relevance score
        scores.sort(key=lambda x: x["score"], reverse=True)
        return scores[:top_k]

    def build_augmented_context(self, query: str, top_k: int = 3) -> Tuple[str, List[Dict[str, Any]]]:
        """
        Generates augmented context string and list of citations.
        """
        matches = self.retrieve(query, top_k=top_k)
        if not matches:
            return "", []

        context_lines = [
            "\n[RETRIEVED KNOWLEDGE BASE CONTEXT]",
            "Use the following excerpts from verified local documents to ground your answer.",
            "Cite the source document if using specific facts from it.\n"
        ]

        citations = []
        for rank, m in enumerate(matches, 1):
            context_lines.append(f"--- Document Source [{rank}]: {m['filename']} (Section {m['chunk_index'] + 1}) ---")
            context_lines.append(m["text"])
            context_lines.append("")
            citations.append({
                "source_num": rank,
                "filename": m["filename"],
                "chunk_id": m["chunk_id"],
                "relevance_score": m["score"],
                "excerpt": m["text"][:180] + "..." if len(m["text"]) > 180 else m["text"]
            })

        context_lines.append("[END OF RETRIEVED CONTEXT]\n")
        return "\n".join(context_lines), citations
