import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, UIDocumentPickerDelegate {

  private let channelName = "com.snapdock.videodownloader/folder"
  private var folderResultCallback: FlutterResult?

  private func whatsappSourceDirectory() -> URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    return base.appendingPathComponent("whatsapp_statuses_ios_source", isDirectory: true)
  }

  private func ensureWhatsappSourceDirectory() throws {
    let dir = whatsappSourceDirectory()
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
  }

  private func clearWhatsappSourceDirectory() {
    let dir = whatsappSourceDirectory()
    if let items = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
      for url in items {
        try? FileManager.default.removeItem(at: url)
      }
    }
  }

  private func copyIntoWhatsappSource(sourceURL: URL) throws {
    try ensureWhatsappSourceDirectory()

    let dir = whatsappSourceDirectory()
    let originalName = sourceURL.lastPathComponent
    let ext = (sourceURL.pathExtension.isEmpty ? "dat" : sourceURL.pathExtension)
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let destName = "\(timestamp)_\(originalName)"
    let destURL = dir.appendingPathComponent(destName)

    // Some document picker URLs are security-scoped. Start access before copying.
    if sourceURL.startAccessingSecurityScopedResource() {
      defer { sourceURL.stopAccessingSecurityScopedResource() }
    }

    // Attempt to copy the picked file into our app storage.
    // `asCopy: true` in UIDocumentPicker typically provides a readable URL.
    try FileManager.default.copyItem(at: sourceURL, to: destURL)

    // Touch destination to ensure it's valid (no-op for most cases).
    _ = destURL as URL
    _ = ext
  }

  private func listWhatsappStatusFiles() -> [String] {
    let allowedVideoExt = Set(["mp4", "mov", "avi", "mkv"])
    let allowedImageExt = Set(["jpg", "jpeg", "png", "gif", "webp"])

    let dir = whatsappSourceDirectory()
    guard let urls = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
      return []
    }

    return urls.compactMap { url in
      let ext = url.pathExtension.lowercased()
      if allowedVideoExt.contains(ext) || allowedImageExt.contains(ext) {
        return url.path
      }
      return nil
    }
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "openWhatsAppFolderPicker":
      folderResultCallback = result
      openWhatsAppStatusPicker()
    case "listFilesInFolder":
      // iOS ignores the passed uri and lists from the app cache directory.
      let files = listWhatsappStatusFiles()
      result(files)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func openWhatsAppStatusPicker() {
    // On iOS we cannot directly read WhatsApp's internal .Statuses folder.
    // Instead, ask the user to pick WhatsApp status media files the app can access.
    do {
      clearWhatsappSourceDirectory()
    }

    // Use legacy documentTypes so this compiles on iOS < 14.
    // `public.movie` covers typical video formats; `public.image` covers images.
    let picker = UIDocumentPickerViewController(documentTypes: ["public.movie", "public.image"], in: .open)
    picker.delegate = self
    picker.allowsMultipleSelection = true
    picker.modalPresentationStyle = .formSheet

    if let controller = window?.rootViewController {
      controller.present(picker, animated: true, completion: nil)
    } else {
      folderResultCallback?("")
      folderResultCallback = nil
    }
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    // Copy chosen files into app storage so Flutter can list and download consistently.
    do {
      for url in urls {
        try copyIntoWhatsappSource(sourceURL: url)
      }
      folderResultCallback?("ios_whatsapp_status_source_cache")
    } catch {
      folderResultCallback?(FlutterError(code: "PICK_ERROR", message: error.localizedDescription, details: nil))
    }

    folderResultCallback = nil
    controller.dismiss(animated: true, completion: nil)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    folderResultCallback?("")
    folderResultCallback = nil
    controller.dismiss(animated: true, completion: nil)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Configure the MethodChannel after Flutter view controller is created.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }
        self.handleMethodCall(call, result: result)
      }
    }

    return didFinish
  }

  // Prevent iOS from restoring an old UI state on relaunch.
  // This avoids stale state restoration crashes/black screen in debug builds.
  override func application(
    _ application: UIApplication,
    shouldSaveSecureApplicationState coder: NSCoder
  ) -> Bool {
    return false
  }

  override func application(
    _ application: UIApplication,
    shouldRestoreSecureApplicationState coder: NSCoder
  ) -> Bool {
    return false
  }
}
