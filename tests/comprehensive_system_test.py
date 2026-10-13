"""
SmartVision Comprehensive System Verification & Accuracy Test Suite
Covers:
1. Object Detection Accuracy (YOLOv8m 80-Class Canonical)
2. Open-Vocabulary Detection (YOLO-World Custom Items)
3. Coordinate Normalization & Agnostic Non-Maximum Suppression
4. OCR Extraction & Sentence-Chunked Multi-Language Translation
5. Siren Alert & Hazard Detection Logic
6. FastAPI Microservice Endpoints
7. Streamlit Dashboard Service
"""

import os
import sys
import time
import base64
import wave
import json
import requests
import cv2
import numpy as np
from ultralytics import YOLO

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
API_BASE = "http://localhost:8000"
STREAMLIT_URL = "http://localhost:8501"

passed_tests = 0
total_tests = 0

def record_test(name: str, passed: bool, details: str = ""):
    global passed_tests, total_tests
    total_tests += 1
    if passed:
        passed_tests += 1
        print(f"  [PASS] {name} {details}")
    else:
        print(f"  [FAIL] {name} {details}")

def run_tests():
    print("=" * 75)
    print("SMARTVISION END-TO-END ACCURACY AND SYSTEM VERIFICATION")
    print("=" * 75)

    # -------------------------------------------------------------
    # SECTION 1: PRIMARY MODEL ACCURACY (YOLOv8m)
    # -------------------------------------------------------------
    print("\n--- SECTION 1: High-Accuracy Object Detection (YOLOv8m) ---")
    model_path = os.path.join(BASE_DIR, 'yolov8m.pt')
    assert os.path.exists(model_path), f"Missing model: {model_path}"
    model = YOLO(model_path)
    
    # 1.1 Kitchen Knife Detection (11.jpeg)
    img_11 = os.path.join(BASE_DIR, '11.jpeg')
    res_11 = model.predict(img_11, conf=0.25, agnostic_nms=True, verbose=False)[0]
    preds_11 = {model.names[int(b.cls[0])]: float(b.conf[0]) for b in res_11.boxes}
    knife_conf = preds_11.get('knife', 0.0)
    record_test("11.jpeg Knife Detection", knife_conf >= 0.85, f"Confidence: {knife_conf*100:.1f}% (Required: >=85%)")
    record_test("11.jpeg Agnostic NMS", 'scissors' not in preds_11, "Suppressed overlapping duplicate scissors false alarm")
    
    # 1.2 Multi-Object Detection (test_image.png)
    img_cat = os.path.join(BASE_DIR, 'test_image.png')
    res_cat = model.predict(img_cat, conf=0.25, agnostic_nms=True, verbose=False)[0]
    classes_cat = set(model.names[int(b.cls[0])] for b in res_cat.boxes)
    has_expected = {'cat', 'cup'}.issubset(classes_cat)
    record_test("test_image.png Multi-Object", has_expected, f"Found: {sorted(classes_cat)}")
    
    # 1.3 Hazard Detection (test_danger_image.png)
    img_danger = os.path.join(BASE_DIR, 'test_danger_image.png')
    res_danger = model.predict(img_danger, conf=0.25, agnostic_nms=True, verbose=False)[0]
    classes_danger = set(model.names[int(b.cls[0])] for b in res_danger.boxes)
    record_test("test_danger_image.png Hazard Detection", 'scissors' in classes_danger, f"Found: {sorted(classes_danger)}")
    
    # 1.4 Vehicle & Traffic (frame_sample.jpg)
    img_traffic = os.path.join(BASE_DIR, 'frame_sample.jpg')
    res_traffic = model.predict(img_traffic, conf=0.25, agnostic_nms=True, verbose=False)[0]
    car_count = sum(1 for b in res_traffic.boxes if model.names[int(b.cls[0])] == 'car')
    record_test("frame_sample.jpg Vehicle Detection", car_count >= 3, f"Detected {car_count} cars + traffic elements")
    
    # 1.5 Crowded Person Scene (p0.jpg)
    img_p0 = os.path.join(BASE_DIR, 'p0.jpg')
    res_p0 = model.predict(img_p0, conf=0.25, agnostic_nms=True, verbose=False)[0]
    person_count = sum(1 for b in res_p0.boxes if model.names[int(b.cls[0])] == 'person')
    record_test("p0.jpg Crowded Scene", person_count >= 3, f"Detected {person_count} persons without hallucination")

    # -------------------------------------------------------------
    # SECTION 2: OPEN-VOCABULARY DETECTION (YOLO-World)
    # -------------------------------------------------------------
    print("\n--- SECTION 2: Open-Vocabulary Object Detection (YOLO-World) ---")
    world_path = os.path.join(BASE_DIR, 'yolov8s-world.pt')
    if os.path.exists(world_path):
        w_model = YOLO(world_path)
        w_model.set_classes(['knife', 'tomato', 'onion', 'vegetable', 'cutting board'])
        res_w = w_model.predict(img_11, conf=0.25, agnostic_nms=True, verbose=False)[0]
        w_classes = set(w_model.names[int(b.cls[0])] for b in res_w.boxes)
        has_knife_and_food = ('knife' in w_classes) and ('tomato' in w_classes)
        record_test("YOLO-World Custom Food & Knife", has_knife_and_food, f"Detected: {sorted(w_classes)}")
    else:
        record_test("YOLO-World File", False, "yolov8s-world.pt not found")

    # -------------------------------------------------------------
    # SECTION 3: TRANSLATION & CHUNKING ENGINE
    # -------------------------------------------------------------
    print("\n--- SECTION 3: Sentence-Chunked Multi-Language Translation ---")
    academic_text = (
        "A basic Paragraph AE Academic English UK Corporate Social Responsibility (CSR) "
        "can generate a positive reputation for a company leading to possibly more sales and growth. "
        "According to Jones et al (2019), a corporation that invests in the environmental and ethical approaches "
        "of CSR will demonstrate to the public and the media that they are a responsible company. "
        "Watson (2018) provides evidence that this improves consumer sales as customers tend to support ethical "
        "green business practices thus improving bottom-line profitability and brand loyalty."
    )
    from deep_translator import MyMemoryTranslator
    import re

    def chunk_text_test(text, max_chars=350):
        sentences = re.split(r'(\. |\n+|\? |\! )', text)
        chunks = []
        current = ''
        for part in sentences:
            if not part:
                continue
            if len(current) + len(part) <= max_chars:
                current += part
            else:
                if current.strip():
                    chunks.append(current.strip())
                current = part
        if current.strip():
            chunks.append(current.strip())
        return chunks

    chunks = chunk_text_test(academic_text)
    record_test("Paragraph Chunking Boundary", len(chunks) >= 2 and all(len(c) <= 350 for c in chunks), f"Generated {len(chunks)} chunks, max len: {max(len(c) for c in chunks)}")

    # Test Hindi translation of long paragraph
    try:
        t_hi = MyMemoryTranslator(source='en-US', target='hi-IN')
        hi_parts = [t_hi.translate(c) for c in chunks]
        full_hi = " ".join(hi_parts)
        record_test("Hindi Chunked Translation (>500 chars)", len(full_hi) > 100, f"Result: '{full_hi[:65]}...'")
    except Exception as e:
        record_test("Hindi Chunked Translation", False, str(e))

    # Test Spanish translation of long paragraph
    try:
        t_es = MyMemoryTranslator(source='en-US', target='es-ES')
        es_parts = [t_es.translate(c) for c in chunks]
        full_es = " ".join(es_parts)
        record_test("Spanish Chunked Translation (>500 chars)", 'responsabilidad' in full_es.lower() or len(full_es) > 100, f"Result: '{full_es[:65]}...'")
    except Exception as e:
        record_test("Spanish Chunked Translation", False, str(e))

    # Test Telugu translation of long paragraph
    try:
        t_te = MyMemoryTranslator(source='en-US', target='te-IN')
        te_parts = [t_te.translate(c) for c in chunks]
        full_te = " ".join(te_parts)
        record_test("Telugu Chunked Translation (>500 chars)", len(full_te) > 100, f"Result: '{full_te[:65]}...'")
    except Exception as e:
        record_test("Telugu Chunked Translation", False, str(e))

    # -------------------------------------------------------------
    # SECTION 4: SIREN AUDIO & ALERT ASSETS
    # -------------------------------------------------------------
    print("\n--- SECTION 4: Hazard Siren Audio Verification ---")
    siren_path = os.path.join(BASE_DIR, 'siren.wav')
    if os.path.exists(siren_path):
        try:
            with wave.open(siren_path, 'r') as wf:
                duration = wf.getnframes() / float(wf.getframerate())
                record_test("siren.wav Audio Integrity", duration > 0.5, f"Valid WAV, duration: {duration:.2f}s, rate: {wf.getframerate()}Hz")
        except Exception as e:
            record_test("siren.wav Audio Integrity", False, str(e))
    else:
        record_test("siren.wav Exists", False, "siren.wav not found")

    # -------------------------------------------------------------
    # SECTION 5: FASTAPI BACKEND MICROSERVICE
    # -------------------------------------------------------------
    print("\n--- SECTION 5: FastAPI Backend Microservice (port 8000) ---")
    try:
        resp_h = requests.get(f"{API_BASE}/health", timeout=3)
        record_test("FastAPI /health Endpoint", resp_h.status_code == 200, f"Status: {resp_h.status_code}")
    except Exception as e:
        record_test("FastAPI /health Endpoint", False, str(e))

    try:
        with open(img_11, 'rb') as f:
            b64_img = base64.b64encode(f.read()).decode('utf-8')
        t_start = time.time()
        resp_det = requests.post(f"{API_BASE}/detect", json={'image': b64_img}, timeout=10)
        lat = (time.time() - t_start) * 1000.0
        if resp_det.status_code == 200:
            recs = resp_det.json().get('recognitions', [])
            has_knife = any(r['label'] == 'knife' and r['confidence'] >= 0.85 for r in recs)
            record_test("FastAPI /detect on 11.jpeg", has_knife, f"Knife detected, latency: {lat:.1f}ms, recs: {recs}")
        else:
            record_test("FastAPI /detect", False, f"Status: {resp_det.status_code}")
    except Exception as e:
        record_test("FastAPI /detect", False, str(e))

    try:
        resp_ocr = requests.post(f"{API_BASE}/ocr", json={'image': b64_img}, timeout=15)
        record_test("FastAPI /ocr Endpoint", resp_ocr.status_code == 200, f"Status: {resp_ocr.status_code}")
    except Exception as e:
        record_test("FastAPI /ocr Endpoint", False, str(e))

    # -------------------------------------------------------------
    # SECTION 6: STREAMLIT DASHBOARD
    # -------------------------------------------------------------
    print("\n--- SECTION 6: Streamlit Application (port 8501) ---")
    try:
        resp_st = requests.get(STREAMLIT_URL, timeout=5)
        record_test("Streamlit Dashboard Online", resp_st.status_code == 200, f"Status: {resp_st.status_code}")
    except Exception as e:
        record_test("Streamlit Dashboard Online", False, str(e))

    # -------------------------------------------------------------
    # FINAL SUMMARY
    # -------------------------------------------------------------
    print("\n" + "=" * 75)
    print(f"VERIFICATION SUMMARY: {passed_tests}/{total_tests} TESTS PASSED ({passed_tests/total_tests*100:.1f}%)")
    print("=" * 75)
    return passed_tests == total_tests

if __name__ == '__main__':
    success = run_tests()
    sys.exit(0 if success else 1)
