import React, { useRef, useState, useEffect } from 'react';
import { useFrame } from '@react-three/fiber';
import { Box, Edges, Float, Text } from '@react-three/drei';
import * as THREE from 'three';
import { useStore } from '@/store/useStore';
import { visionApi, Detection } from '@/services/visionApi';

// Alert audio is now handled by the Python backend via siren.wav

export function VisionEngineScene() {
  const groupRef = useRef<THREE.Group>(null);
  const isVisionActive = useStore(state => state.isVisionActive);
  const [detections, setDetections] = useState<Detection[]>([]);
  const lastAlertTime = useRef(0);
  
  // Positioned further back along the Z-axis
  const position = new THREE.Vector3(0, 0, -20);
  
  useEffect(() => {
    visionApi.onDetection((newDetections) => {
      setDetections(newDetections);

      const harmfulObjects = ['KNIFE', 'SCISSORS'];
      const hasHarmful = newDetections.some(d => harmfulObjects.includes(d.label));
      
      if (hasHarmful) {
        // Sound is handled by the backend. We only need the visual state here.
      }
    });
  }, []);

  useFrame((state, delta) => {
    if (groupRef.current) {
      groupRef.current.position.y = position.y + Math.sin(state.clock.elapsedTime) * 0.2;
    }
  });

  return (
    <group ref={groupRef} position={position}>
      {detections.map((det) => {
        // Map normalized coordinates (0-1) to 3D space (-5 to 5)
        const xPos = (det.x - 0.5) * 10;
        const yPos = -(det.y - 0.5) * 10 + 2; // Invert Y
        const isHarmful = ['KNIFE', 'SCISSORS'].includes(det.label);
        
        return (
          <DetectedObject 
            key={det.id}
            label={det.label} 
            position={[xPos, yPos, Math.random() * 2 - 1]} 
            confidence={det.confidence} 
            isVisionActive={isVisionActive}
            isHarmful={isHarmful}
          />
        );
      })}
      
      {/* Grid Floor */}
      <gridHelper args={[20, 20, '#06b6d4', '#020617']} position={[0, -2, 0]} />
    </group>
  );
}

function DetectedObject({ label, position, confidence, isVisionActive, isHarmful = false }: { label: string, position: [number, number, number], confidence: number, isVisionActive: boolean, isHarmful?: boolean }) {
  const boxRef = useRef<THREE.Mesh>(null);

  useFrame((state, delta) => {
    if (boxRef.current) {
      boxRef.current.rotation.y += delta * 0.5;
      boxRef.current.rotation.x += delta * 0.2;
    }
  });

  const mainColor = isHarmful ? "#ef4444" : "#06b6d4"; // Red for harmful, Cyan for normal
  const subColor = isHarmful ? "#f87171" : "#38bdf8";

  return (
    <Float speed={2} rotationIntensity={0.5} floatIntensity={1}>
      <group position={position}>
        {/* The object placeholder */}
        <Box ref={boxRef} args={[1, 1, 1]}>
          <meshStandardMaterial color={isHarmful ? "#7f1d1d" : "#1e293b"} wireframe={true} transparent opacity={0.5} />
        </Box>
        
        {/* Detection Box (glows when active) */}
        {isVisionActive && (
          <group>
            <Box args={[1.2, 1.2, 1.2]}>
              <meshBasicMaterial transparent opacity={0} />
              <Edges linewidth={2} scale={1.1} threshold={15} color={mainColor} />
            </Box>
            
            {/* Holographic label */}
            <group position={[0, 1, 0]}>
              <Text
                position={[0, 0, 0]}
                fontSize={0.2}
                color={mainColor}
                anchorX="center"
                anchorY="bottom"
                outlineWidth={0.01}
                outlineColor="#020617"
              >
                {isHarmful ? `⚠️ ${label}` : label}
              </Text>
              <Text
                position={[0, -0.25, 0]}
                fontSize={0.15}
                color={subColor}
                anchorX="center"
                anchorY="bottom"
              >
                {confidence.toFixed(1)}%
              </Text>
            </group>
          </group>
        )}
      </group>
    </Float>
  );
}
