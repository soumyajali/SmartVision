'use client';

import React, { createContext, useContext, useEffect, useRef, useState } from 'react';
import { visionApi } from '@/services/visionApi';

interface WebcamContextType {
  isActive: boolean;
  startCamera: () => Promise<void>;
  stopCamera: () => void;
  videoRef: React.RefObject<HTMLVideoElement | null>;
}

const WebcamContext = createContext<WebcamContextType | null>(null);

export function WebcamProvider({ children }: { children: React.ReactNode }) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [isActive, setIsActive] = useState(false);
  const captureInterval = useRef<NodeJS.Timeout | null>(null);

  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { width: 640, height: 480 } });
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        videoRef.current.play();
        setIsActive(true);
        
        // Start sending frames to backend
        visionApi.startDetection();
        
        // Capture frame every 100ms (~10fps) for inference to avoid overloading
        captureInterval.current = setInterval(() => {
          if (!visionApi.isSocketOpen()) {
            // Optional: log if you want, but might spam
            return;
          }
          if (videoRef.current) {
            const canvas = document.createElement('canvas');
            canvas.width = 640;
            canvas.height = 480;
            const ctx = canvas.getContext('2d');
            if (ctx) {
              ctx.drawImage(videoRef.current, 0, 0, 640, 480);
              const base64Frame = canvas.toDataURL('image/jpeg', 0.7);
              visionApi.sendFrame(base64Frame);
            }
          }
        }, 100);
      }
    } catch (err) {
      console.error("Error accessing webcam:", err);
    }
  };

  const stopCamera = () => {
    if (videoRef.current && videoRef.current.srcObject) {
      const stream = videoRef.current.srcObject as MediaStream;
      stream.getTracks().forEach(track => track.stop());
      videoRef.current.srcObject = null;
    }
    if (captureInterval.current) {
      clearInterval(captureInterval.current);
    }
    setIsActive(false);
    visionApi.stopDetection();
  };

  useEffect(() => {
    return () => {
      stopCamera();
    };
  }, []);

  return (
    <WebcamContext.Provider value={{ isActive, startCamera, stopCamera, videoRef }}>
      {/* Hidden video element for capturing */}
      <video ref={videoRef} className="hidden" playsInline muted />
      {children}
    </WebcamContext.Provider>
  );
}

export const useWebcam = () => {
  const ctx = useContext(WebcamContext);
  if (!ctx) throw new Error("useWebcam must be used within WebcamProvider");
  return ctx;
};
