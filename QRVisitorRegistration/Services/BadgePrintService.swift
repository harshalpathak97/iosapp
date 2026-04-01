import UIKit

/// Service for printing visitor badges via AirPrint or connected printers.
///
/// Generates a professional badge layout with name, title, and company,
/// then sends it to the iPad's connected printer.
class BadgePrintService {

    struct BadgeLayout {
        var badgeWidth: CGFloat = 4.0 * 72   // 4 inches in points
        var badgeHeight: CGFloat = 3.0 * 72  // 3 inches in points
        var companyName: String = "VISITOR"   // Header text on badge
        var accentColor: UIColor = UIColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1.0)
    }

    var layout = BadgeLayout()

    /// Print a badge for the given attendee
    func printBadge(for attendee: Attendee, from viewController: UIViewController, completion: @escaping (Bool, String) -> Void) {
        let printController = UIPrintInteractionController.shared

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "Visitor Badge - \(attendee.name)"
        printInfo.outputType = .general
        printInfo.orientation = .landscape

        printController.printInfo = printInfo
        printController.printingItem = renderBadgeImage(for: attendee)

        printController.present(from: viewController.view.frame, in: viewController.view, animated: true) { _, completed, error in
            if completed {
                completion(true, "Badge printed successfully")
            } else if let error = error {
                completion(false, "Print error: \(error.localizedDescription)")
            } else {
                completion(false, "Printing was cancelled")
            }
        }
    }

    /// Print silently to a specific printer (for kiosk mode)
    func printBadgeSilently(for attendee: Attendee, printerURL: URL, completion: @escaping (Bool, String) -> Void) {
        guard let printer = UIPrinter(url: printerURL) else {
            completion(false, "Invalid printer URL")
            return
        }

        let printController = UIPrintInteractionController.shared

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "Visitor Badge - \(attendee.name)"
        printInfo.outputType = .general
        printInfo.orientation = .landscape

        printController.printInfo = printInfo
        printController.printingItem = renderBadgeImage(for: attendee)

        printController.print(to: printer, completionHandler: { _, completed, error in
            if completed {
                completion(true, "Badge printed successfully")
            } else if let error = error {
                completion(false, "Print error: \(error.localizedDescription)")
            } else {
                completion(false, "Printing failed")
            }
        })
    }

    /// Render the badge as a UIImage for printing
    func renderBadgeImage(for attendee: Attendee) -> UIImage {
        let size = CGSize(width: layout.badgeWidth, height: layout.badgeHeight)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let ctx = context.cgContext

            // Background
            UIColor.white.setFill()
            ctx.fill(rect)

            // Accent header bar
            let headerHeight: CGFloat = 60
            layout.accentColor.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: headerHeight))

            // Header text
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let headerText = layout.companyName
            let headerSize = headerText.size(withAttributes: headerAttributes)
            headerText.draw(
                at: CGPoint(x: (size.width - headerSize.width) / 2, y: (headerHeight - headerSize.height) / 2),
                withAttributes: headerAttributes
            )

            // Name (large, centered)
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let nameSize = attendee.name.size(withAttributes: nameAttributes)
            let nameY = headerHeight + 30
            attendee.name.draw(
                at: CGPoint(x: (size.width - nameSize.width) / 2, y: nameY),
                withAttributes: nameAttributes
            )

            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]
            let titleSize = attendee.title.size(withAttributes: titleAttributes)
            let titleY = nameY + nameSize.height + 12
            attendee.title.draw(
                at: CGPoint(x: (size.width - titleSize.width) / 2, y: titleY),
                withAttributes: titleAttributes
            )

            // Company
            let companyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            let companySize = attendee.company.size(withAttributes: companyAttributes)
            let companyY = titleY + titleSize.height + 8
            attendee.company.draw(
                at: CGPoint(x: (size.width - companySize.width) / 2, y: companyY),
                withAttributes: companyAttributes
            )

            // Bottom accent line
            layout.accentColor.setFill()
            ctx.fill(CGRect(x: 20, y: size.height - 8, width: size.width - 40, height: 4))

            // Border
            UIColor.lightGray.setStroke()
            ctx.setLineWidth(1)
            ctx.stroke(rect.insetBy(dx: 0.5, dy: 0.5))
        }
    }
}
