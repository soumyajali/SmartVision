'use client';

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

export function LoadingScreen() {
  const [loading, setLoading] = useState(true);
  const [statusText, setStatusText] = useState('INITIALIZING AI CORE');

  useEffect(() => {
    const sequence = [
      { text: 'LOADING VISION ENGINE', delay: 800 },
      { text: 'CALIBRATING DETECTION', delay: 1600 },
      { text: 'SYSTEM READY', delay: 2400 },
    ];

    sequence.forEach(({ text, delay }) => {
      setTimeout(() => setStatusText(text), delay);
    });

    setTimeout(() => setLoading(false), 3000);
  }, []);

  return (
    <AnimatePresence>
      {loading && (
        <motion.div
          initial={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 1, ease: 'easeInOut' }}
          className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-slate-950 text-cyan-400"
        >
          <div className="text-2xl font-bold tracking-[0.3em] mb-12">SMARTVISION</div>
          
          <div className="w-64 h-px bg-cyan-900 relative mb-4">
            <motion.div
              className="absolute top-0 left-0 h-full bg-cyan-400"
              initial={{ width: 0 }}
              animate={{ width: '100%' }}
              transition={{ duration: 2.8, ease: 'linear' }}
            />
          </div>
          
          <div className="text-xs font-mono tracking-widest text-cyan-500/70 h-4">
            {statusText}
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
