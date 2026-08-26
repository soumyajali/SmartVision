import streamlit as st

HTML = """
<div id="three-container" style="width: 100%; height: 500px; border: 1px solid rgba(255,255,255,0.1); border-radius: 16px; overflow: hidden; background: rgba(15, 23, 42, 0.4); backdrop-filter: blur(12px);"></div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
"""

JS = """
export default function (component) {
  const { data, parentElement, setTriggerValue } = component;
  
  if (parentElement.querySelector('canvas')) return; // Already initialized

  const container = parentElement.querySelector('#three-container');
  
  // Scene Setup
  const scene = new THREE.Scene();
  
  const camera = new THREE.PerspectiveCamera(45, container.clientWidth / container.clientHeight, 0.1, 100);
  camera.position.set(10, 5, 10);
  camera.lookAt(0, 0, 0);
  
  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setClearColor( 0x000000, 0 );
  renderer.setSize(container.clientWidth, container.clientHeight);
  container.appendChild(renderer.domElement);
  
  // Lights
  const ambient = new THREE.AmbientLight(0xffffff, 0.4);
  scene.add(ambient);
  const spotLight = new THREE.SpotLight(0x00ffff, 1);
  spotLight.position.set(0, 10, 0);
  scene.add(spotLight);
  
  // Pipeline Parts
  const parts = [];
  
  // Input Layer
  const matInput = new THREE.MeshStandardMaterial({ color: 0x3b82f6, wireframe: true, emissive: 0x1d4ed8 });
  const geoInput = new THREE.BoxGeometry(0.5, 4, 4);
  const meshInput = new THREE.Mesh(geoInput, matInput);
  meshInput.position.set(-6, 0, 0);
  meshInput.userData = { name: "Input Layer (Image)", desc: "Receives raw 640x640 RGB image from the camera." };
  scene.add(meshInput);
  parts.push(meshInput);
  
  // Conv Layers (Feature Extraction)
  const matConv = new THREE.MeshStandardMaterial({ color: 0x8b5cf6, transparent: true, opacity: 0.8 });
  for(let i=0; i<3; i++) {
      const geoConv = new THREE.BoxGeometry(1, 3 - i*0.5, 3 - i*0.5);
      const meshConv = new THREE.Mesh(geoConv, matConv);
      meshConv.position.set(-3 + i*2, 0, 0);
      meshConv.userData = { name: `Convolutional Block ${i+1}`, desc: `Extracts hierarchical features. Spatial dims: ${320/(Math.pow(2,i))}x${320/(Math.pow(2,i))}` };
      scene.add(meshConv);
      parts.push(meshConv);
      
      // Connect lines
      if (i === 0) {
          const matLine = new THREE.LineBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.2 });
          const geoLine = new THREE.BufferGeometry().setFromPoints([meshInput.position, meshConv.position]);
          scene.add(new THREE.Line(geoLine, matLine));
      } else {
          const matLine = new THREE.LineBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.2 });
          const geoLine = new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(-3 + (i-1)*2, 0, 0), meshConv.position]);
          scene.add(new THREE.Line(geoLine, matLine));
      }
  }
  
  // Output Head
  const matOut = new THREE.MeshStandardMaterial({ color: 0x10b981, wireframe: true, emissive: 0x059669 });
  const geoOut = new THREE.BoxGeometry(0.5, 1, 1);
  const meshOut = new THREE.Mesh(geoOut, matOut);
  meshOut.position.set(4, 0, 0);
  meshOut.userData = { name: "Detection Head", desc: "Outputs bounding boxes, class scores, and objectiveness predictions." };
  scene.add(meshOut);
  parts.push(meshOut);
  
  const matLineOut = new THREE.LineBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.2 });
  const geoLineOut = new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(-3 + 2*2, 0, 0), meshOut.position]);
  scene.add(new THREE.Line(geoLineOut, matLineOut));
  
  // Raycaster for clicks
  const raycaster = new THREE.Raycaster();
  const mouse = new THREE.Vector2();
  
  container.addEventListener('click', (event) => {
      const rect = renderer.domElement.getBoundingClientRect();
      mouse.x = ( (event.clientX - rect.left) / rect.width ) * 2 - 1;
      mouse.y = - ( (event.clientY - rect.top) / rect.height ) * 2 + 1;
      
      raycaster.setFromCamera(mouse, camera);
      const intersects = raycaster.intersectObjects(parts);
      
      if (intersects.length > 0) {
          const clickedMesh = intersects[0].object;
          setTriggerValue("clicked_part", clickedMesh.userData);
          
          // Flash animation
          const originalColor = clickedMesh.material.color.getHex();
          clickedMesh.material.color.setHex(0xffffff);
          setTimeout(() => { clickedMesh.material.color.setHex(originalColor); }, 200);
      }
  });
  
  // Animation loop
  const animate = function () {
      requestAnimationFrame(animate);
      
      // Auto-rotation
      scene.rotation.y += 0.005;
      
      renderer.render(scene, camera);
  };
  animate();
}
"""

_interactive_3d_viewer = st.components.v2.component(
    "interactive_3d_viewer",
    html=HTML,
    js=JS,
)

def render_interactive_viewer():
    """Renders the 3D Neural Network Pipeline Explorer and returns the clicked part data (if any)."""
    return _interactive_3d_viewer(key="nn_viewer")
