import streamlit as st
import torch
import torch.nn as nn
from ultralytics import YOLO
from torchvision import models, transforms
from PIL import Image
import numpy as np
import cv2
import os
import subprocess
import time
from datetime import datetime
from voice_assistant import get_voice_assistant
from database import get_database
from utils import (
    PerformanceMonitor, OCRReader, QRBarcodeScanner,
    AIAssistant, ReportGenerator
)
from utils.recorder import get_video_recorder
from services.email_service import get_email_service
from services.telegram_service import get_telegram_service
from services.face_service import FaceService
import plotly.graph_objects as go
import plotly.express as px
# Removed insecure SSL certificate workaround as per requirements
# ---------------- CLASS LABELS ----------------


# ---------------- PAGE CONFIG ----------------
st.set_page_config(page_title="Smart Vision AI", page_icon="🤖", layout="wide")

# ---------------- PREMIUM 3D UI (background only — no AI changes) ----------------
from integration import inject_premium_ui
inject_premium_ui()

# ---------------- SESSION STATE ----------------
if "face_service" not in st.session_state:
    st.session_state["face_service"] = FaceService()
if "page" not in st.session_state:
    st.session_state["page"] = "🏠 Home"
if "voice_enabled" not in st.session_state:
    st.session_state["voice_enabled"] = False
if "dark_mode" not in st.session_state:
    st.session_state["dark_mode"] = False
if "confidence_threshold" not in st.session_state:
    st.session_state["confidence_threshold"] = 0.25
if "search_object" not in st.session_state:
    st.session_state["search_object"] = ""
if "search_mode" not in st.session_state:
    st.session_state["search_mode"] = False
if "performance_monitor" not in st.session_state:
    st.session_state["performance_monitor"] = PerformanceMonitor()
if "detections_dir" not in st.session_state:
    st.session_state["detections_dir"] = "detections"
    os.makedirs(st.session_state["detections_dir"], exist_ok=True)
if "email_alerts_enabled" not in st.session_state:
    st.session_state["email_alerts_enabled"] = False
if "email_configured" not in st.session_state:
    st.session_state["email_configured"] = False
if "telegram_alerts_enabled" not in st.session_state:
    st.session_state["telegram_alerts_enabled"] = False
if "telegram_configured" not in st.session_state:
    st.session_state["telegram_configured"] = False
if "recording_dir" not in st.session_state:
    st.session_state["recording_dir"] = "recordings"
    os.makedirs(st.session_state["recording_dir"], exist_ok=True)

# ---------------- LOAD MODELS ----------------
@st.cache_resource
def load_detection_model():
    return YOLO("yolov8m.pt")

@st.cache_resource
def load_classification_model():
    import ssl
    import certifi
    import urllib.request
    ssl_context = ssl.create_default_context(cafile=certifi.where())
    urllib.request.install_opener(urllib.request.build_opener(urllib.request.HTTPSHandler(context=ssl_context)))
    try:
        import urllib.error
        # Use the latest torchvision API to load weights instead of deprecated pretrained=True
        # This will automatically use cached weights if available in ~/.cache/torch/hub/checkpoints/
        weights = models.MobileNet_V2_Weights.DEFAULT
        model = models.mobilenet_v2(weights=weights)
    except urllib.error.URLError as e:
        # Handle SSL certificate verification failures on macOS or offline scenarios gracefully
        # Fallback to weights=None to prevent the app from crashing, though model performance will be degraded initially
        st.error(f"Failed to download pretrained weights: {e}. Falling back to uninitialized model. Note: On macOS, you may need to run 'Install Certificates.command' in your Python folder.")
        model = models.mobilenet_v2(weights=None)
        
    for param in model.features.parameters():
        param.requires_grad = False
    model.classifier = nn.Sequential(
        nn.Dropout(0.3),
        nn.Linear(model.classifier[1].in_features, 1024),
        nn.ReLU(),
        nn.Dropout(0.5),
        nn.Linear(1024, NUM_CLASSES)
    )
    state_dict = torch.load("MobileNET_best.pth", map_location="cpu")
    model.load_state_dict(state_dict, strict=False)
    model.eval()
    return model


CLS_CLASS_NAMES = [name.title() for name in [
'Chair','bottle','Cat','Cup','Bench','Horse','Person','bed','Truck','Airplane',
'Cycle','Bird','bike','bus','potted plant','Pizza','Stop Signal','Bowl',
'Traffic Signal','couch','elephant','Cake','dog','cow','Car'
]]

