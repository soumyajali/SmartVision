import streamlit as st

HTML = """
<div id="three-container" style="width: 100%; height: 600px; border: 1px solid rgba(255,255,255,0.1); border-radius: 16px; overflow: hidden; background: rgba(15, 23, 42, 0.4); backdrop-filter: blur(12px);"></div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
"""

JS = """
export default function (component) {
  const { data, parentElement } = component;
  
  if (parentElement.querySelector('canvas')) return; // Already initialized

  const container = parentElement.querySelector('#three-container');
  
  // Scene Setup
  const scene = new THREE.Scene();
  
  const camera = new THREE.PerspectiveCamera(45, container.clientWidth / container.clientHeight, 0.1, 100);
  camera.position.set(10, 10, 20);
  camera.lookAt(0, 0, 0);
  
  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setClearColor( 0x000000, 0 );
  renderer.setSize(container.clientWidth, container.clientHeight);
  container.appendChild(renderer.domElement);
  
  // Lights
  const ambient = new THREE.AmbientLight(0xffffff, 0.4);
  scene.add(ambient);
  const spotLight = new THREE.SpotLight(0x00ffff, 1);
  spotLight.position.set(0, 20, 0);
  scene.add(spotLight);
  
  // Create a grid
  const gridHelper = new THREE.GridHelper(20, 20, 0x00ffff, 0x444444);
  scene.add(gridHelper);

  // Group for data points
  const pointsGroup = new THREE.Group();
  scene.add(pointsGroup);

  // Default mock data if none provided
  let historyData = (data && data.history) ? data.history : [];
  if (historyData.length === 0) {
      for(let i=0; i<50; i++) {
          historyData.push({
              time: i,
              classId: Math.floor(Math.random() * 5),
              confidence: Math.random(),
              name: "Object " + i
          });
      }
  }

  // Colors for different classes
  const colors = [0xff0000, 0x00ff00, 0x0000ff, 0xffff00, 0xff00ff, 0x00ffff];

  historyData.forEach((item, index) => {
      const geo = new THREE.SphereGeometry(0.2 + item.confidence * 0.3, 16, 16);
      const mat = new THREE.MeshPhongMaterial({ 
          color: colors[item.classId % colors.length], 
          transparent: true, 
          opacity: 0.8,
          emissive: colors[item.classId % colors.length],
          emissiveIntensity: 0.5
      });
      const mesh = new THREE.Mesh(geo, mat);
      
      // X = time, Y = confidence, Z = classId
      mesh.position.set(
          (index - historyData.length/2) * 0.5,
          item.confidence * 10,
          (item.classId - 2.5) * 2
      );
      
      pointsGroup.add(mesh);
  });
  
  // Animation loop
  const animate = function () {
      requestAnimationFrame(animate);
      
      // Auto-rotation
      pointsGroup.rotation.y += 0.002;
      
      renderer.render(scene, camera);
  };
  animate();
}
"""

_analytics_3d_viewer = st.components.v2.component(
    "analytics_3d_viewer",
    html=HTML,
    js=JS,
)

def render_analytics_viewer(history_data=[]):
    """Renders the 3D Analytics scatter plot."""
    return _analytics_3d_viewer(history=history_data, key="analytics_3d_viewer")
