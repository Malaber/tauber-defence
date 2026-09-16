# Tauber Defence implementation plan

Living checklist for the playable TestFlight builds. Update it whenever evidence changes.
The original MVP phases below retain their 0.0.1 evidence; the current iteration tracks 0.0.2.

## How to use this plan

- `[x]` means implementation or verification is evidenced in the repository or retained test output.
- `[ ]` means unfinished, unverified, or dependent on external Apple/GitHub/DNS setup.
- Simulator success does not replace physical-device testing.
- Scope stays one polished marketplace level. Post-MVP ideas must not block the first TestFlight build.

## Current status

- [x] Native SwiftUI + RealityKit vertical slice exists for iPhone and iPad.
- [x] Deterministic game core, five waves, three defences, economy, victory, defeat, and Rüdiger exist.
- [x] Core unit suite contains 36 tests with 96.17% local line coverage and clears the 90% gate.
- [x] Generic iOS Simulator build has succeeded with signing disabled.
- [x] Comprehensive XCUITest flows, deterministic fixtures, retry tooling, and marketing screenshot capture are implemented.
- [x] Make the complete iPhone XCUITest run green and retain its passing artifacts.
- [x] Make the complete iPad XCUITest run green and retain its passing artifacts.
- [x] Public compliance website is deployed through GitHub Pages; custom domain, DNS, HTTPS, `/`, `/support/`, and `/privacy/` return successfully.
- [x] Approved contact-address commit is live; `/capabilities/` and deployed support/privacy addresses are verified.
- [x] Upload first playable `0.0.1 (1)` locally; Apple accepted it and the user tested it on a physical phone.
- [ ] Pass physical-device beta acceptance on one supported iPhone and one supported iPad.

## Phase 1 — Project foundation

- [x] Create native iOS app with SwiftUI lifecycle.
- [x] Use RealityKit `RealityView` for the game world.
- [x] Keep game logic in the platform-neutral `TauberDefenceCore` Swift package.
- [x] Generate the Xcode project from `ios/TauberDefenceIOS/project.yml` with XcodeGen.
- [x] Target iOS 18+, iPhone and iPad.
- [x] Restrict gameplay to landscape orientations.
- [x] Configure bundle identifier `de.malaber.tauber-defence` and team `VWKG94374J`.
- [x] Configure version `0.0.1`, build `1`, Games category, and no non-exempt encryption.
- [x] Add privacy manifest.
- [x] Add original production app icon based on the supplied artwork.
- [x] Document architecture, local delivery, and App Store Connect setup.
- [ ] Confirm minimum OS and Xcode requirements on the intended oldest physical devices.

## Phase 2 — MVP simulation and gameplay

### Level and route

- [x] Implement exactly one level: `Marktplatz`.
- [x] Add one spawn, one fixed waypoint route, and one café destination.
- [x] Add eight fixed build spots.
- [x] Use waypoint interpolation; no A*, navigation mesh, or dynamic pathfinding.
- [x] Add five data-driven waves: 5, 10, 15, 20 Stadttauben, then Rüdiger.

### Pigeons and pressure

- [x] Implement Stadttaube stats: 100 tolerance, speed 1.0, reward €10.
- [x] Implement Rüdiger stats: 1,000 tolerance, speed 0.7, reward €500.
- [x] Implement pigeon states: spawning, moving, alert, panicking, fleeing, reached target, removed.
- [x] Convert defence pressure into reduced tolerance.
- [x] Enter alert/panic states at lower tolerance thresholds.
- [x] Make zero-tolerance pigeons flee instead of die.
- [x] Animate fleeing height and remove escaped pigeons after the flee duration.
- [x] Reward the player for fleeing pigeons.
- [x] Reduce cleanliness when pigeons reach the café.
- [x] Trigger defeat at zero cleanliness.
- [x] Trigger victory after the final wave resolves.

### Defences and economy