det_model = load_detection_model()
CLASS_NAMES = det_model.names
NUM_CLASSES = len(CLS_CLASS_NAMES)
cls_model = load_classification_model()
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])


# ---------------- GLOBAL MODERN CSS ----------------
def get_theme_css():
    return """
<style>
.stApp {
    background-color: #0e1117;
}
.section-title {
    font-size: 32px; font-weight: 700; color: #f8fafc;
    margin-bottom: 5px;
}
.sub-text {
    font-size: 16px; color: #94a3b8; margin-bottom: 30px;
}
.card-box {
    background: #1e293b; padding: 20px; border-radius: 10px;
    border: 1px solid rgba(255, 255, 255, 0.05);
    margin-bottom: 15px;
    color: #e2e8f0;
}
.kpi-card {
    background: #1e293b; padding: 15px; border-radius: 10px;
    border: 1px solid rgba(255, 255, 255, 0.05);
    text-align: center;
}
.kpi-value {
    font-size: 24px; font-weight: bold; color: #f8fafc;
}
.kpi-label {
    font-size: 14px; color: #94a3b8;
}
.model-info-card {
    background: #1e293b; padding: 15px; border-radius: 10px;
    border: 1px solid rgba(255, 255, 255, 0.05);
    margin-top: 20px;
    font-size: 14px;
}
.model-info-row {
    display: flex; justify-content: space-between; margin-bottom: 5px;
}
.model-info-label { color: #94a3b8; }
.model-info-val { color: #e2e8f0; }
.status-ready { color: #22c55e; font-weight: bold; }
div.stButton > button:first-child {
    border-radius: 6px;
    border: 1px solid rgba(255, 255, 255, 0.1);
}
</style>
"""
st.markdown(get_theme_css(), unsafe_allow_html=True)


# ---------------- SIDEBAR ----------------
st.sidebar.markdown("### SMART VISION")
st.sidebar.markdown("<small style='color: #94a3b8;'>Real-Time Object Detection</small>", unsafe_allow_html=True)

page = st.sidebar.radio(
    "",
    ["🏠 Dashboard", "📷 Live Detection", "📋 Detections", "🔔 Alerts", "📜 History", "👤 Face Registration", "⚙️ Settings", "ℹ️ About"],
    index=0
)
st.session_state["page"] = page

st.sidebar.markdown("---")

if page == "⚙️ Settings":
    st.session_state["voice_enabled"] = st.sidebar.toggle("🔊 Voice Assistant", value=st.session_state.get("voice_enabled", False))
    st.session_state["confidence_threshold"] = st.sidebar.slider("🎯 Confidence Threshold", 0.05, 1.00, st.session_state.get("confidence_threshold", 0.10), 0.05)
    st.session_state["search_mode"] = st.sidebar.checkbox("Enable Search Mode")
    if st.session_state["search_mode"]:
        st.session_state["search_object"] = st.sidebar.text_input("Search Object", placeholder="e.g., Bottle")

st.sidebar.markdown("""
<div class="model-info-card">
    <div style="color: #22c55e; margin-bottom: 10px; font-weight: bold;">Model Info</div>
    <div class="model-info-row"><span class="model-info-label">Model</span><span class="model-info-val">YOLOv8</span></div>
    <div class="model-info-row"><span class="model-info-label">Version</span><span class="model-info-val">8.1.0</span></div>
    <div class="model-info-row"><span class="model-info-label">Backend</span><span class="model-info-val">PyTorch</span></div>
    <div class="model-info-row"><span class="model-info-label">Device</span><span class="model-info-val">CPU</span></div>
    <div class="model-info-row"><span class="model-info-label">Status</span><span class="status-ready">Ready</span></div>
</div>
""", unsafe_allow_html=True)


