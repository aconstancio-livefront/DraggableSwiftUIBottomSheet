import Foundation
import UIKit
import SwiftUI

/// A SwiftUI wrapped UIScrollView that can be dragged.
///
public struct DraggableScrollView<Content: View>: UIViewRepresentable {

    /// The content displayed within the scrollable area.
    @ViewBuilder private let content: () -> Content

    /// An action to perform when the drag gesture’s value changes.
    private let onDragChanged: (Value) -> Void

    /// An action to perform when the drag gesture ends.
    private let onDragEnded: (Value) -> Void

    /// The current offset of the draggable view.
    private let offset: CGFloat

    // MARK: UIViewRepresentable
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> UIScrollView {
        // We create a new UIScrollView
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never

        // Attach the SwiftUI View content to a hosting controller
        let hostingController = UIHostingController(rootView: content())
        hostingController.view.backgroundColor = .clear
        hostingController.view.setNeedsLayout()
        hostingController.view.invalidateIntrinsicContentSize()
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])

        // Pass these views to the coordinator to handle behavior of the UIKit views
        context.coordinator.hostingController = hostingController
        context.coordinator.uiScrollView = scrollView

        // Create panGestureRecognizer
        let panGestureRecognizer = UIPanGestureRecognizer(
            target: context.coordinator,
            // Inside the Coordinator, we use the handle pan method for performing actions on the gesture.
            action: #selector(Coordinator.handlePan(gesture:))
        )

        // Assign the coordinator as the gesture recognizer delegate
        panGestureRecognizer.delegate = context.coordinator
        scrollView.panGestureRecognizer.require(toFail: panGestureRecognizer)
        scrollView.addGestureRecognizer(panGestureRecognizer)

        return scrollView
    }

    public func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content()
        context.coordinator.offset = offset

        context.coordinator.hostingController?.view.setNeedsLayout()
        context.coordinator.hostingController?.view.invalidateIntrinsicContentSize()
    }

    public init(
        offset: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            offset: offset,
            onDragChanged: { _ in },
            onDragEnded: { _ in },
            content: content
        )
    }

    init(
        offset: CGFloat = 0,
        onDragChanged: @escaping (Value) -> Void,
        onDragEnded: @escaping (Value) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.offset = offset
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
        self.content = content
    }

    public func onDragChanged(_ action: @escaping (Value) -> Void) -> Self {
        DraggableScrollView(
            offset: offset,
            onDragChanged: action,
            onDragEnded: onDragEnded,
            content: content
        )
    }

    public func onDragEnded(_ action: @escaping (Value) -> Void) -> Self {
        DraggableScrollView(
            offset: offset,
            onDragChanged: onDragChanged,
            onDragEnded: action,
            content: content
        )
    }

    // MARK: Coordinator

    /// An object used to coordinate UIKit scrolling in a `DraggableScrollView`.
    ///
    public class Coordinator: NSObject, UIGestureRecognizerDelegate {

        /// The hosting controller that wraps the view's content.
        var hostingController: UIHostingController<Content>?

        /// The `UIScrollView` wrapped by the view, used to perform the actual scrolling.
        var uiScrollView: UIScrollView?

        /// The current offset of the draggable view.
        var offset: CGFloat = 0

        // The scroll view being coordinated.
        let scrollView: DraggableScrollView

        // MARK: Initialization
        /// Initializes a `DraggableScrollView.Coordinator`.
        ///
        /// - Parameter scrollView: The scroll view to coordinate.
        init(_ scrollView: DraggableScrollView) {
            self.scrollView = scrollView
        }

        // MARK: Methods
        @objc func handlePan(gesture: UIPanGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            let translation = gesture.translation(in: gesture.view)
            let velocity = gesture.velocity(in: gesture.view)

            let value = Value(
                location: location,
                translation: translation,
                velocity: velocity
            )

            // We loop over the different gesture states, and we can give the gesture data to the changed and ended modifier methods.
            switch gesture.state {
            case .began, .possible:
                break
            case .changed:
                scrollView.onDragChanged(value)
            case .cancelled, .ended, .failed:
                scrollView.onDragEnded(value)
            @unknown default:
                break
            }
        }

        // MARK: UIGestureRecognizerDelegate

        public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let scrollView = uiScrollView,
                let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
                return true
            }

            // Using the velocity of the pan gesture, and the scrollViews Y offset, we know when the list is panning, scrolled to top or at the top.
            let velocity = panGesture.velocity(in: panGesture.view)
            let isPanningDown = velocity.y > 0
            let isScrolledToTop = scrollView.contentOffset.y <= 0
            let isAtTop = offset == 0

            if !isScrolledToTop {
                return false
            }

            if isPanningDown && isScrolledToTop {
                return true
            }

            if !isPanningDown && !isAtTop {
                return true
            }

            return false
        }
    }

    // MARK: Value
    /// The attributes of a drag gesture.
    ///
    public struct Value {

        /// The location of the drag gesture's current event.
        public let location: CGPoint

        /// The total translation of the gesture from the start of the gesture to the current event.
        public let translation: CGPoint

        /// The velocity of the drag gesture, which is expressed in points per second.
        public let velocity: CGPoint
    }
}
