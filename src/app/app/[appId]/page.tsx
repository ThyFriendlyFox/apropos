"use client";

import React, { use } from "react";
import { SAMPLE_REPOS } from "@/data/sampleRepos";
import AppHarness from "@/components/AppHarness";
import Link from "next/link";
import { ChevronLeft, Layers, Smartphone } from "lucide-react";

interface AppRunnerPageProps {
  params: Promise<{ appId: string }>;
}

export default function AppRunnerPage({ params }: AppRunnerPageProps) {
  const resolvedParams = use(params);
  const appId = resolvedParams.appId;
  const repo = SAMPLE_REPOS.find((r) => r.id === appId) || SAMPLE_REPOS[0];

  return (
    <div className="w-full min-h-screen bg-black flex flex-col items-center justify-center">
      {/* Floating back button for easy navigation when tested on phone or desktop */}
      <div className="fixed top-3 left-3 z-50">
        <Link
          href="/"
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-slate-900/80 border border-slate-700/60 backdrop-blur-md text-slate-300 text-xs font-semibold hover:text-white transition shadow-lg"
        >
          <ChevronLeft className="w-4 h-4" />
          <span>Launcher</span>
        </Link>
      </div>

      <AppHarness repo={repo} fullScreenMobile={true} />
    </div>
  );
}
