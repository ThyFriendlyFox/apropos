"use client";

import React, { useState } from "react";
import { QRCodeSVG } from "qrcode.react";
import { Smartphone, Copy, Check, ExternalLink, QrCode } from "lucide-react";

interface PhoneTesterModalProps {
  appUrl: string;
  repoName: string;
}

export default function PhoneTesterModal({ appUrl, repoName }: PhoneTesterModalProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(appUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 shadow-2xl flex flex-col items-center text-center max-w-sm w-full">
      <div className="w-12 h-12 rounded-2xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 flex items-center justify-center mb-4">
        <Smartphone className="w-6 h-6" />
      </div>

      <h3 className="text-lg font-bold text-white tracking-tight">
        Open On Your Phone
      </h3>
      <p className="text-xs text-slate-400 mt-1 leading-relaxed">
        Point your iPhone camera at this QR code to launch and test <span className="text-white font-semibold">{repoName}</span> instantly in Safari or add to Home Screen.
      </p>

      {/* QR Code Container with high contrast border */}
      <div className="mt-5 p-4 bg-white rounded-2xl shadow-md flex items-center justify-center">
        <QRCodeSVG
          value={appUrl}
          size={180}
          level="M"
          includeMargin={false}
        />
      </div>

      {/* Direct link copy */}
      <div className="mt-5 w-full flex items-center gap-2">
        <input
          type="text"
          readOnly
          value={appUrl}
          className="flex-1 bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-xs text-slate-300 font-mono focus:outline-none"
        />
        <button
          onClick={handleCopy}
          className="px-3 py-2 bg-indigo-600 hover:bg-indigo-500 active:scale-95 text-white text-xs font-semibold rounded-xl flex items-center gap-1.5 transition shadow-md shadow-indigo-600/30"
          title="Copy Link"
        >
          {copied ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
          <span>{copied ? "Copied" : "Copy"}</span>
        </button>
      </div>

      <div className="mt-4 pt-3 border-t border-slate-800/80 w-full text-[11px] text-slate-400 flex items-center justify-center gap-2">
        <span>Safari Share → &quot;Add to Home Screen&quot; for standalone iOS app icon</span>
      </div>
    </div>
  );
}
