import AppKit

final class ViewController : NSViewController, NSTextViewDelegate {
    @IBOutlet var textView: TextView!

    var bundleManager: BundleManager!
    var attributedParser: AttributedParser!
    var text = NSAttributedString()

    var language: String!
    var theme: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBundleManager()
    }

    func configureBundleManager() {
        bundleManager = BundleManager { identifier, isLanguage in
            let prefix: String
            let suffix: String

            if isLanguage {
                prefix = FileManager.supportDirectory("Languages") + "/"
                suffix = ".tmLanguage"
            } else {
                prefix = FileManager.supportDirectory("Themes") + "/"
                suffix = ".tmTheme"
            }

            return URL(fileURLWithPath: prefix + identifier + suffix)
        }
    }

    func configureParser(language: String, theme: String) {
        guard
            let language = bundleManager.languageWithIdentifier(language),
            let theme = bundleManager.themeWithIdentifier(theme)
        else {
            return
        }

        textView.backgroundColor = theme.backgroundColor
        textView.insertionPointColor = theme.foregroundColor
        attributedParser = AttributedParser(language: language, theme: theme)
    }

    func textDidChange(_ notification: Notification) {
        updateText()
    }

    func update(language: String) {
        attributedParser.language = bundleManager.languageWithIdentifier(language)!
        updateText()
    }

    func update(theme: String) {
        let theme = bundleManager.themeWithIdentifier(theme)!
        apply(theme: theme)
        updateText()
    }

    func apply(theme: Theme) {
        attributedParser.theme = theme
        textView.backgroundColor = theme.backgroundColor
        textView.insertionPointColor = theme.foregroundColor
    }

    func updateText() {
        guard
            let rawText = textView.string
        else {
            return
        }

        let baseAttributes: Attributes = [
            NSFontAttributeName: textView.font!
        ]

        text = attributedParser.attributedStringForString(rawText, baseAttributes: baseAttributes)
        let ranges = textView.selectedRanges
        textView.textStorage?.setAttributedString(text)
        textView.selectedRanges = ranges
    }
}
