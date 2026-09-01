"use client";

import React, { useState } from "react";
import { CloudRain, Sun, Wind, Droplets, Compass, MapPin, Eye, Zap } from "lucide-react";

export default function WeatherIslandApp() {
  const [selectedCity, setSelectedCity] = useState("San Francisco");
  const [activeTab, setActiveTab] = useState<"hourly" | "radar" | "island">("hourly");

  const hourlyData = [
    { time: "Now", temp: 64, icon: "Sun", rain: "0%" },
    { time: "3 PM", temp: 66, icon: "Sun", rain: "0%" },
    { time: "4 PM", temp: 65, icon: "CloudRain", rain: "40%" },
    { time: "5 PM", temp: 62, icon: "CloudRain", rain: "80%" },
    { time: "6 PM", temp: 59, icon: "CloudRain", rain: "65%" },
    { time: "7 PM", temp: 57, icon: "Sun", rain: "10%" },
  ];

  return (
    <div className="flex flex-col h-full bg-gradient-to-b from-sky-900 via-blue-950 to-slate-950 text-white p-4 font-sans select-none overflow-y-auto">
      {/* Header */}
      <div className="flex items-center justify-between pb-3 border-b border-blue-800/40">
        <div>
          <div className="text-[11px] font-semibold text-sky-400 uppercase tracking-wider flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-sky-400 animate-pulse" />
            SwiftUI WeatherKit
          </div>
          <h1 className="text-xl font-bold tracking-tight text-white flex items-center gap-1">
            <MapPin className="w-4 h-4 text-sky-400" /> {selectedCity}
          </h1>
        </div>
        <div className="px-2.5 py-1 bg-sky-950/70 border border-sky-800/50 rounded-full text-xs text-sky-300">
          Live Radar
        </div>
      </div>

      {/* Dynamic Island Preview banner */}
      <div className="mt-3 p-3 rounded-2xl bg-black border border-blue-900/60 shadow-xl flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="w-7 h-7 rounded-full bg-blue-500/30 flex items-center justify-center text-sky-400">
            <CloudRain className="w-4 h-4 animate-bounce" />
          </div>
          <div>
            <div className="text-xs font-semibold text-white">Precipitation in 18m</div>
            <div className="text-[10px] text-blue-300">Dynamic Island Live Activity</div>
          </div>
        </div>
        <div className="text-xs font-mono font-bold text-sky-400 bg-blue-950 px-2 py-0.5 rounded border border-blue-800">
          0.12 in/hr
        </div>
      </div>

      {/* Main Temperature Hero */}
      <div className="my-5 text-center">
        <div className="text-6xl font-light tracking-tighter text-white drop-shadow-lg">
          64°
        </div>
        <div className="text-sm font-medium text-sky-300 mt-0.5">Partly Cloudy • H:67° L:52°</div>
        <div className="text-xs text-sky-400/80 mt-1">Wind gusts up to 14 mph from WNW</div>
      </div>

      {/* 4 Weather Metric Tiles */}
      <div className="grid grid-cols-2 gap-2 my-2">
        <div className="p-3 rounded-xl bg-blue-950/50 border border-blue-800/40">
          <div className="flex items-center gap-1.5 text-xs text-sky-300">
            <Droplets className="w-3.5 h-3.5 text-sky-400" /> Humidity
          </div>
          <div className="text-lg font-bold text-white mt-1">78%</div>
          <div className="text-[10px] text-sky-400/70">Dew point 54°</div>
        </div>

        <div className="p-3 rounded-xl bg-blue-950/50 border border-blue-800/40">
          <div className="flex items-center gap-1.5 text-xs text-sky-300">
            <Wind className="w-3.5 h-3.5 text-sky-400" /> Wind Speed
          </div>
          <div className="text-lg font-bold text-white mt-1">11 mph</div>
          <div className="text-[10px] text-sky-400/70">NW moderate breeze</div>
        </div>
      </div>

      {/* Hourly Forecast Strip */}
      <div className="mt-2 p-3 rounded-2xl bg-blue-950/40 border border-blue-800/30">
        <div className="text-xs font-semibold text-sky-300 uppercase tracking-wider mb-2">
          24-Hour Forecast
        </div>
        <div className="flex justify-between items-center text-center">
          {hourlyData.map((h, i) => (
            <div key={i} className="flex flex-col items-center gap-1">
              <span className="text-[11px] text-sky-300">{h.time}</span>
              {h.icon === "Sun" ? (
                <Sun className="w-5 h-5 text-amber-400 my-1" />
              ) : (
                <CloudRain className="w-5 h-5 text-sky-400 my-1" />
              )}
              <span className="text-xs font-bold text-white">{h.temp}°</span>
              <span className="text-[10px] text-sky-400 font-mono">{h.rain}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
