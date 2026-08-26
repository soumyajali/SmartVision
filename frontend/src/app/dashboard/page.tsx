'use client';

import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';

export default function Dashboard() {
  return (
    <div className="w-full h-screen flex flex-col bg-slate-50">
      {/* Sleek Navigation Bar */}
      <div className="h-14 w-full bg-white border-b border-slate-200 flex items-center px-6 shadow-sm flex-shrink-0">
        <Link 
          href="/" 
          className="flex items-center text-sm font-semibold text-slate-600 hover:text-blue-600 transition-colors"
        >
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back to Home
        </Link>
        <div className="mx-auto text-sm font-bold text-slate-900 tracking-wider uppercase">
          SmartVision Engine Dashboard
        </div>
        <div className="w-[100px]"></div> {/* Spacer to keep title centered */}
      </div>
      
      {/* Full Screen iframe to embed Streamlit Backend */}
      <div className="flex-1 w-full relative">
        <iframe 
          src="http://localhost:8501" 
          className="absolute inset-0 w-full h-full border-0"
          title="SmartVision Backend Dashboard"
          allow="camera; microphone"
        />
      </div>
    </div>
  );
}
