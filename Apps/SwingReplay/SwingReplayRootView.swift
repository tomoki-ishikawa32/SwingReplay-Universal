import SwiftUI
import UIKit

struct SwingReplayRootView: View {
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                ReceiverHostView()
            } else {
                SenderHostView()
            }
        }
    }
}

private struct SenderHostView: View {
    @StateObject private var runtime = PhoneRuntimeController()

    var body: some View {
        PhoneRootView(runtime: runtime)
            .onAppear {
                runtime.start()
            }
            .onDisappear {
                runtime.stop()
            }
    }
}

private struct ReceiverHostView: View {
    @StateObject private var runtime = PadRuntimeController()

    var body: some View {
        PadRootView(runtime: runtime)
            .onAppear {
                runtime.start()
            }
            .onDisappear {
                runtime.stop()
            }
    }
}
