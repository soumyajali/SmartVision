# 🤖 SmartVision AI – Intelligent Multi-Class Object Recognition System
🔍 Deep Learning • Transfer Learning • CNN • YOLO • Computer Vision • Streamlit • Hugging Face Deployment

![Python](https://img.shields.io/badge/Python-3.x-blue?logo=python)
![TensorFlow](https://img.shields.io/badge/Deep%20Learning-TensorFlow-orange?logo=tensorflow)
![PyTorch](https://img.shields.io/badge/Deep%20Learning-PyTorch-red?logo=pytorch)
![CNN](https://img.shields.io/badge/Architecture-CNN-yellow)
![YOLO](https://img.shields.io/badge/Object%20Detection-YOLOv8-green)
![TransferLearning](https://img.shields.io/badge/Method-Transfer%20Learning-purple)
![Streamlit](https://img.shields.io/badge/Web%20App-Streamlit-red?logo=streamlit)
![HuggingFace](https://img.shields.io/badge/Deployment-HuggingFace-blue?logo=huggingface)
![Domain](https://img.shields.io/badge/Domain-Computer%20Vision%20%7C%20AI-brightgreen)

---

## 📘 Overview
**SmartVision AI** is a next-gen **computer vision platform** built to perform:
- 🟩 Multi-class Image Classification  
- 🔶 Multi-object Detection in a single image  

Trained on **25 diverse COCO object classes**, the system integrates:
- CNN-based **Transfer Learning models** (VGG16, ResNet50, MobileNet, EfficientNet)
- **YOLO-based object detection** for bounding boxes and confidence scoring
- **Streamlit multipage UI** for image upload + model comparison
- **Deployment on Hugging Face / Cloud** for real-time inference

This project demonstrates a **full deep learning lifecycle** — from dataset building to cloud deployment.

---

## 🎯 Problem Statement
Industries require visual AI systems that can:
- Detect **multiple objects in an image**
- Classify across **multiple categories**
- Run **real-time inference**
- Maintain **high accuracy under varying lighting & angles**
- Scale **for cloud-based global usage**

SmartVision AI solves this by combining **classification + object detection** into one deployable solution.

---

## 💼 Business Use Cases
| Industry | Application |
|---------|-------------|
| 🚦 Smart Cities | Vehicle detection, pedestrian monitoring, traffic analytics |
| 🛒 Retail | Product recognition, automated checkout, shelf analytics |
| 🛡 Security | Intrusion & suspicious object alerts, surveillance automation |
| 🐾 Wildlife | Animal identification & behavior monitoring from camera traps |
| 🏥 Healthcare | PPE compliance, patient fall detection |
| 🏠 IoT & Smart Home | Object-triggered automation & real-time alerts |
| 🚚 Logistics | Package sorting, barcode detection, damage detection |

---

## 🧠 Skills Takeaway
- TensorFlow & PyTorch Deep Learning
- Transfer Learning with **VGG16 / ResNet50 / MobileNet / EfficientNet**
- **YOLO Object Detection**
- OpenCV for image transformation
- Confusion Matrix & visual evaluation
- Streamlit multi-page UI development
- Deployment on **Hugging Face / Streamlit Cloud**

---

## ⚙️ Approach Summary

### 🔹 Dataset Preparation
- Curated **25 COCO classes**
- Normalized/resized images
- Augmentation: rotation, flipping, gamma correction, zoom, motion blur

### 🔹 CNN-Based Image Classification
4 deep learning models trained:
- **VGG16**
- **ResNet50**
- **MobileNet**
- **EfficientNet**

Dataset passed through:
- Data generators
- Transfer learning
- Fine-tuning stage
- Side-by-side model output comparison

### 🔹 YOLO Object Detection
- Trained for bounding box + class + confidence score
- Supports **multi-object recognition**
- Optimized for **real-time inference & low latency**

### 🔹 Streamlit Multi-Page Web App
Contains:
1️⃣ Home / Overview  
2️⃣ Image Classification (upload → predictions)  
3️⃣ YOLO Object Detection  
4️⃣ Model Performance Dashboard  
5️⃣ About / System Documentation  

### 🔹 Cloud Deployment
- Hosted on **Hugging Face Spaces / Streamlit Cloud**
- Integrated with GitHub for CI/CD
- Supports GPU inference where available

---

<summary>📸 Click to view Streamlit UI screenshots</summary>

#### Home Page  
![Home Page](https://github.com/user-attachments/assets/d4ed0614-4b9e-4d31-9c60-6c94550c7c99)


#### Detection Results Page 1
![Result Page](https://github.com/user-attachments/assets/8e8884b4-db95-4fde-a077-7c14f82cd9f1)


####  Detection Results Page 2
![Dashboard](https://github.com/user-attachments/assets/c4acb123-7f31-48a7-8f2e-ea620dcce65b)


####  Detection Results Page 3
![Dashboard](https://github.com/user-attachments/assets/d7269bff-963b-4c16-9617-0ace8d8534a6)



---

## 🧩 Project Structure
```bash
SmartVision_AI/
│
├── datasets codes/
│   └── Smart_Vision_Data_Code.ipynb
│
├── Traninig Codes/
│   └── SmartVision_Train_Code.ipynb
│
├── classification/
│   ├── test/
│   └── train/
│
├── smart vision detection/
│   ├── train
│   ├── valid
│   └── data.yaml
│
├── SmartVision_Train.ipynb
├── app.py
└── requirements.txt
```

---

## 🛠️ Run Locally
Install dependencies:
```
pip install -r requirements.txt
```

Launch Streamlit app:
```
streamlit run app.py
```

---
arring the repository!

---

