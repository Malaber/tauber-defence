# Localization

German is the app's primary and fallback language. English is also supported. Source code,
identifiers, comments, and documentation stay in English.

All app copy lives in `ios/TauberDefenceIOS/App/Translations.json`. This follows the Planini
approach: one nested JSON catalog, semantic keys, named placeholders, and a small Swift adapter.
Do not add German or English display strings directly to views or the game core.

`AppLocalization` resolves the device's preferred language through
`TauberDefenceLocalizationCatalog`, matching regional identifiers such as `en-GB` to `en`.
Unsupported languages fall back to German. Missing translations fall back to the German value,
then the key. Numbers use the selected locale; euro placement is defined in the catalog.

To add a language:

1. Copy the complete `de` object to a new language-code object in `Translations.json`.
2. Translate its string values, preserving semantic keys and named placeholders such as `{amount}`.
3. Add the language to `CFBundleLocalizations` in `App/Info.plist`.
4. Extend catalog parity tests and the UI language smoke test, then run the local gates.

The UI test runner sets `TAUBERDEFENCE_UI_TEST_LANGUAGE` for deterministic language selection.
Core tests verify key coverage, nonempty values, placeholder parity, regional matching, and
fallback behavior. XCUITest verifies English first-launch and victory screens.
