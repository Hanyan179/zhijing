import Foundation

public enum Localization {
    private static let key = "app_lang"
    public static var current: Lang = {
        if let v = UserDefaults.standard.string(forKey: key), let l = Lang(rawValue: v) { return l }
        let sys = Locale.preferredLanguages.first?.lowercased() ?? "zh"
        if sys.hasPrefix("en") { return .en }
        if sys.hasPrefix("zh-hant") || sys.hasPrefix("zh-tw") || sys.hasPrefix("zh-hk") { return .zhHant }
        if sys.hasPrefix("zh") { return .zh }
        if sys.hasPrefix("ja") { return .ja }
        if sys.hasPrefix("ko") { return .ko }
        if sys.hasPrefix("de") { return .de }
        if sys.hasPrefix("fr") { return .fr }
        if sys.hasPrefix("es") { return .es }
        if sys.hasPrefix("it") { return .it }
        return .en
    }()

    public static func set(_ lang: Lang) {
        current = lang
        UserDefaults.standard.set(lang.rawValue, forKey: key)
    }

    private static func code(for lang: Lang) -> String {
        switch lang {
        case .en: return "en"
        case .zh: return "zh-Hans"
        case .zhHant: return "zh-Hant"
        case .ja: return "ja"
        case .ko: return "ko"
        case .de: return "de"
        case .fr: return "fr"
        case .es: return "es"
        case .it: return "it"
        }
    }
    public static let supported: [Lang] = [.en, .zh, .zhHant, .ja, .ko, .de, .fr, .es, .it]

    public static func tr(_ key: String) -> String {
        let table = "Localizable"
        let code = code(for: current)
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) {
            let r = NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
            if r != key { return r }
        }
        if let ep = Bundle.main.path(forResource: "en", ofType: "lproj"), let eb = Bundle(path: ep) {
            let re = NSLocalizedString(key, tableName: table, bundle: eb, value: key, comment: "")
            if re != key { return re }
        }
        return key
    }
    public static func tr(_ key: String, lang: Lang) -> String {
        let table = "Localizable"
        let code = code(for: lang)
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) {
            let r = NSLocalizedString(key, tableName: table, bundle: bundle, value: key, comment: "")
            if r != key { return r }
        }
        return tr(key)
    }

    public static func displayName(_ lang: Lang) -> String {
        switch lang {
        case .en: return "English"
        case .zh: return "简体中文"
        case .zhHant: return "繁體中文"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .de: return "Deutsch"
        case .fr: return "Français"
        case .es: return "Español"
        case .it: return "Italiano"
        }
    }
}
