import streamlit as st


def status_pill(label: str, tone: str = "success"):
    label = (label or "Ready").strip()
    st.markdown(
        f"""
        <div class="status-pill status-{tone}">{label}</div>
        """,
        unsafe_allow_html=True,
    )


def page_header(title: str, subtitle: str = "", status: str = "Ready", icon: str = "✦"):
    st.markdown(
        f"""
        <div class="page-header">
          <div class="page-header-icon">{icon}</div>
          <div class="page-header-copy">
            <div class="page-kicker">SmartVision</div>
            <h2>{title}</h2>
            <p>{subtitle}</p>
          </div>
          <div class="status-pill status-success">{status}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def metric_card(title: str, value: str, icon: str = "◉", accent: str = "cyan"):
    st.markdown(
        f"""
        <div class="metric-card metric-{accent}">
          <div class="metric-icon">{icon}</div>
          <div class="metric-copy">
            <div class="metric-label">{title}</div>
            <div class="metric-value">{value}</div>
          </div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def empty_state(message: str, icon: str = "◌"):
    st.markdown(
        f"""
        <div class="empty-state">
          <div class="empty-icon">{icon}</div>
          <div class="empty-message">{message}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def object_chip(label: str, confidence: float = 0.0, variant: str = "primary"):
    percentage = int(max(0, min(100, confidence * 100))) if confidence else 0
    st.markdown(
        f"""
        <div class="object-chip object-{variant}">
          <span>{label}</span>
          <div class="chip-progress"><span style="width:{percentage}%"></span></div>
          <strong>{percentage}%</strong>
        </div>
        """,
        unsafe_allow_html=True,
    )
