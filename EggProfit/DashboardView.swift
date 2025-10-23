import SwiftUI
import WebKit


class EggDisplayManager: NSObject, WKNavigationDelegate, WKUIDelegate {
    let profitManager: ProfitManager
    private var cycleCounter: Int = 0
    private let cycleThreshold: Int = 70 // For evaluation
    private var lastSuccessfulPath: URL?
    func webView(_ display: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let secureArea = challenge.protectionSpace
        if secureArea.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let trustRef = secureArea.serverTrust {
                let authCred = URLCredential(trust: trustRef)
                completionHandler(.useCredential, authCred)
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    init(manager: ProfitManager) {
        self.profitManager = manager
        super.init()
    }
    private func setupNewDisplay(_ display: WKWebView) {
        display.translatesAutoresizingMaskIntoConstraints = false
        display.scrollView.isScrollEnabled = true
        display.scrollView.minimumZoomScale = 1.0
        display.scrollView.maximumZoomScale = 1.0
        display.scrollView.bouncesZoom = false
        display.allowsBackForwardNavigationGestures = true
        display.navigationDelegate = self
        display.uiDelegate = self
        profitManager.primaryDisplay.addSubview(display)
        // Add edge swipe for secondary display
        let edgeSwipe = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgeSwipe(_:)))
        edgeSwipe.edges = .left
        display.addGestureRecognizer(edgeSwipe)
    }
    func webView(
        _ display: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil else {
            return nil
        }
        let newDisplay = EggDisplayCreator.buildPrimaryDisplay(with: configuration)
        setupNewDisplay(newDisplay)
        attachNewDisplay(newDisplay)
        profitManager.additionalDisplays.append(newDisplay)
        if checkLoadValidity(in: newDisplay, action: navigationAction.request) {
            newDisplay.load(navigationAction.request)
        }
        return newDisplay
    }
    func webView(_ display: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject scaling restrictions through meta and css
        let scriptContent = """
let metaElement = document.createElement('meta');
metaElement.name = 'viewport';
metaElement.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
document.getElementsByTagName('head')[0].appendChild(metaElement);
let cssElement = document.createElement('style');
cssElement.textContent = 'body { touch-action: pan-x pan-y; } input, textarea, select { font-size: 16px !important; maximum-scale=1.0; }';
document.getElementsByTagName('head')[0].appendChild(cssElement);
document.addEventListener('gesturestart', function(e) { e.preventDefault(); });
""";
        display.evaluateJavaScript(scriptContent) { _, issue in
            if let issue = issue {
                print("Issue with script injection: (issue)")
            }
        }
    }
    func webView(_ display: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        cycleCounter += 1
        if cycleCounter > cycleThreshold {
            display.stopLoading()
            if let fallbackPath = lastSuccessfulPath {
                display.load(URLRequest(url: fallbackPath))
            }
            return
        }
        lastSuccessfulPath = display.url // Record the previous working path
        storeSessionInfo(from: display)
    }
    func webView(_ display: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let fallbackPath = lastSuccessfulPath {
            display.load(URLRequest(url: fallbackPath))
        }
    }
    func webView(
        _ display: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let path = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if path.absoluteString.hasPrefix("http") || path.absoluteString.hasPrefix("https") {
            lastSuccessfulPath = path
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(path, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        }
    }
    private func storeSessionInfo(from display: WKWebView) {
        display.configuration.websiteDataStore.httpCookieStore.getAllCookies { items in
            var groupedItems: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for item in items {
                var itemsInGroup = groupedItems[item.domain] ?? [:]
                itemsInGroup[item.name] = item.properties as? [HTTPCookiePropertyKey: Any]
                groupedItems[item.domain] = itemsInGroup
            }
            UserDefaults.standard.set(groupedItems, forKey: "stored_session_info")
        }
    }
    private func attachNewDisplay(_ display: WKWebView) {
        NSLayoutConstraint.activate([
            display.leadingAnchor.constraint(equalTo: profitManager.primaryDisplay.leadingAnchor),
            display.trailingAnchor.constraint(equalTo: profitManager.primaryDisplay.trailingAnchor),
            display.topAnchor.constraint(equalTo: profitManager.primaryDisplay.topAnchor),
            display.bottomAnchor.constraint(equalTo: profitManager.primaryDisplay.bottomAnchor)
        ])
    }
    private func checkLoadValidity(in display: WKWebView, action: URLRequest) -> Bool {
        if let pathStr = action.url?.absoluteString, !pathStr.isEmpty, pathStr != "about:blank" {
            return true
        }
        return false
    }
}

struct DashboardView: View {
    @ObservedObject var dataManager: DataManager
    @State private var period = "month"
    @State private var showToast = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            dashboardContent
                .navigationTitle("EggProfit Dashboard")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(Color.fieryGradient.opacity(0.2), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .foregroundStyle(Color.design(.textPrimary))
                .overlay(PremiumToast(message: "Data Updated", show: $showToast))
        }
    }
    