# 🏠 HOME PAGE (Dashboard)
if page in ["🏠 Dashboard", "🏠 Home"]:
    st.markdown("""
        <div style="display: flex; justify-content: space-between; align-items: center;">
            <div>
                <div class='section-title'>Dashboard</div>
                <div class='sub-text'>Real-time detection from camera</div>
            </div>
            <div style="text-align: right;">
                <div style="color: #22c55e; font-weight:bold;">● System Active</div>
                <div style="color: #e2e8f0; font-size:14px; margin-top:2px;">""" + datetime.now().strftime("%I:%M:%S %p") + """</div>
            </div>
        </div>
    """, unsafe_allow_html=True)
    
    col_main, col_side = st.columns([3, 1])
    
    input_type = st.radio("Choose Input", ["Webcam", "Upload Image"], horizontal=True)
    img_cv = None
    
    with col_main:
        st.markdown("<div class='card-box'><b style='color:#22c55e;'>🎥 Live Camera Feed</b><br/>", unsafe_allow_html=True)
        
        if input_type == "Upload Image":
            file = st.file_uploader("Upload Image", type=["jpg","jpeg","png"])
            if file:
                data = np.frombuffer(file.read(), np.uint8)
                img_cv = cv2.imdecode(data, cv2.IMREAD_COLOR)
        else:
            snap = st.camera_input("Take a snapshot for detection")
            if snap:
                pil = Image.open(snap)
                img_cv = cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)

        video_placeholder = st.empty()
        
        # Controls
        ctrl_c1, ctrl_c2, ctrl_c3, ctrl_c4, ctrl_c5 = st.columns(5)
        with ctrl_c1:
            st.button("▶️ Start Detection", width="stretch", type="primary")
        with ctrl_c2:
            st.button("⏹️ Stop Detection", width="stretch")
        with ctrl_c3:
            capture_btn = st.button("📸 Save Detection", width="stretch")
        with ctrl_c4:
            st.button("⏺️ Record", width="stretch")
        with ctrl_c5:
            st.button("⛶ Fullscreen", width="stretch")
            
        st.markdown("</div>", unsafe_allow_html=True)
        
    # Variables for stats
    detected_objects_with_conf = []
    dangerous_objects = {"person", "knife", "fire", "gun", "cat", "bottle", "scissors"}
    found_dangerous = False
    alerts_html = ""
    object_counts = {}
    total_detections = 0
    accuracy = 0.0

    if img_cv is not None:
        start_time = time.time()
        results = det_model(img_cv, conf=st.session_state["confidence_threshold"])
        inference_time = time.time() - start_time
        st.session_state["performance_monitor"].record_inference(inference_time)
        
        detected_img = results[0].plot()
        
        for result in results:
            if result.boxes is not None:
                for box in result.boxes:
                    class_id = int(box.cls[0])
                    confidence = float(box.conf[0])
                    if class_id < len(CLASS_NAMES):
                        obj_name = CLASS_NAMES[class_id]
                        detected_objects_with_conf.append((obj_name, confidence))
                        object_counts[obj_name] = object_counts.get(obj_name, 0) + 1
                        total_detections += 1

                        if obj_name == "person":
                            x1, y1, x2, y2 = map(int, box.xyxy[0])
                            face_service = st.session_state.get("face_service")
                            if face_service and face_service.is_trained:
                                person_name = face_service.recognize(img_cv, (x1, y1, x2, y2))
                                if person_name:
                                    # Override the label on the image with a prominent solid background
                                    text_size = cv2.getTextSize(person_name, cv2.FONT_HERSHEY_SIMPLEX, 0.9, 2)[0]
                                    cv2.rectangle(detected_img, (x1, max(y1-30, 0)), (x1 + text_size[0], max(y1-30, 0) + text_size[1] + 10), (0, 200, 0), -1)
                                    cv2.putText(detected_img, person_name, (x1, max(y1-5, 25)), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (255, 255, 255), 2)
                                    # Update the detected objects list with the specific person's name
                                    obj_name = person_name

                        if obj_name in dangerous_objects:
                            found_dangerous = True
                            alerts_html += f"""
                            <div style='display:flex; align-items:flex-start; margin-bottom:10px;'>
                                <span style='margin-right:10px;'>⚠️</span>
                                <div>
                                    <div style='color: #f8fafc; font-size: 14px;'>{obj_name} Detected</div>
                                    <div style='color: #94a3b8; font-size: 12px;'>""" + datetime.now().strftime("%I:%M:%S %p") + """</div>
                                </div>
                            </div>
                            """

        # Update image AFTER drawing faces
        video_placeholder.image(cv2.cvtColor(detected_img, cv2.COLOR_BGR2RGB), width="stretch")
        
        if total_detections > 0:
            accuracy = sum(conf for _, conf in detected_objects_with_conf) / total_detections * 100
            
        if capture_btn:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filepath = os.path.join(st.session_state["detections_dir"], f"detection_{timestamp}.jpg")
            cv2.imwrite(filepath, detected_img)
            st.toast(f"Saved to {filepath}", icon="✅")
            db = get_database()
            for obj, conf in detected_objects_with_conf:
                db.add_detection(obj, conf, filepath)
    else:
        video_placeholder.info("Upload an image or use the webcam to start detecting.")
        
    with col_side:
        # Build summary HTML
        summary_items_html = ""
        for obj, count in object_counts.items():
            summary_items_html += f"<div style='display:flex; justify-content:space-between; margin-bottom:10px;'><span>{obj}</span><span>{count}</span></div>"
            
        st.markdown(f"""
        <div class='card-box' style='height: 100%;'>
            <div style='color: #22c55e; margin-bottom: 15px; font-weight: bold;'>📊 Detection Summary</div>
            {summary_items_html if total_detections > 0 else "<div style='color:#94a3b8; font-size:12px;'>No detections yet</div>"}
            <hr style='border-color: rgba(255,255,255,0.1); margin: 15px 0;'/>
            <div style='display:flex; justify-content:space-between; font-weight:bold; color: #22c55e;'><span>Total Detections</span><span>{total_detections}</span></div>
        </div>
        """, unsafe_allow_html=True)
        
        st.markdown(f"""
        <div class='card-box' style='height: 100%;'>
            <div style='color: #22c55e; margin-bottom: 15px; font-weight: bold;'>🔔 Recent Alerts</div>
            {alerts_html if found_dangerous else "<div style='font-size: 12px; color: #94a3b8;'>No recent alerts.</div>"}
            <div style='text-align:center; margin-top:15px;'>
                <button style='background: transparent; color: #e2e8f0; border: 1px solid rgba(255,255,255,0.2); padding: 5px 15px; border-radius: 5px; cursor: pointer; width: 100%;'>View All Alerts →</button>
            </div>
        </div>
        """, unsafe_allow_html=True)

    # KPI Row
    perf_stats = st.session_state["performance_monitor"].get_stats()
    fps = perf_stats['fps'] if perf_stats else 0.0
    cpu = perf_stats['cpu_percent'] if perf_stats else 0.0

    st.markdown("<br/>", unsafe_allow_html=True)
    k1, k2, k3, k4 = st.columns(4)
    with k1:
        st.markdown("<div class='kpi-card'><div class='kpi-label'>🚀 Real-time</div><div class='kpi-value'>Active</div></div>", unsafe_allow_html=True)
    with k2:
        st.markdown(f"<div class='kpi-card'><div class='kpi-label'>🎯 Average Accuracy</div><div class='kpi-value'>{accuracy:.1f}%</div></div>", unsafe_allow_html=True)
    with k3:
        st.markdown(f"<div class='kpi-card'><div class='kpi-label'>⚡ Processing Speed</div><div class='kpi-value'>{fps:.1f} FPS</div></div>", unsafe_allow_html=True)
    with k4:
        st.markdown(f"<div class='kpi-card'><div class='kpi-label'>💻 CPU Usage</div><div class='kpi-value'>{cpu:.1f}%</div></div>", unsafe_allow_html=True)



