# Experimental beta: 0.0.1 (2)

The first physical-device feedback approved a broad prototype pass. All options remain unlocked;
balance and visual polish are intentionally provisional, not App Store release claims.

## Input and camera

Build spots are now actual, accessible 44-point SwiftUI buttons projected through the same
orthographic camera state as RealityKit. They are the visible yellow markers, not invisible
automation shortcuts. Occupied markers disappear. The debug-only placement strip was removed.
Camera controls support pinch zoom (0.7–2.4×), two-finger rotation, one-finger orbit, and buttons
for zoom, rotation, and returning to the original view. Tests purchase through these real markers.

## Modes and progress

- The main menu shows rank, XP, wins, best completed wave, and pigeons shooed.
- Classic marketplace preserves the original five-wave roster and €300 starting budget.
- Field trials starts with €1,200 and six mixed waves covering all eight pigeon types.
- All nine deterrents are available in both modes; swipe the build catalog to browse them.
- The field guide describes every unit, its mechanics, and prototype stats in German and English.
- A finished or abandoned started run earns 5 XP per fled pigeon, 25 per completed wave, and 150
  for victory. Each 250 XP adds a cosmetic rank. Returning to the menu or restarting records the
  run once. Unfinished battles are not resumed after process termination; force-quitting before
  recording a run loses that run's XP, but earlier recorded progress remains.
- Progress uses one versioned app-local UserDefaults record. The required-reason privacy manifest
  declares `CA92.1`; the public privacy page describes local progress. No network service added.

## New pigeon mechanics

| Pigeon | Tolerance / speed | Trait |
| --- | --- | --- |
| Dieter | 280 / 0.55 | Slow tank |
| Sabine | 55 / 1.8 | Fast scout |
| Volker | 160 / 0.85 | Repeated pressure category is 45% weaker |
| Ingo | 140 / 0.9 | Nearby allies receive 20% less pressure |
| Gurrmann | 400 / 0.6 | Nearby group takes half pressure for 2.2 of every 6 seconds |
| Crumb Coalition | 70 / 1.15 | Takes 30% less pressure near another coalition pigeon |

Group effects have a 2.5-unit radius. Disruption disables an affected pigeon's group protection and
prevents it from providing protection. It does not erase Volker's adaptation. Shields never grant
complete immunity. Distinct sizes and primitive accessories identify prototypes without adding
third-party artwork or dependencies.

## New deterrents

| Tool | Cost | Effect |
| --- | --- | --- |
| Window CD | €60 | 14 single-target visual pressure every 0.85 seconds |
| Alarm tape | €120 | 6 area pressure; 2.2-second group disruption |
| Broom officer | €220 | 38 close-range area pressure; 1.5-second disruption |
| Balcony speaker | €180 | 18 area pressure; 1-second disruption; repeated sound ×0.7, alternating category ×1.3 |
| Form launcher | €140 | 2 single-target pressure; 50% slow |
| Premium crumb decoy | €90 | Area 65% slow with no pressure; no path rerouting |

Slow lasts 1.5 seconds. Slows do not stack; a weaker effect cannot overwrite or extend a stronger
active effect. Original owl, sprinkler, falconer, and arrival haptics remain available.

## Verification checklist

- [x] Simulator application build succeeds.
- [x] 36 core tests pass; 96.17% measured line coverage with Xcode 27.
- [ ] Full iPhone E2E, real marker purchases, pinch/rotation, menu, XP persistence, and screenshots.
- [ ] Same full iPad matrix.
- [ ] Current-main CI passes.
- [ ] Clean, pushed local archive accepted by Apple.
- [ ] Physical-phone placement, camera alignment, readability, and gameplay smoke test.

Apple upload success is the delivery stopping point. No TestFlight processing polling is required.
