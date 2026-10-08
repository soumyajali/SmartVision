**ALVA’S INSTITUTE OF ENGINEERING & TECHNOLOGY** (Autonomous Institution Affiliated to VTU, Belagavi) Shobhavana Campus, Mijar, Moodbidri, D.K – 574225 



<!-- Start of picture text -->
|<br>ALVA'S<br><!-- End of picture text -->

**~~DEPARTMENT OF COMPUTER SCIENCE AND~~ ENGINEERING MAJOR PROJECT PRESENTATION ON** 

**Smart Vision: Real-time object detection PRESENTED BY GUIDE NAME :** Mythri N – Mrs. Anitha Rao Nivedita R 4AL23CS088 Assistant Kagale Ruchita – Professor M Patgar 4AL23CS100 Sowmya B Jaali – 4AL23CS127 – 

4AL24CS409 

~~<u>|</u>~~ <mark>Smart</mark> <u>n</u> <mark>Vision: Real-time object detectio August 13,</mark> 2026 <mark>1 /</mark> 17 

Contents 





















Introduction Project Motivation Literature Review Problem Statement and Objectives Methodology System 

Architecture Algorithm Project Outcomes 

References 

<mark>Smart Vision: Real-time object detectio</mark> <u>n</u> 

<mark>2 /</mark> 17 

<mark>August 13,</mark> 2026 

Introduction 









Smart Vision is a real-time computer vision system that uses a camera (smartphone camera or webcam) and AI-based object detection to identify and understand objects and people in the surrounding environment. 

The system combines multiple vision capabilities such as object detection, tracking, OCR, object search, distance estimation, unknown-object detection, and face recognition, along with voicebased interaction and smart alerts. 

The key focus is adaptive and context-aware processing, where the system adjusts its vision processing according to scene conditions, lighting, detection confidence, and device performance to provide efficient real-time AI on mobile/edge devices. 

<mark>Smart Vision: Real-time object detectio</mark> <u>n</u> 

<mark>3 /</mark> 17 

<mark>August 13,</mark> 2026 

## Project Motivation 







Make vision systems accessible anywhere: Use both smartphone cameras and webcams as readily available vision sources, making the system practical for mobile as well as desktop environments. Go beyond simply seeing objects: Instead of only capturing images, the system intelligently understands and interprets objects, people, text, and events in the camera feed. 



Reduce continuous human effort: Automate tasks such as object searching, counting, face recognition, text extraction, tracking, and environment monitoring, which would otherwise require repeated manual observation. 





Provide real-time, actionable assistance: Convert visual information into alerts, recommendations, chatbot responses, and voice feedback, enabling the system to respond to what is happening rather than merely displaying detections. 

Build an adaptive and practical AI system: Design the system to adjust its processing according to scene conditions, detection confidence, and device ca <mark>p</mark> abilities, allowi ~~n~~ ~~<mark>g</mark> ef~~ fici ~~en~~ t ~~re~~ al-t ~~im~~ e <mark>computer visionsmartphones and</mark> Smart ~~Vision: Rea~~ <u><mark>puter</mark></u> ~~<u><mark>s</mark></u>~~ l-Time object Detection System <mark>August 13, 2026</mark> 17 <mark>4 /</mark> 

## Literature Review 



|**Paper**<br>**thor**|**Au-**<br>**and**|**Methods**|**Advantages**|**Limitations**||
|---|---|---|---|---|---|
|**Ahmad**<br>**(2025)**|**et**<br>**al.**|Attention-based<br>Transformer-<br>YOLOv8 model for<br>surveillance|Highly<br>effective<br>for<br>real-time<br>video<br>security<br>and<br>threat<br>monitoring|No<br>co<br>integration<br>hardware-level<br>(e.g.,<br>autom<br>|hesive<br>of<br>alerts<br>ated|
|**Hong**<br>**(2025)**|**et**<br>**al.**|MobileNetV2-based<br>YOLOv8;<br>MobileNet-<br>YOLO<br>connector;<br>chan-nel<br>reduction;<br>352_×_352 input|Reduces<br>parameters<br>by<br>about<br>17.3%;<br>slightly improves<br>detection accuracy;<br>suitable<br>for resource-<br>constrained<br>and<br>mobile devices|~~OS sirens)~~<br>Evaluated only<br>son<br>class<br>COCO;<br>low-res<br>input<br>may<br>detection<br>of<br>and<br>comp<br>objects; general|on per-<br>from<br>olution<br>limit<br>small<br>lex<br>ization|
|**Fan**<br>**(2025)**|**and**<br>**Liu**<br>L-|YOLOv8-LCFD with<br>CSFM, DyHead atten-<br>tion and UIoU loss;<br>eval-uated on THUD<br>and indoor-COCO<br>Smart<br>Vision:<br>Re<br>n|Improves<br>detection<br>accu-racy<br>and<br>robustness<br>for<br>occlusion<br>and<br>multi-<br>scale objects; achieves<br>75.2% mAP@0.5 on<br>THUD<br>while<br>maintaining<br>real-time<br>al-time<br>object<br>detectio|~~needs further~~<br>More<br>com<br>than<br>standard<br>YOLOv8;<br>mai<br>evaluated  for<br>mobile-robot<br>vironments;<br>grain~~ed~~rec~~o~~gnit<br>requires<br> <br>August 13,<br>2026|~~study~~<br>plex<br>nly<br>indoor<br>en-<br>fine-<br>i~~on~~<br>further<br>5 / 17|