# 👤 FACE REGISTRATION
elif page == "👤 Face Registration":
    st.markdown("<div class='section-title'>👤 Face Registration</div>", unsafe_allow_html=True)
    st.markdown("<div class='sub-text'>Register faces so the AI can recognize them by name</div>", unsafe_allow_html=True)
    
    col1, col2 = st.columns(2)
    with col1:
        st.markdown("<div class='card-box'>", unsafe_allow_html=True)
        reg_name = st.text_input("Name of the Person", placeholder="e.g. John Doe")
        reg_image = st.camera_input("Take a clear picture of their face")
        
        if st.button("Register Face", type="primary", width="stretch"):
            if reg_name and reg_image:
                import numpy as np
                import cv2
                from PIL import Image
                
                # Convert uploaded image to opencv format
                pil_img = Image.open(reg_image)
                cv_img = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
                
                # Register
                saved_path = st.session_state["face_service"].register_face(reg_name, cv_img)
                st.success(f"Successfully registered {reg_name}!")
            else:
                st.error("Please provide both a name and a photo.")
        st.markdown("</div>", unsafe_allow_html=True)
        
    with col2:
        st.markdown("<div class='card-box'><b>Registered People</b><br/>", unsafe_allow_html=True)
        # Display unique registered names
        if st.session_state["face_service"].is_trained:
            for name in set(st.session_state["face_service"].label_map.values()):
                st.markdown(f"<li>{name}</li>", unsafe_allow_html=True)
        else:
            st.markdown("No faces registered yet.")
        st.markdown("</div>", unsafe_allow_html=True)


