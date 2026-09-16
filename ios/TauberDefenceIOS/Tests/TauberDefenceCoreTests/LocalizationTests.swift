import Foundation
import XCTest
@testable import TauberDefenceCore

final class LocalizationTests: XCTestCase {
    func testMatchesOverrideAndPreferredLocales() {
        let catalog = TauberDefenceLocalizationCatalog(
            catalogs: [
                "de": ["sample": ["value": "Primary"]],
                "en": ["sample": ["value": "Secondary"]],
            ]
        )

        XCTAssertEqual(catalog.defaultLocale, "de")
        XCTAssertEqual(catalog.availableLocales, ["de", "en"])
        XCTAssertEqual(catalog.effectiveLocale(preferredLocales: ["fr-FR", "en-US"]), "en")
        XCTAssertEqual(
            catalog.effectiveLocale(preferredLocales: ["en-GB"], overrideLocale: "de_DE"),
            "de"
        )
        XCTAssertEqual(catalog.effectiveLocale(preferredLocales: ["fr-FR"]), "de")
        XCTAssertEqual(catalog.normalizedAvailableLocale("  EN_us  "), "en")
        XCTAssertNil(catalog.normalizedAvailableLocale("fr"))
        XCTAssertNil(catalog.normalizedAvailableLocale("  "))
        XCTAssertNil(catalog.normalizedAvailableLocale(nil))
    }

    func testTranslatesWithFallbackAndNamedParameters() {
        let catalog = TauberDefenceLocalizationCatalog(
            catalogs: [
                "de": [
                    "sample": [
                        "message": "Primary {name}: {count}",
                        "fallback": "Default value",
                    ],
                ],
                "en": [
                    "sample": [
                        "message": "Secondary {count}: {name}",
                    ],
                ],
            ]
        )
        let params: [String: CustomStringConvertible] = ["name": "Ada", "count": 3]

        XCTAssertEqual(
            catalog.translate(locale: "en-US", key: "sample.message", params: params),
            "Secondary 3: Ada"
        )
        XCTAssertEqual(catalog.translate(locale: "en", key: "sample.fallback"), "Default value")
        XCTAssertEqual(catalog.translate(locale: "fr", key: "sample.message"), "Primary {name}: {count}")
        XCTAssertEqual(catalog.translate(locale: "en", key: "sample.missing"), "sample.missing")
    }

    func testBundledTranslationCatalogHasCompleteLocaleAndPlaceholderParity() throws {
        let catalogs = try loadTranslationCatalogs()
        let catalog = TauberDefenceLocalizationCatalog(catalogs: catalogs)

        XCTAssertEqual(catalog.availableLocales, ["de", "en"])
        XCTAssertEqual(catalog.defaultLocale, "de")

        let primary = try flattenedStrings(in: XCTUnwrap(catalogs["de"]))
        let english = try flattenedStrings(in: XCTUnwrap(catalogs["en"]))

        XCTAssertTrue(expectedTranslationKeys.isSubset(of: Set(primary.keys)))
        XCTAssertTrue(expectedTranslationKeys.isSubset(of: Set(english.keys)))
        XCTAssertEqual(Set(primary.keys), Set(english.keys))

        for key in primary.keys {
            let primaryValue = try XCTUnwrap(primary[key], "Missing primary value for \(key)")
            let englishValue = try XCTUnwrap(english[key], "Missing English value for \(key)")
            XCTAssertFalse(
                primaryValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "Primary value is empty for \(key)"
            )
            XCTAssertFalse(
                englishValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "English value is empty for \(key)"
            )
            XCTAssertEqual(
                placeholders(in: primaryValue),
                placeholders(in: englishValue),
                "Placeholder mismatch for \(key)"
            )
        }
    }

    private func loadTranslationCatalogs() throws -> [String: [String: Any]] {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = packageRoot.appendingPathComponent("App/Translations.json")
        let data = try Data(contentsOf: url)
        let object = try JSONSerialization.jsonObject(with: data)
        let root = try XCTUnwrap(object as? [String: Any])

        var result: [String: [String: Any]] = [:]
        for (locale, value) in root {
            result[locale] = try XCTUnwrap(value as? [String: Any], "Invalid catalog for \(locale)")
        }
        return result
    }

    private func flattenedStrings(
        in dictionary: [String: Any],
        prefix: String = ""
    ) throws -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in dictionary {
            let path = prefix.isEmpty ? key : "\(prefix).\(key)"
            if let string = value as? String {
                result[path] = string
            } else if let nested = value as? [String: Any] {
                result.merge(try flattenedStrings(in: nested, prefix: path)) { _, replacement in
                    replacement
                }
            } else {
                throw CatalogTestError.invalidLeaf(path)
            }
        }
        return result
    }

    private func placeholders(in value: String) -> Set<String> {
        let expression = try! NSRegularExpression(pattern: #"\{[A-Za-z][A-Za-z0-9_]*\}"#)
        let range = NSRange(value.startIndex..., in: value)
        return Set(expression.matches(in: value, range: range).compactMap { match in
            Range(match.range, in: value).map { String(value[$0]) }
        })
    }

    private var expectedTranslationKeys: Set<String> {
        [
            "level.marketplace.name",
            "format.euro",
            "pigeon.normal.name",
            "pigeon.normal.subtitle",
            "pigeon.ruediger.name",
            "pigeon.ruediger.subtitle",
            "pigeon.nerve",
            "pigeon.tolerance_value",
            "pigeon.status.spawning",
            "pigeon.status.unimpressed",
            "pigeon.status.concerned",
            "pigeon.status.alert",
            "pigeon.status.panicking",
            "pigeon.status.fleeing",
            "pigeon.status.reached_target",
            "pigeon.status.removed",
            "defense.plastic_owl.name",
            "defense.plastic_owl.tagline",
            "defense.sprinkler.name",
            "defense.sprinkler.tagline",
            "defense.falconer.name",
            "defense.falconer.tagline",
            "hud.money_value",
            "hud.city_budget",
            "hud.wave_value",
            "hud.wave",
            "hud.cleanliness_value",
            "hud.cleanliness",
            "hud.help",
            "hud.resume",
            "hud.pause",
            "build.agency",
            "build.title",
            "build.close",
            "build.price_tagline",
            "build.accessibility",
            "wave.boss_inbound",
            "wave.pigeons_inbound",
            "wave.start_first",
            "wave.summon_boss",
            "wave.next",
            "pause.title",
            "pause.restart",
            "pause.continue",
            "result.victory_title",
            "result.victory_message",
            "result.defeat_title",
            "result.defeat_message",
            "result.restart",
            "help.pick_spot_title",
            "help.pick_spot_body",
            "help.deploy_title",
            "help.deploy_body",
            "help.nerve_title",
            "help.nerve_body",
            "help.clean_title",
            "help.clean_body",
            "help.support",
            "help.privacy",
            "help.title",
            "help.done",
            "toast.wave_already_running",
            "toast.pick_spot_first",
            "toast.defense_ready",
            "toast.spot_occupied",
            "toast.mass_panic",
            "toast.combo",
            "toast.reward",
            "toast.boss_warning",
            "toast.wave_complete",
            "toast.victory",
            "toast.defeat",
            "toast.funds_needed",
            "toast.cannot_build",
            "accessibility.pigeon_close",
            "debug.spot",
            "debug.select_pigeon",
        ]
    }
}

private enum CatalogTestError: Error {
    case invalidLeaf(String)
}