- [x] Implement Plastik-Uhu: €100, single target, 25 pressure.
- [x] Implement Rasensprenger: €150, area target, 10 pressure, 20% slow.
- [x] Implement Falkner: €300, single target, 70 pressure, delayed impact.
- [x] Auto-target eligible pigeons in range.
- [x] Enforce attack cooldowns.
- [x] Buy only on valid unoccupied build spots.
- [x] Reject occupied, invalid, unaffordable, or post-game purchases.
- [x] Deduct purchase cost and publish economy events.
- [x] Support pause, resume, and complete session reset.
- [ ] Play-balance money, range, pressure, cooldowns, spawn intervals, and cleanliness on physical devices.
- [ ] Confirm all five production waves are beatable without one mandatory tower pattern.

## Phase 3 — Rendering, controls, and game feel

### World and camera

- [x] Render a stylized low-poly marketplace from RealityKit primitives.
- [x] Include roads/ground, houses, café, fountain, statue, trees, benches, and bins.
- [x] Use a fixed isometric orthographic camera.
- [x] Keep RealityKit entities as projections of simulation state, never game-state authority.
- [x] Render build spots and placed defences.
- [ ] Audit scene readability on small iPhone screens and large iPads.
- [ ] Profile frame time with the busiest production wave on physical hardware.
- [ ] Remove any entity, material, or audio allocation spikes visible during play.

### Pigeons and attacks

- [x] Render original 2D normal and Rüdiger sprites as camera-facing billboards.
- [x] Render ground shadows beneath pigeons.
- [x] Shrink/separate shadows while pigeons flee upward.
- [x] Render tolerance bars without lethal/HP framing.
- [x] Add idle bob, wobble, panic, and flee presentation.
- [x] Render distinct placeholder visuals for Uhu, sprinkler, and falconer attacks.
- [x] Show selected pigeon details and current tolerance/status.
- [ ] Polish water, falcon, impact, coin, and group-flee effects to release quality.
- [ ] Verify 20 simultaneous pigeons plus effects remain readable and performant.

### HUD and interaction

- [x] Show budget, wave, and cleanliness in the landscape HUD.
- [x] Let players select fixed build spots and purchase each defence.
- [x] Provide wave start, pause/resume, restart, help, victory, and defeat UI.
- [x] Show insufficient-funds and important event feedback.
- [x] Show boss warning text and meme-flavoured status text.
- [x] Emit combo feedback when several pigeons flee in one simulation step.
- [x] Keep all user-facing German and English copy in one bundled translation catalog.
- [x] Select German by default, follow the device language, and fall back safely to German.
- [x] Verify German/English key and placeholder parity in the core test suite.
- [x] Smoke-test the English first-launch and victory flows with XCUITest.
- [ ] Add or tune floating reward text and group-flee spectacle for the intended comedic payoff.
- [ ] Conduct a complete German copy pass for consistency, spelling, and tone.

### Audio and haptics

- [x] Generate local procedural tones for towers, panic, rewards, waves, victory, and defeat.
- [x] Add event-driven haptic feedback.
- [x] Use an ambient audio session that respects other audio.
- [ ] Add/tune original pigeon coos without overlapping sound spam.
- [ ] Cap simultaneous pigeon sounds and verify no clipping or harsh repetition.
- [ ] Verify silent mode, Bluetooth/headphones, interruptions, and background/foreground transitions.

## Phase 4 — Accessibility and device QA