# 🧠 CLASSIFICATION 

elif page == "🧠 Classification":

    st.markdown("<div class='section-title'>🧠 Image Classification</div>", unsafe_allow_html=True)
    st.markdown("<div class='sub-text'>Upload or capture an image to predict the object class</div>", unsafe_allow_html=True)

    input_type = st.radio("Choose Input", ["Upload Image", "Webcam"], horizontal=True)
    img = None

    if input_type == "Upload Image":
        file = st.file_uploader("Upload Image", type=["jpg","jpeg","png"])
        if file:
            img = Image.open(file).convert("RGB")
    else:
        cam = st.camera_input("Capture Image")
        if cam:
            img = Image.open(cam).convert("RGB")

    if img:
        col1, col2 = st.columns(2)

        with col1:
            st.markdown("<div class='card-box'><b>📌 Input Image</b></div>", unsafe_allow_html=True)
            st.image(img, width=420) 

      
        tensor = transform(img).unsqueeze(0)  

        with torch.no_grad(): logits = cls_model(tensor)
        probs = torch.softmax(logits, dim=1)[0]
        idx = torch.argmax(probs).item()

        with col2:
            st.markdown("<div class='card-box'><b>🎯 Result</b></div>", unsafe_allow_html=True)
            st.markdown(f"<div class='result-label'>{CLS_CLASS_NAMES[idx]}</div>", unsafe_allow_html=True)
            st.markdown(f"<div class='confidence-label'>Confidence: {probs[idx]:.2f}</div>", unsafe_allow_html=True)
            
            # Save classification to database
            db = get_database()
            db.add_detection(CLS_CLASS_NAMES[idx], float(probs[idx]))


# 🎯 OBJECT DETECTION 

