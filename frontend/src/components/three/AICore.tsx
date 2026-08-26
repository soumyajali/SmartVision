'use client';

import React, { useRef, useState } from 'react';
import { useFrame } from '@react-three/fiber';
import { Sphere, Torus, Float } from '@react-three/drei';
import * as THREE from 'three';

export function AICoreScene() {
  const coreRef = useRef<THREE.Mesh>(null);
  const ring1Ref = useRef<THREE.Mesh>(null);
  const ring2Ref = useRef<THREE.Mesh>(null);
  const ring3Ref = useRef<THREE.Mesh>(null);
  const groupRef = useRef<THREE.Group>(null);

  const [hovered, setHovered] = useState(false);

  useFrame((state, delta) => {
    if (coreRef.current) {
      coreRef.current.rotation.y += delta * 0.5;
      coreRef.current.rotation.x += delta * 0.2;
    }
    if (ring1Ref.current) {
      ring1Ref.current.rotation.x += delta * 0.8 * (hovered ? 2 : 1);
      ring1Ref.current.rotation.y += delta * 1.2 * (hovered ? 2 : 1);
    }
    if (ring2Ref.current) {
      ring2Ref.current.rotation.y -= delta * 1.0 * (hovered ? 2 : 1);
      ring2Ref.current.rotation.z += delta * 0.5 * (hovered ? 2 : 1);
    }
    if (ring3Ref.current) {
      ring3Ref.current.rotation.x += delta * 0.4 * (hovered ? 2 : 1);
      ring3Ref.current.rotation.z -= delta * 1.5 * (hovered ? 2 : 1);
    }
  });

  return (
    <group ref={groupRef} position={[0, 0, 0]}>
      <group 
        onPointerOver={() => setHovered(true)} 
        onPointerOut={() => setHovered(false)}
        scale={hovered ? 1.1 : 1}
      >
        <Float speed={2} rotationIntensity={1} floatIntensity={2}>
          {/* Central Core */}
          <Sphere ref={coreRef} args={[1, 64, 64]}>
            <meshStandardMaterial 
              color="#06b6d4" 
              emissive="#06b6d4"
              emissiveIntensity={hovered ? 3 : 1.5}
              wireframe={true}
              transparent={true}
              opacity={0.8}
            />
          </Sphere>

          {/* Inner Glowing Core */}
          <Sphere args={[0.8, 32, 32]}>
            <meshBasicMaterial color="#ffffff" transparent opacity={0.3} />
          </Sphere>

          {/* Rings */}
          <Torus ref={ring1Ref} args={[1.5, 0.02, 16, 100]}>
            <meshStandardMaterial color="#38bdf8" emissive="#38bdf8" emissiveIntensity={2} />
          </Torus>
          
          <Torus ref={ring2Ref} args={[2.0, 0.015, 16, 100]} rotation={[Math.PI / 3, 0, 0]}>
            <meshStandardMaterial color="#818cf8" emissive="#818cf8" emissiveIntensity={1.5} />
          </Torus>

          <Torus ref={ring3Ref} args={[2.5, 0.01, 16, 100]} rotation={[0, Math.PI / 4, 0]}>
            <meshStandardMaterial color="#e0e7ff" emissive="#e0e7ff" emissiveIntensity={1} transparent opacity={0.5} />
          </Torus>
        </Float>
      </group>
    </group>
  );
}
