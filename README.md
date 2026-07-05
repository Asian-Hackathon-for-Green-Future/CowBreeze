<div align="center">


# 🤠 CowGirls

**Smart Livestock Odor Reduction for Korean Farms**

[![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-16+-blue?logo=xcode)](https://developer.apple.com/xcode/)
[![iOS](https://img.shields.io/badge/iOS-26.0+-lightgrey?logo=apple)](https://developer.apple.com/ios/)

<img width="540" height="965" alt="Cowgirls_Poster" src="https://github.com/user-attachments/assets/8cef3ae3-3ca0-4ce2-87fc-5b1e61c5499f" />


</div>

---

## 🌾 What is CowGirls?

CowGirls is an iOS app that helps Korean livestock farmers **spray deodorizer at exactly the right moment** — only when NH₃ levels are elevated, wind is blowing toward a populated area, and wind speed is in the effective spray range.

Without smart automation, farmers spray indiscriminately. CowGirls cuts that waste by up to 35% while protecting nearby communities from odor.

---

## 🧠 How It Works

### 1. Urban Direction Detection

At farm registration, CowGirls samples **12 points** around the farm — 3 distances (1 km, 2.5 km, 4.5 km) in each of the 4 cardinal directions — and reverse-geocodes each one using Apple Maps.

> If a point returns a real administrative address (city/neighborhood level), that direction is classified as **urban**. No address = farmland or forest.

These directions are visualized as red wedges on the map when wind is blowing toward them.

### 2. Temperature-Adjusted NH₃ Threshold

NH₃ volatilizes faster at higher temperatures, so the threshold adapts:

| Temperature | NH₃ Threshold |
|------------|--------------|
| < 25°C | 11 ppm (Cool / Standard) |
| 25–35°C | 10 ppm (Warm / Higher Volatilization) |
| ≥ 35°C | 9 ppm (Hot / Extreme Risk) |

### 3. Spray Decision Table

```
[ Temperature ] → Dynamic Threshold
      ↓
[ NH₃ ≥ Threshold? ] → Yes
      ↓
[ Wind toward urban area? ] → Yes
      ↓
[ Wind speed 1.5–3.6 m/s? ] → Yes
      ↓
    ★ TRIGGER SPRAY (60 ml / 1 min)
```

| NH₃ Status | Urban Wind | Wind Speed | Action |
|-----------|-----------|-----------|--------|
| Good | — | — | No spray |
| Caution | ✗ | — | Log only |
| Caution | ✓ | < 1.5 m/s | Wait (wind unstable) |
| Caution | ✓ | 1.5–3.6 m/s | **Normal spray** |
| Caution | ✓ | > 3.6 m/s | Skip (spray ineffective) |
| Danger | ✗ | — | Internal alert + ventilate |
| Danger | ✓ | 1.5–3.6 m/s | **Heavy spray + alert** |
| Danger | ✓ | > 3.6 m/s | Skip |

---

## 🚀 Getting Started

### Requirements

- Xcode 16+ (iOS 26 SDK)
- iOS 26.0+ device or simulator
- OpenWeatherMap API key ([get one free](https://openweathermap.org/api))

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/your-username/CowGirls.git
cd CowGirls

# 2. Set up your API key
cp Config.xcconfig.example Config.xcconfig
# Open Config.xcconfig and replace YOUR_OPENWEATHERMAP_API_KEY_HERE
```

Then in Xcode:
1. Open `CowGirls.xcodeproj`
2. Select your target → **Build Settings** → set `Config.xcconfig` as the configuration file
3. Add `OWM_API_KEY` to `Info.plist` as a string: `$(OWM_API_KEY)`
4. Build & Run (⌘R) on an iOS 26 simulator

> ⚠️ **Never commit `Config.xcconfig`** — it's listed in `.gitignore`.

---

## 🏗 Architecture

```
CowGirls/
├── Models/
│   ├── Farm.swift                    # Farm, LivestockEntry
│   ├── AmmoniaMeasurement.swift      # NH₃ reading + status
│   ├── CompassDirection.swift        # N/E/S/W with bearing math
│   ├── SprayModels.swift             # DailySprayStats, RecommendedSpray, reports
│   └── SprayLog.swift                # Individual spray event record
│
├── Services/
│   ├── WeatherService.swift          # OpenWeatherMap API (10-min polling)
│   ├── UrbanDirectionDetector.swift  # Apple Maps reverse-geocoding heuristic
│   ├── SprayDecisionEngine.swift     # Decision table logic
│   ├── PDFReportService.swift        # PDF generation via UIGraphicsPDFRenderer
│   └── NotificationManager.swift    # Local push notifications with Spray/Cancel actions
│
├── State/
│   ├── AppState.swift                # Single source of truth (ObservableObject)
│   └── DummyData.swift               # Date-aware dummy data for development
│
├── Views/
│   ├── SplashView.swift              # Animated brand intro
│   ├── Onboarding/                   # Farm registration (2-step)
│   ├── Map/                          # Dashboard + spray confirm
│   ├── Report/                       # Monthly/annual stats + spray log
│   ├── Policy/                       # Government livestock notices
│   └── Settings/                     # Farm info + notification testing
│
└── Components/                       # Reusable: WeatherStrip, PinViews, ReportStatCard
```

---

## ✨ Key Features

- **🗺 Smart Map** — Real-time wind direction compass, red odor-risk wedge toward urban areas
- **🧪 NH₃ Monitoring** — Temperature-adjusted threshold; status updates as weather changes
- **💧 One-tap Spray** — Confirm card with 60 ml recommended volume; reactivates after 3 seconds
- **📊 Live Reports** — Monthly stats (sprays, volume, cost, savings) sync in real time; weekly bar chart updates per spray
- **📋 Spray Log** — Day-by-day collapsible list with NH₃ status, wind direction, volume
- **📄 PDF Export** — A4 report generated on-device, shareable via iOS Share Sheet
- **🔔 Smart Alerts** — Lock-screen notification with inline Spray / Cancel actions
- **🌍 Policy Feed** — Local government livestock news, city name detected via GPS

---

## 🔑 API Keys & Secrets

| Key | Where to get it | How to add |
|-----|----------------|-----------|
| `OWM_API_KEY` | [openweathermap.org](https://openweathermap.org/api) | `Config.xcconfig` |

Apple Maps (MapKit) and reverse geocoding require no key — they use the app's bundle ID with Apple's servers.

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first.

---

## 📄 License

© 2026 CowGirls Team

---

<div align="center">
Made with 🤠 for Korean farmers
</div>
