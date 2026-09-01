"use client";

import React, { useState } from "react";
import { CheckCircle2, Circle, Plus, Flame, Sparkles, Award } from "lucide-react";
import confetti from "canvas-confetti";

interface Habit {
  id: string;
  title: string;
  category: string;
  color: string;
  streak: number;
  completedToday: boolean;
  history: boolean[]; // last 7 days
}

export default function StreakHabitApp() {
  const [habits, setHabits] = useState<Habit[]>([
    {
      id: "1",
      title: "Morning 5km Run",
      category: "Fitness",
      color: "#F59E0B",
      streak: 14,
      completedToday: true,
      history: [true, true, true, true, true, true, true]
    },
    {
      id: "2",
      title: "Read 20 pages (System Design)",
      category: "Learning",
      color: "#3B82F6",
      streak: 8,
      completedToday: false,
      history: [true, true, false, true, true, true, false]
    },
    {
      id: "3",
      title: "Drink 2.5L Water",
      category: "Health",
      color: "#06B6D4",
      streak: 21,
      completedToday: true,
      history: [true, true, true, true, true, true, true]
    },
    {
      id: "4",
      title: "Write 1 Git Commit / Code",
      category: "Career",
      color: "#10B981",
      streak: 45,
      completedToday: false,
      history: [true, true, true, true, true, true, false]
    }
  ]);

  const [newHabitText, setNewHabitText] = useState("");
  const [showAdd, setShowAdd] = useState(false);

  const toggleHabit = (id: string) => {
    setHabits((prev) =>
      prev.map((h) => {
        if (h.id === id) {
          const newStatus = !h.completedToday;
          if (newStatus) {
            try {
              confetti({ particleCount: 50, spread: 50, origin: { y: 0.8 } });
            } catch (e) {}
          }
          return {
            ...h,
            completedToday: newStatus,
            streak: newStatus ? h.streak + 1 : Math.max(0, h.streak - 1),
            history: [...h.history.slice(0, 6), newStatus]
          };
        }
        return h;
      })
    );
  };

  const addHabit = () => {
    if (!newHabitText.trim()) return;
    const colors = ["#8B5CF6", "#EC4899", "#10B981", "#F59E0B", "#3B82F6"];
    const newHabit: Habit = {
      id: Date.now().toString(),
      title: newHabitText.trim(),
      category: "Goal",
      color: colors[Math.floor(Math.random() * colors.length)],
      streak: 1,
      completedToday: false,
      history: [false, false, false, false, false, false, false]
    };
    setHabits([...habits, newHabit]);
    setNewHabitText("");
    setShowAdd(false);
  };

  const completedCount = habits.filter((h) => h.completedToday).length;

  return (
    <div className="flex flex-col h-full bg-slate-900 text-white p-4 font-sans select-none overflow-y-auto">
      {/* Header */}
      <div className="flex items-center justify-between pb-3 border-b border-slate-800">
        <div>
          <div className="text-[11px] font-semibold text-amber-400 uppercase tracking-wider flex items-center gap-1.5">
            <Flame className="w-3.5 h-3.5 text-amber-500 fill-amber-500" />
            React Native iOS App
          </div>
          <h1 className="text-xl font-bold tracking-tight text-white">Streakly</h1>
        </div>
        <button
          onClick={() => setShowAdd(!showAdd)}
          className="w-8 h-8 rounded-full bg-amber-500 hover:bg-amber-600 text-slate-950 flex items-center justify-center font-bold shadow-md transition active:scale-95"
        >
          <Plus className="w-5 h-5" />
        </button>
      </div>

      {/* Progress summary banner */}
      <div className="mt-4 p-3.5 rounded-2xl bg-gradient-to-r from-amber-500/20 to-orange-500/20 border border-amber-500/30 flex items-center justify-between">
        <div>
          <div className="text-xs font-semibold text-amber-300">Today&apos;s Momentum</div>
          <div className="text-lg font-bold text-white">
            {completedCount} of {habits.length} Habits Done
          </div>
        </div>
        <div className="w-12 h-12 rounded-xl bg-amber-500/30 border border-amber-400/40 flex flex-col items-center justify-center text-amber-300 font-bold text-sm">
          <span>{Math.round((completedCount / (habits.length || 1)) * 100)}%</span>
        </div>
      </div>

      {showAdd && (
        <div className="mt-3 p-3 rounded-xl bg-slate-800 border border-slate-700 flex gap-2">
          <input
            type="text"
            placeholder="New habit title..."
            value={newHabitText}
            onChange={(e) => setNewHabitText(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && addHabit()}
            className="flex-1 bg-slate-900 border border-slate-700 rounded-lg px-3 py-1.5 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-amber-500"
          />
          <button
            onClick={addHabit}
            className="px-3 py-1.5 rounded-lg bg-amber-500 text-slate-950 font-bold text-xs"
          >
            Add
          </button>
        </div>
      )}

      {/* Habits List */}
      <div className="mt-4 space-y-2.5 flex-1">
        {habits.map((habit) => (
          <div
            key={habit.id}
            className={`p-3.5 rounded-2xl border transition-all ${
              habit.completedToday
                ? "bg-slate-800/90 border-amber-500/40 shadow-sm"
                : "bg-slate-800/40 border-slate-800 hover:border-slate-700"
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <button
                  onClick={() => toggleHabit(habit.id)}
                  className="transition active:scale-90"
                >
                  {habit.completedToday ? (
                    <CheckCircle2 className="w-6 h-6 text-amber-400 fill-amber-400/20" />
                  ) : (
                    <Circle className="w-6 h-6 text-slate-600 hover:text-slate-400" />
                  )}
                </button>
                <div>
                  <div
                    className={`text-sm font-semibold transition ${
                      habit.completedToday ? "text-slate-300 line-through decoration-amber-400/60" : "text-white"
                    }`}
                  >
                    {habit.title}
                  </div>
                  <div className="text-[11px] text-slate-400 flex items-center gap-2 mt-0.5">
                    <span className="px-1.5 py-0.2 bg-slate-700 rounded text-[10px] text-slate-300">
                      {habit.category}
                    </span>
                    <span className="flex items-center gap-0.5 text-amber-400 font-medium">
                      <Flame className="w-3 h-3 fill-amber-400" /> {habit.streak} day streak
                    </span>
                  </div>
                </div>
              </div>

              {/* 7-day mini grid */}
              <div className="flex gap-1">
                {habit.history.map((done, idx) => (
                  <div
                    key={idx}
                    className={`w-2 h-4 rounded-sm ${
                      done ? "bg-amber-400" : "bg-slate-700/60"
                    }`}
                  />
                ))}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