- [x] Add accessibility identifiers for deterministic automation.
- [x] Add basic labels to HUD controls, build choices, menus, and game state.
- [ ] Complete VoiceOver gameplay on physical iPhone.
- [ ] Complete VoiceOver gameplay on physical iPad.
- [ ] Ensure build spots and pigeons expose meaningful, navigable VoiceOver actions.
- [ ] Verify Dynamic Type at accessibility sizes without clipped critical controls.
- [ ] Add and verify Reduce Motion behavior for bob, wobble, fleeing, transitions, and effects.
- [ ] Verify sufficient contrast without relying only on colour for tolerance/cleanliness/status.
- [ ] Verify touch targets are at least 44×44 points for all production controls.
- [ ] Verify left/right landscape rotation, safe areas, camera cutouts, and Stage Manager layouts.
- [ ] Verify pause/resume across app backgrounding, interruption, and screen lock.
- [ ] Verify a fresh install launches without network access or account setup.
- [ ] Run a 20-minute thermal, memory, audio, and battery smoke test on physical devices.

## Phase 5 — Automated tests and App Store screenshots

### Core tests

- [x] Test movement and waypoint interpolation.
- [x] Test spawning and wave completion.
- [x] Test pressure, tolerance transitions, fleeing, and removal.
- [x] Test each defence's targeting and effects.
- [x] Test economy and invalid purchases.
- [x] Test arrival, cleanliness, victory, defeat, reset, pause, and Rüdiger.
- [x] Enforce at least 90% `TauberDefenceCore` line coverage.
- [x] Keep the coverage gate green after every gameplay change.

### End-to-end gameplay

- [x] Add debug-only deterministic launch fixtures: default, battle, boss, victory, defeat.
- [x] Test initial HUD and playable economy.
- [x] Test purchase of Plastik-Uhu, Rasensprenger, and Falkner.
- [x] Test insufficient funds preserve the budget and show feedback.
- [x] Test wave start, pause, and resume.
- [x] Test a prebuilt live battle.
- [x] Test Rüdiger presentation.
- [x] Test victory, restart, and defeat flows.
- [x] Build once, run tests serially, retry named failures, and retain logs/xcresult.
- [x] Pass the complete iPhone XCUITest suite from a clean simulator and retain its evidence.
- [x] Pass the complete iPad suite from a clean simulator.
- [x] Pass both device jobs on release commit `2e3d5ba` (CI run `35103780130`).

### Marketing screenshots

- [x] Capture deterministic full-resolution screenshots from XCUITest.
- [x] Define five motifs: marketplace, battle, Rüdiger, victory, defeat.
- [x] Normalize status bar time/battery for repeatable captures.
- [x] Generate a dimensions manifest and preserve source xcresult.
- [x] Produce and visually inspect all five iPhone landscape PNGs from the release candidate.
- [x] Produce and visually inspect all five iPad landscape PNGs from the release candidate.
- [ ] Confirm final pixel dimensions and device classes are accepted by App Store Connect.
- [ ] Select final gallery ordering and add localized captions only if part of store creative.
- [ ] Archive final screenshot source build/commit and untouched PNGs.

## Phase 6 — Compliance website and public support

- [x] Build product landing page.
- [x] Build feature/capabilities page.
- [x] Build support page.
- [x] Build privacy policy page describing no tracking, accounts, backend, or collected data.
- [x] Add app icon, original artwork, social preview, favicon, sitemap, robots, and CNAME.
- [x] Configure static export and GitHub Pages workflow on `main`.
- [x] Ensure all support addresses use the approved `*tauber-defence@schaedler.rocks` scheme.
- [x] Push approved contact content to `main` in commit `760328c`.
- [x] Confirm Pages run `35029396134` successfully deployed commit `760328c`.
- [x] Configure `tauber-defence.malaber.de` in repository Pages settings.
- [x] Configure DNS CNAME to `malaber.github.io`.
- [x] Enable and verify HTTPS.
- [x] Verify `/`, `/support/`, and `/privacy/` publicly with HTTPS 200 responses.
- [x] Verify `/capabilities/` publicly with HTTPS 200 and confirm deployed contact addresses match commit `760328c`.
- [x] Verify canonical metadata, sitemap, robots, CNAME, and in-app links all use the same public host.
- [ ] Re-check privacy copy against the exact release binary and third-party SDK inventory.

## Phase 7 — CI, signing, and release engineering

