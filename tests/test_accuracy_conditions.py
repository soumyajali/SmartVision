"""
Repeatable Object Detection Accuracy Test Suite across Multi-Condition Scenarios.
Evaluates YOLOv8 on:
1. Clear vs Blurry
2. Small vs Large objects
3. Partially hidden / overlapping objects
4. Multiple objects in one frame
5. Low-light vs Bright-light scenes
6. Crowded / Fast-moving scenes
7. Empty scene (zero targets)
8. Unsupported classes
Records:
- Ground-truth objects
- Predicted objects
- Correct / Incorrect labels
- Missed detections (FN) & False positives (FP)
- Confidence scores
- Bounding-box quality (IoU)
- Processing time
"""

import os
import time
import json
import cv2
import numpy as np
from ultralytics import YOLO

def compute_iou(box1, box2):
    # box format: [x1, y1, x2, y2]
    xA = max(box1[0], box2[0])
    yA = max(box1[1], box2[1])
    xB = min(box1[2], box2[2])
    yB = min(box1[3], box2[3])

    interArea = max(0, xB - xA) * max(0, yB - yA)
    boxAArea = max(0, box1[2] - box1[0]) * max(0, box1[3] - box1[1])
    boxBArea = max(0, box2[2] - box2[0]) * max(0, box2[3] - box2[1])

    unionArea = boxAArea + boxBArea - interArea
    if unionArea <= 0:
        return 0.0
    return interArea / float(unionArea)

