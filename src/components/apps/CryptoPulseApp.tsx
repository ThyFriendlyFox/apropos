"use client";

import React, { useState, useEffect } from "react";
import { TrendingUp, TrendingDown, ArrowUpRight, ArrowDownRight, RefreshCw, Zap, Bell, ShieldCheck } from "lucide-react";

interface CryptoAsset {
  symbol: string;
  name: string;
  price: number;
  change24h: number;
  holdings: number;
  history: number[];
}

export default function CryptoPulseApp() {
  const [assets, setAssets] = useState<CryptoAsset[]>([
    {
      symbol: "BTC",
      name: "Bitcoin",
      price: 88420.50,
      change24h: 3.42,
      holdings: 0.45,
      history: [84200, 85600, 85100, 86900, 87400, 88420.50]
    },
    {
      symbol: "ETH",
      name: "Ethereum",
      price: 3420.80,
      change24h: -1.15,
      holdings: 4.2,
      history: [3510, 3490, 3440, 3480, 3410, 3420.80]
    },
    {
      symbol: "SOL",
      name: "Solana",
      price: 198.40,
      change24h: 7.85,
      holdings: 28.5,
      history: [181, 184, 189, 192, 195, 198.40]
    },
    {
      symbol: "AVAX",
      name: "Avalanche",
      price: 38.25,
      change24h: 2.10,
      holdings: 75.0,
      history: [36.8, 37.1, 37.5, 37.9, 38.0, 38.25]
    }
  ]);

  const [selectedAsset, setSelectedAsset] = useState<CryptoAsset>(assets[0]);
  const [tradeAction, setTradeAction] = useState<"buy" | "sell" | null>(null);

  // Simulate live ticker updates
  useEffect(() => {
    const interval = setInterval(() => {
      setAssets((prev) =>
        prev.map((item) => {
          const delta = (Math.random() - 0.48) * (item.price * 0.003);
          const newPrice = Math.round((item.price + delta) * 100) / 100;
          return {
            ...item,
            price: newPrice,
            history: [...item.history.slice(1), newPrice]
          };
        })
      );
    }, 2500);
    return () => clearInterval(interval);
  }, []);

  const totalPortfolioValue = assets.reduce((sum, item) => sum + item.price * item.holdings, 0);

  return (
    <div className="flex flex-col h-full bg-slate-950 text-slate-100 p-4 font-sans select-none overflow-y-auto">
      {/* Header */}
      <div className="flex items-center justify-between pb-3 border-b border-slate-800">
        <div>
          <div className="text-[11px] font-semibold text-emerald-400 uppercase tracking-wider flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
            Expo EAS Mobile Client
          </div>
          <h1 className="text-xl font-bold tracking-tight text-white">CryptoPulse</h1>
        </div>
        <div className="bg-slate-900 border border-slate-800 px-2.5 py-1 rounded-full text-xs text-slate-400 flex items-center gap-1">
          <Zap className="w-3 h-3 text-amber-400 fill-amber-400" />
          <span>Live Ticker</span>
        </div>
      </div>

      {/* Total Balance Card */}
      <div className="mt-4 p-4 rounded-2xl bg-gradient-to-br from-slate-900 to-slate-900/90 border border-slate-800 relative overflow-hidden shadow-lg">
        <div className="text-xs text-slate-400 font-medium">Total Balance</div>
        <div className="text-3xl font-bold text-white mt-1 tracking-tight">
          ${totalPortfolioValue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
        </div>
        <div className="flex items-center gap-1.5 text-xs text-emerald-400 mt-1.5 font-medium">
          <TrendingUp className="w-3.5 h-3.5" />
          <span>+$1,428.30 (+3.65%) Today</span>
        </div>

        <div className="grid grid-cols-2 gap-2 mt-4">
          <button 
            onClick={() => setTradeAction("buy")}
            className="py-2.5 rounded-xl bg-emerald-500 hover:bg-emerald-600 active:scale-95 text-slate-950 font-bold text-xs flex items-center justify-center gap-1.5 transition shadow-md shadow-emerald-500/20"
          >
            <ArrowDownRight className="w-4 h-4" /> Deposit / Buy
          </button>
          <button 
            onClick={() => setTradeAction("sell")}
            className="py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 active:scale-95 text-slate-200 font-semibold text-xs flex items-center justify-center gap-1.5 border border-slate-700 transition"
          >
            <ArrowUpRight className="w-4 h-4" /> Withdraw / Send
          </button>
        </div>
      </div>

      {/* Watchlist */}
      <div className="mt-4 flex-1">
        <div className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
          Your Assets ({assets.length})
        </div>

        <div className="space-y-2">
          {assets.map((asset) => {
            const isPositive = asset.change24h >= 0;
            const holdingVal = asset.price * asset.holdings;
            return (
              <div
                key={asset.symbol}
                onClick={() => setSelectedAsset(asset)}
                className={`p-3 rounded-xl border transition flex items-center justify-between cursor-pointer ${
                  selectedAsset.symbol === asset.symbol
                    ? "bg-slate-900 border-emerald-500/50 shadow-sm"
                    : "bg-slate-900/50 border-slate-800/80 hover:bg-slate-900"
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-slate-800 flex items-center justify-center font-bold text-sm text-emerald-400 border border-slate-700">
                    {asset.symbol.slice(0, 3)}
                  </div>
                  <div>
                    <div className="text-sm font-semibold text-white">{asset.name}</div>
                    <div className="text-xs text-slate-400">
                      {asset.holdings} {asset.symbol}
                    </div>
                  </div>
                </div>

                <div className="text-right">
                  <div className="text-sm font-mono font-semibold text-white">
                    ${asset.price.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                  </div>
                  <div
                    className={`text-xs font-medium flex items-center justify-end gap-0.5 ${
                      isPositive ? "text-emerald-400" : "text-rose-400"
                    }`}
                  >
                    {isPositive ? "+" : ""}
                    {asset.change24h}%
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Mini Trade Modal / Notification */}
      {tradeAction && (
        <div className="mt-3 p-3 rounded-xl bg-emerald-950/80 border border-emerald-700 text-xs text-emerald-200 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-4 h-4 text-emerald-400" />
            <span>Simulated {tradeAction.toUpperCase()} order on {selectedAsset.symbol}</span>
          </div>
          <button 
            onClick={() => setTradeAction(null)}
            className="text-[11px] font-bold bg-emerald-800 px-2 py-0.5 rounded text-white"
          >
            Done
          </button>
        </div>
      )}
    </div>
  );
}
