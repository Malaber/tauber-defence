# Tauber Defence

Humoristisches 2.5D-Tower-Defense-Spiel für iPhone und iPad. Eine kleine Low-Poly-Stadt trifft auf absichtlich flache 2D-Tauben: Abwehranlagen erzeugen **Pressure**, die Tauben verlieren ihre **Nerven** und fliegen davon. Keine Taube wird verletzt.

## Vertical Slice

- Ein isometrischer Marktplatz mit fester Route, Café-Ziel und acht Bauplätzen
- Fünf datengetriebene Wellen: 5, 10, 15 und 20 Stadttauben, dann Rüdiger
- Plastik-Uhu, Rasensprenger und Falkner mit eigenen Kosten, Reichweiten und Angriffen
- Nerven-/Pressure-System, Fluchtanimationen, Belohnungen, Sauberkeit, Sieg und Niederlage
- Native SwiftUI-Oberfläche und RealityKit-Szene
- Deterministische, von Rendering getrennte Swift-Simulation
- Originale Tauben-Sprites und eigenes App-Icon
- Unit- und UI-Tests, GitHub Actions, TestFlight-Automation und Compliance-Webseite

## Voraussetzungen

- Xcode 26 oder neuer
- XcodeGen 2.38 oder neuer
- iOS 18 oder neuer

## Starten

```bash
cd ios/TauberDefenceIOS
swift test
xcodegen generate
open TauberDefenceApp.xcodeproj
```

Scheme `TauberDefence` wählen und auf einem iPhone- oder iPad-Simulator im Querformat starten.

## Architektur

```text
TauberDefenceCore (Foundation)
  GameSimulation → GameSession + GameEvent
                         ↓
SwiftUI GameViewModel → RealityKit GameRenderer
```

`TauberDefenceCore` besitzt sämtliche Spielwahrheit. RealityKit gleicht Entities ausschließlich mit Session-Snapshots ab. Dadurch bleiben Bewegung, Targeting, Pressure, Wirtschaft und Wellen ohne Grafik deterministisch testbar.

## Automatisierung

Lokale Befehle und benötigte App-Store-Connect-Secrets stehen in [docs/delivery.md](docs/delivery.md) und [docs/app-store-connect-setup.md](docs/app-store-connect-setup.md). Pushes und Pull Requests durchlaufen Core- und iOS-Checks. Erfolgreiche `main`-Builds können nach expliziter Freischaltung automatisch an TestFlight gehen.

Der aktuelle Stand, offene Release-Blocker und die vollständigen TestFlight-Abnahmekriterien stehen im [lebenden Implementierungsplan](docs/implementation-plan.md).

```bash
.venv/bin/inv check                  # Core + iPhone/iPad E2E
.venv/bin/inv app-store-screenshots  # 5 Motive je Gerätefamilie
```

## Webseite

Statische Produkt-, Support- und Datenschutzseiten liegen in [`website/`](website/) und werden über GitHub Pages veröffentlicht.
