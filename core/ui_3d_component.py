import streamlit as st

HTML = """
<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');

#svai-3d-root {
    font-family: 'Inter', system-ui, sans-serif;
    color: #e2e8f0;
    padding: 20px;
}

.glass-panel {
    background: rgba(15, 23, 42, 0.4);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 16px;
    padding: 15px 20px;
    box-shadow: 0 4px 30px rgba(0, 0, 0, 0.1);
}

.core-hologram {
    background: rgba(56, 189, 248, 0.05);
    backdrop-filter: blur(16px);
    -webkit-backdrop-filter: blur(16px);
    border: 1px solid rgba(56, 189, 248, 0.2);
    border-radius: 20px;
    padding: 25px 40px;
    display: inline-block;
    transform: rotateX(15deg);
    box-shadow: 0 10px 40px rgba(56, 189, 248, 0.1);
    transition: all 0.3s ease;
}

h2 { margin: 0; font-size: 18px; font-weight: 700; letter-spacing: 2px; color: #f8fafc; }
h3 { margin: 0 0 10px 0; font-size: 14px; font-weight: 600; letter-spacing: 1px; color: #94a3b8; text-transform: uppercase; }

.stat-row {
    display: flex;
    justify-content: space-between;
    margin-bottom: 6px;
    font-size: 14px;
}
.stat-label { color: #94a3b8; }
.stat-val { font-weight: 600; color: #f1f5f9; }

#ai-status {
    margin-top: 12px;
    font-weight: 600;
    font-size: 15px;
    letter-spacing: 1px;
    color: #38bdf8;
    text-transform: uppercase;
}
</style>

<div id="svai-3d-root">
    <div id="ai-core" style="perspective: 1200px; text-align: center; margin-bottom: 30px;">
        <div class="core-hologram" id="core-card">
            <h2>SMARTVISION AI CORE</h2>
            <div id="ai-status">Initializing Systems...</div>
        </div>
    </div>
    
    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
        <div class="glass-panel" id="panel-performance">
            <h3>System Performance</h3>
            <div class="stat-row"><span class="stat-label">FPS</span><span class="stat-val" id="val-fps">0.0</span></div>
            <div class="stat-row"><span class="stat-label">Latency</span><span class="stat-val"><span id="val-lat">0</span> ms</span></div>
            <div class="stat-row"><span class="stat-label">CPU</span><span class="stat-val"><span id="val-cpu">0.0</span>%</span></div>
            <div class="stat-row"><span class="stat-label">Memory</span><span class="stat-val"><span id="val-ram">0.0</span>%</span></div>
        </div>
        
        <div class="glass-panel" id="panel-detection">
            <h3>Detection Matrix</h3>
            <div class="stat-row"><span class="stat-label">Active Objects</span><span class="stat-val" id="val-obj">0</span></div>
            <div class="stat-row"><span class="stat-label">Tracked Entities</span><span class="stat-val" id="val-trk">0</span></div>
            <div class="stat-row"><span class="stat-label">Security Alerts</span><span class="stat-val" id="val-alt">0</span></div>
        </div>
    </div>
</div>
"""

JS = """
export default function (component) {
  const { data, parentElement } = component;
  if (!data) return;
  
  // Performance Updates
  const updateTxt = (id, val, fixed=0) => {
      const el = parentElement.querySelector(id);
      if(el && val !== undefined) el.textContent = val.toFixed(fixed);
  };
  updateTxt("#val-fps", data.fps, 1);
  updateTxt("#val-lat", data.latency, 0);
  updateTxt("#val-cpu", data.cpu, 1);
  updateTxt("#val-ram", data.ram, 1);
  
  // Detection Updates
  const updateInt = (id, val) => {
      const el = parentElement.querySelector(id);
      if(el && val !== undefined) el.textContent = val;
  };
  updateInt("#val-obj", data.objects);
  updateInt("#val-trk", data.tracks);
  updateInt("#val-alt", data.alerts);
  
  // Dynamic Core State
  const elStatus = parentElement.querySelector("#ai-status");
  const elCard = parentElement.querySelector("#core-card");
  
  if (elStatus && elCard) {
      if (data.alerts > 0) {
          elStatus.textContent = "⚠ Security Alert Active";
          elStatus.style.color = "#f87171"; // Red
          elCard.style.borderColor = "rgba(248, 113, 113, 0.4)";
          elCard.style.boxShadow = "0 10px 40px rgba(248, 113, 113, 0.15)";
      } else if (data.objects > 0) {
          elStatus.textContent = "Tracking Entities";
          elStatus.style.color = "#4ade80"; // Green
          elCard.style.borderColor = "rgba(74, 222, 128, 0.3)";
          elCard.style.boxShadow = "0 10px 40px rgba(74, 222, 128, 0.1)";
      } else {
          elStatus.textContent = "Monitoring Area";
          elStatus.style.color = "#38bdf8"; // Blue
          elCard.style.borderColor = "rgba(56, 189, 248, 0.2)";
          elCard.style.boxShadow = "0 10px 40px rgba(56, 189, 248, 0.1)";
      }
  }
}
"""

_svai_3d_hud = st.components.v2.component(
    "svai_3d_hud",
    html=HTML,
    js=JS,
)

def render_3d_hud(state_data):
    _svai_3d_hud(data=state_data)
