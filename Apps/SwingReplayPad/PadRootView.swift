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
            ZStack {
                Color(red: 0.97, green: 0.97, blue: 0.99)
                    .ignoresSafeArea()

                VStack {
                    VStack(alignment: .leading, spacing: 28) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("再生遅延")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(red: 0.13, green: 0.14, blue: 0.18))

                                Text("映像の表示タイミングを調整します")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(Color.black.opacity(0.48))
                            }

                            Spacer()

                            Button("完了") {
                                isSettingsPresented = false
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 42)
                            .background(
                                Color(red: 0.10, green: 0.41, blue: 0.84),
                                in: Capsule(style: .continuous)
                            )
                        }

                        VStack(alignment: .leading, spacing: 18) {
                            HStack {
                                Text("遅延")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.13, green: 0.14, blue: 0.18))

                                Spacer()

                                Text(String(format: "%.1f秒", runtime.targetDelaySeconds))
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.13, green: 0.14, blue: 0.18))
                                    .monospacedDigit()
                                    .frame(minWidth: 72, alignment: .trailing)
                            }

                            Slider(value: $runtime.targetDelaySeconds, in: 1...8, step: 0.5)
                                .tint(Color(red: 0.10, green: 0.41, blue: 0.84))
                        }
                        .padding(28)
                        .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        }
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 36)

                    Spacer()
                }
            }
        }
    }
}
