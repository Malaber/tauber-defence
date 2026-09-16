import Foundation
import SwiftUI
import TauberDefenceCore

@MainActor
final class AppLocalization: ObservableObject {
    private let catalog: TauberDefenceLocalizationCatalog
    private let preferredLocales: () -> [String]
    private let overrideLocale: String?

    init(
        catalog: TauberDefenceLocalizationCatalog = AppLocalization.loadBundledCatalog(),
        processInfo: ProcessInfo = .processInfo,
        preferredLocales: @escaping () -> [String] = { Locale.preferredLanguages }
    ) {
        self.catalog = catalog
        self.preferredLocales = preferredLocales
        #if DEBUG
        overrideLocale = catalog.normalizedAvailableLocale(
            processInfo.environment["TAUBERDEFENCE_UI_TEST_LANGUAGE"]
        )
        #else
        overrideLocale = nil
        #endif
    }

    var effectiveLocale: String {
        catalog.effectiveLocale(
            preferredLocales: preferredLocales(),
            overrideLocale: overrideLocale
        )
    }

    func t(
        _ key: String,
        _ params: [String: CustomStringConvertible] = [:]
    ) -> String {
        catalog.translate(locale: effectiveLocale, key: key, params: params)
    }

    func format(number: Int) -> String {
        number.formatted(.number.locale(Locale(identifier: effectiveLocale)))
    }

    func format(euros: Int) -> String {
        t("format.euro", ["amount": format(number: euros)])
    }

    nonisolated private static func loadBundledCatalog(
        bundle: Bundle = .main
    ) -> TauberDefenceLocalizationCatalog {
        guard
            let url = bundle.url(forResource: "Translations", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let catalogs = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]]
        else {
            return TauberDefenceLocalizationCatalog(
                defaultLocale: "de",
                catalogs: ["de": [:], "en": [:]]
            )
        }

        return TauberDefenceLocalizationCatalog(defaultLocale: "de", catalogs: catalogs)
    }
}

extension DefenseType {
    @MainActor
    func localizedName(using localization: AppLocalization) -> String {
        localization.t("defense.\(localizationKey).name")
    }

    @MainActor
    func localizedTagline(using localization: AppLocalization) -> String {
        localization.t("defense.\(localizationKey).tagline")
    }

    private var localizationKey: String {
        switch self {
        case .plasticOwl: "plastic_owl"
        default: rawValue
        }
    }
}

extension PigeonType {
    @MainActor
    func localizedName(using localization: AppLocalization) -> String {
        localization.t("pigeon.\(localizationKey).name")
    }

    @MainActor
    func localizedSubtitle(using localization: AppLocalization) -> String {
        localization.t("pigeon.\(localizationKey).subtitle")
    }

    private var localizationKey: String {
        switch self {
        default: rawValue
        }
    }
}
