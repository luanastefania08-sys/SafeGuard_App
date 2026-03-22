import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let securityChannel = FlutterMethodChannel(
      name: "com.safeguard.mobile/security",
      binaryMessenger: controller.binaryMessenger
    )

    securityChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "setSecureFlag":
        result(FlutterMethodNotImplemented)
      case "isSecureFlagEnabled":
        result(false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    // Ocultar contenido sensible cuando la app pasa a segundo plano
    window?.isHidden = false
    let blurEffect = UIBlurEffect(style: .dark)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.tag = 9999
    blurView.frame = window?.bounds ?? .zero
    window?.addSubview(blurView)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    // Remover overlay de privacidad cuando vuelve al frente
    window?.viewWithTag(9999)?.removeFromSuperview()
  }
}
