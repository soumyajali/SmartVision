"""
Smart Vision AI — Premium UI Integration Module
=================================================
Injects a full-screen Three.js animated background and glassmorphism
UI enhancements into the Streamlit app WITHOUT modifying detection logic.

Usage (add once after st.set_page_config in app.py):
    from integration import inject_premium_ui
    inject_premium_ui()

This module is the ONLY touchpoint required — no page logic changes needed.
"""

from __future__ import annotations

import streamlit as st
from pathlib import Path
from functools import lru_cache

# ============================================================
# ASSET PATHS — All UI files live alongside integration.py
# ============================================================
UI_DIR = Path(__file__).parent

THREE_CDN = "https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"
GSAP_CDN = "https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"


# ============================================================
# ASSET LOADER — Cache file reads across Streamlit reruns
# ============================================================
@lru_cache(maxsize=16)
def _load_asset(filename: str) -> str:
    """Read a UI asset file from the project root."""
    path = UI_DIR / filename
    if not path.exists():
        raise FileNotFoundError(f"UI asset not found: {path}")
    return path.read_text(encoding="utf-8")


# ============================================================
# LOADER HTML — Futuristic boot screen markup
# ============================================================
def _build_loader_html() -> str:
    return """
<div id="svai-loader" aria-label="Loading Smart Vision AI">
  <div class="svai-loader-logo">
    <div class="svai-loader-ring"></div>
    <div class="svai-loader-ring"></div>
    <div class="svai-loader-core"></div>
  </div>
  <div class="svai-loader-title">Smart Vision AI</div>
  <div class="svai-loader-sub">Neural Operating System</div>
  <div class="svai-loader-scan"></div>
  <div class="svai-loader-progress">
    <div class="svai-loader-progress-bar" id="svai-progress-bar"></div>
  </div>
  <div class="svai-loader-status" id="svai-loader-status">INITIALIZING...</div>
</div>
"""


# ============================================================
# CANVAS HTML — Fixed-position WebGL container
# ============================================================
def _build_canvas_html() -> str:
    return """
<div id="svai-bg-root">
  <canvas id="svai-bg-canvas" aria-hidden="true"></canvas>
</div>
<div id="svai-mouse-layer" aria-hidden="true"></div>
"""


# ============================================================
# FULL BACKGROUND SCRIPT — Inline JS modules for Streamlit
# ============================================================
def _build_background_script() -> str:
    """Bundle Three.js scene, animations, and bootstrap into one script block."""
    three_scene = _load_asset("three_scene.js")
    animations = _load_asset("animations.js")
    background = _load_asset("background.js")

    return f"""
<script src="{THREE_CDN}"></script>
<script src="{GSAP_CDN}"></script>
<script>
/* ---- three_scene.js (inlined) ---- */
{three_scene}
</script>
<script>
/* ---- animations.js (inlined) ---- */
{animations}
</script>
<script>
/* ---- background.js (inlined) ---- */
{background}
</script>
"""


# ============================================================
# GLASSMORPHISM CSS — Streamlit widget styling overlay
# ============================================================
def _inject_css() -> None:
    """Inject glassmorphism and typography CSS into Streamlit."""
    css = _load_asset("background.css")
    st.markdown(f"<style>{css}</style>", unsafe_allow_html=True)


# ============================================================
# BACKGROUND HTML — Three.js canvas + loader + scripts
# ============================================================
def _inject_background_html(show_loader: bool = True) -> None:
    """
    Inject the 3D background via st.html with JavaScript enabled.
    Uses height=0 because canvas is position:fixed — no layout space needed.
    """
    loader = _build_loader_html() if show_loader else ""
    canvas = _build_canvas_html()
    scripts = _build_background_script()

    html = f"""
<!-- Smart Vision AI Premium Background -->
{loader}
{canvas}
{scripts}
"""

    st.html(html, unsafe_allow_javascript=True, height=0)


# ============================================================
# PUBLIC API — Call from app.py after st.set_page_config()
# ============================================================
def inject_premium_ui(show_loader: bool = True) -> None:
    """
    Inject premium 3D background and glassmorphism UI enhancements.

    Parameters
    ----------
    show_loader : bool
        Whether to show the futuristic loading screen on first load.

    Notes
    -----
    - Background sits at z-index 0; Streamlit widgets remain interactive.
    - Does NOT affect YOLO, webcam, detection, or any AI pipeline code.
    - Called each rerun; JavaScript guards prevent duplicate scene init.
    """
    _inject_css()

    # Show loader only on first browser load; subsequent reruns skip it
    first_load = not st.session_state.get("_svai_first_load_done", False)
    st.session_state["_svai_first_load_done"] = True

    _inject_background_html(show_loader=show_loader and first_load)


def inject_premium_css_only() -> None:
    """
    Inject only the glassmorphism CSS without the 3D background.
    Useful for testing styling without WebGL overhead.
    """
    _inject_css()


def get_standalone_html_path() -> Path:
    """Return path to standalone background.html for browser preview."""
    return UI_DIR / "background.html"
