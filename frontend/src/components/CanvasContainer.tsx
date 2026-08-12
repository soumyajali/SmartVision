'use client';

import { Canvas, useFrame, useThree } from '@react-three/fiber';
import { Preload } from '@react-three/drei';
import { EffectComposer, Bloom, Noise, Vignette, ChromaticAberration } from '@react-three/postprocessing';
import { BlendFunction } from 'postprocessing';
import { AICoreScene } from './three/AICore';
import { VisionEngineScene } from './three/VisionEngine';
import { DataWorldScene } from './three/DataWorld';
import { MobileExperienceScene } from './three/MobileExperience';
import { useStore } from '@/store/useStore';
import * as THREE from 'three';
import { useRef, useMemo } from 'react';

// Define the cinematic camera flight path
const cameraPath = new THREE.CatmullRomCurve3([
  new THREE.Vector3(0, 0, 10),     // Start at AI Core
  new THREE.Vector3(0, 0, 0),      // Pass through AI Core
  new THREE.Vector3(0, 2, -10),    // Vision Engine
  new THREE.Vector3(-8, 8, -12),   // Banking towards DataWorld
  new THREE.Vector3(-10, 8, -10),  // DataWorld View
  new THREE.Vector3(0, 0, -18),    // Swoop down
  new THREE.Vector3(10, -2, -22),  // Approaching Mobile
]);

const lookAtPath = new THREE.CatmullRomCurve3([
  new THREE.Vector3(0, 0, 0),      // Look at AI Core
  new THREE.Vector3(0, 0, -5),     // Look ahead
  new THREE.Vector3(0, 0, -20),    // Look at Vision Engine objects
  new THREE.Vector3(-10, 5, -20),  // Look at DataWorld
  new THREE.Vector3(-10, 5, -20),  // Keep looking at DataWorld
  new THREE.Vector3(10, -5, -30),  // Look towards Mobile
  new THREE.Vector3(10, -5, -30),  // Final Mobile Look
]);

function SceneManager() {
  const scrollProgress = useStore((state) => state.scrollProgress);
  const groupRef = useRef<THREE.Group>(null);
  
  // Parallax vectors
  const targetCameraPos = useRef(new THREE.Vector3());
  const targetLookAt = useRef(new THREE.Vector3());
  const currentCameraPos = useRef(new THREE.Vector3());
  const currentLookAt = useRef(new THREE.Vector3());
  const mouseOffset = useRef(new THREE.Vector3());

  useFrame((state, delta) => {
    // 1. Get positions on the spline based on scroll progress (0 to 1)
    // Clamp progress to slightly less than 1 to avoid spline end issues
    const t = Math.max(0, Math.min(0.999, scrollProgress));
    
    cameraPath.getPointAt(t, targetCameraPos.current);
    lookAtPath.getPointAt(t, targetLookAt.current);

    // 2. Calculate smooth mouse parallax
    // state.pointer is normalized -1 to 1
    const parallaxX = (state.pointer.x * 0.5);
    const parallaxY = (state.pointer.y * 0.5);
    mouseOffset.current.lerp(new THREE.Vector3(parallaxX, parallaxY, 0), delta * 2);

    // 3. Add parallax to target position
    targetCameraPos.current.add(mouseOffset.current);

    // 4. Smoothly interpolate current camera position to target
    currentCameraPos.current.lerp(targetCameraPos.current, delta * 3);
    currentLookAt.current.lerp(targetLookAt.current, delta * 4);

    state.camera.position.copy(currentCameraPos.current);
    state.camera.lookAt(currentLookAt.current);
  });

  return (
    <group ref={groupRef}>
      <AICoreScene />
      <VisionEngineScene />
      <DataWorldScene />
      <MobileExperienceScene />
    </group>
  );
}

export function CanvasContainer() {
  return (
    <div className="fixed inset-0 z-0 pointer-events-auto">
      <Canvas
        camera={{ position: [0, 0, 10], fov: 45 }}
        gl={{ antialias: false, alpha: true, powerPreference: 'high-performance' }} // antialias false for postprocessing
        dpr={[1, 1.5]}
      >
        <color attach="background" args={['#ffffff']} />
        <fog attach="fog" args={['#ffffff', 5, 40]} />
        
        <ambientLight intensity={1.5} />
        <directionalLight position={[10, 10, 10]} intensity={2.0} color="#ffffff" castShadow />
        <pointLight position={[-10, -10, -10]} intensity={1.0} color="#e2e8f0" />
        
        <SceneManager />
        
        <EffectComposer>
          <Bloom luminanceThreshold={0.8} mipmapBlur intensity={0.5} />
          <Noise opacity={0.01} />
          <Vignette eskil={false} offset={0.1} darkness={0.3} />
        </EffectComposer>

        <Preload all />
      </Canvas>
    </div>
  );
}
