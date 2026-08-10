import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { WebcamProvider } from '@/components/WebcamProvider';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'SmartVision - Real-Time Object Detection',
  description: 'Futuristic AI laboratory / computer vision control center.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} bg-slate-950 text-slate-200 min-h-screen selection:bg-cyan-500/30`}>
        <WebcamProvider>
          {/* Subtle grid background */}
          <div className="fixed inset-0 z-[-1] bg-[linear-gradient(to_right,#4f4f4f2e_1px,transparent_1px),linear-gradient(to_bottom,#4f4f4f2e_1px,transparent_1px)] bg-[size:14px_24px] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_100%)]" />
          
          <main className="min-h-screen">
            {children}
          </main>
        </WebcamProvider>
      </body>
    </html>
  );
}