elif page == "🎯 Object Detection":

    st.markdown("<div class='section-title'>🎯 Object Detection</div>", unsafe_allow_html=True)
    st.markdown("<div class='sub-text'>Upload or capture an image for YOLO detection</div>", unsafe_allow_html=True)
    
    # Video Recording Controls
    recorder = get_video_recorder()
    rec_col1, rec_col2, rec_col3 = st.columns(3)
    with rec_col1:
        if st.button("🎥 Start Recording", disabled=recorder.is_recording()):
            recorder.start_recording(frame_size=(640, 480), fps=30)
            st.success("Recording started!")
    with rec_col2:
        if st.button("⏹️ Stop Recording", disabled=not recorder.is_recording()):
            saved_file = recorder.stop_recording()
            if saved_file:
                st.success(f"Recording saved: {saved_file}")
    with rec_col3:
        if st.button("❌ Cancel Recording", disabled=not recorder.is_recording()):
            recorder.cancel_recording()
            st.warning("Recording cancelled")
    
    if recorder.is_recording():
        st.info(f"🔴 Recording... Frames: {recorder.get_frame_count()}")

    input_type = st.radio("Choose Input", ["Upload Image", "Webcam"], horizontal=True)
    img_cv = None

    if input_type == "Upload Image":
        file = st.file_uploader("Upload Image", type=["jpg","jpeg","png"])
        if file:
            data = np.frombuffer(file.read(), np.uint8)
            img_cv = cv2.imdecode(data, cv2.IMREAD_COLOR)
    else:
        snap = st.camera_input("Capture Image")
        if snap:
            pil = Image.open(snap)
            img_cv = cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)

    if img_cv is not None:
        col1, col2 = st.columns(2)

        with col1:
            st.markdown("<div class='card-box'><b>📌 Input Image</b></div>", unsafe_allow_html=True)
            st.image(cv2.cvtColor(img_cv, cv2.COLOR_BGR2RGB), width=420)

        # Record inference time
        start_time = time.time()
        results = det_model(img_cv, conf=st.session_state["confidence_threshold"])
        inference_time = time.time() - start_time
        st.session_state["performance_monitor"].record_inference(inference_time)
        
        detected_img = results[0].plot()
        
        # Extract detected objects with confidence
        detected_objects = set()
        detected_objects_with_conf = []
        detections_for_recording = []
        dangerous_objects = {"person", "knife", "fire", "gun", "cat", "bottle", "scissors"}
        found_dangerous = False
        
        if results and len(results) > 0:
            for result in results:
                if result.boxes is not None:
                    for box in result.boxes:
                        class_id = int(box.cls[0])
                        confidence = float(box.conf[0])
                        if class_id in det_model.names:
                            obj_name = det_model.names[class_id]
                            detected_objects.add(obj_name)
                            detected_objects_with_conf.append((obj_name, confidence))
                            
                            # Prepare for video recording
                            bbox = box.xyxy[0].tolist()
                            detections_for_recording.append({
                                'bbox': bbox,
                                'label': obj_name,
                                'confidence': confidence
                            })
                            
                            # Check for dangerous objects
    
                        if obj_name == "person":
                            x1, y1, x2, y2 = map(int, box.xyxy[0])
                            face_service = st.session_state.get("face_service")
                            if face_service and face_service.is_trained:
                                person_name = face_service.recognize(img_cv, (x1, y1, x2, y2))
                                if person_name:
                                    # Override the label on the image with a prominent solid background
                                    text_size = cv2.getTextSize(person_name, cv2.FONT_HERSHEY_SIMPLEX, 0.9, 2)[0]
                                    cv2.rectangle(detected_img, (x1, max(y1-30, 0)), (x1 + text_size[0], max(y1-30, 0) + text_size[1] + 10), (0, 200, 0), -1)
                                    cv2.putText(detected_img, person_name, (x1, max(y1-5, 25)), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (255, 255, 255), 2)
                                    # Update the detected objects list with the specific person's name
                                    obj_name = person_name

                        if obj_name in dangerous_objects:
                                found_dangerous = True
        
        # Voice Assistant integration
        if st.session_state["voice_enabled"] and detected_objects:
            voice_assistant = get_voice_assistant()
            voice_assistant.reset_announced_objects(detected_objects)
            for obj in detected_objects:
                voice_assistant.announce_detection(obj)
        
        # Dangerous Object Alert
        if found_dangerous:
            st.error("⚠️ DANGEROUS OBJECT DETECTED!")
            
            # Immediately trigger the siren using Streamlit's native audio
            st.audio("siren.wav", format="audio/wav", autoplay=True)

            if st.session_state["voice_enabled"]:
                voice_assistant = get_voice_assistant()
                voice_assistant.speak("Dangerous object detected. Please exercise caution.")
            
            # Email and Telegram Alerts
            screenshot_path = None
            if (st.session_state["email_alerts_enabled"] and st.session_state.get("email_configured", False)) or \
               (st.session_state["telegram_alerts_enabled"] and st.session_state.get("telegram_configured", False)):
                # Save screenshot once for both alerts
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"dangerous_{timestamp}.jpg"
                screenshot_path = os.path.join(st.session_state["detections_dir"], filename)
                cv2.imwrite(screenshot_path, detected_img)
            
            # Email Alert
            if st.session_state["email_alerts_enabled"] and st.session_state.get("email_configured", False) and screenshot_path:
                email_service = get_email_service()
                for obj, conf in detected_objects_with_conf:
                    if obj in dangerous_objects:
                        email_service.send_alert(obj, conf, screenshot_path)
                        st.info(f"📧 Email alert sent for {obj}")
            
            # Telegram Alert
            if st.session_state["telegram_alerts_enabled"] and st.session_state.get("telegram_configured", False) and screenshot_path:
                telegram_service = get_telegram_service()
                for obj, conf in detected_objects_with_conf:
                    if obj in dangerous_objects:
                        telegram_service.send_alert(obj, conf, screenshot_path)
                        st.info(f"📱 Telegram alert sent for {obj}")
        
        # Object Search Mode
        if st.session_state["search_mode"] and st.session_state["search_object"]:
            search_obj = st.session_state["search_object"].lower()
            found = any(search_obj in obj.lower() for obj in detected_objects)
            if found:
                st.success(f"✅ FOUND: {st.session_state['search_object']}")
                if st.session_state["voice_enabled"]:
                    voice_assistant = get_voice_assistant()
                    voice_assistant.speak(f"{st.session_state['search_object']} found.")
            else:
                st.info("🔍 Searching...")
        
        # Object Counter
        if detected_objects_with_conf:
            object_counts = {}
            for obj, conf in detected_objects_with_conf:
                object_counts[obj] = object_counts.get(obj, 0) + 1
            
            st.markdown("### 📊 Object Counts")
            count_cols = st.columns(min(len(object_counts), 4))
            for i, (obj, count) in enumerate(object_counts.items()):
                with count_cols[i % 4]:
                    st.metric(obj, count)
        
        # Smart Recommendations
        if detected_objects:
            ai_assistant = AIAssistant()
            for obj in list(detected_objects)[:1]:  # Show recommendation for first object
                recommendation = ai_assistant.get_recommendation(obj)
                st.info(f"💡 {recommendation}")
        
        # Save detections to database
        db = get_database()
        for obj, conf in detected_objects_with_conf:
            db.add_detection(obj, conf)
        
        # Screenshot Capture
        with col2:
            st.markdown("<div class='card-box'><b>🎯 Detection Result</b></div>", unsafe_allow_html=True)
            st.image(cv2.cvtColor(detected_img, cv2.COLOR_BGR2RGB), width=420)
            
            # Add frame to recording if recording
            if recorder.is_recording():
                recorder.add_annotated_frame(detected_img, detections_for_recording)
            
            if st.button("💾 Save Detection"):
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"detection_{timestamp}.jpg"
                filepath = os.path.join(st.session_state["detections_dir"], filename)
                cv2.imwrite(filepath, detected_img)
                st.success(f"Saved to {filepath}")
                
                # Also save to database with image path
                for obj, conf in detected_objects_with_conf:
                    db.add_detection(obj, conf, filepath)
        
        # AI Assistant - Click on object for info
        if detected_objects:
            st.markdown("### 🤖 AI Assistant")
            selected_obj = st.selectbox("Select object for details", list(detected_objects))
            if selected_obj:
                ai_assistant = AIAssistant()
                info = ai_assistant.get_object_info(selected_obj)
                st.markdown(f"**Description:** {info['description']}")
                st.markdown(f"**Uses:** {info['uses']}")
                st.markdown(f"**Safety:** {info['safety']}")
                st.markdown(f"**Interesting Fact:** {info['facts']}")


