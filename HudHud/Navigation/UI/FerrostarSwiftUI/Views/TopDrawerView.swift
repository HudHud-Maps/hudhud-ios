import SwiftUI

// MARK: - TopDrawerView

/// An expandable drawer view that you can pull down to expose more content.
///
/// The `PersistentContent` is always visible.
/// When `ExpandedContent` is present, tapping or dragging on the drawer's handle expands the view to fill its
/// container, exposing the `ExpandedContent` in a scrollable view.
struct TopDrawerView<PersistentContent: View, ExpandedContent: View>: View {

    // MARK: Properties

    private var backgroundColor: Color
    private var persistentContent: () -> PersistentContent
    private var expandedContent: () -> ExpandedContent?
    @Binding
    private var isExpanded: Bool

    @State
    private var dragOffset: CGFloat = 0

    // MARK: Computed Properties

    private var content: AnyView {
        guard let expandedContent = expandedContent() else {
            return AnyView(self.persistentContent())
        }

        let scrollView = ScrollView {
            // Pad to ensure the bottom of the ScrollView's content is not covered by the handle.
            expandedContent.padding(.bottom, 50)
        }

        let framedScrollView = if self.isExpanded {
            AnyView(scrollView.frame(idealHeight: CGFloat.infinity))
        } else {
            AnyView(scrollView.frame(height: max(0, self.dragOffset)))
        }

        let paddingAboveHandle = 6.0
        return AnyView(ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                self.persistentContent()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.isExpanded = !self.isExpanded
                        }
                    }
                if #available(iOS 16.4, *) {
                    framedScrollView.scrollBounceBehavior(.basedOnSize)
                } else {
                    framedScrollView
                }
            }.padding(.bottom, paddingAboveHandle)
            Handle(isExpanded: self.$isExpanded, dragOffset: self.$dragOffset, backgroundTopPadding: paddingAboveHandle)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.isExpanded = !self.isExpanded
                    }
                }
        })
    }

    // MARK: Lifecycle

    /// - Parameters:
    ///   - backgroundColor: Applied to the context around both the persistent and expanded content
    ///   - persistentContent: This content is always visible. When the drawer is closed, the handle appears just below
    /// the persistent content.
    ///   - expandedContent: This content is only visible when the drawer is expanded. If you omit `expandedContent`, no
    /// handle will be visible.
    init(backgroundColor: Color,
         isExpanded: Binding<Bool> = .constant(false),
         @ViewBuilder persistentContent: @escaping () -> PersistentContent,
         @ViewBuilder expandedContent: @escaping () -> ExpandedContent?) {
        self.backgroundColor = backgroundColor
        _isExpanded = isExpanded
        self.persistentContent = persistentContent
        self.expandedContent = expandedContent
    }

    // MARK: Content

    public var body: some View {
        self.content
            .background(self.backgroundColor)
            .cornerRadius(12)
            .shadow(radius: 12)
            // Interactive dismiss
            .padding(.bottom, self.isExpanded ? max(0, -self.dragOffset) : 0)
    }
}

extension TopDrawerView where ExpandedContent == EmptyView {
    init(backgroundColor: Color,
         isExpanded: Binding<Bool> = .constant(false),
         @ViewBuilder persistentContent: @escaping () -> PersistentContent) {
        self.backgroundColor = backgroundColor
        _isExpanded = isExpanded
        self.persistentContent = persistentContent
        self.expandedContent = { nil }
    }
}

// MARK: - Handle

private struct Handle: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding
    var isExpanded: Bool

    @Binding
    var dragOffset: CGFloat

    var backgroundTopPadding: CGFloat

    // Style
    var foregroundColor: Color = .gray.opacity(0.7)

    var blurStyle: UIBlurEffect.Style {
        self.colorScheme == .light ? .light : .dark
    }

    var body: some View {
        HStack {
            Spacer()
            if self.isExpanded {
                Image(systemName: "chevron.up")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(self.foregroundColor)
                    .padding(.bottom, 16)
            } else {
                Capsule()
                    .foregroundStyle(self.foregroundColor)
                    .frame(width: 40, height: 6)
                    .padding(.bottom, 8)
            }
            Spacer()
        }
        .padding(.top, self.backgroundTopPadding)
        .background(BlurView(style: self.blurStyle))
        // Increase the hit area for the DragGesture with a transparent overlap
        .padding(.top, 20)
        // Required for gesture to "hit" over clear padding
        .contentShape(Rectangle())
        .gesture(DragGesture(coordinateSpace: .global)
            .onChanged { gesture in
                self.dragOffset = gesture.translation.height
            }
            .onEnded { gesture in
                let predictedDragOffset = gesture.predictedEndTranslation.height
                withAnimation(.easeInOut(duration: 0.2)) {
                    // If the user has dragged sufficiently far or with sufficient gusto, consider it an expansion.
                    if self.isExpanded {
                        self.isExpanded = predictedDragOffset > -200
                    } else {
                        self.isExpanded = predictedDragOffset > 200
                    }
                    self.dragOffset = 0
                }
            })
    }
}

// MARK: - BlurView

private struct BlurView: UIViewRepresentable {

    // MARK: Properties

    var style: UIBlurEffect.Style

    // MARK: Functions

    func makeUIView(context _: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }

    func updateUIView(_: UIVisualEffectView, context _: Context) {
        // no-op
    }
}

#Preview("floating") {
    VStack {
        TopDrawerView(
            backgroundColor: .white,
            persistentContent: {
                HStack {
                    Spacer()
                    Text("Persistent Content")
                    Spacer()
                }.padding()
            },
            expandedContent: {
                HStack {
                    Spacer()
                    VStack {
                        Text("Expanded Content 1")
                        Text("Expanded Content 2")
                        Text("Expanded Content 3")
                        Text("Expanded Content 4")
                        Text("Expanded Content 5")
                        Text("Expanded Content 6")
                    }
                    Spacer()
                }
            }
        )
        .padding(.horizontal)
        Spacer()
    }.background(.green)
}

#Preview("floating without expanded content") {
    VStack {
        TopDrawerView(
            backgroundColor: .white,
            persistentContent: {
                HStack {
                    Spacer()
                    Text("Persistent Content")
                    Spacer()
                }.padding()
            }
        )
        .padding(.horizontal)
        Spacer()
    }.background(.green)
}

// Only suitable for non-notched devices
#Preview("to edge") {
    VStack {
        TopDrawerView(
            backgroundColor: .white,
            persistentContent: {
                HStack {
                    Spacer()
                    Text("Persistent Content")
                    Spacer()
                }.padding()
            },
            expandedContent: {
                HStack {
                    Spacer()
                    VStack {
                        Text("Expanded Content 1")
                        Text("Expanded Content 2")
                        Text("Expanded Content 3")
                        Text("Expanded Content 4")
                        Text("Expanded Content 5")
                        Text("Expanded Content 6")
                    }
                    Spacer()
                }
            }
        )
        .ignoresSafeArea()
        Spacer()
    }.background(.green)
}