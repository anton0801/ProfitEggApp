import SwiftUI
import UserNotifications
import Network
import Firebase
import FirebaseMessaging
import AppsFlyerLib
import AppTrackingTransparency

@main
struct EggProfitApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            SplashEggProfitAppView()
        }
    }
    
}


class AppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    private var conversionData: [AnyHashable: Any] = [:]
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        processPushPayload(userInfo)
        completionHandler(.newData)
    }
    
    private func setUpAppsfluer() {
        AppsFlyerLib.shared().appsFlyerDevKey = "efbC7vNvdEdhD44rPp5wS4"
        AppsFlyerLib.shared().appleAppID = "6753625851"
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().start()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
    
        setUpAppsfluer()
        
        if let notifPayload = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            processPushPayload(notifPayload)
        }
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activateTracking),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let payload = notification.request.content.userInfo
        processPushPayload(payload)
        completionHandler([.banner, .sound])
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    
    // AppsFlyer callbacks
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        conversionData = data
        NotificationCenter.default.post(name: Notification.Name("ConversionDataReceived"), object: nil, userInfo: ["conversionData": conversionData])
    }
    
    
    @objc private func activateTracking() {
        AppsFlyerLib.shared().start()
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
            }
        }
    }
    
    func onConversionDataFail(_ error: Error) {
        NotificationCenter.default.post(name: Notification.Name("ConversionDataFailed"), object: nil, userInfo: ["conversionData": [:]])
    }
    
    private func processPushPayload(_ payload: [AnyHashable: Any]) {
        var linkStr: String?
        if let link = payload["url"] as? String {
            linkStr = link
        } else if let info = payload["data"] as? [String: Any], let link = info["url"] as? String {
            linkStr = link
        }
        
        if let linkStr = linkStr {
            UserDefaults.standard.set(linkStr, forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NotificationCenter.default.post(name: NSNotification.Name("LoadTempURL"), object: nil, userInfo: ["tempUrl": linkStr])
            }
        }
    }
    
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, err in
            if let _ = err {
            }
            UserDefaults.standard.set(token, forKey: "fcm_token")
        }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let payload = response.notification.request.content.userInfo
        processPushPayload(payload)
        completionHandler()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
}
