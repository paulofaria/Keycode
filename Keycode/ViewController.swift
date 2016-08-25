import AppKit

final class ViewController : NSViewController, NSTextViewDelegate {
    @IBOutlet var textView: TextView!

    var attributedParser: AttributedParser!
    var text = NSAttributedString()

    override func viewDidLoad() {
        super.viewDidLoad()

        let manager = BundleManager() { identifier, isLanguage in
            let prefix: String
            let suffix: String

            if isLanguage {
                prefix = try! FileManager.supportDirectory("Languages") + "/"
                suffix = ".tmLanguage"
            } else {
                prefix = try! FileManager.supportDirectory("Themes") + "/"
                suffix = ".tmTheme"
            }

            return URL(fileURLWithPath: prefix + identifier + suffix)
        }

        let language = manager.languageWithIdentifier("Swift")!
        let theme = manager.themeWithIdentifier("Monokai")!

        textView.backgroundColor = theme.backgroundColor
        textView.insertionPointColor = theme.foregroundColor

        attributedParser = AttributedParser(language: language, theme: theme)
    }

    func textDidChange(_ notification: Notification) {
        guard
            let textView = notification.object as? NSTextView,
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