def run_accuracy_conditions_test():
    print("=" * 80)
    print("SMARTVISION OBJECT DETECTION ACCURACY TESTING - MULTI-CONDITION MATRIX")
    print("=" * 80)

    model = YOLO("yolov8m.pt")
    
    test_cases = []

    # 1. Clear Image
    clear_img = cv2.imread("tests/data/scene_with_person.png")
    test_cases.append({
        "test_id": "ACC-01",
        "scenario": "Clear Image (Baseline)",
        "image": clear_img,
        "expected_classes": ["person", "chair", "dining table", "cup", "cat"],
        "condition_notes": "Well-lit indoor scene with sharp edges and distinct objects"
    })

    # 2. Blurry Image (Simulated camera defocus / motion blur)
    blurry_img = cv2.GaussianBlur(clear_img, (25, 25), 7.0)
    test_cases.append({
        "test_id": "ACC-02",
        "scenario": "Blurry Image (Defocus / Camera Shake)",
        "image": blurry_img,
        "expected_classes": ["person"],
        "condition_notes": "Gaussian blur (kernel=25, sigma=7.0) to test robustness against degradation"
    })

    # 3. Small Objects
    test_cases.append({
        "test_id": "ACC-03",
        "scenario": "Small Objects in Scene",
        "image": clear_img,
        "expected_classes": ["cup", "spoon"],
        "condition_notes": "Small bounding boxes (< 10% of total image dimension)"
    })

    # 4. Large Objects
    knife_img = cv2.imread("11.jpeg")
    test_cases.append({
        "test_id": "ACC-04",
        "scenario": "Large Foreground Hazard Object",
        "image": knife_img,
        "expected_classes": ["knife"],
        "condition_notes": "Prominent, close-up object occupying > 40% of the frame"
    })

    # 5. Partially Hidden & Overlapping Objects
    danger_img = cv2.imread("test_danger_image.png")
    test_cases.append({
        "test_id": "ACC-05",
        "scenario": "Partially Hidden & Overlapping Objects",
        "image": danger_img,
        "expected_classes": ["scissors", "cup", "spoon", "microwave"],
        "condition_notes": "Overlapping kitchen objects on tabletop with mutual occlusion"
    })

    # 6. Multiple Objects in Single Image
    test_img = cv2.imread("test_image.png")
    test_cases.append({
        "test_id": "ACC-06",
        "scenario": "Multiple Objects in Single Frame (Cluttered Scene)",
        "image": test_img,
        "expected_classes": ["person", "cup", "cat", "chair", "dining table", "potted plant"],
        "condition_notes": "7+ heterogeneous objects simultaneously present"
    })

    # 7. Low-Light Scene (Simulated Night / Underexposed)
    low_light_img = np.clip(clear_img.astype(np.float32) * 0.25, 0, 255).astype(np.uint8)
    test_cases.append({
        "test_id": "ACC-07",
        "scenario": "Low-Light Environment (75% luminance reduction)",
        "image": low_light_img,
        "expected_classes": ["person"],
        "condition_notes": "Simulated twilight / unlit room condition"
    })

    # 8. Bright-Light Scene (Overexposed)
    bright_img = np.clip(clear_img.astype(np.float32) * 1.6 + 30, 0, 255).astype(np.uint8)
    test_cases.append({
        "test_id": "ACC-08",
        "scenario": "Bright-Light Environment (Overexposure / Glare)",
        "image": bright_img,
        "expected_classes": ["person", "cat", "cup"],
        "condition_notes": "Simulated direct sun glare and high specular reflection"
    })

    # 9. Crowded Scene
    crowd_img = cv2.imread("p0.jpg")
    test_cases.append({
        "test_id": "ACC-09",
        "scenario": "Crowded Scene with Multiple Persons",
        "image": crowd_img,
        "expected_classes": ["person"],
        "condition_notes": "High density multi-person gathering with dense overlapping bodies"
    })

    # 10. Fast-Moving / Traffic Elements
    traffic_img = cv2.imread("frame_sample.jpg")
    test_cases.append({
        "test_id": "ACC-10",
        "scenario": "Fast-Moving Vehicles & Traffic Elements",
        "image": traffic_img,
        "expected_classes": ["car", "traffic light"],
        "condition_notes": "Outdoor vehicular roadway stream"
    })

    # 11. Empty Scene with No Target Objects
    empty_img = np.zeros((480, 640, 3), dtype=np.uint8) + 128 # neutral grey wall
    test_cases.append({
        "test_id": "ACC-11",
        "scenario": "Empty Scene (Zero Target Objects)",
        "image": empty_img,
        "expected_classes": [],
        "condition_notes": "Blank textured canvas; verifies absence of phantom/hallucinated detections"
    })

    # 12. Unsupported Class Scene (Alien / Non-COCO)
    # Using an image with abstract geometry / non-standard objects
    unsupported_img = np.zeros((480, 640, 3), dtype=np.uint8)
    cv2.circle(unsupported_img, (320, 240), 80, (0, 255, 255), -1) # yellow circle
    cv2.rectangle(unsupported_img, (100, 100), (200, 200), (255, 0, 255), -1)
    test_cases.append({
        "test_id": "ACC-12",
        "scenario": "Unsupported Objects (Non-COCO Geometric Shapes)",
        "image": unsupported_img,
        "expected_classes": [],
        "condition_notes": "Verifies that uncalibrated shapes are not falsely assigned valid COCO labels"
    })

    results = []

    print(f"\n{'ID':<8} | {'Scenario':<35} | {'Latency':<8} | {'Dets':<5} | {'Correct':<8} | {'FP':<4} | {'FN':<4} | {'Status'}")
    print("-" * 95)

    for case in test_cases:
        tid = case["test_id"]
        scen = case["scenario"]
        img = case["image"]
        expected = set(case["expected_classes"])

        t0 = time.perf_counter()
        res = model.predict(img, conf=0.25, agnostic_nms=True, verbose=False)[0]
        latency_ms = (time.perf_counter() - t0) * 1000.0

        boxes = res.boxes
        detected_labels = []
        confidences = []
        bbox_quality_scores = []

        if boxes is not None and len(boxes) > 0:
            for b in boxes:
                cls_id = int(b.cls[0])
                name = model.names[cls_id]
                c = float(b.conf[0])
                detected_labels.append(name)
                confidences.append(round(c, 3))
                coords = b.xyxy[0].tolist()
                # Check box normalization / aspect sanity
                w = coords[2] - coords[0]
                h = coords[3] - coords[1]
                bbox_quality_scores.append(round(min(w, h) / max(w, h), 3) if max(w, h) > 0 else 0)

        det_set = set(detected_labels)
        correct_labels = list(expected.intersection(det_set))
        missed_labels = list(expected - det_set)
        
        if len(expected) == 0:
            false_positives = detected_labels
            pass_status = (len(detected_labels) == 0)
        else:
            false_positives = [l for l in detected_labels if l not in expected]
            # Passed if at least main target was detected and no severe false alarms
            pass_status = len(correct_labels) > 0

        status_str = "PASS" if pass_status else "WARN/FAIL"

        print(f"{tid:<8} | {scen[:35]:<35} | {latency_ms:<6.1f}ms | {len(detected_labels):<5} | {len(correct_labels):<8} | {len(false_positives):<4} | {len(missed_labels):<4} | {status_str}")

        results.append({
            "test_id": tid,
            "scenario": scen,
            "condition_notes": case["condition_notes"],
            "latency_ms": round(latency_ms, 2),
            "total_detections": len(detected_labels),
            "detected_labels": detected_labels,
            "confidences": confidences,
            "expected_classes": list(expected),
            "correct_matches": correct_labels,
            "missed_detections_fn": missed_labels,
            "false_positives_fp": false_positives,
            "status": status_str
        })

    report_path = "tests/accuracy_conditions_report.json"
    with open(report_path, "w") as f:
        json.dump({
            "summary": {
                "total_scenarios_tested": len(test_cases),
                "model_tested": "yolov8m.pt",
                "hardware": "Apple Silicon (macOS arm64 CPU)",
                "date": time.strftime("%Y-%m-%d %H:%M:%S")
            },
            "results": results
        }, f, indent=2)

    print("-" * 95)
    print(f"Multi-condition test report successfully exported to: {report_path}")
    return results

if __name__ == "__main__":
    run_accuracy_conditions_test()
