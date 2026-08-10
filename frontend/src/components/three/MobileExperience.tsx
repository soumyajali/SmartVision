'use client';

import React, { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import { RoundedBox, Text, Float, Line } from '@react-three/drei';
import * as THREE from 'three';

export function MobileExperienceScene() {
  const groupRef = useRef<THREE.Group>(null);
  const phoneRef = useRef<THREE.Group>(null);
  
  // Positioned further back and down
  const position = new THREE.Vector3(10, -5, -30);
  
  useFrame((state, delta) => {
    if (phoneRef.current) {
      // Rotate towards user slightly based on scroll
      phoneRef.current.rotation.y = Math.sin(state.clock.elapsedTime * 0.5) * 0.1 - 0.2;
      phoneRef.current.rotation.x = Math.cos(state.clock.elapsedTime * 0.3) * 0.05 + 0.1;
    }
  });

  return (
    <group ref={groupRef} position={position}>
      <Float speed={1.5} floatIntensity={0.5}>
        <group ref={phoneRef}>
          {/* Phone Body */}
          <RoundedBox args={[3, 6, 0.2]} radius={0.2} smoothness={4}>
            <meshStandardMaterial color="#1e293b" metalness={0.8} roughness={0.2} />
          </RoundedBox>
          
          {/* Phone Screen */}
          <mesh position={[0, 0, 0.11]}>
            <planeGeometry args={[2.8, 5.8]} />
            <meshBasicMaterial color="#020617" />
          </mesh>
          
          {/* Screen Content - Simulated Camera View */}
          <group position={[0, 0, 0.12]}>
            {/* Camera View Box */}
            <mesh position={[0, 1, 0]}>
              <planeGeometry args={[2.4, 3.2]} />
              <meshBasicMaterial color="#0f172a" />
            </mesh>
            
            {/* Detection Overlay on Phone */}
            <group position={[0, 1, 0.01]}>
              <Line
                points={[[-0.8, -1, 0], [0.8, -1, 0], [0.8, 1, 0], [-0.8, 1, 0], [-0.8, -1, 0]]}
                color="#06b6d4"
                lineWidth={1}
              />
              <Text position={[-0.7, 1.1, 0]} fontSize={0.15} color="#06b6d4" anchorX="left">
                PERSON 98%
              </Text>
            </group>
            
            {/* Phone UI Text */}
            <Text position={[0, -1.2, 0]} fontSize={0.2} color="#ffffff" anchorX="center">
              TENSORFLOW LITE
            </Text>
            <Text position={[0, -1.6, 0]} fontSize={0.15} color="#38bdf8" anchorX="center">
              EDGE AI / REAL-TIME
            </Text>
            <Text position={[0, -2, 0]} fontSize={0.15} color="#818cf8" anchorX="center">
              14ms LATENCY
            </Text>
          </group>
        </group>
      </Float>
      
      {/* Surrounding Nodes / Particles connecting to the phone */}
      <ConnectionLine start={[-5, 2, -2]} end={[-1.5, 0, 0]} label="MODEL" delay={0} />
      <ConnectionLine start={[-4, 0, -3]} end={[-1.5, -0.5, 0]} label="OPTIMIZATION" delay={1} />
    </group>
  );
}

function ConnectionLine({ start, end, label, delay }: { start: [number, number, number], end: [number, number, number], label: string, delay: number }) {
  const particleRef = useRef<THREE.Mesh>(null);
  const startVec = new THREE.Vector3(...start);
  const endVec = new THREE.Vector3(...end);
  const path = new THREE.LineCurve3(startVec, endVec);
  
  useFrame((state) => {
    if (particleRef.current) {
      const t = ((state.clock.elapsedTime + delay) % 2) / 2; // 0 to 1 over 2 seconds
      const pos = path.getPoint(t);
      particleRef.current.position.copy(pos);
    }
  });

  return (
    <group>
      <Line points={[start, end]} color="#38bdf8" transparent opacity={0.3} dashed dashScale={10} dashSize={0.2} dashOffset={0} />
      <mesh ref={particleRef}>
        <sphereGeometry args={[0.05, 8, 8]} />
        <meshBasicMaterial color="#06b6d4" />
      </mesh>
      <Text position={[start[0] - 0.2, start[1], start[2]]} fontSize={0.2} color="#38bdf8" anchorX="right" anchorY="middle">
        {label}
      </Text>
    </group>
  );
}
