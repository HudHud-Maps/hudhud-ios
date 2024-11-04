import SwiftUI

public struct InnerGridView<
    TopLeading: View,
    TopCenter: View,
    TopTrailing: View,
    MidLeading: View,
    MidCenter: View,
    MidTrailing: View,
    BottomLeading: View,
    BottomCenter: View,
    BottomTrailing: View
>: View {

    // MARK: Properties

    var topLeading: TopLeading
    var topCenter: TopCenter
    var topTrailing: TopTrailing
    var midLeading: MidLeading
    var midCenter: MidCenter
    var midTrailing: MidTrailing
    var bottomLeading: BottomLeading
    var bottomCenter: BottomCenter
    var bottomTrailing: BottomTrailing

    // MARK: Lifecycle

    /// A General purpose grid view used for overlaying alerts, controls and other UI components
    /// on top of the map's free space.
    ///
    /// | --- | --- | --- |
    /// | --- | --- | --- |
    /// | --- | --- | --- |
    ///
    /// To control column widths & row heights use a standardized frame argument like `.frame(width: 64)`
    /// throughout the column and/or `height: value`, etc, as well.
    ///
    /// - Parameters:
    ///   - topLeading: The top left corner view. Defaults to a Spacer()
    ///   - topCenter: The top center corner view. Defaults to a Spacer()
    ///   - topTrailing: The top right corner view. Defaults to a Spacer()
    ///   - midLeading: The mid left corner view. Defaults to a Spacer()
    ///   - midCenter: The mid center corner view. Defaults to a Spacer()
    ///   - midTrailing: The mid right corner view. Defaults to a Spacer()
    ///   - bottomLeading: The bottom left corner view. Defaults to a Spacer()
    ///   - bottomCenter: The bottom center corner view. Defaults to a Spacer()
    ///   - bottomTrailing: The bottom right corner view. Defaults to a Spacer()
    public init(
        @ViewBuilder topLeading: @escaping () -> TopLeading = { Spacer() },
        @ViewBuilder topCenter: @escaping () -> TopCenter = { Spacer() },
        @ViewBuilder topTrailing: @escaping () -> TopTrailing = { Spacer() },
        @ViewBuilder midLeading: @escaping () -> MidLeading = { Spacer() },
        @ViewBuilder midCenter: @escaping () -> MidCenter = { Spacer() },
        @ViewBuilder midTrailing: @escaping () -> MidTrailing = { Spacer() },
        @ViewBuilder bottomLeading: @escaping () -> BottomLeading = { Spacer() },
        @ViewBuilder bottomCenter: @escaping () -> BottomCenter = { Spacer() },
        @ViewBuilder bottomTrailing: @escaping () -> BottomTrailing = { Spacer() }
    ) {
        self.topLeading = topLeading()
        self.topCenter = topCenter()
        self.topTrailing = topTrailing()
        self.midLeading = midLeading()
        self.midCenter = midCenter()
        self.midTrailing = midTrailing()
        self.bottomLeading = bottomLeading()
        self.bottomCenter = bottomCenter()
        self.bottomTrailing = bottomTrailing()
    }

    // MARK: Content

    public var body: some View {
        HStack {
            // Leading Column
            VStack(alignment: .leading) {
                self.topLeading

                Spacer()

                self.midLeading

                Spacer()

                self.bottomLeading
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .leading
            )

            // Center Column
            VStack(alignment: .center) {
                self.topCenter

                Spacer()

                self.midCenter

                Spacer()

                self.bottomCenter
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .center
            )

            // Trailing Column
            VStack(alignment: .trailing) {
                self.topTrailing

                Spacer()

                self.midTrailing

                Spacer()

                self.bottomTrailing
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .trailing
            )
        }
    }
}

#Preview("Full Grid") {
    InnerGridView(
        topLeading: {
            Rectangle().frame(width: 64, height: 64)
                .foregroundColor(.blue)
        },
        topCenter: {
            Rectangle()
                .foregroundColor(.blue)
        },
        topTrailing: {
            Rectangle().frame(height: 64)
                .foregroundColor(.blue)
        },
        midLeading: {
            Rectangle().frame(width: 64)
                .foregroundColor(.red)
        },
        midTrailing: {
            Rectangle()
                .foregroundColor(.red)
        },
        bottomLeading: {
            Rectangle().frame(width: 64, height: 64)
                .foregroundColor(.blue)
        },
        bottomCenter: {
            Rectangle()
                .foregroundColor(.blue)
        },
        bottomTrailing: {
            Rectangle().frame(height: 64)
                .foregroundColor(.blue)
        }
    )
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color.green)
}

#Preview("Top Trailing Bottom Leading") {
    InnerGridView(
        topTrailing: {
            Rectangle().frame(width: 64, height: 64)
                .foregroundColor(.blue)
        },
        bottomLeading: {
            Rectangle().frame(width: 64, height: 64)
                .foregroundColor(.blue)
        }
    )
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color.green)
}
