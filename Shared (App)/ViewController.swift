//
//  ViewController.swift
//  Shared (App)
//
//  Created by Neo on 2025/11/3.
//

import WebKit

#if os(iOS)
import UIKit

typealias PlatformViewController = UIViewController
#elseif os(macOS)
import Cocoa
import SafariServices

typealias PlatformViewController = NSViewController
#endif

let extensionBundleIdentifier = "me.uuneo.Meows.Extension"

class ViewController: PlatformViewController, WKNavigationDelegate, WKScriptMessageHandler {
    @IBOutlet var webView: WKWebView!

    #if os(macOS)
    var extensionStateTimer: Timer?
    var lastExtensionEnabledState: Bool?
    
    func startExtensionStateMonitor() {
        extensionStateTimer = Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(checkExtensionState),
            userInfo: nil,
            repeats: true
        )
    }
    

    @objc func checkExtensionState(_ timer: Timer) {
        SFSafariExtensionManager
            .getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { state, error in
                guard let state = state, error == nil, self.lastExtensionEnabledState != state.isEnabled else {
                    return
                }
                

                DispatchQueue.main.async {
                    guard let webView = self.webView else { return }
                    self.lastExtensionEnabledState = state.isEnabled

                    if #available(macOS 13, *) {
                        webView.evaluateJavaScript("show('mac', \(state.isEnabled), true)")
                    } else {
                        webView.evaluateJavaScript("show('mac', \(state.isEnabled), false)")
                    }
                }
            }
    }

    #endif

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self

        #if os(iOS)
        webView.scrollView.isScrollEnabled = false
        #endif

        webView.configuration.userContentController.add(self, name: "controller")

        webView.loadFileURL(
            Bundle.main.url(forResource: "Main", withExtension: "html")!,
            allowingReadAccessTo: Bundle.main.resourceURL!
        )
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        #if os(iOS)
        webView.evaluateJavaScript("show('ios')")
        #elseif os(macOS)
        webView.evaluateJavaScript("show('mac')")

        startExtensionStateMonitor()
        #endif
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        let body = message.body as! String
        #if os(macOS)
        if body  == "open-preferences" {
            SFSafariApplication
                .showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { error in
                    guard error == nil else {
                        // Insert code to inform the user that something went wrong.
                        return
                    }
    
                   
                }
            return
        }else if body  == "close"{
            DispatchQueue.main.async {
                NSApp.terminate(self)
            }
        }

        
        #endif
    }
}
