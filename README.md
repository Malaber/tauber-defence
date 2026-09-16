# Tauber Defence

A witty, nonviolent 2.5D tower-defence game for iPhone and iPad. A low-poly town meets deliberately
flat pigeons: deterrents apply pressure, pigeons lose their nerve, and fly away. No pigeon is harmed.

## Playable beta

- One marketplace, a fixed route, a café destination, and eight build spots.
- Classic mode: five waves ending with Rüdiger. Field trials: six mixed experimental waves.
- Eight pigeon types and nine deterrents with different costs, effects, and counters.
- Native build-marker buttons, pinch zoom, twist/drag rotation, and accessible camera controls.
- Main menu, field guide, locally saved XP, cosmetic ranks, wins, and best wave.
- German and English UI from one translation catalog; code and documentation in English.
- SwiftUI + RealityKit presentation over a deterministic, platform-neutral Swift simulation.
- Core coverage gate, real-control iPhone/iPad E2E, marketing screenshots, and local TestFlight upload.

Prototype mechanics and verification status: [experimental beta](docs/experimental-beta.md).
Long-term scope and acceptance checklist: [implementation plan](docs/implementation-plan.md).

## Requirements

- A compatible Xcode installation: local delivery on macOS 27 uses Xcode 27.
- XcodeGen 2.38 or newer; Swift 6; iOS 18 or newer.

```bash
cd ios/TauberDefenceIOS
swift test
xcodegen generate
open TauberDefenceApp.xcodeproj
```

Choose the `TauberDefence` scheme and an iPhone or iPad in landscape orientation.

## Architecture

`TauberDefenceCore` owns game state. `GameViewModel` consumes events, updates local progression,
and publishes snapshots. `GameRenderer` projects those snapshots into RealityKit entities.
Rendering never decides movement, targeting, pressure, economy, or wave progression.

## Tests and delivery

See [delivery](docs/delivery.md), [localization](docs/localization.md), and
[App Store Connect setup](docs/app-store-connect-setup.md).

```bash
.venv/bin/inv check                  # Core coverage + iPhone/iPad E2E
.venv/bin/inv app-store-screenshots  # Seven motifs per device family
.venv/bin/inv upload-testflight --marketing-version=0.0.2 --build-number=2
```

Uploads run locally from clean, committed, pushed `main`. Apple's successful-upload response
completes delivery; no processing polling is required. Automatic GitHub uploads remain opt-in.

## Website

Product, support, and privacy pages live in [website/](website/) and deploy from `main` through
GitHub Pages at [tauber-defence.malaber.de](https://tauber-defence.malaber.de/).
