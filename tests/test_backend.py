import base64
import os
import cv2
import numpy as np
import pytest
from fastapi.testclient import TestClient
from ai_server import app

client = TestClient(app)

def encode_image(filepath: str) -> str:
    with open(filepath, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

def test_health_check():
    """Requirement: GET /health returns 200"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_detect_objects_success():
    """Requirement: POST /detect returns labels, confidences, and bounding boxes for expected object"""
    image_b64 = encode_image("tests/data/scene_with_person.png")
    response = client.post("/detect", json={"image": image_b64})
    assert response.status_code == 200
    data = response.json()
    assert "recognitions" in data
    recognitions = data["recognitions"]
    assert len(recognitions) > 0
    # Confirm structure
    first = recognitions[0]
    assert "rect" in first and "label" in first and "confidence" in first
    assert all(k in first["rect"] for k in ["left", "top", "right", "bottom"])
    labels = [r["label"] for r in recognitions]
    assert "person" in labels

def test_detect_invalid_and_empty_image():
    """Requirement: Empty or invalid image returns clean error (400), not 500"""
    # 1. Empty string
    response_empty = client.post("/detect", json={"image": ""})
    assert response_empty.status_code == 400, f"Expected 400 on empty image, got {response_empty.status_code}: {response_empty.text}"

    # 2. Corrupt/Invalid base64 string
    response_corrupt = client.post("/detect", json={"image": "not_valid_base64_content!!!"})
    assert response_corrupt.status_code == 400, f"Expected 400 on corrupt base64, got {response_corrupt.status_code}: {response_corrupt.text}"

def test_ocr_extraction():
    """Requirement: POST /ocr extracts known text from text image"""
    image_b64 = encode_image("tests/data/text_image.png")
    response = client.post("/ocr", json={"image": image_b64})
    assert response.status_code == 200
    data = response.json()
    assert "texts" in data
    texts = [t["text"].upper() for t in data["texts"]]
    # Should contain SMART or VISION
    matched = any("SMART" in t or "VISION" in t for t in texts)
    assert matched, f"Expected 'SMART' or 'VISION' in extracted OCR texts: {texts}"

def test_face_register_and_recognize():
    """Requirement: POST /face/register then /face/recognize: registered face identified, unregistered unknown"""
    reg_img_b64 = encode_image("tests/data/face_registered.jpg")
    unreg_img_b64 = encode_image("tests/data/face_unregistered.jpg")

    # 1. Register face
    reg_res = client.post("/face/register", json={"image": reg_img_b64}, params={"name": "Sowmya"})
    assert reg_res.status_code == 200

    # 2. Recognize registered face
    rec_res = client.post("/face/recognize", json={"image": reg_img_b64})
    assert rec_res.status_code == 200
    data = rec_res.json()
    assert "recognitions" in data
    # Note: ai_server.py is currently a stub returning {"recognitions": []}
    # This assert tests whether the pipeline actually identified the registered face
    assert len(data["recognitions"]) > 0, "Stub failure: /face/recognize returned empty recognitions for registered face"
    assert data["recognitions"][0].get("name") == "Sowmya"

    # 3. Recognize unregistered face
    unrec_res = client.post("/face/recognize", json={"image": unreg_img_b64})
    assert unrec_res.status_code == 200
    unreg_data = unrec_res.json()
    assert len(unreg_data["recognitions"]) > 0
    assert unreg_data["recognitions"][0].get("name") in ["Unknown", "unknown"]

def test_chatbot_query():
    """Requirement: POST /chatbot/query answers 'what do you see' and 'how many people' consistently with detection result"""
    context = {
        "counts": {"person": 2, "laptop": 1},
        "detections": ["person", "person", "laptop"]
    }

    # Query 1: 'how many people'
    res1 = client.post("/chatbot/query", json={"query": "how many people are there?", "context": context})
    assert res1.status_code == 200
    data1 = res1.json()
    assert "response" in data1
    # Check if consistent with context count (2 people)
    assert "2" in data1["response"] or "two" in data1["response"].lower(), f"Expected count of 2 people in response, got: {data1['response']}"

    # Query 2: 'what do you see'
    res2 = client.post("/chatbot/query", json={"query": "what do you see?", "context": context})
    assert res2.status_code == 200
    data2 = res2.json()
    assert "response" in data2
    assert "person" in data2["response"].lower() or "laptop" in data2["response"].lower(), f"Expected scene description in response, got: {data2['response']}"
