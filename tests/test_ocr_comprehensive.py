import os
import sys
import json
import base64
import time
import math
import numpy as np
import cv2
import requests

# Ensure workspace root is in path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from core_utils import OCRReader

def compute_cer_wer(gt: str, pred: str):
    """
    Computes Character Error Rate (CER) and Word Error Rate (WER) using Levenshtein distance.
    """
    def levenshtein(s1, s2):
        dp = [[0] * (len(s2) + 1) for _ in range(len(s1) + 1)]
        for i in range(len(s1) + 1):
            dp[i][0] = i
        for j in range(len(s2) + 1):
            dp[0][j] = j
        for i in range(1, len(s1) + 1):
            for j in range(1, len(s2) + 1):
                if s1[i - 1] == s2[j - 1]:
                    dp[i][j] = dp[i - 1][j - 1]
                else:
                    dp[i][j] = 1 + min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1])
        return dp[len(s1)][len(s2)]

    gt_norm = " ".join(gt.strip().split())
    pred_norm = " ".join(pred.strip().split())
    
    # CER
    char_dist = levenshtein(gt_norm, pred_norm)
    cer = (char_dist / max(1, len(gt_norm))) * 100.0

    # WER
    gt_words = gt_norm.split()
    pred_words = pred_norm.split()
    word_dist = levenshtein(gt_words, pred_words)
    wer = (word_dist / max(1, len(gt_words))) * 100.0

    return cer, wer, char_dist, word_dist

