# Swing Replay

Golf swing capture and relay project.

MVP architecture:
- iPhone app: capture + encode + send
- iPad app: receive + buffer + decode + display
- Shared module: packet/chunk/buffer/network logic (`SwingReplayCore`)

## Current Repository Status

This repository contains a universal iOS app target and a shared Swift package for core pipeline components.

- `Package.swift`: Swift Package definition
- `Sources/SwingReplayCore`: sender/receiver shared logic
- `Tests/SwingReplayCoreTests`: package unit tests
- `SwingReplayApps.xcodeproj`: app project (`SwingReplay`)
- `Apps/SwingReplay`: universal app entry/UI routing
- `Apps/SwingReplayPhone`: iPhone sender UI/runtime
- `Apps/SwingReplayPad`: iPad receiver UI/runtime
- `Config/*.plist`: app permissions and launch/orientation settings

## Core Files

- `Sources/SwingReplayCore/PhoneSenderSession.swift`
- `Sources/SwingReplayCore/PadReceiverSession.swift`
- `Sources/SwingReplayCore/CameraCaptureService.swift`
- `Sources/SwingReplayCore/RealtimeH264Encoder.swift`
- `Sources/SwingReplayCore/SenderTransportPipeline.swift`
- `Sources/SwingReplayCore/FramePacket.swift`
- `Sources/SwingReplayCore/FrameChunker.swift`
- `Sources/SwingReplayCore/DelayBuffer.swift`
- `Sources/SwingReplayCore/ReceiverPipeline.swift`
- `Sources/SwingReplayCore/RealtimeH264Decoder.swift`
- `Sources/SwingReplayCore/ReceiverVideoView.swift`
- `Sources/SwingReplayCore/ReceiverFailSafeController.swift`

## Verify

```bash
swift test
xcodebuild -project SwingReplayApps.xcodeproj -scheme SwingReplay -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```
