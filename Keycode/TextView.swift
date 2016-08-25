import Cocoa

extension CGSize {
    static let unit = CGSize(width: 1, height: 1)
    static let infinite = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
}

final class TextView : NSTextView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.textContainerInset = NSSize(width: 0.0, height: 4.0)

        let font: NSFont? = {
            let fontName = userDefaults[.fontName] ?? ""
            let fontSize = userDefaults[.fontSize]
            return NSFont(name: fontName, size: fontSize) ?? NSFont.userFont(ofSize: fontSize)
        }()

        super.font = font
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

        userDefaults[.fontName] = font.fontName
        userDefaults[.fontSize] = font.pointSize

        for layoutManager in textStorage.layoutManagers {
            layoutManager.firstTextView?.font = font
        }
    }
}
