import SwiftUI

struct ContentView: View {

    /// The translation of the bottom sheet gesture.
    @State var finishedTranslation: CGFloat = 0

    /// The current position of the bottom sheet.
    @State var currentPosition: CGFloat = 0

    /// The offset applied to the list content.
    private var offset: CGFloat {
        return max(finishedTranslation, 0)
    }

    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        listScrollView
            .offset(y: offset)
            .background(Color.white)
    }

    var listScrollView: some View {
        GeometryReader { geo in
            VStack(alignment: .center) {
                DraggableScrollView(
                    offset: offset
                ) {
                // Wraps these views in a UIScrollView
                ForEach(0..<20) { item in
                    Text("List item " + item.description)
                        .fontWeight(.black)
                        .font(.title)
                        .frame(width: geo.size.width, height: 100)
                        .background(Color.blue)
                        .padding(.top)
                    }
                }
                .onDragChanged { value in
                    // Update the offset of the view
                    onDragChanged(by: value.translation.y)
                }
                .onDragEnded { value in
                    // Update snap positions
                    onDragEnded(
                        screenHeight: geo.size.height,
                        translation: value.translation.y,
                        velocity: value.velocity.y
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.cyan)
            .mask(
                RoundedCorner(
                    radius: 16,
                    corners: [.topLeft, .topRight]
                )
            )
            .padding(.top, verticalSizeClass == .compact ? 6 : 40)
            .onAppear {
                let halfPosition = geo.size.height / 2
                currentPosition = halfPosition
                self.finishedTranslation = halfPosition
            }
        }
    }

    /// Called when a drag gesture value changes.
    ///
    /// - Parameter translation: The vertical translation value of the gesture.
    ///
    private func onDragChanged(
        by translation: CGFloat
    ) {
        let sheetPosition = translation + currentPosition
        self.finishedTranslation = sheetPosition
    }

    /// Called when the drag gesture ends.
    ///
    /// - Parameters:
    ///  - screenHeight: The current height of the screen, read from GeometryReader proxy.
    ///  - translation: The vertical translation value of the gesture.
    ///  - velocity: The vertical velocity of the gesture
    ///
    private func onDragEnded(
        screenHeight: Double,
        translation: CGFloat,
        velocity: CGFloat
    ) {
        /// The current position of the bottom sheet
        let sheetPosition = translation + currentPosition
        /// 1/4 of the screens height
        let quarterScreen = screenHeight / 4
        /// 3/4 of the screens height
        let threeFourthsScreen = quarterScreen * 3

        /// Setting for the half screen position
        let halfPosition = screenHeight / 2
        /// Setting for the full screen position
        let higherPosition: CGFloat = 0
        /// Setting for the closed position
        let closedPosition = screenHeight

        withAnimation(.interactiveSpring()) {
            // Adjust sheet position based on location sheet at end of gesture.
            if sheetPosition > quarterScreen
                && sheetPosition < threeFourthsScreen {
                // List is half screen
                currentPosition = halfPosition
                finishedTranslation = halfPosition
            } else if sheetPosition < threeFourthsScreen {
                // List is full screen
                currentPosition = higherPosition
                finishedTranslation = higherPosition
            } else {
                // List is closed
                currentPosition = closedPosition
                finishedTranslation = closedPosition
            }
        }
    }
}

/// Creates a `Shape` that allows adjusting the radius for the specified corner.
///
struct RoundedCorner: Shape {

    /// The specified radius to apply to the corner.
    var radius: CGFloat = .infinity

    /// An array of corners in which to apply the radius to.
    var corners: UIRectCorner = .allCorners

    /// Returns a custom `Path` for the `Shape`
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