|Literature<br>Review<br> <br>||||
|---|---|---|---|
|**Paper  and**<br>**Au-thor**<br>|**Methods**<br>|**Advantages**<br>|**Limitations**<br>|
|**Azatbekuly et al.**<br>**(2024)**<br>|YOLO Algorithm, Real-<br>time<br>video<br>frame<br>process-ing<br>|Achieves<br>high-<br>accuracy<br>object<br>detection in live video<br>streams<br>|Lacks<br>immersive<br>3D<br>visu-alization<br>and<br>automated<br>physical<br>security alerts<br>|
|**Liang**<br>**et**<br>**al.**<br>**(2022)**<br>**[Edge YOLO]**<br>|Edge-Cloud<br>Cooperation<br>architecture<br>for<br>object detection<br>|Balances<br>detection<br>accu-racy<br>with<br>low<br>edge-device<br>computational load<br>|Primarily focused on<br>au-tonomous<br>vehicles<br>rather than web-based<br>surveil-lance<br>|
|**Jocher**<br>**et**<br>**al. (2023)**<br>|YOLOv8<br>architecture with<br>anchor-free design<br>|State-of-the-art<br>infer-<br>ence<br>speed<br>and<br>high<br>mean<br>Average<br>Precision (mAP)<br>|Standard output is lim-<br>ited to basic 2D bound-<br>ing<br>boxes<br>without<br>spatial context<br>|



<mark>Smart Vision: Real-time object detectio</mark> <u>n</u> 

<mark>6 / 17</mark> 

<mark>August 13,</mark> 2026 

Problem Statement 



### **Problem Statement** 

Conventional mobile cameras mainly capture visual information but do not intelligently interpret objects, people, text, or events. Users therefore need separate tools to identify objects, recognize faces, read text, search for items, and receive alerts. This project addresses this limitation by developing an integrated AI-powered mobile vision system that can understand real-time camera input and provide intelligent assistance through a unified platform. 

<mark>Smart</mark> <u>n</u> <mark>Vision: Real-time object detectio August 13,</mark> 2026 

<mark>7 / 17</mark> 

Objectives 



### **Objectives** 











**Real-Time Detection:** Detect and identify objects and people from live camera feeds using AI-based computer vision. **Tracking & Searching:** Search for specific objects and count and track them according to user requirements. 

**Face Recognition & OCR:** Recognize registered faces and extract text from the surrounding environment. 

**Contextual Alerts:** Identify predefined events and provide timely alerts or recommendations. 

**Interactive Assistance:** Enable natural user interaction through chatbot and voice assistance. 

<mark>Smart</mark> <u>n</u> <mark>Vision: Real-time object detectio August 13,</mark> 2026 

<mark>8 / 17</mark> 

## Methodology – Overview 



### **Proposed Methodology** 

The proposed Smart Vision system follows a continuous camera input, processing, interpretation, and assistance workflow, where visual data from a smartphone camera or webcam is analyzed in real time. 

- 1 **Camera Input:** The system captures real-time video through either a smartphone camera or webcam. 

> 2 **Frame Processing:** The captured video is divided into frames and preprocessed to make them suitable for AI analysis. 

> 3 **Visual Detection and Recognition:** YOLOv8 detects objects, while face recognition identifies registered individuals and OCR extracts text from the scene. 

> 4 **Object Analysis:** The detected objects are further processed for counting, searching, and tracking according to the user’s requirements. 

<mark>Smart Vision: Real-time object detectio</mark> <u>n</u> 

<mark>9 / 17</mark> 

<mark>August 13,</mark> 2026 

## Methodology – Continued 



> 5 **Event Detection:** The system analyzes the visual information to identify predefined events such as object disappearance, restrictedarea entry, or exceeding a specified object count. 

> 6 **Intelligent Response:** Based on the detected situation, the system generates alerts and smart recommendations to provide useful and timely assistance. 

> 7 **User Interaction:** Users can interact with the system through a chatbot and voice assistant to ask questions, give commands, and receive 8 information. 

#### 8 

**Adaptive Processing and Output:** The system adjusts its processing based on scene conditions, detection confidence, and device capability, and provides the final results through the application, alerts, chatbot, or voice feedback. 

<u><mark>Smart</mark></u> ~~<u>n</u>~~ <u><mark>Vision: Real-time object detectio</mark></u> <mark>August 13,</mark> 2026 

<mark>10 /</mark> 17 

System 

