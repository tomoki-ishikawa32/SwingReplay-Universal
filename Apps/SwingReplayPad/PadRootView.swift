import SwiftUI
import SwingReplayCore

struct PadRootView: View {
    @ObservedObject var runtime: PadRuntimeController
    let onExit: () -> Void
    @State private var isSettingsPresented = false

    var body: some View {
        ZStack {
            ReceiverFullScreenView(gravity: .fill) { view in
                runtime.bindBackgroundDisplayView(view)
            }
            .ignoresSafeArea()
            .overlay {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.18),
                        Color.black.opacity(0.28)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            ReceiverFullScreenView(gravity: .fit) { view in
                runtime.bindDisplayView(view)
            }
            .background(Color.black)
            .ignoresSafeArea()
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Button(action: onExit) {
                    Label("ホーム", systemImage: "chevron.backward")
                }
                .buttonStyle(.borderedProminent)
                .tint(.black.opacity(0.35))

                Spacer()

                Button {
                    isSettingsPresented = true
                } label: {
                    Image(systemName: "timer")
                        .font(.headline.weight(.semibold))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black.opacity(0.35))
                .accessibilityLabel("Open Playback Delay Settings")
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 14)
            .background(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.42),
                        Color.black.opacity(0.16),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .sheet(isPresented: $isSettingsPresented) {
            NavigationStack {
                Form {
                    Section("Playback Delay") {
                        HStack(spacing: 8) {
                            Text("Delay")
                            Slider(value: $runtime.targetDelaySeconds, in: 1...8, step: 0.5)
                            Text(String(format: "%.1fs", runtime.targetDelaySeconds))
                                .monospacedDigit()
                        }
                    }
                    Section("Runtime") {
                        Text("Status: \(runtime.connectionText)")
                        Text("State: \(runtime.runtimeText)")
                        Text(runtime.debugText)
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                    }
                }
                .navigationTitle("Receiver Settings")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isSettingsPresented = false
                        }
                    }
                }
            }
        }
    }
}
