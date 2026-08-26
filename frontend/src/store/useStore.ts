import { create } from 'zustand';

interface State {
  scrollProgress: number;
  setScrollProgress: (progress: number) => void;
  activeSection: string;
  setActiveSection: (section: string) => void;
  isVisionActive: boolean;
  setVisionActive: (active: boolean) => void;
  searchTarget: string;
  setSearchTarget: (target: string) => void;
}

export const useStore = create<State>((set) => ({
  scrollProgress: 0,
  setScrollProgress: (progress) => set({ scrollProgress: progress }),
  activeSection: 'intro',
  setActiveSection: (section) => set({ activeSection: section }),
  isVisionActive: false,
  setVisionActive: (active) => set({ isVisionActive: active }),
  searchTarget: 'BOTTLE',
  setSearchTarget: (target) => set({ searchTarget: target }),
}));
