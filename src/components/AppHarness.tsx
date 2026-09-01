"use client";

import React, { useState, useEffect } from "react";
import { RepoApp } from "@/types/repo";
import ZenFocusApp from "@/components/apps/ZenFocusApp";
import CryptoPulseApp from "@/components/apps/CryptoPulseApp";
import StreakHabitApp from "@/components/apps/StreakHabitApp";
import RetroLensApp from "@/components/apps/RetroLensApp";
import MarkdownNotesApp from "@/components/apps/MarkdownNotesApp";
import WeatherIslandApp from "@/components/apps/WeatherIslandApp";
import { 
  Wifi, 
  Battery, 
  Signal, 
  RotateCcw, 
  Share2, 
  ExternalLink, 
  Smartphone, 
  Layers, 
  CheckCircle2, 
  Code2, 
  Download,
  AlertCircle,
  Play
} from "lucide-react";

interface AppHarnessProps {
  repo: RepoApp;
  onSelectAnother?: () => void;
  fullScreenMobile?: boolean;
}

export default function AppHarness({ repo, onSelectAnother, fullScreenMobile = false }: AppHarnessProps) {
  const [currentTime, setCurrentTime] = useState("9:41");
  const [batteryLevel, setBatteryLevel] = useState(98);
  const [isRotating, setIsRotating] = useState(false);
  const [appKey, setAppKey] = useState(0);

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      const hours = now.getHours();
      const minutes = now.getMinutes();
      setCurrentTime(`${hours}:${minutes < 10 ? "0" : ""}${minutes}`);
    };
    updateTime();
    const timer = setInterval(updateTime, 10000);
    return () => clearInterval(timer);
  }, []);

  const handleRestart = () => {
    setIsRotating(true);
    setAppKey((prev) => prev + 1);
    setTimeout(() => setIsRotating(false), 500);
  };

  const renderActiveApp = () => {
    const key = repo.buildDetails?.appComponentKey || "";
    switch (key) {
      case "zen-focus":
        return <ZenFocusApp key={appKey} />;
      case "crypto-pulse":
        return <CryptoPulseApp key={appKey} />;
      case "streak-habit":
        return <StreakHabitApp key={appKey} />;
      case "retro-lens":
        return <RetroLensApp key={appKey} />;
      case "markdown-notes":
        return <MarkdownNotesApp key={appKey} />;
      case "weather-island":
        return <WeatherIslandApp key={appKey} />;
      default:
        // Generic Web / PWA / External harness for other repos
        return (
          <div className="flex flex-col h-full bg-slate-950 text-slate-100 p-6 justify-between select-none">
            <div>
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-xs font-semibold uppercase tracking-wider">
                <Code2 className="w-3.5 h-3.5" />
                iOS Runner Bridge
              </div>
              <h2 className="text-2xl font-bold text-white mt-4">{repo.name}</h2>
              <p className="text-sm text-slate-400 mt-2 leading-relaxed">
                {repo.description}
              </p>

              <div className="mt-6 space-y-3">
                <div className="bg-slate-900 border border-slate-800 rounded-xl p-3.5 flex items-center justify-between">
                  <span className="text-xs text-slate-400">Build Target</span>
                  <span className="text-xs font-semibold text-emerald-400 font-mono">
                    {repo.buildType.toUpperCase()}
                  </span>
                </div>
                <div className="bg-slate-900 border border-slate-800 rounded-xl p-3.5 flex items-center justify-between">
                  <span className="text-xs text-slate-400">Bundle ID</span>
                  <span className="text-xs font-mono text-slate-300">
                    {repo.buildDetails.bundleId || `com.app.${repo.name}`}
                  </span>
                </div>
                <div className="bg-slate-900 border border-slate-800 rounded-xl p-3.5 flex items-center justify-between">
                  <span className="text-xs text-slate-400">Target iOS Version</span>
                  <span className="text-xs font-medium text-slate-300">
                    {repo.buildDetails.iosTargetVersion || "iOS 16.0+"}
                  </span>
                </div>
              </div>
            </div>

            <div className="space-y-2.5">
              {repo.buildDetails.artifactUrl ? (
                <a
                  href={repo.buildDetails.artifactUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="w-full py-3 bg-blue-600 hover:bg-blue-500 active:scale-95 text-white font-semibold rounded-xl text-xs flex items-center justify-center gap-2 shadow-lg shadow-blue-600/30 transition"
                >
                  <Download className="w-4 h-4" /> Open Build / TestFlight
                </a>
              ) : null}

              {repo.buildDetails.demoUrl ? (
                <a
                  href={repo.buildDetails.demoUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="w-full py-3 bg-slate-800 hover:bg-slate-700 active:scale-95 text-slate-200 font-semibold rounded-xl text-xs flex items-center justify-center gap-2 border border-slate-700 transition"
                >
                  <ExternalLink className="w-4 h-4" /> View GitHub Repository
                </a>
              ) : null}
            </div>
          </div>
        );
    }
  };

  // If running directly on a phone (viewport full width/height), display natively with safe area
  if (fullScreenMobile) {
    return (
      <div className="w-full h-screen bg-black flex flex-col relative overflow-hidden">
        {/* Dynamic Island / Notch on mobile */}
        <div className="w-full pt-2 pb-1 px-6 flex items-center justify-between bg-black text-white text-xs font-semibold z-40 select-none">
          <span>{currentTime}</span>
          <div className="w-24 h-5 bg-zinc-900 rounded-full border border-zinc-800 flex items-center justify-center">
            <div className="w-2.5 h-2.5 rounded-full bg-zinc-700 mr-2" />
            <div className="w-2.5 h-2.5 rounded-full bg-indigo-500 animate-pulse" />
          </div>
          <div className="flex items-center gap-1.5">
            <Signal className="w-3.5 h-3.5" />
            <Wifi className="w-3.5 h-3.5" />
            <Battery className="w-4 h-4 text-emerald-400" />
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-hidden relative">
          {renderActiveApp()}
        </div>

        {/* iOS Home Indicator */}
        <div className="w-full h-6 bg-black flex items-center justify-center pb-1 z-40">
          <div className="w-32 h-1 bg-white/70 rounded-full" />
        </div>
      </div>
    );
  }

  // Desktop simulator frame wrapper
  return (
    <div className="flex flex-col items-center justify-center h-full max-w-full">
      {/* iOS Device Frame (iPhone 16 Pro Style) */}
      <div className="relative w-[370px] h-[740px] max-h-[88vh] bg-slate-900 rounded-[50px] p-[10px] shadow-[0_25px_60px_-15px_rgba(0,0,0,0.7)] border-[4px] border-slate-700 ring-1 ring-slate-600/50 flex flex-col">
        {/* Outer buttons simulation */}
        <div className="absolute -left-[7px] top-[105px] w-[3px] h-[26px] bg-slate-600 rounded-l-sm" /> {/* Action button */}
        <div className="absolute -left-[7px] top-[145px] w-[3px] h-[46px] bg-slate-600 rounded-l-sm" /> {/* Volume Up */}
        <div className="absolute -left-[7px] top-[200px] w-[3px] h-[46px] bg-slate-600 rounded-l-sm" /> {/* Volume Down */}
        <div className="absolute -right-[7px] top-[160px] w-[3px] h-[65px] bg-slate-600 rounded-r-sm" /> {/* Power button */}

        {/* Screen bezel */}
        <div className="relative w-full h-full bg-black rounded-[42px] overflow-hidden flex flex-col border border-zinc-800">
          
          {/* iOS Status Bar & Dynamic Island */}
          <div className="w-full pt-3 pb-1 px-6 flex items-center justify-between text-white text-[11px] font-semibold z-40 select-none bg-black">
            <span>{currentTime}</span>

            {/* Dynamic Island */}
            <div className="h-[22px] px-3 bg-zinc-950 rounded-full border border-zinc-800 flex items-center justify-center gap-2 shadow-inner">
              <div className="w-2.5 h-2.5 rounded-full bg-zinc-800" />
              <div className="w-2.5 h-2.5 rounded-full bg-indigo-500/80 animate-pulse" />
              <span className="text-[10px] font-mono text-indigo-400 pl-1">{repo.name.slice(0, 10)}</span>
            </div>

            <div className="flex items-center gap-1.5 text-zinc-300">
              <Signal className="w-3.5 h-3.5" />
              <Wifi className="w-3.5 h-3.5" />
              <div className="flex items-center gap-0.5 font-mono text-[10px] text-zinc-300">
                <Battery className="w-4 h-4 text-emerald-400" />
              </div>
            </div>
          </div>

          {/* Running App Interactive Viewport */}
          <div className="flex-1 overflow-hidden relative bg-black">
            {renderActiveApp()}
          </div>

          {/* iOS Home Bar Indicator */}
          <div className="w-full h-5 bg-black flex items-center justify-center pb-1 z-40">
            <div className="w-28 h-1 bg-white/70 rounded-full" />
          </div>
        </div>
      </div>

      {/* Simulator Quick Controls under phone */}
      <div className="mt-4 flex items-center gap-3 bg-slate-900/90 border border-slate-800 backdrop-blur-md px-4 py-2 rounded-2xl shadow-lg">
        <button
          onClick={handleRestart}
          className="flex items-center gap-1.5 text-xs text-slate-300 hover:text-white px-2.5 py-1 rounded-lg hover:bg-slate-800 transition"
          title="Restart app session"
        >
          <RotateCcw className={`w-3.5 h-3.5 ${isRotating ? "animate-spin" : ""}`} />
          <span>Reload</span>
        </button>

        <div className="w-[1px] h-4 bg-slate-700" />

        <div className="text-xs text-emerald-400 flex items-center gap-1.5 font-medium">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
          <span>Live iOS Runtime</span>
        </div>

        {repo.buildDetails?.bundleId && (
          <>
            <div className="w-[1px] h-4 bg-slate-700" />
            <span className="text-[11px] font-mono text-slate-400 hidden sm:inline">
              {repo.buildDetails.bundleId}
            </span>
          </>
        )}
      </div>
    </div>
  );
}