## Architecture 





<!-- Start of picture text -->
‘SMARTPHONE(al pat CAMERA DATA{Frame ACQUISITION Capture)<br>‘REPROCESSING<br>(Resi, Enhance, Denis)<br>User SETTINGS "AI MULTIMODAL ENGINE<br>(Preferences les) (70Lov8<br>(ch Text xractonobjec eect,SaneFace Understanding) Rcoption<br>(objet Detection, Counting. Tracie,<br>Test Recoptn, Canter Aly)<br>(Eve ales,‘DECISION Lape ng,& EVENT SatPROCESSING Recommendations)<br>(We / Seem Ao) (Passed (rettospech (Sart Alert 8<br>(raat nents) | | Quer Handing) | le Feet) Noten<br>[ti<br><!-- End of picture text -->

<mark>Smart</mark> <u>n</u> <mark>Vision: Real-time object detectio August 13,</mark> 2026 <mark>11 /</mark> 17 

## Technologies Used 



**YOLOv8m – Object Detection & Tracking** Real-time object detection using CNN. Pre-trained on the COCO dataset with 80 object classes. 

**EasyOCR – Text Recognition** Extracts English text from images. Uses CRAFT for text detection and CRNN for recognition. 

**MediaPipe – Face Detection & Recognition** Lightweight, real-time facial analysis. Uses the BlazeFace architecture. 

**pyttsx3 – Voice Assistant** Offline Text-to-Speech (TTS). Uses the system’s native speech 

<mark>engine.</mark> 

<mark>Smart</mark> <u>n</u> <mark>Vision: Real-time object detectio August 13,</mark> 2026 

<mark>12 /</mark> 17 

Expected Outcomes 











**Real-Time Object Detection:** The proposed system is expected to detect and identify multiple objects from a smartphone or webcam feed in real time. 

**Face Recognition:** The system is expected to recognize registered individuals from the live camera feed, enabling personalized visual assistance. 

**Object Counting, Search and Tracking:** Users are expected to be able to count objects, search for specific objects, and track their movement across consecutive frames. 

**OCR-Based Text Extraction:** The system is expected to extract text from documents, labels, and signboards and convert it into digital information. 

<mark>Smart Vision: Real-time object detectio</mark> <u>n</u> 

<mark>13 /</mark> 17 

<mark>August 13,</mark> 2026 

Expected Outcomes 











**Event Detection and Alerts:** The system is expected to detect predefined events, such as restricted-area entry, object disappearance, target-object appearance, and object-count thresholds, and generate timely alerts. 

**Smart Recommendations:** Based on detected objects, recognized individuals, extracted text, and identified events, the system is expected to provide relevant recommendations and useful information. 

- **Interactive Assistance:** The integration of a chatbot and voice assistant is expected to enable natural interaction between users and the system. 

- **Adaptive and Efficient Performance:** The system is expected to adapt its processing according to scene conditions, detection confidence, and device capabilities to achieve reliable real-time performance while efficiently utilizing computational resources. 

<mark>Smart Vision: Real-time object detectio</mark> <u>n</u> 

<mark>14 /</mark> 17 

<mark>August 13,</mark> 2026 

Conclusion 

















The project demonstrates the use of multimodal AI and computer vision for real-time visual analysis. YOLOv8m is used for object detection and tracking. EasyOCR enables text detection and extraction. MediaPipe supports face detection and analysis. pyttsx3 provides voice-based feedback. 

FAISS can be used for efficient similarity searching. 

The combination of these technologies provides intelligent visual understanding, analysis, and user assistance. 

<mark>Smart</mark> <u>n</u> <mark>Vision: Real-time object detectio August 13,</mark> 2026 

<mark>15 /</mark> 17 

## References 



> 1 S. Vats et al. (2025), YOLOv8-based real-time object detection system. 

- 2 N. Azatbekuly et al. (2024), development of an intelligent object detection system based on the YOLO algorithm. 

- 3 G. Jocher, A. Chaurasia, and J. Qiu (2023), YOLOv5 and YOLOv8 realtime object detection models. 

- 4 TensorFlow Team (2023), TensorFlow Lite for machine learning on mobile and embedded devices. 

- 5 H. Sharma and N. Kanwal (2023), survey of object detection techniques using deep learning. 

> 6 A. Bochkovskiy, C.-Y. Wang, and H.-Y. M. Liao (2020), YOLOv4: optimal speed and accuracy of object detection. 

<u><mark>Smart</mark></u> ~~<u>n</u>~~ <u><mark>Vision: Real-time object detectio</mark></u> <mark>August 13,</mark> 2026 

<mark>16 /</mark> 17 



<!-- Start of picture text -->
|<br>ALVA'S<br><!-- End of picture text -->

# **THANK YOU** 

Questions ? 

~~<u>|</u>~~ <mark>Smart</mark> <u>n</u> <mark>Vision: Real-time object detectio August 13,</mark> 2026 <mark>17 /</mark> 17 

