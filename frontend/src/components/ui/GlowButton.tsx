import React from 'react';
import { cn } from './GlassCard';

interface GlowButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger';
}

export const GlowButton = React.forwardRef<HTMLButtonElement, GlowButtonProps>(
  ({ className, variant = 'primary', children, ...props }, ref) => {
    
    const variants = {
      primary: 'bg-cyan-500/10 text-cyan-400 border-cyan-500/50 hover:bg-cyan-500/20 hover:shadow-[0_0_20px_rgba(6,182,212,0.5)]',
      secondary: 'bg-gray-800/50 text-gray-300 border-gray-700 hover:bg-gray-700/50 hover:text-white',
      danger: 'bg-red-500/10 text-red-400 border-red-500/50 hover:bg-red-500/20 hover:shadow-[0_0_20px_rgba(239,68,68,0.5)]'
    };

    return (
      <button
        ref={ref}
        className={cn(
          'relative px-6 py-2.5 rounded-lg border backdrop-blur-sm transition-all duration-300 uppercase tracking-wider text-sm font-semibold active:scale-95 flex items-center justify-center gap-2',
          variants[variant],
          className
        )}
        {...props}
      >
        {children}
      </button>
    );
  }
);

GlowButton.displayName = 'GlowButton';
