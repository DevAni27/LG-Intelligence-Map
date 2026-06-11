# Global Pulse — AI-Powered World Intelligence Map

A Flutter-based Liquid Galaxy controller app that visualizes real-world global events (earthquakes, disasters, disease outbreaks) as 3D KML markers on a multi-screen LG rig, with AI-powered explanations via Gemini.

**GESOC 2026 · Liquid Galaxy**

## Features

- **Real-time data pipeline** — Fetches live events from USGS, NASA EONET, WHO, and GDELT
- **3D KML visualization** — Category-colored extruded markers on the LG rig
- **Flutter controller app** — Interactive map, dashboard, category filters, Fly-To navigation
- **AI insights** — Natural language queries and event summaries powered by Gemini Flash
- **Voice briefings** — Daily Global Pulse 60-second audio summary
- **Multilingual** — On-device translation via Google ML Kit
- **Historical playback** — Replay past events with timeline controls

## Architecture

```
Flutter App → Fetches APIs → Normalizes Data → Stores in Hive
           → Generates KML → Sends to LG via SSH
           → Calls Gemini API for AI features
```

No separate backend. Everything runs in the Flutter app.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.x |
| State Management | BLoC |
| Map | flutter_map + OpenStreetMap |
| AI | Gemini Flash API |
| LG Communication | dartssh2 (SSH/SFTP) |
| KML | xml package |
| Local Storage | Hive |
| Voice | flutter_tts |
| Translation | Google ML Kit |

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Android Studio / VS Code
- Liquid Galaxy rig (physical or VirtualBox VMs)

### Installation

```bash
git clone https://github.com/YOUR_USERNAME/global_pulse.git
cd global_pulse
flutter pub get
dart run build_runner build
flutter run
```

### LG Rig Connection

1. Open the app → Settings tab
2. Enter the LG master IP, port (22), username, and password
3. Tap Connect
4. Go to Map tab → Fly to View on LG

## Project Structure

```
lib/
├── core/          Constants, theme, utilities
├── data/          Models, API services, repositories
├── logic/         BLoC state management
├── presentation/  Screens and widgets
└── services/      SSH, KML, Gemini, TTS services
```

## Data Sources

| Source | Data | Auth | Format |
|--------|------|------|--------|
| USGS | Earthquakes | None | GeoJSON |
| NASA EONET | Natural disasters | None | JSON |
| WHO | Disease outbreaks | None | RSS/XML |
| GDELT | Global events | None | JSON |

## License

This project is part of the Liquid Galaxy GESOC 2026 program.
