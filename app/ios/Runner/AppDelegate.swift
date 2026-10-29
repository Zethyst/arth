import CoreHaptics
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Local notifications (review reminders) show while the app is open and
    // report taps; FlutterAppDelegate passes these on to the plugins.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // A device id that survives reinstalling the app (the free AI allowance
    // is per phone): kept in the Keychain, which outlives the app.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ArthDevice") {
      let channel = FlutterMethodChannel(name: "arth/device", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        if call.method == "stableId" {
          result(StableDeviceId.value())
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    // The hum under a page being turned (PageHaptics in feel.dart).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ArthHaptics") {
      let channel = FlutterMethodChannel(name: "arth/haptics", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        let args = call.arguments as? [String: Any]
        switch call.method {
        case "pageStart":
          PageTurnHaptics.shared.start()
        case "pageUpdate":
          PageTurnHaptics.shared.update(
            intensity: Float(args?["intensity"] as? Double ?? 0),
            sharpness: Float(args?["sharpness"] as? Double ?? 0))
        case "pageStop":
          PageTurnHaptics.shared.stop()
        default:
          result(FlutterMethodNotImplemented)
          return
        }
        result(nil)
      }
    }
  }
}

/// One long continuous haptic, started when a page lifts and stopped when it
/// settles, its strength and sharpness changed as the page moves.
final class PageTurnHaptics {
  static let shared = PageTurnHaptics()

  private var engine: CHHapticEngine?
  private var player: CHHapticAdvancedPatternPlayer?

  private func ready() -> CHHapticEngine? {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }
    if let engine { return engine }
    guard let made = try? CHHapticEngine() else { return nil }
    made.playsHapticsOnly = true
    made.isAutoShutdownEnabled = true
    // The system stopped or reset the engine (the app went to the
    // background, audio was interrupted): build a fresh one next time.
    made.stoppedHandler = { [weak self] _ in
      self?.player = nil
      self?.engine = nil
    }
    made.resetHandler = { [weak self] in
      self?.player = nil
      self?.engine = nil
    }
    engine = made
    return made
  }

  func start() {
    guard let engine = ready() else { return }
    stop()
    do {
      try engine.start()
      // Full scale here; pageUpdate scales it down with its own values.
      let event = CHHapticEvent(
        eventType: .hapticContinuous,
        parameters: [
          CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
          CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
        ],
        relativeTime: 0,
        duration: 30)
      let made = try engine.makeAdvancedPlayer(with: CHHapticPattern(events: [event], parameters: []))
      try made.sendParameters(
        [CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: 0, relativeTime: 0)],
        atTime: CHHapticTimeImmediate)
      try made.start(atTime: CHHapticTimeImmediate)
      player = made
    } catch {
      player = nil
    }
  }

  func update(intensity: Float, sharpness: Float) {
    try? player?.sendParameters(
      [
        CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: intensity, relativeTime: 0),
        // Relative to the event's 0.5: -0.5 is the softest, papery end.
        CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: sharpness - 0.5, relativeTime: 0),
      ],
      atTime: CHHapticTimeImmediate)
  }

  func stop() {
    try? player?.stop(atTime: CHHapticTimeImmediate)
    player = nil
  }
}

/// A random id created once and kept in the Keychain. "This device only":
/// it isn't synced to the reader's other devices or restored onto a new one.
enum StableDeviceId {
  private static let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "com.zethyst.arth.device",
    kSecAttrAccount as String: "id",
  ]

  static func value() -> String? {
    var read = query
    read[kSecReturnData as String] = true
    read[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    if SecItemCopyMatching(read as CFDictionary, &item) == errSecSuccess,
       let data = item as? Data, let id = String(data: data, encoding: .utf8) {
      return id
    }
    let id = UUID().uuidString
    var add = query
    add[kSecValueData as String] = Data(id.utf8)
    add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    return SecItemAdd(add as CFDictionary, nil) == errSecSuccess ? id : nil
  }
}
