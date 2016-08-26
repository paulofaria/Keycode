import Cocoa

final class TextView : NSTextView {
    let defaultFontSize: CGFloat = 18
    let defaultTextContainerInset = NSSize(width: 0.0, height: 4.0)

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureTextView()
    }

    func configureTextView() {
        self.textContainerInset = defaultTextContainerInset
        self.font = lastFont() ?? defaultFont()
        self.isAutomaticQuoteSubstitutionEnabled = false
        self.isAutomaticDashSubstitutionEnabled = false
        self.isAutomaticTextReplacementEnabled = false
        self.isAutomaticDataDetectionEnabled = false
        self.isAutomaticLinkDetectionEnabled = false
        self.isAutomaticSpellingCorrectionEnabled = false
    }

    func lastFont() -> NSFont? {
        let fontName = userDefaults[.fontName] ?? ""
        let fontSize = userDefaults[.fontSize]
        return NSFont(name: fontName, size: fontSize)
    }

    func defaultFont() -> NSFont? {
        return NSFont.userFont(ofSize: defaultFontSize)
    }

    override func changeFont(_ sender: Any?) {
        guard
            let manager = sender as? NSFontManager,
            let currentFont = self.font,
            let textStorage = self.textStorage
        else {
            return
        }

        let font = manager.convert(currentFont)
        textStorage.font = font

        userDefaults[.fontName] = font.fontName
        userDefaults[.fontSize] = font.pointSize
    }
}
