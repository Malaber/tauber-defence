# Delivery and testing

## Requirements

- Swift 6 and Xcode 26 with an iOS 18-or-newer simulator runtime
- XcodeGen 2.38 or newer
- Python 3.11 or newer
- Invoke 2.2.0, installed through the repository's editable development package

Set up the local task runner once:

```bash
python3 -m venv .venv
.venv/bin/pip install -e .
.venv/bin/inv install-xcodegen
```

## Repeatable local gates

Generate the ignored Xcode project and build one simulator target:

```bash
.venv/bin/inv generate-ios-project
.venv/bin/inv build-ios-simulator --device-name="iPhone 17 Pro"
```

Run portable core tests with LLVM line coverage:

```bash
.venv/bin/inv check-ios-package
```

`ios/TauberDefenceIOS/Scripts/check_coverage.sh` writes JSON, LCOV, a text report, and a concise
summary under ignored `ios/TauberDefenceIOS/coverage`. It measures only files below
`Sources/TauberDefenceCore`. The default threshold is 90%; set
`TAUBERDEFENCE_COVERAGE_MINIMUM` only when deliberately testing another threshold locally.

Run deterministic serial UI flows on each supported device family:

```bash
.venv/bin/inv ios-ui-e2e --device-name="iPhone 17 Pro"
.venv/bin/inv ios-ui-e2e \
  --device-name="iPad Pro 13-inch (M5)" \
  --artifact-dir="e2e-artifacts/ios-ipad"
```

The UI runner generates the Xcode project, builds once for testing with signing disabled, boots only
the selected simulator, removes the installed app, and executes tests serially. Failed named tests
are retried in isolation; infrastructure failures fall back to a complete isolated retry. Logs,
screenshots, the simulator inventory, a Markdown summary, and `TestResults.xcresult` remain in the
chosen artifact directory. Set `TAUBERDEFENCE_E2E_ATTEMPTS` to change the default two attempts.

The suite covers launch and economy, every defence purchase, insufficient funds, active wave,
pause/resume, prebuilt battle, Rüdiger, victory/restart, and defeat. Fixtures are selected through
the debug-only `--ui-test-fixture` launch argument; tests use accessibility identifiers and
observable state instead of animation sleeps.

Capture only the five-shot App Store gallery on both default device families:

```bash
.venv/bin/inv app-store-screenshots
```

Outputs land in `e2e-artifacts/marketing-iphone` and `e2e-artifacts/marketing-ipad`. Each directory
contains full-resolution landscape PNGs, a dimensions manifest, logs, and the source xcresult. CI
also produces `app-store-screenshots-iphone` and `app-store-screenshots-ipad` artifacts with 30-day
retention. Status bars are normalized to 09:41 and a full battery for repeatable store assets.

Run the complete local gate used before a manual upload:

```bash
.venv/bin/inv check
```

## GitHub Actions

- `.github/workflows/ci.yml` runs on pull requests, pushes to `main`, and manual dispatch.
- `.github/workflows/ios-checks.yml` runs portable Swift coverage in Linux Swift 6.2 and an iPhone /
  iPad XCUITest matrix on `macos-26`. Full evidence is retained for 14 days; extracted App Store
  PNGs are retained for 30 days.
- `.github/workflows/testflight.yml` runs a signed upload only after successful CI for a current
  `main` commit, or after a manual dispatch reruns the complete check matrix.
- `.github/workflows/pages.yml` publishes `website/` when site changes reach `main`.

Pull requests never upload to TestFlight. Superseded CI runs cancel by event and ref. Delivery does
not cancel once signing starts, but checks the selected commit against current `origin/main` before
the archive and again immediately before upload.

## Local Xcode upload

With an Xcode Apple account configured for team `VWKG94374J`, archive and upload directly:

```bash
.venv/bin/inv upload-testflight --marketing-version=0.0.1 --build-number=1
```

Use a new build number for every later upload of the same marketing version. The task generates the
project, archives with automatic signing, and exports using `ExportOptions.TestFlight.plist`, whose
`destination` is `upload`. The script uses a system-only `PATH` for `xcodebuild`; Homebrew `rsync`
does not support an extended-attribute option used by Xcode packaging and can otherwise cause an
opaque `exportArchive Copy failed` error. The signed archive remains at the printed temporary path.

## Automatic TestFlight delivery

Keep the repository variable `TESTFLIGHT_UPLOAD_ENABLED` unset until the one-time Apple and GitHub
setup in [app-store-connect-setup.md](app-store-connect-setup.md) is complete and a first build has
passed physical-device testing. When the variable is exactly `true`, every successful current-main
CI run triggers delivery.

Repository variables:

- `TESTFLIGHT_UPLOAD_ENABLED`
- `APPLE_TEAM_ID` (optional; defaults to `VWKG94374J`)
- `IOS_BUNDLE_IDENTIFIER` (optional; defaults to `de.malaber.tauberdefence`)
- `IOS_MARKETING_VERSION` (optional; defaults to `0.0.1`)
- `APP_STORE_CONNECT_APP_ID` (required numeric Apple ID)

Protected `testflight` environment secrets:

- `KEYCHAIN_PASSWORD`
- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

The workflow validates configuration, imports the distribution certificate into a temporary
keychain, installs the app-specific provisioning profile, exports an IPA with manual signing,
retains the signed archive and delivery logs for 14 days, uploads using App Store Connect API-key
authentication, and removes temporary signing material even after failure.

## Release checklist

1. Make portable tests and both simulator jobs green.
2. Smoke-test build placement, all three defences, pause/restart, each wave, Rüdiger, victory, and
   defeat on a physical iPhone and iPad.
3. Verify VoiceOver labels, large text, reduced motion, and landscape layout on both device families.
4. Confirm the privacy manifest and public privacy/support pages still describe the shipped code.
5. Upload a current clean `main` build and wait for App Store Connect processing.
6. Complete export-compliance questions, add the build to an internal TestFlight group, and install
   it on both physical device families.
7. Enable automatic uploads only after the initial build has passed that TestFlight smoke test.
