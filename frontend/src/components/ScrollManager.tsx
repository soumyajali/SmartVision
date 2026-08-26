'use client';

import { useEffect, useRef } from 'react';
import Lenis from 'lenis';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { useStore } from '@/store/useStore';
import { usePathname } from 'next/navigation';

gsap.registerPlugin(ScrollTrigger);

export function ScrollManager({ children }: { children: React.ReactNode }) {
  const setScrollProgress = useStore((state) => state.setScrollProgress);
  const setActiveSection = useStore((state) => state.setActiveSection);
  const containerRef = useRef<HTMLDivElement>(null);
  const pathname = usePathname();

  useEffect(() => {
    // Only run on the main page for 3D scroll
    if (pathname !== '/') return;

    const lenis = new Lenis({
      duration: 1.2,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      orientation: 'vertical',
      gestureOrientation: 'vertical',
      smoothWheel: true,
      wheelMultiplier: 1,
      touchMultiplier: 2,
      infinite: false,
    });

    lenis.on('scroll', (e: any) => {
      ScrollTrigger.update();
      setScrollProgress(e.progress); // 0 to 1
      
      // Determine active section based on progress
      if (e.progress < 0.15) setActiveSection('intro');
      else if (e.progress < 0.35) setActiveSection('vision');
      else if (e.progress < 0.55) setActiveSection('objects');
      else if (e.progress < 0.75) setActiveSection('analytics');
      else setActiveSection('pipeline');
    });

    gsap.ticker.add((time) => {
      lenis.raf(time * 1000);
    });

    gsap.ticker.lagSmoothing(0, 0);

    return () => {
      lenis.destroy();
      gsap.ticker.remove(lenis.raf);
    };
  }, [setScrollProgress, setActiveSection, pathname]);

  return (
    <div ref={containerRef} className="w-full relative">
      {children}
    </div>
  );
}
