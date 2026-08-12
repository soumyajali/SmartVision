import { ScrollManager } from '@/components/ScrollManager';
import { CanvasContainer } from '@/components/CanvasContainer';
import { SpatialUI } from '@/components/ui/SpatialUI';
import { LoadingScreen } from '@/components/ui/LoadingScreen';

export default function Home() {
  return (
    <main className="relative min-h-screen bg-white text-slate-900 selection:bg-blue-500/30">
      <LoadingScreen />
      
      <CanvasContainer />
      
      <ScrollManager>
        <SpatialUI />
        
        {/* Scrollable container sections to drive the Lenis scroll */}
        <div className="relative z-10 w-full">
          {/* Section 1: Intro (0-20vh) */}
          <section className="h-[150vh] w-full" />
          
          {/* Section 2: Vision Activation (150-300vh) */}
          <section className="h-[150vh] w-full" />
          
          {/* Section 3: 3D Objects / Search (300-450vh) */}
          <section className="h-[150vh] w-full" />
          
          {/* Section 4: Analytics (450-600vh) */}
          <section className="h-[150vh] w-full" />
          
          {/* Section 5: Pipeline & Mobile (600-750vh) */}
          <section className="h-[150vh] w-full" />
        </div>
      </ScrollManager>
    </main>
  );
}
