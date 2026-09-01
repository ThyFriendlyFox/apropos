"use client";

import React, { useState, useEffect } from "react";
import { RepoApp } from "@/types/repo";
import { SAMPLE_REPOS } from "@/data/sampleRepos";
import AppHarness from "@/components/AppHarness";
import PhoneTesterModal from "@/components/PhoneTesterModal";
import {
  Smartphone,
  ChevronDown,
  Layers,
  Sparkles,
  Search,
  Filter,
  CheckCircle2,
  GitBranch,
  QrCode,
  ArrowRight,
  RefreshCw,
  ExternalLink,
  Code2,
  Box,
  Share2,
  Apple,
  X,
  SlidersHorizontal
} from "lucide-react";

export default function RepoRunnerLauncher() {
  const [repos, setRepos] = useState<RepoApp[]>(SAMPLE_REPOS);
  const [selectedRepoId, setSelectedRepoId] = useState<string>(SAMPLE_REPOS[0].id);
  const [onlyIosBuilds, setOnlyIosBuilds] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [selectedBuildType, setSelectedBuildType] = useState<string>("all");
  const [isDropdownOpen, setIsDropdownOpen] = useState<boolean>(false);
  const [showQrModal, setShowQrModal] = useState<boolean>(false);
  const [githubUsername, setGithubUsername] = useState<string>("");
  const [isLoadingRepos, setIsLoadingRepos] = useState<boolean>(false);
  const [customHostUrl, setCustomHostUrl] = useState<string>("");
  const [isMobileViewport, setIsMobileViewport] = useState<boolean>(false);

  useEffect(() => {
    if (typeof window !== "undefined") {
      setCustomHostUrl(window.location.origin);
      // Check if user is already on a real phone
      const checkMobile = () => {
        setIsMobileViewport(window.innerWidth <= 768);
      };
      checkMobile();
      window.addEventListener("resize", checkMobile);
      return () => window.removeEventListener("resize", checkMobile);
    }
  }, []);

  const handleFetchGithubRepos = async () => {
    if (!githubUsername.trim()) return;
    setIsLoadingRepos(true);
    try {
      const res = await fetch(`/api/repos?username=${encodeURIComponent(githubUsername)}&iosOnly=false`);
      const data = await res.json();
      if (data.success && data.repos && data.repos.length > 0) {
        setRepos(data.repos);
        // auto select first repo with iOS build if available
        const firstIos = data.repos.find((r: RepoApp) => r.hasIosBuild);
        if (firstIos) {
          setSelectedRepoId(firstIos.id);
        } else {
          setSelectedRepoId(data.repos[0].id);
        }
      }
    } catch (e) {
      console.error("Failed to load GitHub user repos", e);
    } finally {
      setIsLoadingRepos(false);
    }
  };

  const handleResetToSamples = () => {
    setRepos(SAMPLE_REPOS);
    setSelectedRepoId(SAMPLE_REPOS[0].id);
    setGithubUsername("");
  };

  // Filtered repos according to user selections
  const filteredRepos = repos.filter((repo) => {
    if (onlyIosBuilds && !repo.hasIosBuild) return false;
    if (selectedBuildType !== "all" && repo.buildType !== selectedBuildType) return false;
    if (searchQuery.trim() !== "") {
      const q = searchQuery.toLowerCase();
      const matchName = repo.name.toLowerCase().includes(q);
      const matchDesc = repo.description.toLowerCase().includes(q);
      const matchLang = repo.language.toLowerCase().includes(q);
      if (!matchName && !matchDesc && !matchLang) return false;
    }
    return true;
  });

  const selectedRepo = repos.find((r) => r.id === selectedRepoId) || filteredRepos[0] || repos[0];

  const buildTypeLabels: Record<string, string> = {
    all: "All Stacks",
    "swift-xcode": "Swift / Xcode",
    expo: "Expo EAS",
    "react-native": "React Native",
    flutter: "Flutter",
    "capacitor-ionic": "Capacitor / Ionic"
  };

  const phoneLaunchUrl = `${customHostUrl}/app/${selectedRepo?.id || "repo-zen-focus"}`;

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col selection:bg-indigo-500 selection:text-white">
      {/* Top Navigation Bar */}
      <header className="border-b border-slate-800/80 bg-slate-900/60 backdrop-blur-xl sticky top-0 z-30 px-4 sm:px-8 py-3.5 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-indigo-600 via-indigo-500 to-sky-400 p-[1px] shadow-lg shadow-indigo-500/20">
            <div className="w-full h-full bg-slate-950 rounded-[15px] flex items-center justify-center">
              <Apple className="w-5 h-5 text-indigo-400" />
            </div>
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="font-bold text-base sm:text-lg tracking-tight text-white">
                iOS Repo Runner
              </h1>
              <span className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 hidden sm:inline">
                App Launcher
              </span>
            </div>
            <p className="text-xs text-slate-400 hidden sm:block">
              Select any repo with an iOS build &amp; run it live on your phone
            </p>
          </div>
        </div>

        {/* Action controls */}
        <div className="flex items-center gap-2 sm:gap-3">
          {/* QR Code Phone Button */}
          <button
            onClick={() => setShowQrModal(true)}
            className="flex items-center gap-2 px-3.5 py-2 rounded-xl bg-gradient-to-r from-indigo-600 to-indigo-500 hover:from-indigo-500 hover:to-indigo-400 text-white text-xs font-semibold shadow-lg shadow-indigo-600/25 transition active:scale-95"
          >
            <QrCode className="w-4 h-4" />
            <span className="hidden sm:inline">Test on Phone</span>
            <span className="sm:hidden">Phone QR</span>
          </button>

          <a
            href={phoneLaunchUrl}
            target="_blank"
            rel="noreferrer"
            className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-medium border border-slate-700 transition"
            title="Open direct fullscreen web app"
          >
            <ExternalLink className="w-3.5 h-3.5" />
            <span className="hidden md:inline">Direct Link</span>
          </a>
        </div>
      </header>

      {/* Main Container */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Left Column: Repository Selection Dropdown & Controls */}
        <section className="lg:col-span-6 flex flex-col gap-4">
          
          {/* Main Dropdown Picker Card */}
          <div className="bg-slate-900/80 border border-slate-800/90 rounded-3xl p-5 sm:p-6 shadow-xl backdrop-blur-md">
            <div className="flex items-center justify-between mb-4">
              <label className="text-xs font-bold uppercase tracking-wider text-indigo-400 flex items-center gap-1.5">
                <Layers className="w-4 h-4" />
                Select Repository App
              </label>
              <span className="text-xs text-slate-400 font-mono">
                {filteredRepos.length} {filteredRepos.length === 1 ? "repo" : "repos"} with iOS build
              </span>
            </div>

            {/* Custom Interactive Dropdown */}
            <div className="relative">
              <button
                type="button"
                onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                className="w-full bg-slate-950 border border-slate-700/80 hover:border-indigo-500/80 rounded-2xl p-3.5 sm:p-4 text-left transition flex items-center justify-between shadow-inner group"
              >
                <div className="flex items-center gap-3 overflow-hidden">
                  <div
                    className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 border"
                    style={{
                      backgroundColor: `${selectedRepo.buildDetails?.themeColor || "#6366F1"}15`,
                      borderColor: `${selectedRepo.buildDetails?.themeColor || "#6366F1"}40`,
                      color: selectedRepo.buildDetails?.themeColor || "#6366F1"
                    }}
                  >
                    <Smartphone className="w-5 h-5" />
                  </div>
                  <div className="overflow-hidden">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-sm sm:text-base text-white truncate">
                        {selectedRepo.name}
                      </span>
                      {selectedRepo.hasIosBuild && (
                        <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 flex items-center gap-1 shrink-0">
                          <CheckCircle2 className="w-3 h-3" /> iOS Ready
                        </span>
                      )}
                    </div>
                    <div className="text-xs text-slate-400 truncate mt-0.5">
                      {selectedRepo.owner}/{selectedRepo.name} • {selectedRepo.language}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2 pl-2 shrink-0">
                  <span className="text-xs text-slate-400 hidden sm:inline">Change</span>
                  <div className={`p-1.5 rounded-lg bg-slate-800 text-slate-300 transition-transform ${isDropdownOpen ? "rotate-180" : ""}`}>
                    <ChevronDown className="w-4 h-4" />
                  </div>
                </div>
              </button>

              {/* Dropdown Menu List */}
              {isDropdownOpen && (
                <div className="absolute top-full left-0 right-0 mt-2 bg-slate-900 border border-slate-700/90 rounded-2xl shadow-2xl z-50 overflow-hidden max-h-[380px] flex flex-col">
                  {/* Search inside dropdown */}
                  <div className="p-3 border-b border-slate-800 bg-slate-950/60 flex items-center gap-2">
                    <Search className="w-4 h-4 text-slate-400" />
                    <input
                      type="text"
                      placeholder="Search repositories..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="bg-transparent text-xs text-white placeholder-slate-500 focus:outline-none w-full"
                    />
                    {searchQuery && (
                      <button onClick={() => setSearchQuery("")} className="text-slate-400 hover:text-white">
                        <X className="w-3.5 h-3.5" />
                      </button>
                    )}
                  </div>

                  {/* Repos list items */}
                  <div className="overflow-y-auto p-2 space-y-1 divide-y divide-slate-800/40">
                    {filteredRepos.map((repo) => {
                      const isSelected = repo.id === selectedRepo.id;
                      return (
                        <button
                          key={repo.id}
                          onClick={() => {
                            setSelectedRepoId(repo.id);
                            setIsDropdownOpen(false);
                          }}
                          className={`w-full p-3 rounded-xl text-left transition flex items-center justify-between ${
                            isSelected
                              ? "bg-indigo-600/20 border border-indigo-500/40 text-white"
                              : "hover:bg-slate-800/70 text-slate-300 hover:text-white"
                          }`}
                        >
                          <div className="flex items-center gap-3 overflow-hidden">
                            <div
                              className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0 text-xs font-bold border"
                              style={{
                                backgroundColor: `${repo.buildDetails?.themeColor || "#6366F1"}20`,
                                borderColor: `${repo.buildDetails?.themeColor || "#6366F1"}50`,
                                color: repo.buildDetails?.themeColor || "#6366F1"
                              }}
                            >
                              <Smartphone className="w-4 h-4" />
                            </div>
                            <div className="overflow-hidden">
                              <div className="font-semibold text-xs sm:text-sm text-white truncate">
                                {repo.name}
                              </div>
                              <div className="text-[11px] text-slate-400 truncate">
                                {repo.description}
                              </div>
                            </div>
                          </div>

                          <div className="text-right shrink-0 pl-2">
                            <span className="text-[10px] font-mono font-medium px-2 py-0.5 rounded bg-slate-800 text-slate-300 border border-slate-700">
                              {repo.buildType}
                            </span>
                          </div>
                        </button>
                      );
                    })}

                    {filteredRepos.length === 0 && (
                      <div className="p-6 text-center text-xs text-slate-500">
                        No repositories matching current filters.
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* Stack Filter Pills */}
            <div className="mt-4 flex flex-wrap gap-1.5">
              {Object.entries(buildTypeLabels).map(([key, label]) => (
                <button
                  key={key}
                  onClick={() => setSelectedBuildType(key)}
                  className={`text-xs px-3 py-1.5 rounded-xl font-medium transition border ${
                    selectedBuildType === key
                      ? "bg-indigo-600 text-white border-indigo-500 shadow-sm"
                      : "bg-slate-950/60 border-slate-800 text-slate-400 hover:text-slate-200"
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>

            {/* Filter Toggle */}
            <div className="mt-4 pt-4 border-t border-slate-800/80 flex items-center justify-between">
              <label className="text-xs font-medium text-slate-300 flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={onlyIosBuilds}
                  onChange={(e) => setOnlyIosBuilds(e.target.checked)}
                  className="rounded border-slate-700 bg-slate-950 text-indigo-600 focus:ring-indigo-500"
                />
                <span>Only show repositories with detected iOS build target</span>
              </label>
            </div>
          </div>

          {/* Active Selected App Details Card */}
          <div className="bg-slate-900/60 border border-slate-800/80 rounded-3xl p-5 sm:p-6 shadow-lg">
            <div className="flex items-start justify-between">
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-lg font-bold text-white tracking-tight">
                    {selectedRepo.name}
                  </h3>
                  <span className="text-[10px] font-mono px-2 py-0.5 bg-slate-800 border border-slate-700 rounded-md text-slate-300">
                    v{selectedRepo.buildDetails?.version || "1.0.0"}
                  </span>
                </div>
                <p className="text-xs text-slate-400 mt-1 leading-relaxed">
                  {selectedRepo.description}
                </p>
              </div>
            </div>

            {/* Build Metadata Badges */}
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5 mt-4">
              <div className="bg-slate-950/70 border border-slate-800 rounded-xl p-2.5">
                <div className="text-[10px] uppercase font-bold text-slate-500">iOS Framework</div>
                <div className="text-xs font-semibold text-slate-200 mt-0.5">
                  {selectedRepo.buildType}
                </div>
              </div>

              <div className="bg-slate-950/70 border border-slate-800 rounded-xl p-2.5">
                <div className="text-[10px] uppercase font-bold text-slate-500">Target Version</div>
                <div className="text-xs font-semibold text-slate-200 mt-0.5">
                  {selectedRepo.buildDetails?.iosTargetVersion || "iOS 16.0+"}
                </div>
              </div>

              <div className="bg-slate-950/70 border border-slate-800 rounded-xl p-2.5 col-span-2 sm:col-span-1">
                <div className="text-[10px] uppercase font-bold text-slate-500">Live Status</div>
                <div className="text-xs font-semibold text-emerald-400 flex items-center gap-1.5 mt-0.5">
                  <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                  Ready to run
                </div>
              </div>
            </div>

            {/* Tags */}
            <div className="mt-4 flex flex-wrap gap-1.5">
              {selectedRepo.buildDetails?.tags?.map((tag, idx) => (
                <span
                  key={idx}
                  className="text-[11px] px-2.5 py-0.5 rounded-lg bg-slate-800 text-slate-300 border border-slate-700/60 font-mono"
                >
                  {tag}
                </span>
              ))}
            </div>

            {/* Action Bar */}
            <div className="mt-5 pt-4 border-t border-slate-800/80 flex flex-wrap gap-2">
              <button
                onClick={() => setShowQrModal(true)}
                className="flex-1 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 active:scale-95 text-white font-semibold text-xs flex items-center justify-center gap-2 shadow-lg shadow-indigo-600/30 transition"
              >
                <Smartphone className="w-4 h-4" />
                <span>Launch On My Phone</span>
              </button>

              <a
                href={phoneLaunchUrl}
                target="_blank"
                rel="noreferrer"
                className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 active:scale-95 text-slate-200 font-medium text-xs flex items-center justify-center gap-1.5 border border-slate-700 transition"
              >
                <span>Fullscreen</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </a>
            </div>
          </div>

          {/* GitHub Account Connect / Custom User Repos Card */}
          <div className="bg-slate-900/40 border border-slate-800/60 rounded-3xl p-5 shadow-sm">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-slate-400">
                <GitBranch className="w-4 h-4 text-indigo-400" />
                Connect Your GitHub Repos
              </div>
              {githubUsername && (
                <button
                  onClick={handleResetToSamples}
                  className="text-[11px] text-indigo-400 hover:underline"
                >
                  Reset to demo repos
                </button>
              )}
            </div>

            <div className="flex gap-2">
              <input
                type="text"
                placeholder="Enter GitHub username (e.g. your-handle)..."
                value={githubUsername}
                onChange={(e) => setGithubUsername(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleFetchGithubRepos()}
                className="flex-1 bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500"
              />
              <button
                onClick={handleFetchGithubRepos}
                disabled={isLoadingRepos || !githubUsername.trim()}
                className="px-4 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 disabled:opacity-50 text-white font-semibold text-xs transition flex items-center gap-1.5 border border-slate-700"
              >
                {isLoadingRepos ? (
                  <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <span>Load</span>
                )}
              </button>
            </div>
          </div>
        </section>

        {/* Right Column: Live iOS Simulator & Runtime Harness */}
        <section className="lg:col-span-6 flex flex-col items-center justify-center">
          <div className="w-full flex items-center justify-between mb-3 px-2">
            <div className="text-xs font-bold uppercase tracking-wider text-slate-400 flex items-center gap-2">
              <Smartphone className="w-4 h-4 text-indigo-400" />
              Interactive Simulator
            </div>
            <div className="text-xs text-slate-400 flex items-center gap-2">
              <span>Try features, clicks &amp; inputs</span>
            </div>
          </div>

          <div className="w-full flex justify-center">
            <AppHarness repo={selectedRepo} />
          </div>
        </section>
      </main>

      {/* QR Code Phone Modal */}
      {showQrModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="relative">
            <button
              onClick={() => setShowQrModal(false)}
              className="absolute -top-3 -right-3 w-8 h-8 rounded-full bg-slate-800 border border-slate-700 text-slate-300 hover:text-white flex items-center justify-center shadow-lg transition"
            >
              <X className="w-4 h-4" />
            </button>
            <PhoneTesterModal appUrl={phoneLaunchUrl} repoName={selectedRepo.name} />
          </div>
        </div>
      )}
    </div>
  );
}
