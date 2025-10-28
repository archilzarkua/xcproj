import UIKit
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Firebase safe init: only call configure if GoogleService-Info.plist exists in bundle
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            // If Firebase is not added to the project via SPM/CocoaPods this will still crash.
            // The developer should add Firebase packages as described in FirebaseGuide.md
            #if canImport(FirebaseCore)
            FirebaseApp.configure()
            print("FirebaseApp configured")
            #else
            print("FirebaseCore not available. Add Firebase via SPM or CocoaPods.")
            #endif
        } else {
            print("GoogleService-Info.plist not found — running without Firebase.")
        }

        window = UIWindow(frame: UIScreen.main.bounds)
        let vc = GameViewController()
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        return true
    }
}
