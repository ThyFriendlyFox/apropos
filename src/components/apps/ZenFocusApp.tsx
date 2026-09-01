"use client";

import React, { useState, useEffect } from "react";
import { Play, Pause, RotateCcw, Bell, Moon, Sun, Volume2, Sparkles, Trophy } from "lucide-react";
import confetti from "canvas-confetti";

export default function ZenFocusApp() {
  const [mode, setMode] = useState<"work" | "shortBreak" | "longBreak">("work");
  const [timeLeft, setTimeLeft] = useState(25 * 60);
  const [isRunning, setIsRunning] = useState(false);
  const [completedSessions, setCompletedSessions] = useState(3);
  const [ambientSound, setAmbientSound] = useState<"none" | "rain" | "waves" | "forest">("rain");

  const modeTimes = {
    work: 25 * 60,
    shortBreak: 5 * 60,
    longBreak: 15 * 60,
  };

  useEffect(() => {
    let interval: any = null;
    if (isRunning && timeLeft > 0) {
      interval = setInterval(() => {
        setTimeLeft((prev) => prev - 1);
      }, 1000);
    } else if (timeLeft === 0 && isRunning) {
      setIsRunning(false);
      try {
        confetti({ particleCount: 80, spread: 60, origin: { y: 0.7 } });
      } catch (e) {}
      if (mode === "work") {
        setCompletedSessions((prev) => prev + 1);
        setMode("shortBreak");
        setTimeLeft(modeTimes.shortBreak);
      } else {
        setMode("work");
        setTimeLeft(modeTimes.work);
      }
    }
    return () => clearInterval(interval);
  }, [isRunning, timeLeft, mode]);

  const switchMode = (newMode: "work" | "shortBreak" | "longBreak") => {
    setIsRunning(false);
    setMode(newMode);
    setTimeLeft(modeTimes[newMode]);
  };

  const minutes = Math.floor(timeLeft / 60);
  const seconds = timeLeft % 60;
  const formattedTime = `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
  const totalDuration = modeTimes[mode];
  const progressPercent = ((totalDuration - timeLeft) / totalDuration) * 100;

  return (
    <div className="flex flex-col h-full bg-gradient-to-b from-indigo-950 via-slate-900 to-black text-white p-4 font-sans select-none overflow-y-auto">
      {/* iOS Navigation Header */}
      <div className="flex items-center justify-between pt-2 pb-4 border-b border-indigo-900/40">
        <div>
          <div className="text-xs font-semibold text-indigo-400 uppercase tracking-widest flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-indigo-500 animate-ping" />
            Live SwiftUI Session
          </div>
          <h1 className="text-xl font-bold tracking-tight text-white flex items-center gap-1.5">
            ZenFocus <span className="text-xs bg-indigo-500/30 text-indigo-300 px-2 py-0.5 rounded-full font-mono">v2.4</span>
          </h1>
        </div>
        <div className="flex items-center gap-2">
          <button 
            onClick={() => {
              const sounds: Array<"none" | "rain" | "waves" | "forest"> = ["none", "rain", "waves", "forest"];
              const nextIndex = (sounds.indexOf(ambientSound) + 1) % sounds.length;
              setAmbientSound(sounds[nextIndex]);
            }}
            className="flex items-center gap-1 text-xs bg-indigo-900/60 border border-indigo-700/50 hover:bg-indigo-800 text-indigo-200 px-2.5 py-1.5 rounded-full transition"
          >
            <Volume2 className="w-3.5 h-3.5 text-indigo-400" />
            <span className="capitalize">{ambientSound}</span>
          </button>
        </div>
      </div>

      {/* Mode Selectors (iOS Segmented Control) */}
      <div className="grid grid-cols-3 gap-1 bg-indigo-950/80 p-1.5 rounded-2xl border border-indigo-800/40 mt-4 backdrop-blur-md">
        <button
          onClick={() => switchMode("work")}
          className={`py-2 text-xs font-medium rounded-xl transition ${
            mode === "work"
              ? "bg-indigo-600 text-white shadow-lg shadow-indigo-600/30"
              : "text-indigo-300 hover:text-white"
          }`}
        >
          Deep Focus
        </button>
        <button
          onClick={() => switchMode("shortBreak")}
          className={`py-2 text-xs font-medium rounded-xl transition ${
            mode === "shortBreak"
              ? "bg-indigo-600 text-white shadow-lg shadow-indigo-600/30"
              : "text-indigo-300 hover:text-white"
          }`}
        >
          Short Rest
        </button>
        <button
          onClick={() => switchMode("longBreak")}
          className={`py-2 text-xs font-medium rounded-xl transition ${
            mode === "longBreak"
              ? "bg-indigo-600 text-white shadow-lg shadow-indigo-600/30"
              : "text-indigo-300 hover:text-white"
          }`}
        >
          Long Rest
        </button>
      </div>

      {/* Circular Progress & Timer */}
      <div className="flex-1 flex flex-col items-center justify-center my-6 relative">
        <div className="relative w-56 h-56 flex items-center justify-center">
          {/* Background Ring */}
          <svg className="w-full h-full transform -rotate-90">
            <circle
              cx="112"
              cy="112"
              r="96"
              className="stroke-indigo-950"
              strokeWidth="12"
              fill="transparent"
            />
            <circle
              cx="112"
              cy="112"
              r="96"
              className="stroke-indigo-500 transition-all duration-1000 ease-linear"
              strokeWidth="12"
              strokeDasharray={2 * Math.PI * 96}
              strokeDashoffset={2 * Math.PI * 96 * (1 - progressPercent / 100)}
              strokeLinecap="round"
              fill="transparent"
            />
          </svg>

          {/* Time Display Inside */}
          <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
            <span className="text-5xl font-mono font-extrabold tracking-tighter text-white drop-shadow-md">
              {formattedTime}
            </span>
            <span className="text-xs uppercase tracking-widest text-indigo-300 mt-1 font-medium">
              {isRunning ? "Focusing..." : "Paused"}
            </span>
          </div>
        </div>
      </div>

      {/* Control Buttons */}
      <div className="flex items-center justify-center gap-4 mb-4">
        <button
          onClick={() => {
            setTimeLeft(modeTimes[mode]);
            setIsRunning(false);
          }}
          className="w-12 h-12 rounded-2xl bg-indigo-950 border border-indigo-800/60 flex items-center justify-center text-indigo-300 hover:bg-indigo-900 active:scale-95 transition"
          title="Reset timer"
        >
          <RotateCcw className="w-5 h-5" />
        </button>

        <button
          onClick={() => setIsRunning(!isRunning)}
          className="px-8 h-14 rounded-2xl bg-gradient-to-r from-indigo-500 to-indigo-600 hover:from-indigo-600 hover:to-indigo-700 active:scale-95 text-white font-semibold flex items-center gap-2 shadow-xl shadow-indigo-500/25 transition text-base"
        >
          {isRunning ? (
            <>
              <Pause className="w-5 h-5 fill-current" />
              Pause
            </>
          ) : (
            <>
              <Play className="w-5 h-5 fill-current" />
              Start Focus
            </>
          )}
        </button>
      </div>

      {/* Bottom Live Activity / Streak Card */}
      <div className="bg-indigo-950/60 border border-indigo-800/40 rounded-2xl p-3.5 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-amber-500/20 text-amber-400 flex items-center justify-center border border-amber-500/30">
            <Trophy className="w-5 h-5" />
          </div>
          <div>
            <div className="text-xs font-semibold text-white">Daily Target</div>
            <div className="text-[11px] text-indigo-300">{completedSessions} of 5 sessions completed</div>
          </div>
        </div>
        <div className="flex gap-1">
          {[1, 2, 3, 4, 5].map((i) => (
            <div
              key={i}
              className={`w-2.5 h-6 rounded-full ${
                i <= completedSessions ? "bg-amber-400 shadow-sm shadow-amber-400/50" : "bg-indigo-900/60"
              }`}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
