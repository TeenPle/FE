import Flutter
import Photos
import PhotosUI
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate,
  PHPickerViewControllerDelegate, UIImagePickerControllerDelegate,
  UINavigationControllerDelegate
{
  private let mediaChannelName = "teenple/media"
  private var pendingPickResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TeenpleMediaPlugin")
    let channel = FlutterMethodChannel(
      name: mediaChannelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleMediaCall(call, result: result)
    }
  }

  private func handleMediaCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickImage":
      pickImage(result: result)
    case "normalizeImageFile":
      normalizeImageFile(call: call, result: result)
    case "saveImageToGallery":
      saveImageToGallery(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pickImage(result: @escaping FlutterResult) {
    guard pendingPickResult == nil else {
      result(FlutterError(code: "PICK_IN_PROGRESS", message: "Image picker is already open.", details: nil))
      return
    }
    guard let presenter = topViewController() else {
      result(FlutterError(code: "PICK_FAILED", message: "Cannot present image picker.", details: nil))
      return
    }

    pendingPickResult = result
    if #available(iOS 14, *) {
      var configuration = PHPickerConfiguration(photoLibrary: .shared())
      configuration.filter = .images
      configuration.selectionLimit = 1
      let picker = PHPickerViewController(configuration: configuration)
      picker.delegate = self
      presenter.present(picker, animated: true)
    } else {
      let picker = UIImagePickerController()
      picker.delegate = self
      picker.sourceType = .photoLibrary
      presenter.present(picker, animated: true)
    }
  }

  @available(iOS 14, *)
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard let provider = results.first?.itemProvider else {
      finishPick(nil)
      return
    }

    provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] url, error in
      guard let self else { return }
      guard let url, error == nil else {
        self.finishPickError(error?.localizedDescription ?? "Cannot load selected image.")
        return
      }
      self.finishPickedFile(url: url, suggestedName: provider.suggestedName)
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    finishPick(nil)
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)
    guard let url = info[.imageURL] as? URL else {
      finishPickError("Cannot load selected image.")
      return
    }
    finishPickedFile(url: url, suggestedName: url.lastPathComponent)
  }

  private func finishPickedFile(url: URL, suggestedName: String?) {
    do {
      finishPick(try normalizedImagePayload(url: url, suggestedName: suggestedName))
    } catch {
      finishPickError(error.localizedDescription)
    }
  }

  private func normalizeImageFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let path = arguments["path"] as? String,
      !path.isEmpty
    else {
      result(FlutterError(code: "NORMALIZE_FAILED", message: "Image path is empty.", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      do {
        let payload = try self.normalizedImagePayload(
          url: URL(fileURLWithPath: path),
          suggestedName: arguments["name"] as? String
        )
        DispatchQueue.main.async {
          result(payload)
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "NORMALIZE_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func normalizedImagePayload(url: URL, suggestedName: String?) throws -> [String: Any] {
    let sourceData = try Data(contentsOf: url)
    let sourceExt = url.pathExtension.lowercased()
    let isPng = sourceExt == "png"
    let data: Data
    let ext: String
    if isPng {
      data = sourceData
      ext = "png"
    } else {
      guard let image = UIImage(data: sourceData), let jpeg = image.jpegData(compressionQuality: 0.9) else {
        throw NSError(
          domain: "TeenpleMediaPlugin",
          code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Cannot convert selected image."]
        )
      }
      data = jpeg
      ext = "jpg"
    }

    let suggestedBaseName = suggestedName?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .split(separator: ".")
      .dropLast()
      .joined(separator: ".")
    let baseName = suggestedBaseName?.isEmpty == false ? suggestedBaseName! : "image"
    let name = sanitizeName("\(baseName).\(ext)")
    let cacheDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(
      "picked_images",
      isDirectory: true
    )
    try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    let cachedURL = cacheDirectory.appendingPathComponent(
      "\(UUID().uuidString)_\(name)"
    )
    try data.write(to: cachedURL, options: .atomic)
    return [
      "path": cachedURL.path,
      "name": name,
      "mimeType": isPng ? "image/png" : "image/jpeg",
      "bytes": FlutterStandardTypedData(bytes: data),
    ]
  }

  private func finishPick(_ value: Any?) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      let result = self.pendingPickResult
      self.pendingPickResult = nil
      result?(value)
    }
  }

  private func finishPickError(_ message: String) {
    finishPick(FlutterError(code: "PICK_FAILED", message: message, details: nil))
  }

  private func saveImageToGallery(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let typedData = arguments["bytes"] as? FlutterStandardTypedData,
      !typedData.data.isEmpty
    else {
      result(FlutterError(code: "SAVE_FAILED", message: "Image bytes are empty.", details: nil))
      return
    }
    let requestedName = arguments["name"] as? String
    let name = sanitizeName(
      requestedName?.isEmpty == false
        ? requestedName!
        : "teenple_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
    )

    requestPhotoAddPermission { authorized in
      guard authorized else {
        result(FlutterError(code: "SAVE_DENIED", message: "Photo library access was denied.", details: nil))
        return
      }
      PHPhotoLibrary.shared().performChanges({
        let options = PHAssetResourceCreationOptions()
        options.originalFilename = name
        let request = PHAssetCreationRequest.forAsset()
        request.addResource(with: .photo, data: typedData.data, options: options)
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            result(true)
          } else {
            result(FlutterError(code: "SAVE_FAILED", message: error?.localizedDescription, details: nil))
          }
        }
      }
    }
  }

  private func requestPhotoAddPermission(completion: @escaping (Bool) -> Void) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        DispatchQueue.main.async {
          completion(status == .authorized || status == .limited)
        }
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        DispatchQueue.main.async {
          completion(status == .authorized)
        }
      }
    }
  }

  private func sanitizeName(_ name: String) -> String {
    name.replacingOccurrences(
      of: #"[\\/:*?"<>|]"#,
      with: "_",
      options: .regularExpression
    )
  }

  private func topViewController() -> UIViewController? {
    var controller = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { $0.isKeyWindow }?
      .rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }
}
