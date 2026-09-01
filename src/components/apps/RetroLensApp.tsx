"use client";

import React, { useState } from "react";
import { Camera, Sparkles, Sliders, RefreshCw, Download, Image as ImageIcon, Check } from "lucide-react";

export default function RetroLensApp() {
  const [activeFilter, setActiveFilter] = useState<"kodak" | "fuji" | "cyberpunk" | "noir" | "polaroid">("kodak");
  const [grain, setGrain] = useState(65);
  const [vignette, setVignette] = useState(40);
  const [exposure, setExposure] = useState(10);
  const [captured, setCaptured] = useState(false);
  const [photoCount, setPhotoCount] = useState(12);

  const filterStyles = {
    kodak: "sepia(0.4) saturate(1.4) contrast(1.1) hue-rotate(-10deg)",
    fuji: "saturate(1.2) contrast(1.15) hue-rotate(15deg) brightness(1.05)",
    cyberpunk: "contrast(1.4) saturate(2) hue-rotate(180deg) brightness(0.9)",
    noir: "grayscale(1) contrast(1.6) brightness(0.9)",
    polaroid: "sepia(0.2) contrast(0.9) brightness(1.15) saturate(0.85)"
  };

  const handleShutter = () => {
    setCaptured(true);
    setPhotoCount((prev) => prev + 1);
    setTimeout(() => {
      setCaptured(false);
    }, 400);
  };

  return (
    <div className="flex flex-col h-full bg-stone-950 text-stone-100 p-4 font-sans select-none overflow-y-auto">
      {/* Viewfinder Header */}
      <div className="flex items-center justify-between pb-3 border-b border-stone-800">
        <div>
          <div className="text-[11px] font-semibold text-rose-400 uppercase tracking-widest flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse" />
            Flutter Metal Shader
          </div>
          <h1 className="text-xl font-bold tracking-tight text-white font-mono">RETRO-LENS 90s</h1>
        </div>
        <div className="px-2.5 py-1 bg-stone-900 border border-stone-800 rounded-full text-xs text-stone-400 font-mono">
          ISO 400 • {36 - photoCount} EXP
        </div>
      </div>

      {/* Simulated Camera Viewfinder */}
      <div className="mt-4 relative rounded-2xl overflow-hidden border-2 border-stone-800 bg-stone-900 aspect-square flex items-center justify-center shadow-inner">
        {/* Shutter flash animation */}
        {captured && (
          <div className="absolute inset-0 bg-white z-30 transition-opacity duration-300" />
        )}

        {/* Viewfinder Sample Image Simulation with active CSS filters */}
        <div
          className="w-full h-full relative transition-all duration-300 flex items-center justify-center bg-cover bg-center"
          style={{
            backgroundImage: "url('https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80')",
            filter: filterStyles[activeFilter]
          }}
        >
          {/* Grain overlay simulation */}
          <div
            className="absolute inset-0 pointer-events-none opacity-30 mix-blend-overlay"
            style={{
              backgroundImage: "radial-gradient(#fff 1px, transparent 1px)",
              backgroundSize: "4px 4px"
            }}
          />

          {/* Vignette simulation */}
          <div
            className="absolute inset-0 pointer-events-none"
            style={{
              background: `radial-gradient(circle, transparent ${100 - vignette}%, rgba(0,0,0,0.8) 100%)`
            }}
          />

          {/* Viewfinder grid lines & Crosshair */}
          <div className="absolute inset-0 grid grid-cols-3 grid-rows-3 pointer-events-none opacity-25">
            <div className="border-r border-b border-white" />
            <div className="border-r border-b border-white" />
            <div className="border-b border-white" />
            <div className="border-r border-b border-white" />
            <div className="border-r border-b border-white flex items-center justify-center">
              <div className="w-8 h-8 border border-white/60 rounded-full" />
            </div>
            <div className="border-b border-white" />
            <div className="border-r border-white" />
            <div className="border-r border-white" />
            <div />
          </div>

          {/* Timestamp bottom-right 90s style */}
          <div className="absolute bottom-3 right-3 text-amber-400 font-mono text-xs font-bold drop-shadow tracking-wider z-20">
            &apos;26 09 01
          </div>
        </div>
      </div>

      {/* Preset Film Filters */}
      <div className="mt-4">
        <div className="text-[11px] font-semibold text-stone-400 uppercase tracking-wider mb-2">
          Film Emulation Preset
        </div>
        <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-none">
          {[
            { id: "kodak", name: "Kodak Portra", color: "#F59E0B" },
            { id: "fuji", name: "Fuji Velvia", color: "#10B981" },
            { id: "cyberpunk", name: "Tokyo Neon", color: "#EC4899" },
            { id: "noir", name: "B&W Noir", color: "#9CA3AF" },
            { id: "polaroid", name: "Polaroid 600", color: "#3B82F6" }
          ].map((f) => (
            <button
              key={f.id}
              onClick={() => setActiveFilter(f.id as any)}
              className={`px-3 py-1.5 rounded-xl text-xs font-medium whitespace-nowrap transition border ${
                activeFilter === f.id
                  ? "bg-rose-950/80 border-rose-500 text-rose-200 shadow-md"
                  : "bg-stone-900 border-stone-800 text-stone-400 hover:text-white"
              }`}
            >
              {f.name}
            </button>
          ))}
        </div>
      </div>

      {/* Shutter Button & Controls */}
      <div className="mt-auto pt-4 flex items-center justify-around">
        <button 
          onClick={() => setGrain((g) => (g >= 90 ? 20 : g + 25))}
          className="flex flex-col items-center gap-1 text-[11px] text-stone-400 hover:text-white"
        >
          <Sliders className="w-5 h-5 text-stone-300" />
          <span>Grain {grain}%</span>
        </button>

        {/* Big Mechanical Shutter Button */}
        <button
          onClick={handleShutter}
          className="w-16 h-16 rounded-full bg-stone-200 hover:bg-white active:scale-90 flex items-center justify-center p-1 shadow-2xl transition border-4 border-stone-700"
        >
          <div className="w-full h-full rounded-full border-2 border-stone-900 bg-rose-600 flex items-center justify-center shadow-inner">
            <Camera className="w-6 h-6 text-white" />
          </div>
        </button>

        <button 
          onClick={() => setVignette((v) => (v >= 80 ? 10 : v + 25))}
          className="flex flex-col items-center gap-1 text-[11px] text-stone-400 hover:text-white"
        >
          <Sparkles className="w-5 h-5 text-stone-300" />
          <span>Vignette {vignette}%</span>
        </button>
      </div>
    </div>
  );
}
