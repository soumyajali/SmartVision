# 🤖 Smart Vision AI

![Python](https://img.shields.io/badge/Python-3.x-blue?logo=python)
![PyTorch](https://img.shields.io/badge/Deep%20Learning-PyTorch-red?logo=pytorch)
![YOLO](https://img.shields.io/badge/Object%20Detection-YOLOv8-green)
![Streamlit](https://img.shields.io/badge/Web%20App-Streamlit-red?logo=streamlit)
![License](https://img.shields.io/badge/License-MIT-purple)

**Smart Vision AI** is an intelligent, multi-class object recognition and detection platform. By combining the power of **YOLO (You Only Look Once)** for real-time object detection and **MobileNetV2** for high-accuracy image classification, this application provides a robust and interactive web interface built with **Streamlit**.

---

## 🌟 Features

- **🎯 Real-Time Object Detection**: Upload images or use your webcam to instantly detect multiple objects within a single frame using a custom-trained YOLO model.
- **🧠 Image Classification**: Quickly classify images into one of 25 diverse COCO categories using a fine-tuned MobileNetV2 architecture.
- **📷 Multi-Modal Inputs**: Seamlessly switch between file uploads (JPG, PNG) and live webcam capture.
- **✨ Modern UI/UX**: Enjoy a sleek, responsive, and intuitive interface with custom CSS styling and interactive elements.

---

## 🛠️ Technology Stack

- **Frontend**: Streamlit, HTML/CSS
- **Deep Learning Framework**: PyTorch, Torchvision
- **Computer Vision**: OpenCV, Ultralytics (YOLO)
- **Data Manipulation**: NumPy, Pillow (PIL)

---

## 🚀 Getting Started

### Prerequisites

Make sure you have Python 3.8+ installed on your system.

### 1. Clone the Repository

```bash
git clone https://github.com/soumyajali/SmartVision.git
cd SmartVision
```

### 2. Set Up a Virtual Environment (Recommended)

```bash
python -m venv venv
source venv/bin/activate  # On Windows use `venv\Scripts\activate`
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Run the Application

```bash
streamlit run app.py
```

The app will launch in your default web browser at `http://localhost:8501`.

---

## 📂 Project Structure

```text
SmartVision/
├── app.py                      # Main Streamlit application
├── requirements.txt            # Python dependencies
├── SmartVision_v3.pt           # Custom YOLO detection model weights
├── MobileNET_best.pth          # Fine-tuned MobileNet classification weights
├── Datasets Codes/             # Data preparation scripts and notebooks
├── Traninig Codes/             # Model training notebooks
└── README.md                   # Project documentation
```

---

## 🎯 Supported Classes

The models are trained to recognize and classify the following 25 categories:
*Chair, Bottle, Cat, Cup, Bench, Horse, Person, Bed, Truck, Airplane, Cycle, Bird, Bike, Bus, Potted Plant, Pizza, Stop Signal, Bowl, Traffic Signal, Couch, Elephant, Cake, Dog, Cow, Car.*

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](../../issues).

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

---

*If you found this project helpful, please consider giving it a ⭐ on GitHub!*