# 📊 ANALYTICS PAGE

elif page == "📊 Analytics":
    st.markdown("<div class='section-title'>📊 Detection Analytics</div>", unsafe_allow_html=True)
    
    db = get_database()
    stats = db.get_detection_stats()
    object_counts = db.get_object_counts()
    timeline = db.get_detection_timeline(days=7)
    
    # Key Metrics
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Detections", stats['total_detections'])
    with col2:
        st.metric("Today's Detections", stats['today_detections'])
    with col3:
        st.metric("Most Detected", stats['most_detected_object'] or 'N/A')
    with col4:
        st.metric("Avg Confidence", f"{stats['average_confidence']:.3f}")
    
    st.markdown("---")
    
    # Pie Chart
    if object_counts:
        st.markdown("### 📊 Detection Distribution")
        fig_pie = go.Figure(data=[go.Pie(
            labels=list(object_counts.keys()),
            values=list(object_counts.values()),
            hole=0.3
        )])
        fig_pie.update_layout(title="Object Detection Distribution")
        st.plotly_chart(fig_pie, width="stretch")
    
    # Bar Chart
    if object_counts:
        st.markdown("### 📊 Detection Counts")
        fig_bar = go.Figure(data=[go.Bar(
            x=list(object_counts.keys()),
            y=list(object_counts.values()),
            marker_color='skyblue'
        )])
        fig_bar.update_layout(
            title="Detection Counts by Object",
            xaxis_title="Object",
            yaxis_title="Count"
        )
        st.plotly_chart(fig_bar, width="stretch")
    
    # Timeline
    if timeline:
        st.markdown("### 📊 Detection Timeline (Last 7 Days)")
        fig_line = go.Figure(data=[go.Scatter(
            x=[t['date'] for t in timeline],
            y=[t['count'] for t in timeline],
            mode='lines+markers',
            line=dict(color='orange', width=3)
        )])
        fig_line.update_layout(
            title="Detection Timeline",
            xaxis_title="Date",
            yaxis_title="Count"
        )
        st.plotly_chart(fig_line, width="stretch")
    
    # Export Reports
    st.markdown("---")
    st.markdown("### 📄 Export Reports")
    detections = db.get_all_detections()
    
    col1, col2 = st.columns(2)
    with col1:
        if st.button("Generate CSV Report"):
            report_gen = ReportGenerator()
            csv_path = report_gen.generate_csv(detections)
            st.success(f"CSV report generated: {csv_path}")
    
    with col2:
        if st.button("Generate PDF Report"):
            report_gen = ReportGenerator()
            pdf_path = report_gen.generate_pdf(detections, stats)
            st.success(f"PDF report generated: {pdf_path}")


