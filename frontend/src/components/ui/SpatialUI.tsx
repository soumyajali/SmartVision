'use client';

import React, { useState, useEffect } from 'react';
import { useStore } from '@/store/useStore';
import { motion, AnimatePresence } from 'framer-motion';
import { Target, Eye, Database, ShieldAlert, Cpu } from 'lucide-react';
import Link from 'next/link';
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
        <div className="text-xl font-bold tracking-tight text-slate-900 flex items-center gap-2">
          <div className="w-2 h-2 bg-blue-600 rounded-full" />
          SmartVision
        </div>
        
        <div className="hidden md:flex items-center gap-8 text-sm font-medium text-slate-400">
          <NavItem active={activeSection === 'vision'}>Vision</NavItem>
          <NavItem active={activeSection === 'objects'}>Search</NavItem>
          <NavItem active={activeSection === 'analytics'}>Analytics</NavItem>
          <NavItem active={activeSection === 'pipeline'}>Technology</NavItem>
        </div>

        <div className="text-sm font-medium text-blue-600 flex items-center gap-2">
          <div className={`w-2 h-2 rounded-full ${isActive ? 'bg-green-500' : 'bg-slate-300'}`} />
          {isActive ? 'System Online' : 'System Offline'}
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
                visible: { opacity: 1, transition: { staggerChildren: 0.15 } }
              }}
              className="text-center"
            >
              <motion.h1 
                variants={{
                  hidden: { opacity: 0, y: 50 },
                  visible: { opacity: 1, y: 0, transition: { duration: 0.8, ease: [0.16, 1, 0.3, 1] } }
                }}
                className="text-6xl md:text-9xl font-black tracking-tighter text-slate-900 leading-[0.9] mb-6"
              >
                Understand<br />
                <span className="text-blue-600">The World.</span>
              </motion.h1>
              <motion.p 
                variants={{
                  hidden: { opacity: 0, y: 20 },
                  visible: { opacity: 1, y: 0, transition: { duration: 0.8, ease: [0.16, 1, 0.3, 1] } }
                }}
                className="text-slate-500 max-w-xl mx-auto mb-8 text-lg font-medium"
              >
                SmartVision transforms live visual input into intelligent, real-time understanding.
              </motion.p>
              <motion.p 
                variants={{
                  hidden: { opacity: 0 },
                  visible: { opacity: 1 }
                }}
                className="text-slate-400 text-sm font-medium tracking-wide mt-24"
              >
                Scroll to initialize vision engine ↓
              </motion.p>
            </motion.div>
          )}

          {activeSection === 'vision' && (
            <motion.div
              key="vision"
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -40 }}
              transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
              className="flex flex-col items-center"
            >
              <div className="bg-white/80 backdrop-blur-xl border border-slate-200 p-10 rounded-[2rem] shadow-xl text-center max-w-md">
                <div className="w-16 h-16 bg-blue-100 rounded-2xl flex items-center justify-center mx-auto mb-6">
                  <Eye className="w-8 h-8 text-blue-600" />
                </div>
                <h2 className="text-3xl font-bold text-slate-900 mb-3 tracking-tight">Vision Engine</h2>
                <p className="text-slate-500 mb-8 font-medium">
                  {isActive ? 'Scanning environment for objects using YOLOv8 neural network...' : 'Ready to initialize real-time environment scan.'}
                </p>
                
                {!isActive ? (
                  <div className="flex flex-col gap-3">
                    <button 
                      onClick={startCamera}
                      className="px-8 py-4 bg-slate-900 hover:bg-slate-800 text-white font-semibold rounded-full transition-all shadow-lg hover:shadow-xl hover:-translate-y-1 w-full"
                    >
                      Initialize Scanner
                    </button>
                    <Link
                      href="/dashboard"
                      className="px-8 py-4 bg-white border-2 border-slate-200 hover:border-blue-500 hover:text-blue-600 text-slate-700 font-semibold rounded-full transition-all w-full flex items-center justify-center"
                    >
                      Open Dashboard
                    </Link>
                  </div>
                ) : (
                  <div className="flex flex-col gap-6">
                    <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                      <div className="h-full bg-blue-500 animate-[pulse_1.5s_ease-in-out_infinite]" style={{ width: '100%' }} />
                    </div>
                    <Link
                      href="/dashboard"
                      className="px-8 py-4 bg-blue-50 hover:bg-blue-100 text-blue-700 font-semibold rounded-full transition-all w-full flex items-center justify-center"
                    >
                      Open Dashboard
                    </Link>
                  </div>
                )}
              </div>
            </motion.div>
          )}

          {/* More sections can be added here */}
        </AnimatePresence>
      </div>

      {/* Bottom HUD */}
      <div className="flex justify-between items-end font-medium text-sm text-slate-400">
        <div>
          <p>YOLOv8 Engine</p>
          <p>Confidence: {'>'} 85%</p>
        </div>
        
        <div className="text-right">
          <p>FPS: {fps}</p>
          <p>Latency: 32ms</p>
        </div>
      </div>
    </div>
  );
}

function NavItem({ children, active }: { children: React.ReactNode, active: boolean }) {
  return (
    <span className={`transition-colors duration-300 cursor-pointer ${active ? 'text-slate-900 font-bold' : 'hover:text-slate-600'}`}>
      {children}
    </span>
  );
}
