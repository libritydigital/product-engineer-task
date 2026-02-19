import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var volumeHandler: VolumeButtonHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "VolumeButtonListener"
    )
    guard let messenger = registrar?.messenger() else { return }

    volumeHandler = VolumeButtonHandler()
    volumeHandler?.register(with: messenger)
  }
}

// MARK: - Volume button handler

class VolumeButtonHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var isListening = false
  private var lastVolume: Float = -1

  func register(with messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(
      name: "com.example.product_engineer_task/volume_buttons",
      binaryMessenger: messenger
    )
    let eventChannel = FlutterEventChannel(
      name: "com.example.product_engineer_task/volume_button_events",
      binaryMessenger: messenger
    )

    methodChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "startListening":
        self?.startObserving()
        result(nil)
      case "stopListening":
        self?.stopObserving()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    eventChannel.setStreamHandler(self)
  }

  // MARK: FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  // MARK: AVAudioSession KVO

  private func startObserving() {
    guard !isListening else { return }
    isListening = true

    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try session.setActive(true)
    } catch {
      print("[VolumeButtonHandler] Failed to activate audio session: \(error)")
    }
    lastVolume = session.outputVolume
    session.addObserver(self, forKeyPath: "outputVolume", options: [.new, .old], context: nil)
  }

  private func stopObserving() {
    guard isListening else { return }
    isListening = false
    AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
  }

  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey: Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    guard keyPath == "outputVolume", isListening else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
      return
    }

    let newVolume = change?[.newKey] as? Float ?? 0
    let oldVolume = change?[.oldKey] as? Float ?? lastVolume
    lastVolume = newVolume

    if newVolume > oldVolume {
      eventSink?("up")
    } else if newVolume < oldVolume {
      eventSink?("down")
    }
  }

  deinit {
    stopObserving()
  }
}
