'use client';

import React, { useState, useEffect } from 'react';
import { useStore } from '@/store/useStore';
import { motion, AnimatePresence } from 'framer-motion';
import { Target, Eye, Database, ShieldAlert, Cpu } from 'lucide-react';
import { useWebcam } from '@/components/WebcamProvider';

export function SpatialUI() {
  const activeSection = useStore(state => state.activeSection);
  const scrollProgress = useStore(state => state.scrollProgress);
  const [fps, setFps] = useState(31);

  useEffect(() => {
    const interval = setInterval(() => {
      setFps(Math.floor(28 + Math.random() * 5));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const { isActive, startCamera, stopCamera } = useWebcam();

  return (
    <div className="fixed inset-0 z-20 pointer-events-none flex flex-col justify-between p-8">
      {/* Top Navigation */}
      <nav className="flex items-center justify-between pointer-events-auto">
        <div className="text-xl font-bold tracking-widest text-white flex items-center gap-2">
          <div className="w-2 h-2 bg-cyan-400 rounded-full animate-pulse" />
          SMARTVISION
        </div>
        
        <div className="hidden md:flex items-center gap-8 text-xs font-mono text-slate-400">
          <NavItem active={activeSection === 'vision'}>VISION</NavItem>
          <NavItem active={activeSection === 'objects'}>SEARCH</NavItem>
          <NavItem active={activeSection === 'analytics'}>ANALYTICS</NavItem>
          <NavItem active={activeSection === 'pipeline'}>TECHNOLOGY</NavItem>
        </div>

        <div className="text-xs font-mono text-cyan-400 flex items-center gap-2">
          <div className={`w-1.5 h-1.5 rounded-full ${isActive ? 'bg-green-400 animate-ping' : 'bg-red-400'}`} />
          {isActive ? 'SYSTEM ONLINE' : 'SYSTEM OFFLINE'}
        </div>
      </nav>

      {/* Main Content Area - Transitions based on active section */}
      <div className="flex-1 flex flex-col justify-center items-center pointer-events-auto mt-20">
        <AnimatePresence mode="wait">
          {activeSection === 'intro' && (
            <motion.div
              key="intro"
              initial="hidden"
              animate="visible"
              exit="hidden"
              variants={{
                hidden: { opacity: 0 },
                visible: { opacity: 1, transition: { staggerChildren: 0.2 } }
              }}
              className="text-center"
            >
              <motion.h1 
                variants={{
                  hidden: { opacity: 0, y: 30, scale: 0.95 },
                  visible: { opacity: 1, y: 0, scale: 1, transition: { type: "spring", damping: 20, stiffness: 100 } }
                }}
                className="text-5xl md:text-7xl font-extrabold tracking-tighter mb-4"
              >
                SEE THE WORLD.<br />
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-cyan-400 to-blue-600 drop-shadow-[0_0_15px_rgba(6,182,212,0.5)]">
                  UNDERSTAND IT.
                </span>
              </motion.h1>
              <motion.p 
                variants={{
                  hidden: { opacity: 0, y: 20 },
                  visible: { opacity: 1, y: 0, transition: { type: "spring", damping: 20, stiffness: 100 } }
                }}
                className="text-slate-400 max-w-lg mx-auto mb-8 font-mono text-sm"
              >
                SmartVision transforms live visual input into intelligent, real-time understanding.
              </motion.p>
              <motion.p 
                variants={{
                  hidden: { opacity: 0 },
                  visible: { opacity: 1 }
                }}
                className="text-cyan-500 text-xs font-mono tracking-widest uppercase mt-32 animate-pulse"
              >
                Scroll to initialize vision engine ↓
              </motion.p>
            </motion.div>
          )}

          {activeSection === 'vision' && (
            <motion.div
              key="vision"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 1.1 }}
              className="flex flex-col items-center"
            >
              <div className="border border-cyan-500/30 bg-cyan-950/40 backdrop-blur-md p-6 rounded-lg text-center max-w-md">
                <Eye className="w-8 h-8 text-cyan-400 mx-auto mb-4" />
                <h2 className="text-2xl font-bold mb-2">VISION ENGINE</h2>
                <p className="text-slate-400 text-sm mb-6 font-mono">
                  {isActive ? 'Scanning environment for objects using YOLOv8 neural network...' : 'Ready to initialize real-time environment scan.'}
                </p>
                
                {!isActive ? (
                  <button 
                    onClick={startCamera}
                    className="px-6 py-2 bg-cyan-600 hover:bg-cyan-500 text-white font-bold rounded-full transition-all"
                  >
                    INITIALIZE SCANNER
                  </button>
                ) : (
                  <div className="w-full h-1 bg-slate-800 rounded-full overflow-hidden">
                    <div className="h-full bg-cyan-400 animate-[pulse_1.5s_ease-in-out_infinite]" style={{ width: '100%' }} />
                  </div>
                )}
              </div>
            </motion.div>
          )}

          {/* More sections can be added here */}
        </AnimatePresence>
      </div>

      {/* Bottom HUD */}
      <div className="flex justify-between items-end font-mono text-xs text-cyan-500/70">
        <div>
          <p>YOLOv8 DETECTOR</p>
          <p>CONFIDENCE: &gt; 85%</p>
        </div>
        
        <div className="text-right">
          <p>FPS: {fps}</p>
          <p>LATENCY: 32ms</p>
        </div>
      </div>
    </div>
  );
}

function NavItem({ children, active }: { children: React.ReactNode, active: boolean }) {
  return (
    <span className={`transition-colors duration-300 ${active ? 'text-cyan-400 font-bold' : 'hover:text-white'}`}>
      {children}
    </span>
  );
}
