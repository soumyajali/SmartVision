# SmartVision AI – Intelligent Multi-Class Object Recognition System

[![Python](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/)
[![YOLOv8](https://img.shields.io/badge/YOLO-v8-00FFFF.svg)](https://ultralytics.com/)
[![Flutter](https://img.shields.io/badge/Flutter-Android%20%7C%20iOS-02569B.svg)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688.svg)](https://fastapi.tiangolo.com/)
[![Streamlit](https://img.shields.io/badge/Dashboard-Streamlit-FF4B4B.svg)](https://streamlit.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

SmartVision includes a Streamlit website and FastAPI AI backend, plus a Flutter mobile app. The mobile app runs supported vision workflows on device and does not require the Python server.

---

## 📌 Project Overview

**SmartVision AI** provides configurable computer-vision workflows through its website and mobile client:

- **Multi-Class Object Detection:** Powered by state-of-the-art **YOLOv8** architectures (`yolov8n`, `yolov8s-world`, `yolov8m`).
- **Hazard & Dangerous Object Alerting:** Real-time detection of knives, scissors, firearms, and hazardous materials with visual warning banners and automated siren alarms.
- **Biometric Face Recognition:** OpenCV YuNet face detection and SFace embeddings for registered identities, with conservative rejection of weak or ambiguous matches.
- **Optical Character Recognition (OCR):** Embedded EasyOCR engine for document screening and text reading.
- **Voice Assistant & Audio Guidance:** Hands-free speech alerts, spoken questions about the current detections, and voice commands for dashboard navigation and settings.
- **Interactive Web Dashboard:** Rich Streamlit interface featuring 3D visualizations, live analytics, and detection histories.
- **Android Mobile App:** Flutter uses a bundled YOLOv8n TFLite model for local object detection, ML Kit for on-device OCR and drowsiness cues, and local video frame analysis and history. It does not call the FastAPI backend. Identity recognition is not enabled because no trained face-embedding model is bundled.

---

## 🚀 Key Features

| Feature | Description |
| :--- | :--- |
| 🔍 **Real-Time Object Detection** | Instant bounding-box localization with confidence scores using YOLOv8. |
| 🚨 **Dangerous Object Alert System** | Flags weapons, fire, and hazardous objects with loud siren audio and screen warnings. |
| 🔎 **Object Search ("Find My Item")** | Target-specific tracker alerting users via voice when a specific item appears in view. |
| 👤 **Face Verification & Recognition** | Uses aligned face embeddings to identify registered people across changes in lighting, camera angle, scene, and clothing; only close, unambiguous matches receive a registered name. Unmatched or ambiguous faces are marked **Not Registered**. Face Registration lets you manage saved images for each identity. |
| 📄 **Document Screening & OCR** | Extracts text and scanned information from live camera feed. |
| 🗣️ **Voice Assistant (TTS)** | Context-aware audio feedback (avoids repeated spamming, speaks on fresh detections). |
| 🎙️ **Voice Questions & Commands** | Ask about detected objects in the Vision Chatbot or use spoken commands to navigate dashboard pages and toggle voice announcements or object tracking. Chatbot and voice-input answers are spoken in the browser using its built-in speech synthesis. Voice input transcription uses Google's online recognition service; an internet connection is required and recordings are sent to Google for transcription. |
| 📊 **Analytics & Detection History** | SQLite-backed database (`detections.db`) tracking detections, metrics, and trends. |
| 📱 **Mobile Android App** | Flutter client with camera/image detection, video OCR and review, face-consent flow, drowsiness monitoring, settings, and local analysis history. |

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
├── lib/                       # Flutter UI screens, services, and controllers
├── android/                   # Native Android Gradle configuration
├── pubspec.yaml               # Flutter dependencies and assets
├── datasets/                  # Training and validation image datasets
├── tests/                     # Unit and integration test suites
└── docs/                      # Technical reports, synopses, and presentations
```

---

## 🛠️ Tech Stack

- **Computer Vision & AI:** PyTorch, Ultralytics YOLOv8, MobileNetV2, OpenCV, MediaPipe, EasyOCR, FAISS
- **Backend & APIs:** FastAPI, Uvicorn, WebSockets, RESTful endpoints
- **Frontend & Dashboard:** Streamlit, Plotly, HTML5/CSS3, Three.js
- **Mobile Development:** Flutter (Dart), Flutter Camera plugin, SQLite
- **Database & Storage:** SQLite (`detections.db`)

---

## 💻 Getting Started

### 1. Prerequisites
- Python 3.10 or higher
- Flutter SDK (for building the Android app)
- Android Studio with Android SDK (for mobile deployment)

The face-recognition backend may download OpenCV Zoo YuNet and SFace model files into its local application cache on first startup. Mobile face images are sent to the configured FastAPI backend for processing; obtain the subject's consent before registration or recognition.

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

Open **Voice Assistant** in the dashboard navigation to record a question or command. Ask about app features (for example, “What features does this application have?” or “Tell me about OCR”). Assistant responses are spoken through the browser on your device; select **Record next question** after an answer to start another recording.

The **Vision Chatbot** page includes a conversation history panel and a **New chat** button. Conversations are kept in the current Streamlit session and can be selected again from the panel.

In **Video Fast Review**, reference-image person matching uses the app's YuNet/SFace face recognizer to compare faces directly in sampled video frames; it does not depend on person detection, clothing, or body shape. **Strict**, **Balanced**, and **Tolerant** modes set the minimum face-similarity threshold, with higher recall increasing the chance of false matches. Increase **Face detection resolution** to improve recall for distant faces. A single reference image cannot train a new identity model or guarantee recognition at every angle.

### 4. Launch FastAPI Server (for the Mobile App)

```bash
uvicorn ai_server:app --host 0.0.0.0 --port 8000 --reload
```

---

## 📱 Running the Android Mobile App

The Flutter app performs supported detection and media analysis on the device.
No Python environment or FastAPI server is required to run the mobile app.

1. **Navigate to the Flutter directory:**
   ```bash
   cd SmartVision
   ```

2. **Get Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on connected Android phone or emulator:**
   ```bash
   flutter run -d <android-device-id>
   ```

4. **Build a debug APK:**
   ```bash
   flutter build apk --debug
   ```
   The APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`.

5. **Build a release APK:**
   ```bash
   flutter build apk --release
   ```
   The APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📊 Evaluation & Performance

Mobile inference latency depends on the Android device. The mobile app uses the bundled YOLOv8n TFLite model; it does not use the website's custom PyTorch weights.

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
