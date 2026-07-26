import streamlit as st
import torch
import torch.nn as nn
from ultralytics import YOLO
from torchvision import models, transforms
from PIL import Image
import numpy as np
import cv2
# Removed insecure SSL certificate workaround as per requirements
# ---------------- CLASS LABELS ----------------
CLASS_NAMES = [
'Chair','bottle','Cat','Cup','Bench','Horse','Person','bed','Truck','Airplane',
'Cycle','Bird','bike','bus','potted plant','Pizza','Stop Signal','Bowl',
'Traffic Signal','couch','elephant','Cake','dog','cow','Car'
]
NUM_CLASSES = len(CLASS_NAMES)

# ---------------- PAGE CONFIG ----------------
st.set_page_config(page_title="Smart Vision AI", page_icon="🤖", layout="wide")

# ---------------- SESSION STATE ----------------
if "page" not in st.session_state:
    st.session_state["page"] = "🏠 Home"

# ---------------- LOAD MODELS ----------------
@st.cache_resource
def load_detection_model():
    return YOLO("SmartVision_v3.pt")

@st.cache_resource
def load_classification_model():
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

det_model = load_detection_model()
cls_model = load_classification_model()
transform = transforms.Compose([transforms.Resize((224, 224)), transforms.ToTensor()])


# ---------------- GLOBAL MODERN CSS ----------------
st.markdown("""
<style>
.section-title {
    font-size: 52px; font-weight: 900; text-align: center;
    color: var(--primary-color);           
    margin-bottom: 5px;
}
.sub-text {
    text-align: center; font-size: 21px; color: var(--text-color); opacity: 0.8; margin-bottom: 30px;
}
.card-box {
    background: var(--secondary-background-color); padding: 22px; border-radius: 12px;
    border: 1px solid rgba(128, 128, 128, 0.2);
    margin-top: 10px; margin-bottom: 18px;
}
.result-label {
    font-size: 32px; font-weight: 900; text-align:center; color: var(--primary-color);
}
.confidence-label {
    font-size: 20px; text-align:center; margin-top: 3px; color: var(--text-color); opacity: 0.8;
}
</style>
""", unsafe_allow_html=True)


# ---------------- SIDEBAR ----------------
page = st.sidebar.radio(
    "Navigation",
    ["🏠 Home", "🧠 Classification", "🎯 Object Detection"],
    index=["🏠 Home", "🧠 Classification", "🎯 Object Detection"].index(st.session_state["page"])
)
st.session_state["page"] = page




# 🏠 HOME PAGE

if page == "🏠 Home":

    st.markdown("<div class='section-title'>Smart Vision AI</div>", unsafe_allow_html=True)
    st.markdown("<div class='sub-text'>Advanced Deep Learning for Object Detection & Image Classification</div>", unsafe_allow_html=True)

    col1, col2, col3 = st.columns(3)
    with col1:
        st.markdown("<div class='card-box'><img src='https://cdn-icons-png.flaticon.com/512/2103/2103658.png' width='80'><h4>YOLO Detection</h4><p>Detect multiple objects instantly</p></div>", unsafe_allow_html=True)
    with col2:
        st.markdown("<div class='card-box'><img src='https://cdn-icons-png.flaticon.com/512/4305/4305434.png' width='80'><h4>MobileNet Classification</h4><p>Predict object class with high accuracy</p></div>", unsafe_allow_html=True)
    with col3:
        st.markdown("<div class='card-box'><img src='https://cdn-icons-png.flaticon.com/512/3602/3602145.png' width='80'><h4>Upload / Webcam</h4><p>Multiple input modes supported</p></div>", unsafe_allow_html=True)

    colA, colB = st.columns(2)
    with colA:
        if st.button("🚀 Start Object Detection"):
            st.session_state["page"] = "🎯 Object Detection"
            st.rerun()
    with colB:
        if st.button("🧠 Start Classification"):
            st.session_state["page"] = "🧠 Classification"
            st.rerun()




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
            st.markdown(f"<div class='result-label'>{CLASS_NAMES[idx]}</div>", unsafe_allow_html=True)
            st.markdown(f"<div class='confidence-label'>Confidence: {probs[idx]:.2f}</div>", unsafe_allow_html=True)


# 🎯 OBJECT DETECTION 

elif page == "🎯 Object Detection":

    st.markdown("<div class='section-title'>🎯 Object Detection</div>", unsafe_allow_html=True)
    st.markdown("<div class='sub-text'>Upload or capture an image for YOLO detection</div>", unsafe_allow_html=True)

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

        results = det_model(img_cv)
        detected_img = results[0].plot()

        with col2:
            st.markdown("<div class='card-box'><b>🎯 Detection Result</b></div>", unsafe_allow_html=True)
            st.image(cv2.cvtColor(detected_img, cv2.COLOR_BGR2RGB), width=420)