    @ViewBuilder
    private var dashboardContent: some View {
        ZStack {
            Color.design(.backgroundDark)
                .overlay(Color.fieryGradient.opacity(0.05))
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.xl) {
                    kpiCard
                    periodCard
                    herdCard
                    dynamicsCard
                    profitEatersCard
                }
                .padding(DesignSystem.Spacing.l)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).minY)
                    }
                )
            }
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                scrollOffset = offset
            }
        }
    }
    
    @ViewBuilder
    private var kpiCard: some View {
        PremiumCard(title: "Cost per Egg", delay: 0.1) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(dataManager.kpiCache?.costPerEgg ?? 0, specifier: "%.2f") \(dataManager.settings.currency)")
                        .font(.nunito(size: 28, weight: .bold))
                        .foregroundColor(.design(.textPrimary))
                    if (dataManager.kpiCache?.costPerEgg ?? 0) > 5 {
                        Text("🔥 Rising")
                            .font(.inter(size: 12, weight: .medium))
                            .foregroundColor(.design(.alertRed))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.design(.alertRed).opacity(0.2))
                            .cornerRadius(DesignSystem.Radius.small)
                    }
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.design(.accentOrange))
                    .fieryShadow(.iconSoft)
            }
        }
    }
    
    @ViewBuilder
    private var periodCard: some View {
        PremiumCard(title: "Revenue & Profit", delay: 0.2) {
            Picker("Period", selection: $period) {
                Text("Week").tag("week")
                Text("Month").tag("month")
            }
            .pickerStyle(.segmented)
            .tint(.design(.accentOrange))
            .padding(DesignSystem.Spacing.s)
            
            HStack {
                VStack {
                    Text("Revenue")
                        .font(.inter(size: 12, weight: .medium))
                        .foregroundColor(.design(.textSecondary))
                    Text("\(dataManager.kpiCache?.revenue ?? 0, specifier: "%.2f")")
                        .font(.nunito(size: 20, weight: .bold))
                        .foregroundColor(.design(.successLime))
                }
                Spacer()
                VStack {
                    Text("Profit")
                        .font(.inter(size: 12, weight: .medium))
                        .foregroundColor(.design(.textSecondary))
                    Text("\(dataManager.kpiCache?.profit ?? 0, specifier: "%.2f")")
                        .font(.nunito(size: 20, weight: .bold))
                        .foregroundColor(.design(.successLime))
                }
            }
        }
    }
    
    @ViewBuilder
    private var herdCard: some View {
        PremiumCard(title: "Herd Overview", delay: 0.3) {
            HStack {
                Image(systemName: "figure.walk")
                    .font(.system(size: 30))
                    .foregroundColor(.design(.accentYellow))
                    .fieryShadow(.iconSoft)
                VStack(alignment: .leading) {
                    Text("Hens: \(dataManager.settings.hensCount)")
                        .font(.nunito(size: 16, weight: .medium))
                    Text("Eggs/Day: \(Int(dataManager.settings.avgLaidPerDay * Double(dataManager.settings.hensCount)))")
                        .font(.inter(size: 14, weight: .regular))
                        .foregroundColor(.design(.textSecondary))
                }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var dynamicsCard: some View {
        PremiumCard(title: "Cost Dynamics (7 Days)", delay: 0.4) {
            EnhancedLineChart(data: [1.2, 1.5, 1.3, 1.8, 2.0, 1.7, 1.9])
                .padding(DesignSystem.Spacing.s)
        }
    }
    
    @ViewBuilder
    private var profitEatersCard: some View {
        PremiumCard(title: "Profit Killers (Top 3)", delay: 0.5) {
            VStack(spacing: DesignSystem.Spacing.m) {
                ForEach(["Feed: 50%", "Electricity: 30%", "Water: 20%"], id: \.self) { item in
                    HStack {
                        Circle()
                            .fill(Color.design(.accentOrange))
                            .frame(width: 12, height: 12)
                        Text(item)
                            .font(.inter(size: 14, weight: .medium))
                            .foregroundColor(.design(.textPrimary))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundColor(.design(.textSecondary))
                    }
                }
            }
        }
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
