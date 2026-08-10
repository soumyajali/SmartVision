'use client';

import React, { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import { Text, Float, Instance, Instances } from '@react-three/drei';
import * as THREE from 'three';

const data = [
  { label: 'PERSON', value: 124, color: '#38bdf8' },
  { label: 'BOTTLE', value: 78, color: '#06b6d4' },
  { label: 'LAPTOP', value: 54, color: '#818cf8' },
  { label: 'PHONE', value: 37, color: '#c084fc' },
  { label: 'CHAIR', value: 29, color: '#e879f9' },
];

export function DataWorldScene() {
  const groupRef = useRef<THREE.Group>(null);
  
  // Positioned further back and up, scroll will navigate to it
  const position = new THREE.Vector3(-10, 5, -20);
  
  useFrame((state, delta) => {
    if (groupRef.current) {
      groupRef.current.rotation.y = Math.sin(state.clock.elapsedTime * 0.1) * 0.2;
    }
  });

  return (
    <group ref={groupRef} position={position}>
      <Text
        position={[0, 4, -2]}
        fontSize={0.8}
        color="#ffffff"
        anchorX="center"
        anchorY="bottom"
      >
        DETECTION ANALYTICS
      </Text>
      
      {data.map((item, index) => {
        const height = item.value / 20;
        const xPos = (index - data.length / 2) * 2 + 1;
        
        return (
          <group key={item.label} position={[xPos, 0, 0]}>
            {/* The Bar */}
            <mesh position={[0, height / 2, 0]}>
              <boxGeometry args={[1, height, 1]} />
              <meshStandardMaterial color={item.color} transparent opacity={0.7} />
            </mesh>
            
            {/* Glowing inner core */}
            <mesh position={[0, height / 2, 0]}>
              <boxGeometry args={[0.5, height - 0.2, 0.5]} />
              <meshBasicMaterial color={item.color} />
            </mesh>
            
            {/* Label */}
            <Text
              position={[0, -0.5, 0.6]}
              fontSize={0.3}
              color={item.color}
              anchorX="center"
              anchorY="middle"
              rotation={[-Math.PI / 4, 0, 0]}
            >
              {item.label}
            </Text>
            
            {/* Value */}
            <Float speed={2} floatIntensity={0.5}>
              <Text
                position={[0, height + 0.5, 0]}
                fontSize={0.5}
                color="#ffffff"
                anchorX="center"
                anchorY="middle"
              >
                {item.value}
              </Text>
            </Float>
          </group>
        );
      })}
      
      <Particles count={200} />
    </group>
  );
}

function Particles({ count }: { count: number }) {
  const ref = useRef<THREE.InstancedMesh>(null);
  
  // Use React.useMemo instead of importing from 'react' to avoid Next.js warnings if unused
  const particles = React.useMemo(() => {
    const temp = [];
    for (let i = 0; i < count; i++) {
      temp.push({
        position: new THREE.Vector3(
          (Math.random() - 0.5) * 20,
          Math.random() * 10,
          (Math.random() - 0.5) * 20
        ),
        factor: Math.random() * 2 + 1,
        speed: Math.random() * 0.01 + 0.01,
      });
    }
    return temp;
  }, [count]);

  const dummy = React.useMemo(() => new THREE.Object3D(), []);

  useFrame(() => {
    if (ref.current) {
      particles.forEach((particle, i) => {
        particle.position.y += particle.speed;
        if (particle.position.y > 10) particle.position.y = 0;
        
        dummy.position.copy(particle.position);
        dummy.updateMatrix();
        ref.current!.setMatrixAt(i, dummy.matrix);
      });
      ref.current.instanceMatrix.needsUpdate = true;
    }
  });

  return (
    <instancedMesh ref={ref} args={[undefined, undefined, count]}>
      <sphereGeometry args={[0.05, 8, 8]} />
      <meshBasicMaterial color="#38bdf8" transparent opacity={0.5} />
    </instancedMesh>
  );
}
