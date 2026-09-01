# iOS Repo Runner

A web and mobile application launcher that lets you select any repository with an iOS build from a dropdown menu and run/test it directly on your phone or in an interactive iOS device simulator.

## Features

- **Dropdown Repository Selector**: Browse all connected repositories, automatically filtered for those with detected iOS targets (Swift / Xcode, Expo EAS, React Native, Flutter, Capacitor / Ionic).
- **Interactive iOS Device Simulator**: Realistic iPhone 16 Pro simulator frame with Dynamic Island, status bar, and real live playable apps.
- **Instant Phone Testing (QR Code)**: One-click QR code scanner to test the app live in Safari or add to your iPhone Home Screen as a standalone PWA.
- **Live Interactive Applications Included**:
  - `zen-focus-ios`: SwiftUI Pomodoro focus timer with circular progress and soundscapes.
  - `crypto-pulse-mobile`: Expo React Native real-time crypto portfolio tracker with live ticker.
  - `streakly-habit-tracker`: React Native habit tracker with streak grids and animations.
  - `retro-lens-camera`: Flutter vintage film camera simulator with grain shaders.
  - `obsidian-mini-notes`: Capacitor markdown notes editor with live search.
  - `dynamic-weather-island`: SwiftUI weather app with Dynamic Island precipitation radar.
- **GitHub Integration**: Connect any GitHub user handle to inspect repositories and auto-detect iOS build files.

## Running Locally

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser or scan the QR code from your iPhone connected to your local network.
