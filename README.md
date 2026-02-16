# 🎾 Padel Scorer PWA

A progressive web app for point-by-point padel match scoring. Works offline, installable on iPhone home screen.

## Features
- **Point-by-point scoring** — standard padel rules (0/15/30/40, deuce, advantage)
- **Best of 3 sets** with tiebreak at 6-6
- **Touch input** — large Us / Them buttons
- **Voice commands** — say "us", "them", "nuestro", or "suyo"
- **Point history** — scrollable log of all points
- **Undo** — revert the last point
- **Works offline** — service worker caches everything

## How to Use

### Option 1: Serve locally
```bash
cd projects/padel-scorer
python3 -m http.server 8080
```
Open `http://localhost:8080` on your phone.

### Option 2: Deploy anywhere
Upload `index.html`, `manifest.json`, and `sw.js` to any static host (GitHub Pages, Netlify, etc.)

### Add to Home Screen (iPhone)
1. Open the URL in Safari
2. Tap the Share button (⬆)
3. Tap "Add to Home Screen"
4. The app runs full-screen, no browser chrome

## Tech
- Single HTML file, zero dependencies
- PWA manifest + service worker for offline/install
- Web Speech API for voice (Safari/Chrome)
- Mobile-first, dark theme, large touch targets
