# Tauber Defence architecture

## Core boundary

Tauber Defence deliberately separates deterministic game rules from rendering:

```text
SwiftUI HUD and input
        ↓ player commands
GameViewModel (@MainActor)
        ↓
TauberDefenceCore.GameSimulation
        ↓ immutable snapshots
RealityKit renderer
```

`ios/TauberDefenceIOS/Sources/TauberDefenceCore` owns level and wave definitions, pigeons,
defences, economy, movement, targeting, pressure, spawning, cleanliness, victory, and defeat. The
core imports Foundation and uses plain value types. It does not import SwiftUI, UIKit, or
RealityKit.

`ios/TauberDefenceIOS/App` owns the SwiftUI lifecycle, landscape HUD, touch handling, RealityKit
entities, animation, procedural audio, haptics, accessibility, and presentation-only meme text.
RealityKit entities mirror simulation identifiers and state; they never become the authoritative
game model.

This boundary keeps movement and tower behavior testable without an iOS simulator and leaves room
for future save-game serialization without extracting state from a scene graph.

## Update model

The app advances `GameSimulation` with an elapsed-time delta. The simulation clamps invalid time,
processes deterministic systems, and publishes a new `GameSession` snapshot. Runtime events such as
pressure hits, fleeing pigeons, rewards, and target arrivals are consumed by the app for feedback.

Tests should call the same public commands and `update(deltaTime:)` method used by the app. They
must not wait on wall-clock timers. The UI runner uninstalls the app before an attempt so tests start
from fresh state; UI tests use explicit accessibility identifiers for the HUD, build spots, tower
choices, wave control, pigeon selection, and game-over actions.

## Playable beta scope

The beta contains one marketplace, one fixed waypoint path, eight fixed build spots, nine defence
types, and eight pigeon types. Classic mode has five waves; experimental field trials has six.
The main menu and field guide expose all prototypes without progression locks. Cosmetic XP,
rank, wins, and best wave are saved locally. It does not contain pathfinding, upgrades, multiple maps, accounts, cloud saves,
analytics, ads, in-app purchases, or multiplayer.

Tauber Defence requires iOS 18 because it uses SwiftUI's iOS `RealityView`. The generated Xcode
project comes from `ios/TauberDefenceIOS/project.yml`; the `.xcodeproj` is build output and must not
be edited as source.

## Privacy boundary

The current app has no account, backend, analytics, advertising, or tracking integration. Audio and
haptic feedback are generated locally. Progress uses app-local UserDefaults with required-reason
code `CA92.1`. The checked-in privacy manifest must stay aligned with the
APIs and SDKs shipped in each release. The public policy lives at
`https://tauber-defence.malaber.de/privacy/` and must be updated before behavior changes.
