import FerrostarCore
import FerrostarCoreFFI
import SwiftUI

public struct MuteUIButton: View {

    // MARK: Properties

    let isMuted: Bool
    let action: () -> Void

    // MARK: Lifecycle

    public init(isMuted: Bool, action: @escaping () -> Void) {
        self.isMuted = isMuted
        self.action = action
    }

    // MARK: Content

    public var body: some View {
        Button(action: self.action) {
            Image(systemName: self.isMuted ? "speaker.slash.fill" : "speaker.2.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .padding()
        }
        .foregroundColor(.black)
        .background(Color.white)
        .clipShape(Circle())
    }
}

#Preview {
    MuteUIButton(isMuted: true, action: {})

    MuteUIButton(isMuted: false, action: {})
}
