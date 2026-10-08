# SmartVision AI – Intelligent Multi-Class Object Recognition System

[![Python](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/)
[![YOLOv8](https://img.shields.io/badge/YOLO-v8-00FFFF.svg)](https://ultralytics.com/)
[![Flutter](https://img.shields.io/badge/Flutter-Android%20%7C%20iOS-02569B.svg)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688.svg)](https://fastapi.tiangolo.com/)
[![Streamlit](https://img.shields.io/badge/Dashboard-Streamlit-FF4B4B.svg)](https://streamlit.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An intelligent, real-time computer vision and multi-class object recognition ecosystem designed to detect objects, recognize faces, extract text, trigger hazard warnings, and assist users through voice guidance across desktop, web, and mobile (Android) platforms.

---

## 📌 Project Overview

Traditional surveillance and vision recognition systems depend on heavy, costly infrastructure and centralized cloud computing. **SmartVision AI** bridges this gap by delivering lightweight, edge-ready, real-time intelligence using deep learning:

- **Multi-Class Object Detection:** Powered by state-of-the-art **YOLOv8** architectures (`yolov8n`, `yolov8s-world`, `yolov8m`).
- **Hazard & Dangerous Object Alerting:** Real-time detection of knives, scissors, firearms, and hazardous materials with visual warning banners and automated siren alarms.
- **Biometric Face Recognition:** MediaPipe Face Landmarker, OpenCV Haar Cascades, and FAISS vector embeddings for registered face identification.
- **Optical Character Recognition (OCR):** Embedded EasyOCR engine for document screening and text reading.
- **Voice Assistant & Audio Guidance:** Hands-free offline speech alerts announcing newly detected items, lost objects, and safety hazards.
- **Interactive Web Dashboard:** Rich Streamlit interface featuring 3D visualizations, live analytics, and detection histories.
- **Cross-Platform Mobile App:** Flutter-based Android mobile application with live camera screening and on-device processing.

---

## 🚀 Key Features

| Feature | Description |
| :--- | :--- |
| 🔍 **Real-Time Object Detection** | Instant bounding-box localization with confidence scores using YOLOv8. |
| 🚨 **Dangerous Object Alert System** | Flags weapons, fire, and hazardous objects with loud siren audio and screen warnings. |
| 🔎 **Object Search ("Find My Item")** | Target-specific tracker alerting users via voice when a specific item appears in view. |
| 👤 **Face Verification & Recognition** | Recognizes registered identities and flags unknown individuals. |
| 📄 **Document Screening & OCR** | Extracts text and scanned information from live camera feed. |
| 🗣️ **Voice Assistant (TTS)** | Context-aware audio feedback (avoids repeated spamming, speaks on fresh detections). |
| 📊 **Analytics & Detection History** | SQLite-backed database (`detections.db`) tracking detections, metrics, and trends. |
| 📱 **Mobile Android App** | Flutter client connecting to the FastAPI backend or running on-device inference. |

---

## 📂 Repository Structure

```text
SmartVision/
├── app.py                     # Main Streamlit web dashboard application
├── ai_server.py               # High-performance FastAPI server for mobile & API access
├── voice_assistant.py         # Threaded Text-to-Speech (TTS) audio engine
├── database.py                # SQLite database manager for detection logs
├── services/                  # Core vision and biometric services
│   ├── face_service.py        # Face detection, landmarking, and recognition
│   └── camera_service.py      # Camera streaming and frame processing
├── models/ & weights          # Deep learning model weights
│   ├── yolov8n.pt             # Nano YOLOv8 model for lightweight edge detection
│   ├── yolov8s-world.pt       # YOLO-World open-vocabulary model
│   ├── MobileNET_best.pth     # Custom trained MobileNetV2 classifier
│   └── haarcascade_*.xml      # Haar Cascade face detection classifier
├── app/                       # Flutter Mobile Application (Android / iOS)
│   ├── lib/                   # Dart UI screens, providers, and controllers
│   ├── android/               # Native Android Gradle configuration
│   └── pubspec.yaml           # Flutter dependencies and assets
├── datasets/                  # Training and validation image datasets
├── tests/                     # Unit and integration test suites
└── docs/                      # Technical reports, synopses, and presentations
```

---

## 🛠️ Tech Stack

- **Computer Vision & AI:** PyTorch, Ultralytics YOLOv8, MobileNetV2, OpenCV, MediaPipe, EasyOCR, FAISS
- **Backend & APIs:** FastAPI, Uvicorn, WebSockets, RESTful endpoints
- **Frontend & Dashboard:** Streamlit, Plotly, HTML5/CSS3, Three.js
- **Mobile Development:** Flutter (Dart), CameraX, SQLite, TensorFlow Lite
- **Database & Storage:** SQLite (`detections.db`)

---

## 💻 Getting Started

### 1. Prerequisites
- Python 3.10 or higher
- Flutter SDK (for building the Android app)
- Android Studio with Android SDK (for mobile deployment)

### 2. Setup Python Environment

Clone the repository and install dependencies:

```bash
git clone https://github.com/soumyajali/SmartVision.git
cd SmartVision
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Launch Streamlit Web Dashboard

```bash
streamlit run app.py
```
Open `http://localhost:8501` in your browser to access the live detection dashboard.

### 4. Launch FastAPI Server (for Mobile App)

```bash
uvicorn ai_server:app --host 0.0.0.0 --port 8000 --reload
```

---

## 📱 Running the Android Mobile App

The mobile client is located in `app/`:

1. **Navigate to the Flutter directory:**
   ```bash
   cd app
   ```

2. **Get Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on connected Android phone or emulator:**
   ```bash
   flutter run
   ```

4. **Build release APK:**
   ```bash
   flutter build apk --release
   ```
   The APK will be generated at:  
   `app/build/app/outputs/flutter-apk/app-release.apk`

---

## 📊 Evaluation & Performance

- **YOLOv8 Inference Speed:** ~15-30ms per frame on modern CPU / GPU.
- **Classification Accuracy:** >94% on test datasets with MobileNetV2.
- **Hazard Response Time:** <100ms from frame acquisition to audio-visual siren trigger.

---

## 📄 Documentation

- [Project Overview](Project_Overview.md)
- [Implemented Features](FEATURES_IMPLEMENTED.md)
- [Test Report](TEST_REPORT.md)
- [Project Synopsis PDF](SmartVision_AI_Synopsis.pdf)

---

## 👥 Authors & Contributors

Developed as part of the **SmartVision AI** Research & Development Project.  
Repository: [github.com/soumyajali/SmartVision](https://github.com/soumyajali/SmartVision)
