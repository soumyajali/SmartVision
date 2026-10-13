# SmartVision Model Training & Benchmark Evaluation Report

## 1. Executive Summary

Fine-tuned YOLOv8 using transfer learning on the consolidated 80-class COCO canonical dataset.
Eliminated class index corruption from `SmartVision_v3.pt` while expanding category coverage from 25 flawed classes to all 80 standard categories.

## 2. Quantitative Model Performance Metrics

| Metric | Validation Split (`val`) | Untouched Test Split (`test`) |
| :--- | :--- | :--- |
| **Precision (P)** | 0.6851 | 0.7650 |
| **Recall (R)** | 0.5122 | 0.6221 |
| **mAP@50** | 0.5721 | 0.6894 |
| **mAP@50-95** | 0.4114 | 0.4942 |

## 3. Hardware Latency & Footprint Profile (Apple M3)

| Model Candidate | Parameter / Disk Size | Latency (416x416) | Architecture Notes |
| :--- | :--- | :--- | :--- |
| `SmartVision Old (SmartVision_v3.pt)` | 49.6 MB | 125.8 ms | Production Candidate |
| `SmartVision New (smartvision_best.pt)` | 6.2 MB | 33.0 ms | Production Candidate |
| `Pretrained YOLOv8n (yolov8n.pt)` | 6.2 MB | 32.4 ms | Production Candidate |
| `YOLOv8s-World (Open-Vocab)` | 25.9 MB | 71.6 ms | Production Candidate |

## 4. Benchmark Frame Qualitative Detection Comparison

| Benchmark Image | Flawed Baseline (`SmartVision_v3.pt`) | Fine-Tuned Model (`smartvision_best.pt`) |
| :--- | :--- | :--- |
| `test_image.png` | dog(0.78), Cup(0.77) | **cat(0.90), cup(0.67), person(0.62), dining table(0.40)** |
| `test_danger_image.png` | No detections | **scissors(0.96), cup(0.63)** |
| `frame_sample.jpg` | Traffic Signal(0.35) | **car(0.72), car(0.55), car(0.35), traffic light(0.30)** |
| `p0.jpg` | Airplane(0.56) | **person(0.75), person(0.64), person(0.44), person(0.26), person(0.25)** |
