"""
RAG API Router.
Handles document upload, text indexing, chunk inspection, and semantic query testing.
"""

from typing import Optional
from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel

from backend.app.services.rag_engine import RAGEngine

router = APIRouter(prefix="/rag", tags=["rag"])

class RAGQueryRequest(BaseModel):
    query: str
    top_k: Optional[int] = 3

@router.get("/documents")
def get_documents():
    """List all indexed local documents."""
    engine = RAGEngine.get_instance()
    docs = engine.list_documents()
    return {
        "count": len(docs),
        "total_chunks": len(engine.chunks),
        "documents": docs
    }

@router.post("/upload")
async def upload_document(file: UploadFile = File(...)):
    """Upload a document to the local RAG knowledge base."""
    if not file.filename:
        raise HTTPException(status_code=400, detail="Missing filename")
    
    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Empty file uploaded")

    engine = RAGEngine.get_instance()
    try:
        result = engine.add_document(file.filename, contents)
        return {
            "status": "success",
            "message": f"Successfully indexed '{file.filename}'",
            "document": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process document: {str(e)}")

@router.delete("/documents/{doc_id}")
def delete_document(doc_id: str):
    """Delete a document and its chunks from RAG index."""
    engine = RAGEngine.get_instance()
    success = engine.delete_document(doc_id)
    if not success:
        raise HTTPException(status_code=404, detail="Document not found")
    return {"status": "success", "deleted_doc_id": doc_id}

@router.delete("/documents")
def clear_all_documents():
    """Clear all documents from RAG index."""
    engine = RAGEngine.get_instance()
    engine.clear_all()
    return {"status": "success", "message": "All documents removed from knowledge base"}

@router.post("/query")
def test_retrieval(payload: RAGQueryRequest):
    """Test retrieval against knowledge base without invoking LLM."""
    engine = RAGEngine.get_instance()
    matches = engine.retrieve(payload.query, top_k=payload.top_k or 3)
    return {
        "query": payload.query,
        "results_count": len(matches),
        "matches": matches
    }
