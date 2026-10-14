import base64
import os
import time

import streamlit as st


def _logo_data_url() -> str:
    candidates = [
        os.path.join("assets", "logo.jpeg"),
        os.path.join("assets", "logo.jpg"),
        os.path.join("assets", "logo.png"),
        "logo.jpeg",
        "logo.jpg",
        "logo.png",
    ]
    for candidate in candidates:
        if os.path.exists(candidate):
            with open(candidate, "rb") as f:
                payload = base64.b64encode(f.read()).decode("utf-8")
            ext = os.path.splitext(candidate)[1].lower().replace(".", "") or "png"
            return f"data:image/{ext};base64,{payload}"
    return ""


def show_splash():
    logo_src = _logo_data_url()
    st.markdown(
        """
        <style>
        .splash-shell {
            position: fixed;
            inset: 0;
            z-index: 9999;
            display: flex;
            align-items: center;
            justify-content: center;
            background: radial-gradient(circle at center, rgba(124, 58, 237, 0.16), transparent 24%), #0B1230;
            overflow: hidden;
        }
        .splash-shell::before {
            content: "";
            position: absolute;
            inset: 10% 20% 10% 20%;
            border-radius: 32px;
            background: radial-gradient(circle, rgba(56, 189, 248, 0.12), transparent 60%);
            filter: blur(50px);
        }
        .splash-card {
            position: relative;
            z-index: 1;
            text-align: center;
            padding: 1rem 1.2rem 1.4rem;
        }
        .splash-logo {
            width: 320px;
            max-width: 78vw;
            filter: drop-shadow(0 0 22px rgba(124, 58, 237, 0.36));
            animation: logoFade 1.1s ease, logoPulse 2.3s ease-in-out infinite alternate;
            border-radius: 28px;
        }
        .splash-title {
            margin-top: 1.3rem;
            font-size: clamp(2.1rem, 7vw, 4.5rem);
            line-height: 1.05;
            font-family: 'Orbitron', 'Segoe UI', sans-serif;
            font-weight: 800;
            letter-spacing: 0.05em;
            background: linear-gradient(90deg, #38BDF8 0%, #7C3AED 100%);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
            text-transform: uppercase;
        }
        .splash-subtitle {
            margin-top: 0.4rem;
            font-size: clamp(0.9rem, 2vw, 1.18rem);
            color: rgba(230, 238, 255, 0.8);
            letter-spacing: 0.04em;
        }
        .splash-loader {
            width: min(40vw, 310px);
            height: 4px;
            margin: 1.2rem auto 0;
            border-radius: 999px;
            background: rgba(148,163,200,0.18);
            overflow: hidden;
            position: relative;
        }
        .splash-loader::before {
            content: "";
            position: absolute;
            inset: 0;
            width: 38%;
            background: linear-gradient(90deg, #38BDF8, #7C3AED);
            border-radius: inherit;
            animation: loaderMove 2.4s ease-in-out infinite;
        }
        .splash-skip {
            position: absolute;
            top: 1rem;
            right: 1rem;
            z-index: 2;
        }
        .splash-skip button {
            border-radius: 999px !important;
            padding: 0.5rem 0.9rem !important;
            background: rgba(255,255,255,0.05) !important;
            border: 1px solid rgba(255,255,255,0.12) !important;
            color: var(--text) !important;
        }
        @keyframes logoFade { from { opacity: 0; transform: scale(0.96) translateY(8px); } to { opacity: 1; transform: scale(1) translateY(0); } }
        @keyframes logoPulse { from { filter: drop-shadow(0 0 20px rgba(124, 58, 237, 0.34)); } to { filter: drop-shadow(0 0 35px rgba(56, 189, 248, 0.38)); } }
        @keyframes loaderMove { 0% { transform: translateX(-52%); } 50% { transform: translateX(150%); } 100% { transform: translateX(-52%); } }
        @media (max-width: 576px) {
          .splash-title { letter-spacing: 0.03em; }
        }
        </style>
        """,
        unsafe_allow_html=True,
    )

    st.markdown(
        """
        <style>
        header[data-testid="stHeader"] { visibility: hidden; }
        [data-testid="stToolbar"] { visibility: hidden; }
        [data-testid="stSidebar"] { display: none !important; }
        footer { display: none !important; }
        </style>
        """,
        unsafe_allow_html=True,
    )

    st.markdown('<div class="splash-skip">', unsafe_allow_html=True)
    if st.button("Skip", key="splash_skip_btn"):
        st.session_state["splash_done"] = True
        st.rerun()
    st.markdown('</div>', unsafe_allow_html=True)

    st.markdown(
        f"""
        <div class="splash-shell">
          <div class="splash-card">
            <img class="splash-logo" src="{logo_src}" alt="Smart Vision logo" />
            <div class="splash-title">Smart Vision</div>
            <div class="splash-subtitle">Real Time Object Detection using Mobile Devices</div>
            <div class="splash-loader"></div>
          </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    time.sleep(3.5)
    st.session_state["splash_done"] = True
    st.rerun()
