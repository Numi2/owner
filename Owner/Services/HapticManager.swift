import UIKit

/// Centralised utility for triggering haptic feedback across the app.
final class HapticManager {
    static let shared = HapticManager()
    private init() { }

    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let successGenerator = UINotificationFeedbackGenerator()
    private let errorGenerator = UINotificationFeedbackGenerator()

    /// Call to give the user a medium impact tap.
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Call to notify a successful action.
    func success() {
        successGenerator.prepare()
        successGenerator.notificationOccurred(.success)
    }

    /// Call to notify an error or failure.
    func error() {
        errorGenerator.prepare()
        errorGenerator.notificationOccurred(.error)
    }
}