import SwiftUI
import WebKit

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var webViewModel = WebViewModel()
    @State private var urlString: String = "https://www.youtube.com"
    @State private var showURLInput: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom toolbar
            HStack {
                Spacer()
                
                Text("MacTube")
                    .padding(.leading, 110)
                
                Spacer()
                
                Button(action: {
                    self.webViewModel.webView.goBack()
                }) {
                    Image(nsImage: NSImage(named: "NSGoLeftTemplate")!)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .disabled(!webViewModel.canGoBack)
                
                Button(action: {
                    self.webViewModel.webView.goForward()
                }) {
                    Image(nsImage: NSImage(named: "NSGoRightTemplate")!)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .disabled(!webViewModel.canGoForward)
                
                Button(action: {
                    self.webViewModel.webView.reload()
                }) {
                    Image(nsImage: NSImage(named: "NSRefreshTemplate")!)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                
                Button(action: {
                    self.showURLInput.toggle()
                }) {
                    Image(nsImage: NSImage(named: "NSNetwork")!)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding()
            .background(colorScheme == .dark
                ? Color(NSColor(calibratedRed: 0.097, green: 0.097, blue: 0.097, alpha: 1))
                : Color(NSColor.windowBackgroundColor))
            
            if showURLInput {
                HStack {
                    TextField("Enter URL", text: $urlString, onCommit: {
                        webViewModel.loadURL(urlString)
                        showURLInput = false
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Go") {
                        webViewModel.loadURL(urlString)
                        showURLInput = false
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            WebView(viewModel: webViewModel)
        }
    }
}

class WebViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    
    var webView: WKWebView
    
    override init() {
        let config = WKWebViewConfiguration()
        
        // Basic preferences
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = false
        config.preferences = preferences
        
        // Increase process memory limit
            //  ProcessInfo.processInfo.increasedMemoryLimit = true
        
        // Configure process pool with more memory
        let processPool = WKProcessPool()
        config.processPool = processPool
        
        // Create webview with configuration
        self.webView = WKWebView(frame: .zero, configuration: config)
        
        super.init()
        
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        
        // Set up observers
        self.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack), options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward), options: .new, context: nil)
        
        // Initial loading
        if let url = URL(string: "https://www.youtube.com") {
            self.webView.load(URLRequest(url: url))
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "canGoBack" {
            self.canGoBack = self.webView.canGoBack
        }
        if keyPath == "canGoForward" {
            self.canGoForward = self.webView.canGoForward
        }
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward))
    }
    
    func loadURL(_ urlString: String) {
        webView.stopLoading()
        
        var finalURLString = urlString
        if !urlString.lowercased().hasPrefix("http") {
            finalURLString = "https://" + urlString
        }
        
        if let url = URL(string: finalURLString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    // MARK: - WKNavigationDelegate methods
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        if (error as NSError).code == NSURLErrorCancelled {
            return
        }
        print("Failed to load: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
}

struct WebView: NSViewRepresentable {
    @ObservedObject var viewModel: WebViewModel
    
    func makeNSView(context: Context) -> WKWebView {
        return viewModel.webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
    }
}
