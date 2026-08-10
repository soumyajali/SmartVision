'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Eye, Menu } from 'lucide-react';
import { cn } from '../ui/GlassCard';

const navLinks = [
  { href: '/vision', label: 'Vision' },
  { href: '/search', label: 'Object Search' },
  { href: '/analytics', label: 'Analytics' },
  { href: '/alerts', label: 'Alerts' },
  { href: '/about', label: 'About' },
];

export function Navbar() {
  const pathname = usePathname();

  return (
    <nav className="fixed top-0 w-full z-50 bg-black/60 backdrop-blur-md border-b border-cyan-900/40">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <div className="flex-shrink-0">
            <Link href="/" className="flex items-center gap-2 group">
              <div className="relative">
                <Eye className="w-8 h-8 text-cyan-400 group-hover:text-cyan-300 transition-colors" />
                <div className="absolute inset-0 bg-cyan-400/20 blur-md rounded-full group-hover:bg-cyan-400/40 transition-all" />
              </div>
              <span className="text-xl font-bold tracking-widest text-white">
                SMART<span className="text-cyan-400">VISION</span>
              </span>
            </Link>
          </div>
          
          <div className="hidden md:block">
            <div className="ml-10 flex items-baseline space-x-8">
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className={cn(
                    "px-3 py-2 rounded-md text-sm font-medium transition-all duration-300 hover:text-cyan-400 hover:bg-cyan-900/20",
                    pathname === link.href ? "text-cyan-400 bg-cyan-900/30" : "text-gray-300"
                  )}
                >
                  {link.label}
                </Link>
              ))}
            </div>
          </div>

          <div className="hidden md:flex items-center gap-3">
            <div className="flex items-center gap-2 px-3 py-1 bg-green-500/10 border border-green-500/20 rounded-full">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
              </span>
              <span className="text-xs font-semibold tracking-wider text-green-400">SYSTEM ONLINE</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1 bg-yellow-500/10 border border-yellow-500/20 rounded-full">
              <span className="text-xs font-semibold tracking-wider text-yellow-400">DEMO MODE</span>
            </div>
          </div>

          <div className="md:hidden">
            <button className="text-gray-300 hover:text-cyan-400 focus:outline-none p-2">
              <Menu className="w-6 h-6" />
            </button>
          </div>
        </div>
      </div>
    </nav>
  );
}
