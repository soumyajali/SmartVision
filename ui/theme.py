import streamlit as st


def apply_theme():
    st.markdown(
        """
        <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Orbitron:wght@500;600;700;800&family=Rajdhani:wght@600;700&family=JetBrains+Mono:wght@400;500;600;700&display=swap');

        :root {
          --bg: #0B1230;
          --bg-2: #101935;
          --panel: #121A3D;
          --panel-strong: rgba(15, 22, 46, 0.98);
          --card: #121A3D;
          --card-soft: rgba(24, 34, 68, 0.88);
          --border: rgba(56, 189, 248, 0.25);
          --primary: #38BDF8;
          --accent: #7C3AED;
          --success: #22C55E;
          --warning: #F59E0B;
          --danger: #EF4444;
          --text: #E6EEFF;
          --muted: #94A3C8;
          --shadow: rgba(56, 189, 248, 0.18);
          --shadow-accent: rgba(124, 58, 237, 0.2);
          --header-font: 'Rajdhani', 'Orbitron', 'Segoe UI', sans-serif;
          --body-font: 'Inter', 'Segoe UI', sans-serif;
          --mono-font: 'JetBrains Mono', 'Consolas', monospace;
          --font-size-base: 15px;
          --font-size-label: 13px;
          --font-size-small: 12px;
          --font-size-page-title: 32px;
          --font-size-metric: 30px;
          --control-radius: 14px;
        }

        html, body, [data-testid="stAppViewContainer"] {
          background: radial-gradient(circle at top, rgba(124,58,237,0.18), transparent 30%),
                      radial-gradient(circle at bottom right, rgba(56,189,248,0.12), transparent 30%),
                      var(--bg);
          color: var(--text);
          font-family: var(--body-font);
          font-size: var(--font-size-base);
          line-height: 1.5;
        }

        .stApp {
          background: transparent !important;
          color: var(--text) !important;
          font-family: var(--body-font) !important;
          font-size: var(--font-size-base) !important;
          line-height: 1.5 !important;
        }

        .stApp p,
        .stApp li,
        .stApp input,
        .stApp textarea,
        .stApp button,
        .stApp label,
        .stApp [data-testid="stCaptionContainer"],
        .stApp [data-testid="stMarkdownContainer"] {
          font-family: var(--body-font) !important;
          line-height: 1.5 !important;
        }

        .stApp [data-testid="stCaptionContainer"],
        .stApp label,
        .stApp [data-testid="stMetricLabel"] {
          font-size: var(--font-size-label) !important;
        }

        .stApp .page-kicker,
        .stApp .status-pill,
        .stApp .live-badge {
          font-size: var(--font-size-small) !important;
        }

        .stApp h1,
        .stApp h2,
        .stApp h3,
        .stApp h4,
        .stApp h5,
        .stApp h6,
        .stApp .stMarkdown p {
          color: var(--text) !important;
        }

        .stApp .page-header-copy p,
        .stApp .sub-text,
        .stApp .assistant-section-label,
        .stApp .assistant-card-label {
          color: var(--muted) !important;
        }

        .stApp [style*="color: #0f172a"],
        .stApp [style*="color:#0f172a"],
        .stApp [style*="color: #172033"],
        .stApp [style*="color:#172033"],
        .stApp [style*="color: #1e293b"],
        .stApp [style*="color:#1e293b"] {
          color: var(--text) !important;
        }

        .stApp [style*="color: rgb(15, 23, 42)"],
        .stApp [style*="color: rgb(23, 32, 51)"],
        .stApp [style*="color: rgb(30, 41, 59)"],
        .stApp [style*="color: rgb(51, 65, 85)"] {
          color: var(--text) !important;
        }

        .stApp [style*="color: rgb(100, 116, 139)"],
        .stApp [style*="color: rgb(148, 163, 184)"] {
          color: var(--muted) !important;
        }

        .stApp .section-title,
        .stApp div[data-testid="stMetricValue"] {
          color: var(--text) !important;
        }

        .stApp .section-title {
          font-family: var(--header-font) !important;
          font-size: var(--font-size-page-title) !important;
          line-height: 1.2 !important;
        }

        .stApp div[data-testid="stMetricLabel"] {
          color: var(--muted) !important;
          font-size: var(--font-size-label) !important;
        }

        .stApp div[data-testid="stMetricValue"],
        .stApp .kpi-value {
          font-family: var(--header-font) !important;
          font-size: var(--font-size-metric) !important;
          color: var(--text) !important;
        }

        .stApp [style*="font-size:11px"],
        .stApp [style*="font-size: 11px"] {
          font-size: var(--font-size-small) !important;
        }

        .stApp [data-testid="stAlert"] {
          color: var(--text) !important;
          background: var(--panel) !important;
          border-color: var(--border) !important;
          border-radius: var(--control-radius) !important;
        }

        .stApp [data-testid="stAlert"] p,
        .stApp [data-testid="stAlert"] span {
          color: var(--text) !important;
        }

        [data-testid="stMain"] .block-container {
          box-sizing: border-box;
          width: 100% !important;
          max-width: none !important;
          padding: 1.25rem 1.5rem 3rem !important;
          animation: fadeIn 0.5s ease;
        }

        [data-testid="stHeader"] {
          background: rgba(11, 18, 48, 0.6);
          backdrop-filter: blur(12px);
          border-bottom: 1px solid rgba(255,255,255,0.04);
        }

        [data-testid="stSidebar"] {
          background: linear-gradient(180deg, rgba(11, 18, 48, 0.96), rgba(13, 20, 42, 0.96));
          border-right: 1px solid rgba(56, 189, 248, 0.18);
          box-shadow: 16px 0 36px rgba(0,0,0,0.14);
        }

        [class*="st-key-feature-navigation"] {
          margin-bottom: 1rem;
          padding: 0.4rem 0.6rem;
          border: 1px solid var(--border);
          border-radius: 14px;
          background: rgba(18, 26, 61, 0.82);
        }

        [class*="st-key-feature-navigation"] [data-testid="stRadioGroup"] {
          display: flex;
          flex-flow: row wrap !important;
          align-items: center;
          justify-content: flex-start;
          gap: 0.5rem;
          overflow: visible;
          width: 100%;
          padding: 0.15rem 0.1rem 0.35rem;
        }

        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"] {
          flex: 0 0 auto;
          display: flex;
          align-items: center;
          white-space: nowrap;
          border: 1px solid transparent;
          border-radius: 10px;
          background: rgba(11, 18, 48, 0.62);
          padding: 0.55rem 0.9rem;
          color: #E6EEFF !important;
          font-size: 14px !important;
          font-weight: 600;
          line-height: 1.35 !important;
        }

        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"] p {
          color: #E6EEFF !important;
          white-space: nowrap;
          margin: 0 !important;
          line-height: 1.35 !important;
          font-size: 14px !important;
          font-weight: 600 !important;
        }

        /* Hide every possible radio-circle element in the horizontal nav */
        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"] > div > div:first-child,
        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"] > label > div:first-child,
        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"] > div:first-child > div:first-child {
          display: none !important;
        }

        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"] input,
        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"] svg,
        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"] [data-testid="stMarkdownContainer"] + div,
        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"] span[aria-hidden],
        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"] [class*="radio"] {
          display: none !important;
        }

        /* Force label to be the full clickable pill, no gap before text */
        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"] label {
          display: flex !important;
          align-items: center !important;
          padding: 0 !important;
          margin: 0 !important;
          width: 100% !important;
          cursor: pointer !important;
        }

        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"] label > div {
          display: flex !important;
          align-items: center !important;
          gap: 0 !important;
        }

        /* Hide radio circle in secondary (vertical) sidebar nav too */
        [class*="st-key-secondary-feature-navigation"] [data-testid="stRadioOption"] input,
        [class*="st-key-secondary-feature-navigation"] [data-testid="stRadioOption"] svg,
        [class*="st-key-secondary-feature-navigation"] [data-testid="stRadioOption"] span[aria-hidden],
        [class*="st-key-secondary-feature-navigation"] [data-testid="stRadioOption"] [class*="radio"],
        [class*="st-key-secondary-feature-navigation"] [data-testid="stRadioOption"] > div > div:first-child,
        [class*="st-key-secondary-feature-navigation"] [data-testid="stRadioOption"] > label > div:first-child {
          display: none !important;
        }

        /* Also hide circles on the ai-tools sidebar nav */
        [class*="st-key-ai-tools-feature-navigation"] [data-testid="stRadioOption"] input,
        [class*="st-key-ai-tools-feature-navigation"] [data-testid="stRadioOption"] svg,
        [class*="st-key-ai-tools-feature-navigation"] [data-testid="stRadioOption"] span[aria-hidden],
        [class*="st-key-ai-tools-feature-navigation"] [data-testid="stRadioOption"] [class*="radio"],
        [class*="st-key-ai-tools-feature-navigation"] [data-testid="stRadioOption"] > div > div:first-child,
        [class*="st-key-ai-tools-feature-navigation"] [data-testid="stRadioOption"] > label > div:first-child {
          display: none !important;
        }

        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"]:hover {
          border-color: var(--border);
          background: rgba(56, 189, 248, 0.1);
        }

        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"][data-selected="true"] {
          border-color: rgba(56, 189, 248, 0.55);
          background: linear-gradient(100deg, rgba(56, 189, 248, 0.2), rgba(124, 58, 237, 0.22));
          box-shadow: inset 0 -2px 0 var(--primary), 0 0 14px rgba(56, 189, 248, 0.12);
        }

        [class*="st-key-secondary-feature-navigation"] [data-testid="stRadioGroup"] {
          display: flex;
          flex-direction: column;
          gap: 0.35rem;
        }

        [class*="st-key-secondary-feature-navigation"] [data-testid="stRadioOption"] {
          width: 100%;
          border: 1px solid transparent;
          border-radius: 10px;
          background: rgba(15, 22, 46, 0.4);
          padding: 0.6rem 0.75rem;
          color: #E6EEFF !important;
          font-size: 14px !important;
          font-weight: 600 !important;
        }

        [class*="st-key-secondary-feature-navigation"] [data-testid="stRadioOption"] p {
          color: #E6EEFF !important;
          white-space: normal;
          font-size: 14px !important;
          font-weight: 600 !important;
        }

        [class*="st-key-secondary-feature-navigation"] [data-testid="stRadioOption"]:hover {
          border-color: var(--border);
          background: rgba(56, 189, 248, 0.1);
        }

        [class*="st-key-secondary-feature-navigation"] [data-testid="stRadioOption"][data-selected="true"] {
          border-color: rgba(56, 189, 248, 0.45);
          background: linear-gradient(90deg, rgba(56, 189, 248, 0.16), rgba(124, 58, 237, 0.16));
          box-shadow: inset 3px 0 0 var(--primary), 0 0 14px rgba(56, 189, 248, 0.1);
        }

        [data-testid="stSidebar"] .model-info-card {
          display: block;
          margin-top: 0.6rem;
          padding: 0.65rem 0.7rem;
          border: 1px solid var(--border);
          border-radius: 12px;
          background: rgba(18, 26, 61, 0.72);
        }

        [data-testid="stSidebar"] .model-info-row {
          display: flex;
          justify-content: space-between;
          gap: 0.5rem;
          margin: 0.2rem 0;
          font-size: var(--font-size-small);
        }

        [data-testid="stSidebar"] .model-info-label {
          color: var(--muted);
        }

        [data-testid="stSidebar"] .model-info-val {
          color: var(--text);
          font-weight: 600;
        }

        [data-testid="stSidebarContent"] {
          padding: 1rem 0.65rem 1rem 0.85rem;
          height: 100vh;
          overflow-y: auto;
        }

        .stSidebar .block-container {
          padding-top: 0.5rem;
        }

        .sidebar-logo {
          display: block;
          margin: 0.25rem 0 0.5rem;
          text-align: left;
        }

        .sidebar-logo img {
          display: block;
          width: 100% !important;
          max-width: 100% !important;
          height: auto;
          border-radius: 14px;
          box-shadow: 0 0 18px rgba(124,58,237,0.35);
          margin-bottom: 0.6rem;
        }

        .sidebar-brand {
          display: block;
          font-family: var(--header-font);
          font-size: 1rem;
          letter-spacing: 0.22rem;
          font-weight: 800;
          color: var(--text) !important;
          margin: 0 0 0.15rem 0;
          padding-left: 0.1rem;
        }

        .sidebar-tagline {
          display: block;
          margin: 0 0 1rem;
          font-size: var(--font-size-small);
          color: var(--muted) !important;
          letter-spacing: 0.08rem;
          text-transform: uppercase;
          padding-left: 0.1rem;
        }

        .nav-section {
          margin-top: 0.7rem;
          margin-bottom: 0.35rem;
          padding-left: 0.35rem;
          color: #94A3C8 !important;
          font-size: var(--font-size-small);
          letter-spacing: 0.12rem;
          text-transform: uppercase;
          font-weight: 700;
        }

        [data-testid="stSidebar"] .stRadio > div {
          display: flex;
          flex-direction: column;
          gap: 0.35rem;
        }

        [data-testid="stSidebar"] .stRadio [role="radiogroup"] {
          display: flex;
          flex-direction: column;
          gap: 0.35rem;
        }

        [data-testid="stSidebar"] .stRadio label {
          border: 1px solid transparent;
          border-radius: 12px;
          background: rgba(15, 22, 46, 0.4);
          padding: 0.7rem 0.8rem 0.7rem 0.9rem;
          color: var(--text);
          transition: all 0.2s ease;
          margin: 0;
          font-size: 14px !important;
          line-height: 1.5 !important;
        }

        [data-testid="stSidebar"] .stRadio label:hover {
          border-color: rgba(56, 189, 248, 0.2);
          background: rgba(18,26,61,0.78);
          transform: translateX(2px);
        }

        [data-testid="stSidebar"] .stRadio label > div {
          display: flex;
          align-items: center;
          gap: 0.55rem;
        }

        [data-testid="stSidebar"] .stRadio input[type="radio"] {
          display: none !important;
          opacity: 0 !important;
          width: 0 !important;
          height: 0 !important;
          pointer-events: none !important;
        }

        [data-testid="stSidebar"] .stRadio label[data-checked="true"] {
          background: linear-gradient(90deg, rgba(56, 189, 248, 0.16), rgba(124, 58, 237, 0.16));
          border: 1px solid rgba(56, 189, 248, 0.45);
          box-shadow: inset 3px 0 0 var(--primary), 0 0 18px rgba(56, 189, 248, 0.12);
        }

        h1, h2, h3, h4, h5, h6 {
          color: var(--text);
          font-family: var(--header-font);
          letter-spacing: -0.02em;
          line-height: 1.2;
        }

        h1 {
          font-size: var(--font-size-page-title);
        }

        p, li, div, button, input, textarea, select, label {
          font-family: var(--body-font);
        }

        .stMarkdown, .stTextInput, .stNumberInput, .stSelectbox, .stSlider, .stCheckbox, .stRadio, .stDataFrame, .stFileUploader {
          color: var(--text);
        }

        .stButton > button {
          min-height: 44px !important;
          border: 1px solid var(--border) !important;
          border-radius: var(--control-radius) !important;
          background: transparent !important;
          color: var(--text) !important;
          font-weight: 700 !important;
          letter-spacing: 0.02em !important;
          font-size: var(--font-size-label) !important;
          line-height: 1.2 !important;
          padding: 0.45rem 0.65rem !important;
          box-shadow: none !important;
          transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .stButton > button:hover {
          border-color: var(--primary) !important;
          background: rgba(56, 189, 248, 0.1) !important;
          color: var(--text) !important;
          box-shadow: 0 0 16px var(--shadow) !important;
        }

        .stButton > button[kind="primary"] {
          border: 1px solid transparent !important;
          background: linear-gradient(135deg, var(--primary), var(--accent)) !important;
          color: var(--bg) !important;
          box-shadow: 0 8px 20px var(--shadow-accent) !important;
        }

        .stButton > button[kind="primary"]:hover {
          background: linear-gradient(135deg, var(--accent), var(--primary)) !important;
          color: var(--text) !important;
        }

        .stButton > button:disabled,
        .stButton > button[disabled] {
          opacity: 0.45 !important;
          cursor: not-allowed !important;
          box-shadow: none !important;
          transform: none !important;
        }

        [data-testid="stSidebar"] .stButton > button {
          min-width: 0 !important;
          width: 100% !important;
          padding: 0.4rem 0.3rem !important;
          white-space: normal !important;
          overflow-wrap: anywhere;
          font-size: var(--font-size-small) !important;
        }

        .stTextInput > div > div > input,
        .stNumberInput > div > div > input,
        .stTextArea > div > div > textarea,
        .stSelectbox [data-baseweb="select"] > div,
        .stDateInput [data-baseweb="input"] > div,
        .stTextInput [data-baseweb="input"] > div,
        .stNumberInput [data-baseweb="input"] > div,
        .stTextArea [data-baseweb="textarea"] > div,
        .stFileUploader [data-testid="stFileUploaderDropzone"] {
          color: var(--text) !important;
          background: var(--card) !important;
          border: 1px solid var(--border) !important;
          border-radius: var(--control-radius) !important;
          box-shadow: none;
        }

        .stSelectbox .react-aria-ComboBox > div,
        .stDateInput .react-aria-Group,
        .stTextInput .react-aria-TextField,
        .stNumberInput .react-aria-Group,
        .stTextArea .react-aria-TextField {
          color: var(--text) !important;
          background: var(--card) !important;
          border: 1px solid var(--border) !important;
          border-radius: var(--control-radius) !important;
        }

        .stSelectbox .react-aria-ComboBox input,
        .stDateInput input,
        .stTextInput input,
        .stNumberInput input,
        .stTextArea textarea {
          color: var(--text) !important;
          background: transparent !important;
          font-family: var(--body-font) !important;
          font-size: var(--font-size-label) !important;
        }

        .stSelectbox [data-baseweb="select"] *,
        .stDateInput [data-baseweb="input"] *,
        .stTextInput [data-baseweb="input"] *,
        .stNumberInput [data-baseweb="input"] *,
        .stTextArea [data-baseweb="textarea"] *,
        .stFileUploader,
        .stFileUploader * {
          color: var(--text) !important;
          font-size: var(--font-size-label) !important;
        }

        .stApp input::placeholder,
        .stApp textarea::placeholder,
        .stApp [data-testid="stSelectbox"] [data-testid="stMarkdownContainer"] {
          color: var(--muted) !important;
          opacity: 1;
          font-size: var(--font-size-label) !important;
        }

        .stFileUploader [data-testid="stFileUploadDropzone"] {
          border-style: dashed !important;
        }

        .stSlider [data-testid="stSliderThumbValue"],
        .stSlider [data-testid="stTickBarMin"],
        .stSlider [data-testid="stTickBarMax"],
        .stSlider p {
          color: var(--text) !important;
          font-size: var(--font-size-label) !important;
        }

        .stSlider [data-testid="stSliderThumbValue"] {
          font-family: var(--mono-font) !important;
        }

        .stSlider .css-1v0mbdj {
          background: linear-gradient(90deg, var(--primary), var(--accent));
        }

        .stTabs [role="tablist"] {
          border-bottom: 1px solid rgba(148, 163, 200, 0.15);
        }

        .stTabs [role="tab"] {
          color: var(--muted);
          border: 1px solid transparent;
        }

        .stTabs [role="tab"][aria-selected="true"] {
          background: rgba(56, 189, 248, 0.12);
          border-color: rgba(56, 189, 248, 0.2);
          color: var(--text);
        }

        .stExpander {
          border: 1px solid rgba(56, 189, 248, 0.16);
          border-radius: 14px;
          background: rgba(15,22,46,0.4);
        }

        .stExpander summary {
          color: var(--text);
          font-weight: 600;
        }

        [data-testid="stMain"] .card-box,
        [data-testid="stMain"] .kpi-card,
        [data-testid="stMain"] [data-testid="stVerticalBlockBorderWrapper"] {
          color: var(--text) !important;
          background: var(--card) !important;
          border: 1px solid var(--border) !important;
          border-radius: var(--control-radius) !important;
          box-shadow: 0 10px 26px rgba(0, 0, 0, 0.18);
        }

        [data-testid="stMain"] .card-box {
          padding: 1rem !important;
        }

        [data-testid="stMain"] .kpi-card {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 1rem;
          padding: 1rem !important;
        }

        [data-testid="stMain"] .dashboard-recent-heading {
          display: flex;
          align-items: baseline;
          justify-content: space-between;
          gap: 1rem;
          margin: 1rem 0 0.55rem;
          color: var(--text);
        }

        [data-testid="stMain"] .dashboard-recent-heading span {
          color: var(--muted);
          font-size: 12px;
        }

        [data-testid="stMain"] .dashboard-recent-card {
          min-height: 88px;
          padding: 0.7rem 0.8rem;
          border: 1px solid var(--border);
          border-radius: 12px;
          background: linear-gradient(145deg, rgba(18, 26, 61, 0.96), rgba(15, 22, 46, 0.9));
        }

        [data-testid="stMain"] .dashboard-recent-object {
          overflow: hidden;
          color: var(--text);
          font-size: 14px;
          font-weight: 700;
          text-overflow: ellipsis;
          white-space: nowrap;
        }

        [data-testid="stMain"] .dashboard-recent-meta {
          display: flex;
          justify-content: space-between;
          gap: 0.45rem;
          margin: 0.2rem 0 0.4rem;
          color: var(--muted);
          font-size: 11px;
        }

        [data-testid="stMain"] .dashboard-confidence-track {
          height: 5px;
          overflow: hidden;
          border-radius: 999px;
          background: rgba(148, 163, 200, 0.2);
        }

        [data-testid="stMain"] .dashboard-confidence-track span {
          height: 100%;
          display: block;
          border-radius: inherit;
          background: linear-gradient(90deg, var(--primary), var(--accent));
        }

        [data-testid="stMain"] .dashboard-empty-state {
          display: flex;
          align-items: center;
          gap: 0.6rem;
          min-height: 56px;
          padding: 0.8rem;
          border: 1px dashed var(--border);
          border-radius: var(--control-radius);
          background: rgba(11, 18, 48, 0.5);
          color: var(--muted) !important;
          font-size: var(--font-size-label) !important;
        }

        [data-testid="stMain"] .dashboard-empty-state span:first-child {
          color: var(--primary) !important;
          font-size: 20px !important;
        }

        [data-testid="stCameraInput"],
        [data-testid="stCameraInputWebcamComponent"],
        [data-testid="stCameraInputWebcamStyledBox"] {
          color: var(--text) !important;
          background-color: var(--card) !important;
          border: 1px solid var(--border) !important;
          border-radius: var(--control-radius) !important;
          overflow: hidden;
        }

        [data-testid="stCameraInput"] {
          position: relative;
          padding: 0.75rem !important;
        }

        [data-testid="stCameraInputWebcamStyledBox"] {
          outline: 1px solid rgba(56, 189, 248, 0.12);
          outline-offset: -10px;
          background-image:
            linear-gradient(rgba(56, 189, 248, 0.04) 1px, transparent 1px),
            linear-gradient(90deg, rgba(56, 189, 248, 0.04) 1px, transparent 1px) !important;
          background-size: 24px 24px;
        }

        [data-testid="stCameraInputWebcamComponent"] > div {
          color: var(--muted) !important;
          background:
            linear-gradient(rgba(56, 189, 248, 0.035) 1px, transparent 1px),
            linear-gradient(90deg, rgba(56, 189, 248, 0.035) 1px, transparent 1px),
            var(--bg) !important;
          background-size: 24px 24px;
        }

        [data-testid="stCameraInputWebcamComponent"] > div p,
        [data-testid="stCameraInputWebcamComponent"] > div a {
          color: var(--muted) !important;
        }

        [data-testid="stCameraInputWebcamComponent"] video {
          background: var(--bg) !important;
        }

        [data-testid="stCameraInputButton"] {
          min-height: 44px !important;
          width: 100% !important;
          border: 1px solid var(--border) !important;
          border-radius: var(--control-radius) !important;
          background: var(--card) !important;
          color: var(--text) !important;
          font-size: var(--font-size-label) !important;
          padding: 0.4rem 0.65rem !important;
        }

        [data-testid="stMain"] [data-testid="stHorizontalBlock"] > [data-testid="column"] {
          min-width: 0;
        }

        [data-testid="stMain"] [data-testid="stHorizontalBlock"] {
          gap: 1rem;
        }

        [data-testid="stMain"] [data-testid="stHorizontalBlock"] .stButton > button {
          min-height: 44px !important;
          width: 100% !important;
          padding: 0.35rem 0.4rem !important;
          white-space: normal !important;
          overflow-wrap: anywhere;
          font-size: var(--font-size-small) !important;
        }

        .page-header {
          display: flex;
          align-items: center;
          gap: 1rem;
          padding: 1rem 1.2rem;
          border: 1px solid rgba(56,189,248,0.18);
          background: linear-gradient(135deg, rgba(17, 24, 39, 0.84), rgba(17, 24, 39, 0.65));
          border-radius: 18px;
          margin-bottom: 1.15rem;
          box-shadow: 0 14px 30px rgba(11, 18, 48, 0.22);
        }

        .page-header-icon {
          width: 48px;
          height: 48px;
          display: grid;
          place-items: center;
          border-radius: 14px;
          background: linear-gradient(135deg, rgba(56,189,248,0.2), rgba(124,58,237,0.22));
          border: 1px solid rgba(56,189,248,0.24);
          font-size: 1.4rem;
          color: var(--primary);
        }

        .page-header-copy {
          flex: 1;
        }

        .page-kicker {
          color: var(--primary);
          text-transform: uppercase;
          font-size: 0.7rem;
          letter-spacing: 0.15rem;
          margin-bottom: 0.2rem;
        }

        .page-header-copy h2 {
          margin: 0;
          font-size: clamp(1.5rem, 2vw, 2.2rem);
          line-height: 1.2;
        }

        .page-header-copy p {
          margin: 0.18rem 0 0;
          color: var(--muted);
          font-size: 0.9rem;
        }

        .status-pill {
          display: inline-flex;
          align-items: center;
          gap: 0.5rem;
          border-radius: 999px;
          padding: 0.42rem 0.75rem;
          font-size: 0.72rem;
          letter-spacing: 0.06rem;
          text-transform: uppercase;
          font-weight: 700;
          border: 1px solid rgba(34,197,94,0.35);
          background: rgba(34,197,94,0.12);
          color: #d5ffe7;
        }

        .status-success { border-color: rgba(34,197,94,0.35); background: rgba(34,197,94,0.12); color: #d5ffe7; }
        .status-warning { border-color: rgba(245,158,11,0.35); background: rgba(245,158,11,0.12); color: #ffe9bf; }
        .status-danger { border-color: rgba(239,68,68,0.35); background: rgba(239,68,68,0.12); color: #ffd5d5; }

        .metric-card {
          background: linear-gradient(180deg, rgba(18,26,61,0.9), rgba(15,22,46,0.8));
          border: 1px solid rgba(56, 189, 248, 0.18);
          border-radius: 16px;
          padding: 1rem 1rem 0.9rem;
          box-shadow: 0 12px 24px rgba(11, 18, 48, 0.18);
          transition: transform 0.2s ease, border-color 0.2s ease;
        }

        .metric-card:hover {
          transform: translateY(-2px);
          border-color: rgba(56, 189, 248, 0.35);
        }

        .metric-icon {
          font-size: 1.2rem;
          margin-bottom: 0.5rem;
          color: var(--primary);
        }

        .metric-label {
          font-size: var(--font-size-label);
          color: var(--muted);
          text-transform: uppercase;
          letter-spacing: 0.08rem;
        }

        .metric-value {
          margin-top: 0.3rem;
          font-family: var(--mono-font);
          font-size: var(--font-size-metric);
          font-weight: 700;
          color: var(--text);
        }

        .empty-state {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          text-align: center;
          min-height: 180px;
          border: 1px dashed rgba(56,189,248,0.26);
          border-radius: 18px;
          background: var(--card);
          color: var(--muted);
          padding: 1rem;
        }

        .empty-icon {
          font-size: 2.1rem;
          margin-bottom: 0.5rem;
          color: var(--primary);
        }

        .empty-message {
          font-size: var(--font-size-label);
          max-width: 360px;
          line-height: 1.6;
          color: var(--muted);
        }

        .object-chip {
          display: flex;
          align-items: center;
          gap: 0.7rem;
          background: rgba(15, 22, 46, 0.8);
          border: 1px solid rgba(56,189,248,0.15);
          border-radius: 12px;
          padding: 0.55rem 0.7rem;
          color: var(--text);
        }

        .object-chip strong {
          font-family: var(--mono-font);
          font-size: var(--font-size-small);
          color: var(--text);
        }

        .chip-progress {
          flex: 1;
          height: 8px;
          background: rgba(148,163,200,0.12);
          border-radius: 999px;
          overflow: hidden;
        }

        .chip-progress span {
          display: block;
          height: 100%;
          border-radius: 999px;
          background: linear-gradient(90deg, var(--primary), var(--accent));
        }

        .card-surface {
          background: linear-gradient(180deg, rgba(18,26,61,0.82), rgba(15,22,46,0.8));
          border: 1px solid rgba(56,189,248,0.14);
          border-radius: 16px;
          padding: 1rem;
          box-shadow: 0 18px 40px rgba(11,18,48,0.16);
        }

        .alert-banner {
          border-radius: 14px;
          padding: 0.8rem 1rem;
          font-weight: 600;
          border: 1px solid rgba(239,68,68,0.3);
          background: rgba(239,68,68,0.10);
          color: #ffd7d7;
        }

        .safe-banner {
          border-radius: 14px;
          padding: 0.8rem 1rem;
          font-weight: 600;
          border: 1px solid rgba(34,197,94,0.3);
          background: rgba(34,197,94,0.10);
          color: #d7ffe7;
        }

        .live-badge {
          display: inline-flex;
          align-items: center;
          gap: 0.45rem;
          padding: 0.35rem 0.65rem;
          border-radius: 999px;
          background: rgba(239,68,68,0.14);
          border: 1px solid rgba(239,68,68,0.28);
          color: #ffd5d5;
          font-weight: 700;
          font-size: 0.7rem;
          letter-spacing: 0.08rem;
          text-transform: uppercase;
        }

        .live-dot {
          width: 0.5rem;
          height: 0.5rem;
          border-radius: 999px;
          background: var(--danger);
          box-shadow: 0 0 12px rgba(239,68,68,0.9);
          animation: pulse 1.2s infinite;
        }

        .content-shell {
          animation: fadeIn 0.45s ease;
        }

        .stDataFrame {
          border-radius: 14px;
          overflow: hidden;
          border: 1px solid rgba(56,189,248,0.14);
        }

        ::-webkit-scrollbar {
          width: 9px;
          height: 9px;
        }
        ::-webkit-scrollbar-track {
          background: rgba(15,22,46,0.7);
        }
        ::-webkit-scrollbar-thumb {
          background: linear-gradient(180deg, var(--primary), var(--accent));
          border-radius: 999px;
        }

        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(8px); }
          to { opacity: 1; transform: translateY(0); }
        }

        @keyframes pulse {
          0% { transform: scale(1); opacity: 1; }
          50% { transform: scale(1.5); opacity: 0.7; }
          100% { transform: scale(1); opacity: 1; }
        }

        @media (max-width: 768px) {
          .page-header { flex-wrap: wrap; }
          .status-pill { margin-left: auto; }
          [data-testid="stMain"] .section-title { font-size: 28px !important; }
          [data-testid="stMain"] [data-testid="stHorizontalBlock"] .stButton > button {
            padding: 0.3rem 0.2rem !important;
          }
          [class*="st-key-feature-navigation"] {
            padding: 0.3rem;
          }
          [class*="st-key-feature-navigation"] [data-testid="stRadioOption"] {
            padding: 0.4rem 0.6rem;
            font-size: 12px !important;
          }
        }

        /* ---- AI Tools sidebar nav ---- */
        [class*="st-key-ai-tools-feature-navigation"] [data-testid="stRadioGroup"] {
          display: flex;
          flex-direction: column;
          gap: 0.35rem;
        }

        [class*="st-key-ai-tools-feature-navigation"] [data-testid="stRadioOption"] {
          width: 100%;
          border: 1px solid transparent;
          border-radius: 10px;
          background: rgba(15, 22, 46, 0.4);
          padding: 0.6rem 0.75rem;
          color: #E6EEFF !important;
          font-size: 14px !important;
          font-weight: 600 !important;
        }

        [class*="st-key-ai-tools-feature-navigation"] [data-testid="stRadioOption"] p {
          color: #E6EEFF !important;
          white-space: normal;
          font-size: 14px !important;
          font-weight: 600 !important;
        }

        [class*="st-key-ai-tools-feature-navigation"] [data-testid="stRadioOption"]:hover {
          border-color: var(--border);
          background: rgba(56, 189, 248, 0.1);
        }

        [class*="st-key-ai-tools-feature-navigation"] [data-testid="stRadioOption"][data-selected="true"] {
          border-color: rgba(56, 189, 248, 0.45);
          background: linear-gradient(90deg, rgba(56, 189, 248, 0.16), rgba(124, 58, 237, 0.16));
          box-shadow: inset 3px 0 0 var(--primary), 0 0 14px rgba(56, 189, 248, 0.1);
        }

        /* ---- Global sidebar text visibility ---- */
        [data-testid="stSidebar"] p,
        [data-testid="stSidebar"] span,
        [data-testid="stSidebar"] label,
        [data-testid="stSidebar"] b,
        [data-testid="stSidebar"] strong {
          color: #E6EEFF !important;
        }

        [data-testid="stSidebar"] .stRadio label {
          color: #E6EEFF !important;
          font-size: 14px !important;
          font-weight: 600 !important;
        }

        /* ---- Sidebar image uses full width ---- */
        [data-testid="stSidebar"] [data-testid="stImage"] img {
          width: 100% !important;
          border-radius: 14px;
          box-shadow: 0 0 18px rgba(124,58,237,0.35);
          margin-bottom: 0.6rem;
        }

        /* ---- Selected horizontal nav item text always white ---- */
        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"][data-selected="true"] p,
        [class*="st-key-feature-navigation"] [data-testid="stRadioOption"][data-selected="true"] {
          color: #FFFFFF !important;
        }

        /* ---- Model info card text ---- */
        .model-info-label { color: #94A3C8 !important; }
        .model-info-val   { color: #E6EEFF !important; font-weight: 700 !important; }
        </style>
        """,
        unsafe_allow_html=True,
    )