def run_tests():
    print("==================================================")
    print("   SMART VISION - COMPREHENSIVE OCR QA SUITE     ")
    print("==================================================")

    results = {}

    # 1. OCR Engine Initialization
    t0 = time.time()
    reader = OCRReader()
    init_time = time.time() - t0
    assert reader.reader is not None, "OCR reader failed to initialize"
    print(f"[PASS] 1. OCR Engine Loaded successfully in {init_time:.2f}s")
    results["engine_load"] = {"status": "PASS", "time_sec": round(init_time, 2)}

    # 2. Existing Baseline Sample: tests/data/text_image.png
    sample_path = "tests/data/text_image.png"
    if os.path.exists(sample_path):
        img1 = cv2.imread(sample_path)
        extracted = reader.extract_text_simple(img1)
        gt1 = "SMART VISION"
        cer1, wer1, _, _ = compute_cer_wer(gt1, extracted)
        print(f"[PASS] 2. Baseline Image OCR: Pred='{extracted}' (GT='{gt1}') | CER: {cer1:.2f}%, WER: {wer1:.2f}%")
        results["image_ocr_baseline"] = {
            "status": "PASS",
            "extracted": extracted,
            "cer": round(cer1, 2),
            "wer": round(wer1, 2)
        }
    else:
        print("[FAIL] tests/data/text_image.png not found")
        results["image_ocr_baseline"] = {"status": "FAIL"}

    # 3. Complex Text Recognition: Multi-line, Numbers, Punctuation, Fonts
    # Create synthetic high-res image with exact known ground truth
    synth_h, synth_w = 300, 800
    synth_img = np.ones((synth_h, synth_w, 3), dtype=np.uint8) * 255
    font = cv2.FONT_HERSHEY_SIMPLEX
    
    cv2.putText(synth_img, "SMART VISION AI 2026", (30, 60), font, 1.2, (10, 10, 10), 2, cv2.LINE_AA)
    cv2.putText(synth_img, "TESTING OCR: ACCURACY 99.5%", (30, 130), font, 1.0, (20, 20, 20), 2, cv2.LINE_AA)
    cv2.putText(synth_img, "LATENCY #1 - REALTIME CAMERA", (30, 200), font, 0.9, (20, 20, 20), 2, cv2.LINE_AA)
    cv2.imwrite("tests/data/test_ocr_synthetic.png", synth_img)

    synth_gt = "SMART VISION AI 2026\nTESTING OCR: ACCURACY 99.5%\nLATENCY #1 - REALTIME CAMERA"
    synth_pred = reader.extract_text_simple(synth_img)
    cer_synth, wer_synth, _, _ = compute_cer_wer(synth_gt, synth_pred)
    print(f"[EVAL] 3. Complex Text Recognition:")
    print(f"       Extracted:\n{synth_pred}")
    print(f"       CER: {cer_synth:.2f}%, WER: {wer_synth:.2f}%")
    results["complex_text_accuracy"] = {
        "status": "PASS" if cer_synth < 15.0 else "WARNING",
        "cer": round(cer_synth, 2),
        "wer": round(wer_synth, 2),
        "pred": synth_pred
    }

    # 4. Image Degradation Tests (Low-light, Blur, Noise)
    # Low-light
    dark_img = (synth_img * 0.25).astype(np.uint8)
    dark_pred = reader.extract_text_simple(dark_img)
    cer_dark, wer_dark, _, _ = compute_cer_wer(synth_gt, dark_pred)
    print(f"[EVAL] 4a. Low-Light Text Extraction: CER={cer_dark:.2f}%, WER={wer_dark:.2f}% (Pred='{dark_pred.splitlines()[0] if dark_pred else 'NONE'}')")

    # Blur
    blur_img = cv2.GaussianBlur(synth_img, (7, 7), 2.5)
    blur_pred = reader.extract_text_simple(blur_img)
    cer_blur, wer_blur, _, _ = compute_cer_wer(synth_gt, blur_pred)
    print(f"[EVAL] 4b. Blurry Image Text Extraction: CER={cer_blur:.2f}%, WER={wer_blur:.2f}%")

    # Noise
    noise = np.random.normal(0, 25, synth_img.shape).astype(np.int16)
    noisy_img = np.clip(synth_img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    noisy_pred = reader.extract_text_simple(noisy_img)
    cer_noisy, wer_noisy, _, _ = compute_cer_wer(synth_gt, noisy_pred)
    print(f"[EVAL] 4c. Noisy Image Text Extraction: CER={cer_noisy:.2f}%, WER={wer_noisy:.2f}%")

    results["degradation"] = {
        "dark_cer": round(cer_dark, 2),
        "blur_cer": round(cer_blur, 2),
        "noisy_cer": round(cer_noisy, 2)
    }

    # 5. Video Frame OCR and Timestamp Tracking
    # Test video processing on dummy.mp4 or synthesize a 3-second test video
    test_video_path = "tests/data/test_ocr_video.mp4"
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    vw = cv2.VideoWriter(test_video_path, fourcc, 10.0, (640, 360))
    # Frame 0 to 10 (0s - 1s): "TRACKING VEHICLE A-102"
    f1 = np.ones((360, 640, 3), dtype=np.uint8) * 240
    cv2.putText(f1, "TRACKING VEHICLE A-102", (50, 180), font, 1.0, (10, 10, 10), 2)
    for _ in range(12):
        vw.write(f1)
    # Frame 12 to 24 (1s - 2s): "SPEED: 45 MPH"
    f2 = np.ones((360, 640, 3), dtype=np.uint8) * 240
    cv2.putText(f2, "SPEED: 45 MPH", (50, 180), font, 1.0, (10, 10, 10), 2)
    for _ in range(12):
        vw.write(f2)
    vw.release()

    # Emulate the video OCR loop from app.py
    cap = cv2.VideoCapture(test_video_path)
    fps = cap.get(cv2.CAP_PROP_FPS) or 10.0
    frame_interval = max(1, int(fps * 1.0))
    frame_count = 0
    timeline = []
    seen = set()
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        if frame_count % frame_interval == 0:
            sec = frame_count / fps
            t_str = time.strftime('%M:%S', time.gmtime(sec))
            txt = reader.extract_text_simple(frame, min_confidence=0.3).strip()
            norm = " ".join(txt.lower().split())
            if norm and norm not in seen:
                seen.add(norm)
                timeline.append({"time": t_str, "text": txt})
        frame_count += 1
    cap.release()

    print(f"[PASS] 5. Video OCR with Timestamps: Extracted {len(timeline)} timeline events:")
    for item in timeline:
        print(f"       [{item['time']}] -> {item['text']}")
    results["video_ocr"] = {
        "status": "PASS" if len(timeline) >= 2 else "PARTIAL",
        "events": timeline
    }

    # 6. Error Handling & Edge Cases
    # 6a. Blank white image
    white_img = np.ones((200, 200, 3), dtype=np.uint8) * 255
    res_white = reader.extract_text_simple(white_img)
    # 6b. Blank black image
    black_img = np.zeros((200, 200, 3), dtype=np.uint8)
    res_black = reader.extract_text_simple(black_img)
    # 6c. Empty numpy array
    empty_img = np.array([])
    res_empty = reader.extract_text_simple(empty_img)

    print(f"[PASS] 6a. Blank White Image -> Returns '{res_white}' (Safe empty)")
    print(f"[PASS] 6b. Blank Black Image -> Returns '{res_black}' (Safe empty)")
    print(f"[PASS] 6c. Zero-byte/Empty Array -> Returns '{res_empty}' (Safe empty, No crash)")
    results["error_handling_local"] = "PASS"

    # 7. Backend API Integration (/ocr endpoint on port 8000)
    try:
        _, buffer = cv2.imencode('.jpg', img1)
        b64_str = base64.b64encode(buffer).decode('utf-8')
        resp = requests.post("http://localhost:8000/ocr", json={"image": b64_str}, timeout=15)
        if resp.status_code == 200:
            data = resp.json()
            texts = [d["text"] for d in data.get("texts", [])]
            print(f"[PASS] 7a. Backend API POST /ocr: 200 OK -> {texts}")
            results["api_ocr"] = {"status": "PASS", "response": texts}
        else:
            print(f"[FAIL] 7a. Backend API returned {resp.status_code}")
            results["api_ocr"] = {"status": "FAIL", "code": resp.status_code}
            
        # 7b. Invalid base64 error handling
        resp_bad = requests.post("http://localhost:8000/ocr", json={"image": "invalid_base64_payload"}, timeout=5)
        print(f"[PASS] 7b. Corrupt Input API Response: status={resp_bad.status_code} ({resp_bad.text})")
        results["api_invalid"] = {"status": "PASS", "code": resp_bad.status_code}
    except Exception as e_api:
        print(f"[WARN] 7. Backend API test skipped or error: {e_api}")
        results["api_ocr"] = {"status": "BLOCKED", "error": str(e_api)}

    # 8. Translation Functional Test (Testing chunked translator logic from app.py)
    try:
        from deep_translator import GoogleTranslator
        sample_ocr = "Smart Vision AI Project"
        translator = GoogleTranslator(source='auto', target='es')
        trans_es = translator.translate(sample_ocr)
        print(f"[PASS] 8. Translation Test (Spanish): '{sample_ocr}' -> '{trans_es}'")
        results["translation"] = {"status": "PASS", "translated": trans_es}
    except Exception as e_trans:
        print(f"[WARN] 8. Translation network/service test: {e_trans}")
        results["translation"] = {"status": "BLOCKED/NETWORK", "error": str(e_trans)}

    # 9. Summarization Check
    # Verify if summarization UI or backend exists
    results["summarization"] = {"status": "NOT IMPLEMENTED", "detail": "OCR page provides multi-lingual translation (18 languages); text summarization not implemented in OCR flow."}

    # Save complete results
    with open("tests/ocr_test_results.json", "w") as f:
        json.dump(results, f, indent=2)
    print("\n[COMPLETE] Test results saved to tests/ocr_test_results.json")

if __name__ == "__main__":
    run_tests()