# 📜 HISTORY PAGE

elif page == "📜 History":
    st.markdown("<div class='section-title'>📜 Detection History</div>", unsafe_allow_html=True)
    
    db = get_database()
    
    # Search
    search_query = st.text_input("🔍 Search history", placeholder="Search by object name...")
    
    # Actions
    col1, col2, col3 = st.columns(3)
    with col1:
        if st.button("🗑️ Clear All History"):
            count = db.clear_all_detections()
            st.success(f"Cleared {count} records")
            st.rerun()
    
    with col2:
        if st.button("🔄 Refresh"):
            st.rerun()
    
    # Display History
    if search_query:
        detections = db.search_detections(search_query)
    else:
        detections = db.get_all_detections()
    
    if detections:
        st.markdown(f"### Total Records: {len(detections)}")
        
        for i, det in enumerate(detections[:50]):  # Show first 50
            with st.expander(f"ID: {det['id']} - {det['object_name']} ({det['confidence']:.3f})"):
                col1, col2, col3 = st.columns(3)
                col1.write(f"**Date:** {det['date']}")
                col2.write(f"**Time:** {det['time']}")
                col3.write(f"**Confidence:** {det['confidence']:.3f}")
                if det['image_path']:
                    st.write(f"**Image:** {det['image_path']}")
                
                if st.button(f"Delete {det['id']}", key=f"del_{det['id']}"):
                    db.delete_detection(det['id'])
                    st.rerun()
    else:
        st.info("No detection records found.")


# 🔍 OCR PAGE

elif page == "🔍 OCR":
    st.markdown("<div class='section-title'>🔍 OCR - Text Extraction</div>", unsafe_allow_html=True)
    st.markdown("<div class='sub-text'>Upload an image to extract text using EasyOCR</div>", unsafe_allow_html=True)
    
    ocr_reader = OCRReader()
    
    file = st.file_uploader("Upload Image for OCR", type=["jpg", "jpeg", "png"])
    
    if file:
        img = Image.open(file)
        img_array = np.array(img)
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("<div class='card-box'><b>📌 Input Image</b></div>", unsafe_allow_html=True)
            st.image(img, width=420)
        
        with col2:
            st.markdown("<div class='card-box'><b>📝 Extracted Text</b></div>", unsafe_allow_html=True)
            
            with st.spinner("Extracting text..."):
                results = ocr_reader.extract_text(cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR))
            
            if results:
                extracted_text = " ".join([r['text'] for r in results])
                st.text_area("Extracted Text", extracted_text, height=200)
                
                if st.button("📋 Copy Text"):
                    st.text(extracted_text)
                    st.success("Text displayed above - copy from text area")
                
                # Show detailed results
                with st.expander("Detailed Results"):
                    for i, result in enumerate(results):
                        st.write(f"**Text {i+1}:** {result['text']}")
                        st.write(f"**Confidence:** {result['confidence']:.3f}")
                        st.write("---")
            else:
                st.warning("No text detected in the image.")


# 📷 QR SCANNER PAGE

elif page == "📷 QR Scanner":
    st.markdown("<div class='section-title'>📷 QR & Barcode Scanner</div>", unsafe_allow_html=True)
    st.markdown("<div class='sub-text'>Upload an image to scan for QR codes and barcodes</div>", unsafe_allow_html=True)
    
    qr_scanner = QRBarcodeScanner()
    
    file = st.file_uploader("Upload Image for Scanning", type=["jpg", "jpeg", "png"])
    
    if file:
        img = Image.open(file)
        img_array = np.array(img)
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("<div class='card-box'><b>📌 Input Image</b></div>", unsafe_allow_html=True)
            st.image(img, width=420)
        
        with col2:
            st.markdown("<div class='card-box'><b>🔍 Scan Results</b></div>", unsafe_allow_html=True)
            
            with st.spinner("Scanning..."):
                results = qr_scanner.scan(cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR))
            
            if results:
                for i, result in enumerate(results):
                    st.success(f"**Code {i+1} Detected**")
                    st.write(f"**Type:** {result['type']}")
                    st.write(f"**Data:** {result['data']}")
                    st.write("---")
            else:
                st.warning("No QR codes or barcodes detected in the image.")