### Continuous integration

- [x] Run Swift core tests and coverage on pushes, pull requests, and manual dispatch.
- [x] Run iPhone and iPad XCUITest matrix on macOS runners.
- [x] Retain coverage, logs, xcresult, and screenshot artifacts.
- [x] Cancel superseded CI runs per event/ref.
- [x] Publish website changes from `main` through GitHub Pages Actions.
- [x] Gate automatic TestFlight delivery on successful current-`main` CI.
- [x] Refuse stale commits before archive and again before upload.
- [x] Make every CI job green for the first uploaded release (`2e3d5ba`).
- [x] Confirm Pages workflow has successfully deployed the production repository.
- [ ] Confirm repository branch/environment protections match desired release policy.

### Signing material

- [x] Register explicit App ID `de.malaber.tauber-defence` in Apple Developer.
- [ ] Confirm valid Apple Distribution certificate for team `VWKG94374J`.
- [ ] Create App Store distribution provisioning profile for this bundle ID.
- [ ] Create/reuse least-privilege App Store Connect API key.
- [ ] Create protected GitHub environment `testflight`.
- [ ] Add `KEYCHAIN_PASSWORD`.
- [ ] Add `BUILD_CERTIFICATE_BASE64` and `P12_PASSWORD`.
- [ ] Add `BUILD_PROVISION_PROFILE_BASE64`.
- [ ] Add `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, and private key.
- [ ] Add numeric `APP_STORE_CONNECT_APP_ID` repository variable.
- [ ] Verify a signed Release archive and IPA export without uploading.
- [ ] Keep `TESTFLIGHT_UPLOAD_ENABLED` unset until first manual beta passes.

## Phase 8 — First flight: App Store Connect and TestFlight `0.0.1`

### App record and metadata

- [ ] Accept current Apple agreements.
- [x] Create App Store Connect app record for `Tauber Defence` (Apple ID `6812439777`).
- [x] Set German as the primary language and confirm name availability.
- [x] Set SKU and bundle identifier to `de.malaber.tauber-defence`.
- [ ] Add product, support, and privacy URLs after public verification.
- [ ] Add app description, subtitle, keywords, promotional text, and copyright.
- [ ] Upload final iPhone and iPad screenshot galleries.
- [ ] Complete App Privacy answers from shipped behavior.
- [ ] Complete age-rating/content questionnaires from shipped content.
- [ ] Confirm export compliance (`ITSAppUsesNonExemptEncryption = NO`) still applies.
- [ ] Add review notes: no sign-in, all gameplay available, wave starts from visible control, nonviolent tolerance/pressure framing.
- [ ] Add required beta description and feedback contact.

### First upload

- [x] Freeze clean, green, pushed `2e3d5ba` as first playable `0.0.1 (1)`.
- [x] Run complete local gate: core coverage plus iPhone and iPad E2E.
- [x] Archive and upload locally with Xcode 27; Apple reported successful upload.
- [x] Retain signed archive and upload log in `e2e-artifacts/release-0.0.1-1/`.
- [x] First build appeared in TestFlight, confirmed by the user. Future uploads stop at Apple’s successful-upload response.
- [ ] Complete build-level export-compliance questions.
- [ ] Add processed build to an internal TestFlight group.
- [ ] Install from TestFlight on physical iPhone and iPad.

## Phase 9 — Physical-phone bug hunt

Use uploaded `0.0.1` as physical-device debugging build. It becomes ready for broader TestFlight use only when every item below passes:

- [ ] Fresh install and first launch succeed offline on iPhone and iPad.
- [ ] Landscape UI has no clipping, unsafe-area overlap, or unreadable controls.
- [ ] Player can place all three defences and receives correct budget feedback.
- [ ] All five waves can be started and completed.
- [ ] Pressure, slow, delayed falcon hit, fleeing, rewards, and cleanliness behave correctly.
- [ ] Rüdiger appears, is clearly identified, and can be defeated.
- [ ] Victory, defeat, pause/resume, and restart work repeatedly.
- [ ] Audio/haptics behave correctly with silent mode and interruptions.
- [ ] VoiceOver, large text, and Reduce Motion checks have no release blocker.
- [ ] No crash, hang, runaway memory, severe frame drop, or thermal issue occurs during a full session.
- [ ] Public support/privacy URLs and contact addresses work from the installed app.
- [ ] App Store Connect shows correct icon, version/build, privacy, compliance, and beta metadata.
- [ ] Record device models, OS versions, tester, date, and results in release notes or issue tracker.
- [ ] Only after this passes: set `TESTFLIGHT_UPLOAD_ENABLED=true` for future current-`main` builds.

## Phase 10 — More birds, more bureaucracy

Start only after `0.0.1` reaches a physical phone and its blocking bugs are recorded.

- [ ] Add Dicker Dieter: slow, high tolerance, larger reward; prove type-specific stats end to end.
- [ ] Add Späher-Sabine: fast, low tolerance, early-wave targeting pressure.
- [ ] Add Veteran Volker: modest resistance/habituation without making one defence useless.
- [ ] Add Schwarm behavior only after individual variants remain readable.
- [ ] Add more original pigeon poses: eating, angry, and panicking.
- [ ] Add CD am Fenster as cheap short-range visual pressure.
- [ ] Add Flatterband as area control with low sustained pressure.
- [ ] Add Besen-Beauftragte as mobile human pressure prototype.
- [ ] Add drone, net, water cannon, and Ordnungsamt only after first three additions are balanced.
- [ ] Add habituation and pressure categories: visual, sound, water, predator, human.
- [ ] Add attraction-based behavior for food, shelter, water, people, and nesting sites.
- [ ] Add dynamic route choice only after behavior design is validated.
- [ ] Add camera pinch-to-zoom and bounded pan; never add free rotation without a new design decision.
- [ ] Add upgrades/skill trees only after core-loop balancing.
- [ ] Add more maps only after the marketplace is fun and stable.
- [ ] Evaluate save games, achievements, Game Center, cloud save, and monetization separately.
- [ ] Keep accounts, analytics, ads, IAP, online features, multiplayer, map editor, procedural maps, and large tower catalog out until explicitly scoped.

## Current physical-feedback iteration

- [x] Replace debug-only placement test shortcuts with real yellow-marker input tests.
- [x] Implement native marker taps, bounded zoom, and free camera rotation; physical acceptance remains pending.
- [x] Add all six proposed pigeon variants and six countermeasures as experimental content.
- [x] Keep classic mode; add field trials with every new enemy type.
- [x] Add a main menu, local XP, rank, wins, best wave, and a roster guide.
- [x] Remove the self-targeting orbit camera that could hide the town; add a screenshot rendering guard.
- [ ] Verify persistence, both languages, gameplay, and screenshots on both simulator families.
- [ ] Commit and push checkpoints; upload the next build from clean, green main.

## Recommended next sequence

1. Finish the 0.0.2 iPhone/iPad gates and visually inspect the seven screenshot motifs.
2. Commit and push the release candidate; require green current-`main` CI.
3. Archive and upload `0.0.2 (2)` locally from clean, committed current `main`.
4. Accept Apple's successful upload response; do not poll TestFlight processing.
5. Test real marker placement, camera gestures, progress, and the experimental roster on a physical phone.
6. Narrow and balance the roster using feedback; keep arrival haptics and the bilingual comic tone.
7. Run physical accessibility, audio, performance, and iPad QA before App Store release.
8. Complete App Store metadata and screenshot upload for the eventual review build.
9. Keep local delivery as requested; enabling unattended delivery requires a separate decision.

Operational commands and credential names live in [delivery.md](delivery.md). Apple/GitHub setup details live in [app-store-connect-setup.md](app-store-connect-setup.md).
