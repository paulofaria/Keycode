import Cocoa

class WindowController: NSWindowController {
    @IBOutlet weak var languagePopUpButton: NSPopUpButton!
    @IBOutlet weak var themePopUpButton: NSPopUpButton!

    let pasteboard = NSPasteboard.general()

    var languages: [String] = []
    var themes: [String] = []

    var language = userDefaults[.languageName] ?? ""
    var theme = userDefaults[.themeName] ?? ""
    
    override func windowDidLoad() {
        super.windowDidLoad()
        configureWindow()
        configureToolbar()
    }

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
        guard let name = sender?.title, name != self.language else {
            return
        }

        language = name
        userDefaults[.languageName] = name
    }

    @IBAction func changeTheme(_ sender: AnyObject?) {
        guard let name = sender?.title, name != self.theme else {
            return
        }

        theme = name
        userDefaults[.themeName] = name
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
        let languageDirectory = try! FileManager.supportDirectory("Languages")
        let themeDirectory = try! FileManager.supportDirectory("Themes")

        languages = try! FileManager.default.contentsOfDirectory(atPath: languageDirectory)
            .filter({$0.hasSuffix(".tmLanguage")})
            .filter({!FileManager.isDirectory((languageDirectory as NSString).appendingPathComponent($0))})
            .map({($0 as NSString).deletingPathExtension})

        themes = try! FileManager.default.contentsOfDirectory(atPath: themeDirectory)
            .filter({$0.hasSuffix(".tmTheme")})
            .filter({!FileManager.isDirectory((languageDirectory as NSString).appendingPathComponent($0))})
            .map({($0 as NSString).deletingPathExtension})

        buildLanguagePopupButton()
        buildThemePopupButton()

        invalidateLanguageSelection()
        invalidateThemeSelection()
    }
}

extension WindowController {
    func buildLanguagePopupButton() {
        guard let menu = languagePopUpButton.menu else {
            return
        }

        let action = #selector(WindowController.changeLanguage(_:))

        menu.removeAllItems()

        menu.addItem(withTitle: "None", action: action, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())

        for language in languages {
            menu.addItem(withTitle: language, action: action, keyEquivalent: "")
        }

        self.invalidateLanguageSelection()
    }

    func invalidateLanguageSelection() {
        languagePopUpButton.selectItem(withTitle: language)

        if languagePopUpButton.selectedItem == nil {
            languagePopUpButton.selectItem(at: 0)  // select "None"
        }
    }
}

extension WindowController {
    func buildThemePopupButton() {
        guard let menu = themePopUpButton.menu else {
            return
        }

        let action = #selector(WindowController.changeTheme(_:))

        menu.removeAllItems()

        menu.addItem(withTitle: "None", action: action, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())

        for theme in themes {
            menu.addItem(withTitle: theme, action: action, keyEquivalent: "")
        }

        self.invalidateLanguageSelection()
    }

    func invalidateThemeSelection() {
        themePopUpButton.selectItem(withTitle: theme)
        
        if themePopUpButton.selectedItem == nil {
            themePopUpButton.selectItem(at: 0)  // select "None"
        }
    }
}
