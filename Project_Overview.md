# SmartVision AI - Intelligent Multi-Class Object Recognition System

## Abstract
This project presents an AI-based system for real-time object detection using computer vision techniques. Object detection is an important application in modern intelligent systems, and traditional methods often rely on heavy infrastructure such as CCTV cameras and cloud-based processing, which can be costly and less efficient.

The proposed system uses deep learning techniques, particularly the YOLOv8 model, to automatically analyse video frames and detect objects in real time. By leveraging mobile-based processing and advanced machine learning algorithms, the system aims to provide a lightweight, accurate, and efficient solution for object detection. This approach improves accessibility by eliminating the need for complex hardware and enables fast, real-time performance on portable devices. The system can be effectively used for applications such as identifying objects, monitoring environments, and assisting users in everyday tasks.

## Introduction
Object detection is one of the most important applications of computer vision, widely used in fields such as security, surveillance, and smart assistance systems. Traditional object detection methods often rely on heavy infrastructure such as CCTV cameras, GPUs, and cloud-based processing, which increases cost and reduces accessibility for everyday use.

Recent advancements in deep learning have significantly improved the efficiency and accuracy of object detection systems. Technologies like YOLO (You Only Look Once) enable real-time detection with high speed and precision, making them suitable for practical applications.

This project focuses on developing a lightweight and efficient real-time object detection system using deep learning techniques. The use of the YOLOv8 model allows the system to accurately detect and classify objects from live video streams. By integrating mobile-based processing with optimized frameworks like TensorFlow Lite, the system ensures portability, low latency, and ease of use.

## Problem Statement
Detecting harmful or specific objects in real-time video is a challenging task that involves analyzing frames continuously based on features such as predefined object shapes, pixel color, patterns, and intensity variations.

Current object detection methods often rely on heavy infrastructure such as CCTV cameras, high-performance GPUs, and cloud-based processing, making them costly, less portable, and not easily accessible for everyday use. There is a lack of efficient and automated systems that can accurately perform real-time object detection on lightweight devices.

Hence, there is a need for a reliable, mobile-based, and AI-driven system that can analyse real-time video streams and accurately detect objects while ensuring speed, portability, and ease of use.

## Literature Survey
[1] N. Azatbekuly et al., “Development of an Intelligent Object Detection System Based on YOLO Algorithm,” IEEE SIST, 2024.
[2] S. Vats et al., “YOLOv8-Based Real-Time Object Detection System,” IEEE ASIANCON, 2025.
[3] H. Sharma and N. Kanwal, “Survey of Object Detection Techniques Using Deep Learning,” IEEE ICIIP, 2023.
[4] G. Jocher et al., “YOLOv5 and YOLOv8: Real-Time Object Detection Models,” IEEE/ArXiv.
[5] M. Sandler et al., “MobileNetV2: Efficient CNN Architecture for Mobile Vision Applications,” IEEE CVPR, 2018.
[6] TensorFlow Team, “TensorFlow Lite: Machine Learning for Mobile Devices,” IEEE White Paper.
[7] J. Redmon et al., “You Only Look Once: Unified Real-Time Object Detection,” IEEE CVPR, 2016.

## Objectives Of Our Project
1. Detect and verify specific objects accurately
2. Implement a lightweight model using YOLOv8
3. Deploy the system on mobile using TensorFlow Lite
4. Generate alerts when objects are detected
5. Ensure the system is portable, efficient, and user-friendly

## Methodology
### 1. Video Input & Data Acquisition
Capture video stream using camera (mobile / webcam / CCTV). Extract frames continuously in real-time.

### 2. Preprocessing
Resize frames for model input. Apply noise reduction and normalization. Convert frames into suitable format for detection model.

### 3. Object Detection & Feature Extraction
Use YOLOv8 model for object detection. Extract features such as object shape, color, patterns, and intensity. Identify and localize objects in each frame.

### 4. Classification & Filtering
Classify detected objects (e.g., bottle, keys, harmful objects). Apply confidence score threshold to filter accurate detections.

### 5. Alert Generation & Output
Verify object presence across frames. Trigger alerts based on predefined conditions. Display detected objects with bounding boxes in real time.

## Expected Outcome of the Proposed Project
- **High Accuracy Detection:** Achieve high accuracy in detecting and classifying objects in real-time video streams.
- **Real-Time Detection System:** Provide fast and efficient object detection with low latency.
- **Lightweight & Portable Solution:** Enable object detection on mobile devices without requiring heavy hardware.
- **Deployable Solution:** Integration with smartphones using TensorFlow Lite for real-world applications.
- **Practical Impact:** Assist users in identifying objects, locating lost items, and monitoring environments effectively.

## Summary
This project focuses on developing an AI-based system for real-time object detection using computer vision techniques. By combining image processing methods with deep learning models, the system provides an efficient and automated approach for detecting objects in live video streams.

The use of the YOLOv8 model enhances detection performance by accurately identifying objects with high speed and precision. The proposed solution can be deployed on mobile devices using lightweight frameworks like TensorFlow Lite, making it portable and user-friendly.

This system has practical applications in everyday scenarios such as identifying lost items, monitoring environments, and assisting users in real-time, thereby improving accessibility and usability of intelligent vision systems.
