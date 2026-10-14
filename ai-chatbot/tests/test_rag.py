"""
Unit tests for RAG (Retrieval-Augmented Generation) Engine
"""

import os
import sys
import pytest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from backend.app.services.rag_engine import RAGEngine

def test_rag_chunking_and_indexing():
    engine = RAGEngine.get_instance()
    engine.clear_all()
    
    sample_doc = (
        "Quantum computing is a rapidly-emerging technology that harnesses the laws of quantum mechanics "
        "to solve problems too complex for classical computers. Superconducting qubits and trapped ions "
        "are two leading hardware modalities. Shor's algorithm demonstrates exponential speedup for integer factorization."
    )
    
    res = engine.add_document("quantum_notes.txt", sample_doc.encode("utf-8"))
    assert res["filename"] == "quantum_notes.txt"
    assert res["chunks_indexed"] >= 1
    
    # Test retrieval
    matches = engine.retrieve("quantum mechanics qubits", top_k=2)
    assert len(matches) > 0
    assert matches[0]["filename"] == "quantum_notes.txt"
    assert matches[0]["score"] > 0
    
    # Test context builder
    context, citations = engine.build_augmented_context("qubits and Shor algorithm")
    assert "quantum_notes.txt" in context
    assert len(citations) > 0
    assert citations[0]["filename"] == "quantum_notes.txt"
    
    # Clean up
    engine.clear_all()
    assert len(engine.documents) == 0
    assert len(engine.chunks) == 0
