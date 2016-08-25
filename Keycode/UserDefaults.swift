import AppKit

let userDefaults = UserDefaults.standard

class UserDefaultsKeyBase : RawRepresentable, Hashable, CustomStringConvertible {
    let rawValue: String

    required init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(_ key: String) {
        self.rawValue = key
    }

    var hashValue: Int {
        return self.rawValue.hashValue
    }

    var description: String {
        return self.rawValue
    }
}

final class UserDefaultsKey<T>: UserDefaultsKeyBase { }

extension UserDefaults {
    subscript(key: UserDefaultsKey<Bool>) -> Bool {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.bool(forKey: key.rawValue) }
    }

    subscript(key: UserDefaultsKey<Int>) -> Int {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.integer(forKey: key.rawValue) }
    }

    subscript(key: UserDefaultsKey<UInt>) -> UInt {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return UInt(self.integer(forKey: key.rawValue)) }
    }

    subscript(key: UserDefaultsKey<Double>) -> Double {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.double(forKey: key.rawValue) }
    }

    subscript(key: UserDefaultsKey<CGFloat>) -> CGFloat {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return CGFloat(self.double(forKey: key.rawValue)) }
    }

    subscript(key: UserDefaultsKey<String>) -> String? {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.string(forKey: key.rawValue) }
    }

    subscript(key: UserDefaultsKey<[String]>) -> [String]? {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.stringArray(forKey: key.rawValue) }
    }

    subscript(key: UserDefaultsKey<[NSNumber]>) -> [NSNumber] {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.array(forKey: key.rawValue) as? [NSNumber] ?? [] }
    }

    subscript(key: UserDefaultsKey<[Any]>) -> [Any]? {
        set { self.set(newValue, forKey: key.rawValue) }
        get { return self.array(forKey: key.rawValue) }
    }
}

extension UserDefaultsKeyBase {
    static let languageName = UserDefaultsKey<String>("languageName")
    static let themeName = UserDefaultsKey<String>("themeName")
    static let fontName = UserDefaultsKey<String>("fontName")
    static let fontSize = UserDefaultsKey<CGFloat>("fontSize")
}
