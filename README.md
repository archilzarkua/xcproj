CRUSH GAME v3 — Full Prototype (Landscape, UIKit Shop, Firebase-safe, Programmatic VFX)
=====================================================================================

What's included:
- AppDelegate.swift (Firebase-safe initialization)
- GameViewController.swift (landscape)
- GameScene.swift (gameplay; programmatic particles for crash/smoke)
- ShopViewController.swift (UIKit shop + purchases working with local profile)
- FirebaseManager.swift (uses Firebase if GoogleService-Info.plist provided; otherwise mock)
- AdsManager.swift (AdMob scaffold using test IDs; SDK integration required)
- Assets placeholder list and instructions
- Updated guides and how-to-run steps

Important notes:
- Add your GoogleService-Info.plist file to the Xcode project root to enable Firebase features.
- Add AdMob App ID in Info.plist and integrate GoogleMobileAds SDK to enable rewarded ads.
- This prototype uses test AdMob IDs and will gracefully degrade if dependencies are missing.

How to preview:
1. Open Xcode -> New Game -> SpriteKit (Swift).
2. Add these Swift files to the project, replace default ones.
3. In Project Settings -> Deployment Info -> check Landscape orientations only.
4. Add placeholder images to Assets.xcassets with names used in the code.
5. Build & Run in simulator or device.

If you want, paste your GoogleService-Info.plist here (or upload) and I will integrate and test code paths that call Firebase. For security, do not paste public keys in chat; instead upload the file via the app file upload feature if you want me to include it in the package.
