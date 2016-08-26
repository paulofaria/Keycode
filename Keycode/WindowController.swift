import Cocoa

class WindowController : NSWindowController {
    @IBOutlet weak var languagePopUpButton: NSPopUpButton!
    @IBOutlet weak var themePopUpButton: NSPopUpButton!

    let pasteboard = NSPasteboard.general()

    var languages: [String] = []
    var language: String!

    var themes: [String] = []
    var theme: String!

    override func windowDidLoad() {
        super.windowDidLoad()
        configureLanguage()
        configureTheme()
        configureParser()
        configureWindow()
        configureToolbar()
    }
}

extension WindowController {
    func configureLanguage() {
        let languageDirectory = try! FileManager.supportDirectory("Languages")

        languages = try! FileManager.default.contentsOfDirectory(atPath: languageDirectory)
            .filter({$0.hasSuffix(".tmLanguage")})
            .filter({!FileManager.isDirectory((languageDirectory as NSString).appendingPathComponent($0))})
            .map({($0 as NSString).deletingPathExtension})

        language = userDefaults[.languageName] ?? languages.first!
    }

    func configureTheme() {
        let themeDirectory = try! FileManager.supportDirectory("Themes")

        themes = try! FileManager.default.contentsOfDirectory(atPath: themeDirectory)
            .filter({$0.hasSuffix(".tmTheme")})
            .filter({!FileManager.isDirectory((themeDirectory as NSString).appendingPathComponent($0))})
            .map({($0 as NSString).deletingPathExtension})

        theme = userDefaults[.themeName] ?? themes.first!
    }

    func configureParser() {
        guard
            let viewController = contentViewController as? ViewController
        else {
            return
        }

        viewController.configureParser(language: language, theme: theme)
    }
}

extension WindowController {
    func configureWindow() {
        hide(button: .closeButton)
        hide(button: .miniaturizeButton)
        hide(button: .zoomButton)
    }

    func hide(button: NSWindowButton) {
        self.window?.standardWindowButton(button)?.isHidden = true
    }
}

extension WindowController {
    func configureToolbar() {
        buildLanguagePopupButton()
        selectLanguage()

        buildThemePopupButton()
        selectTheme()
    }
}

extension WindowController {
    func buildLanguagePopupButton() {
        guard let menu = languagePopUpButton.menu else {
            return
        }

        menu.removeAllItems()
        let action = #selector(WindowController.changeLanguage(_:))

        for language in languages {
            menu.addItem(withTitle: language, action: action, keyEquivalent: "")
        }
    }

    func selectLanguage() {
        languagePopUpButton.selectItem(withTitle: language)

        if languagePopUpButton.selectedItem == nil {
            languagePopUpButton.selectItem(at: 0)
        }
    }
}

extension WindowController {
    func buildThemePopupButton() {
        guard let menu = themePopUpButton.menu else {
            return
        }

        menu.removeAllItems()
        let action = #selector(WindowController.changeTheme(_:))

        for theme in themes {
            menu.addItem(withTitle: theme, action: action, keyEquivalent: "")
        }
    }

    func selectTheme() {
        themePopUpButton.selectItem(withTitle: theme)
        
        if themePopUpButton.selectedItem == nil {
            themePopUpButton.selectItem(at: 0)
        }
    }
}

extension WindowController {
    @IBAction func copy(_ sender: NSToolbarItem) {
        guard
            let viewController = contentViewController as? ViewController
        else {
            return
        }

        pasteboard.clearContents()
        pasteboard.writeObjects([viewController.text])
    }

    @IBAction func changeLanguage(_ sender: AnyObject?) {
        guard
            let title = sender?.title, title != self.language,
            let viewController = contentViewController as? ViewController
        else {
            return
        }

        language = title
        userDefaults[.languageName] = title
        viewController.update(language: title)
    }

    @IBAction func changeTheme(_ sender: AnyObject?) {
        guard
            let title = sender?.title, title != self.theme,
            let viewController = contentViewController as? ViewController
        else {
            return
        }

        theme = title
        userDefaults[.themeName] = title
        viewController.update(theme: title)
    }
}
