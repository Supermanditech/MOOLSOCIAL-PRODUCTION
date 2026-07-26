#if DEBUG
  import CryptoKit
  import Flutter
  import Foundation
  import Security
  import UIKit
  import WebKit

  final class YouTubeEmbeddedPlayerPlatformView:
    NSObject, FlutterPlatformView, WKNavigationDelegate, WKUIDelegate,
    WKScriptMessageHandler
  {
    private static let playerBaseURL = "https://com.moolsocial.app/"
    private static let playerHost = "com.moolsocial.app"
    private static let nonceMarker = "__MOOLSOCIAL_NATIVE_PORT_NONCE__"
    private static let expectedBootstrapSHA256 =
      "F63983016541BF07FD5390EACB34B8CCA7B6A564957DCD647A643689B27D0FBB"
    private static let minimumPlayerDimension = 200.0
    private static let maximumMessageBytes = 8_192
    private static let readyTimeoutSeconds = 15.0
    private static let mountKeys: Set<String> = [
      "bootstrapHtml",
      "baseUrl",
      "width",
      "height",
      "aspect",
    ]
    private static let sendKeys: Set<String> = ["message"]
    private static let playerAspects: Set<String> = [
      "standardVideo",
      "verifiedVerticalShort",
    ]
    private static let providerFrameHostSuffixes = [
      "youtube.com",
      "youtube-nocookie.com",
      "googlevideo.com",
      "ytimg.com",
      "gstatic.com",
      "doubleclick.net",
      "googlesyndication.com",
      "googleadservices.com",
      "google.com",
    ]
    private static let externalAccountHosts: Set<String> = [
      "accounts.google.com",
      "myaccount.google.com",
    ]

    // These scripts only create and use the private MessagePort. They never
    // inspect a player command/event or execute caller-provided JavaScript.
    private static let connectPortScript = """
      if (window.__moolsocialNativePlayerPort !== undefined) {
        return false;
      }
      const channel = new MessageChannel();
      channel.port1.onmessage = function(event) {
        if (typeof event.data !== 'string') return;
        const handler = window.webkit.messageHandlers[handlerName];
        if (handler) handler.postMessage(event.data);
      };
      channel.port1.start();
      window.__moolsocialNativePlayerPort = channel.port1;
      window.postMessage(
        connection,
        'https://com.moolsocial.app',
        [channel.port2]
      );
      return true;
      """

    private static let sendMessageScript = """
      const port = window.__moolsocialNativePlayerPort;
      if (port === undefined) return false;
      port.postMessage(message);
      return true;
      """

    private let rootView: UIView
    private let channel: FlutterMethodChannel

    private var webView: WKWebView?
    private var scriptHandlerName: String?
    private var connectionNonce: String?
    private var bridgeConnected = false
    private var bridgeEventReceived = false
    private var bootstrapLoadPending = false
    private var readyTimeout: Timer?
    private var disposed = false

    init(
      frame: CGRect,
      viewId: Int64,
      messenger: FlutterBinaryMessenger
    ) {
      rootView = UIView(frame: frame)
      rootView.backgroundColor = .black
      channel = FlutterMethodChannel(
        name: "\(YouTubeEmbeddedPlayerPlatformViewFactory.viewType)/\(viewId)",
        binaryMessenger: messenger
      )
      super.init()
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(
            FlutterError(
              code: "disposed",
              message: "The provider player view is unavailable.",
              details: nil
            )
          )
          return
        }
        self.handle(call, result: result)
      }
    }

    deinit {
      dispose()
    }

    func view() -> UIView {
      rootView
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      guard !disposed else {
        result(
          FlutterError(
            code: "disposed",
            message: "The provider player view is disposed.",
            details: nil
          )
        )
        return
      }
      switch call.method {
      case "mount":
        mount(call.arguments, result: result)
      case "send":
        send(call.arguments, result: result)
      case "detach":
        guard call.arguments == nil else {
          result(
            FlutterError(
              code: "invalid_detach",
              message: "Detach accepts no payload.",
              details: nil
            )
          )
          return
        }
        destroyCurrentWebView()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    private func mount(_ arguments: Any?, result: @escaping FlutterResult) {
      guard
        let values = arguments as? [String: Any],
        Set(values.keys) == Self.mountKeys,
        let template = values["bootstrapHtml"] as? String,
        let baseURL = values["baseUrl"] as? String,
        baseURL == Self.playerBaseURL,
        let width = finiteDouble(values["width"]),
        let height = finiteDouble(values["height"]),
        width >= Self.minimumPlayerDimension,
        height >= Self.minimumPlayerDimension,
        let aspect = values["aspect"] as? String,
        Self.playerAspects.contains(aspect)
      else {
        result(
          FlutterError(
            code: "invalid_mount",
            message: "Mount payload is invalid.",
            details: nil
          )
        )
        return
      }
      guard sha256(template) == Self.expectedBootstrapSHA256 else {
        result(
          FlutterError(
            code: "bootstrap_mismatch",
            message: "The player bootstrap is not approved.",
            details: nil
          )
        )
        return
      }
      guard template.components(separatedBy: Self.nonceMarker).count == 2 else {
        result(
          FlutterError(
            code: "bootstrap_nonce",
            message: "The player bootstrap nonce marker is invalid.",
            details: nil
          )
        )
        return
      }
      guard
        let nonce = makeNonce(),
        let approvedBaseURL = URL(string: Self.playerBaseURL)
      else {
        result(
          FlutterError(
            code: "native_entropy",
            message: "The provider player connection could not be created.",
            details: nil
          )
        )
        return
      }

      destroyCurrentWebView()
      connectionNonce = nonce
      let handlerName = "moolsocialPlayerEvent_\(nonce)"
      scriptHandlerName = handlerName

      let userContentController = WKUserContentController()
      userContentController.add(
        WeakScriptMessageHandler(delegate: self),
        name: handlerName
      )
      let configuration = WKWebViewConfiguration()
      configuration.userContentController = userContentController
      configuration.websiteDataStore = .nonPersistent()
      configuration.allowsInlineMediaPlayback = true
      configuration.mediaTypesRequiringUserActionForPlayback = .all
      configuration.allowsPictureInPictureMediaPlayback = false
      configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
      configuration.defaultWebpagePreferences.allowsContentJavaScript = true

      let playerWebView = WKWebView(
        frame: rootView.bounds,
        configuration: configuration
      )
      webView = playerWebView
      bootstrapLoadPending = true
      bridgeConnected = false
      bridgeEventReceived = false
      playerWebView.navigationDelegate = self
      playerWebView.uiDelegate = self
      playerWebView.backgroundColor = .black
      playerWebView.isOpaque = true
      playerWebView.scrollView.backgroundColor = .black
      playerWebView.scrollView.isScrollEnabled = false
      playerWebView.scrollView.bounces = false
      playerWebView.scrollView.contentInsetAdjustmentBehavior = .never
      playerWebView.allowsBackForwardNavigationGestures = false
      playerWebView.allowsLinkPreview = false
      playerWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      if #available(iOS 16.4, *) {
        playerWebView.isInspectable = true
      }
      rootView.addSubview(playerWebView)

      let html = template.replacingOccurrences(
        of: Self.nonceMarker,
        with: nonce
      )
      playerWebView.loadHTMLString(html, baseURL: approvedBaseURL)
      result(nil)
    }

    private func send(_ arguments: Any?, result: @escaping FlutterResult) {
      guard
        let values = arguments as? [String: Any],
        Set(values.keys) == Self.sendKeys,
        let message = values["message"] as? String,
        message.lengthOfBytes(using: .utf8) <= Self.maximumMessageBytes
      else {
        result(
          FlutterError(
            code: "invalid_command",
            message: "Player command is invalid.",
            details: nil
          )
        )
        return
      }
      guard let playerWebView = webView, bridgeConnected else {
        result(
          FlutterError(
            code: "port_unavailable",
            message: "The player port is unavailable.",
            details: nil
          )
        )
        return
      }
      playerWebView.callAsyncJavaScript(
        Self.sendMessageScript,
        arguments: ["message": message],
        in: nil,
        in: .page
      ) { [weak self, weak playerWebView] response in
        guard
          let self,
          !self.disposed,
          let playerWebView,
          playerWebView === self.webView
        else {
          result(
            FlutterError(
              code: "stale_player",
              message: "The provider player changed before the command completed.",
              details: nil
            )
          )
          return
        }
        switch response {
        case .success(let value) where value as? Bool == true:
          result(nil)
        case .success:
          result(
            FlutterError(
              code: "port_unavailable",
              message: "The player port is unavailable.",
              details: nil
            )
          )
        case .failure:
          self.failAndDetach(
            expectedWebView: playerWebView,
            code: "port_closed",
            message: "The player port is closed."
          )
          result(
            FlutterError(
              code: "port_closed",
              message: "The player port is closed.",
              details: nil
            )
          )
        }
      }
    }

    private func connectPort(_ playerWebView: WKWebView) {
      guard
        playerWebView === webView,
        bootstrapLoadPending,
        let nonce = connectionNonce,
        let handlerName = scriptHandlerName,
        let connection = connectionEnvelope(nonce: nonce)
      else {
        return
      }
      bootstrapLoadPending = false
      playerWebView.callAsyncJavaScript(
        Self.connectPortScript,
        arguments: [
          "connection": connection,
          "handlerName": handlerName,
        ],
        in: nil,
        in: .page
      ) { [weak self, weak playerWebView] response in
        guard
          let self,
          !self.disposed,
          let playerWebView,
          playerWebView === self.webView
        else {
          return
        }
        switch response {
        case .success(let value) where value as? Bool == true:
          self.bridgeConnected = true
          if !self.bridgeEventReceived {
            self.scheduleReadyTimeout(expectedWebView: playerWebView)
          }
        default:
          self.failAndDetach(
            expectedWebView: playerWebView,
            code: "port_transfer_failed",
            message: "The provider player connection could not be transferred."
          )
        }
      }
    }

    func userContentController(
      _ userContentController: WKUserContentController,
      didReceive message: WKScriptMessage
    ) {
      guard !disposed, let playerWebView = webView else {
        return
      }
      let origin = message.frameInfo.securityOrigin
      guard
        message.frameInfo.isMainFrame,
        origin.protocol == "https",
        origin.host.caseInsensitiveCompare(Self.playerHost) == .orderedSame,
        origin.port == 0 || origin.port == 443
      else {
        return
      }
      guard
        let raw = message.body as? String,
        raw.lengthOfBytes(using: .utf8) <= Self.maximumMessageBytes
      else {
        failAndDetach(
          expectedWebView: playerWebView,
          code: "invalid_bridge_event",
          message: "The provider player returned an invalid event."
        )
        return
      }
      bridgeEventReceived = true
      cancelReadyTimeout()
      channel.invokeMethod("playerEvent", arguments: raw)
    }

    func webView(
      _ webView: WKWebView,
      decidePolicyFor navigationAction: WKNavigationAction,
      decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
      guard webView === self.webView else {
        decisionHandler(.cancel)
        return
      }
      guard let url = navigationAction.request.url else {
        decisionHandler(.cancel)
        return
      }
      let isMainFrame = navigationAction.targetFrame?.isMainFrame == true
      if isMainFrame {
        if isExactPlayerDocument(url) {
          decisionHandler(.allow)
          return
        }
        if
          navigationAction.navigationType == .linkActivated,
          url.scheme?.lowercased() == "https"
        {
          openExternal(url)
        }
        decisionHandler(.cancel)
        return
      }
      if
        navigationAction.navigationType == .linkActivated,
        url.scheme?.lowercased() == "https"
      {
        openExternal(url)
        decisionHandler(.cancel)
        return
      }
      if isAllowedProviderFrameDocument(url) {
        decisionHandler(.allow)
        return
      }
      decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      guard webView === self.webView, bootstrapLoadPending else {
        return
      }
      guard isExactPlayerDocument(webView.url) else {
        failAndDetach(
          expectedWebView: webView,
          code: "unexpected_main_document",
          message: "The provider player document was rejected."
        )
        return
      }
      connectPort(webView)
    }

    func webView(
      _ webView: WKWebView,
      didFail navigation: WKNavigation!,
      withError error: Error
    ) {
      failMainFrameLoad(webView)
    }

    func webView(
      _ webView: WKWebView,
      didFailProvisionalNavigation navigation: WKNavigation!,
      withError error: Error
    ) {
      failMainFrameLoad(webView)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
      failAndDetach(
        expectedWebView: webView,
        code: "web_content_process_terminated",
        message: "The provider player stopped."
      )
    }

    func webView(
      _ webView: WKWebView,
      createWebViewWith configuration: WKWebViewConfiguration,
      for navigationAction: WKNavigationAction,
      windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
      if
        navigationAction.targetFrame == nil,
        navigationAction.navigationType == .linkActivated,
        let url = navigationAction.request.url,
        url.scheme?.lowercased() == "https"
      {
        openExternal(url)
      }
      return nil
    }

    @available(iOS 15.0, *)
    func webView(
      _ webView: WKWebView,
      requestMediaCapturePermissionFor origin: WKSecurityOrigin,
      initiatedByFrame frame: WKFrameInfo,
      type: WKMediaCaptureType,
      decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
      decisionHandler(.deny)
    }

    private func failMainFrameLoad(_ expectedWebView: WKWebView) {
      guard expectedWebView === webView else {
        return
      }
      failAndDetach(
        expectedWebView: expectedWebView,
        code: "main_frame_error",
        message: "The provider player could not load."
      )
    }

    private func openExternal(_ url: URL) {
      UIApplication.shared.open(url, options: [:]) { [weak self] opened in
        guard !opened, let self, !self.disposed else {
          return
        }
        self.channel.invokeMethod(
          "platformFailure",
          arguments: [
            "code": "external_handoff_unavailable",
            "message": "The provider destination is unavailable.",
          ]
        )
      }
    }

    private func scheduleReadyTimeout(expectedWebView: WKWebView) {
      cancelReadyTimeout()
      readyTimeout = Timer.scheduledTimer(
        withTimeInterval: Self.readyTimeoutSeconds,
        repeats: false
      ) { [weak self, weak expectedWebView] _ in
        guard let self, let expectedWebView else {
          return
        }
        self.failAndDetach(
          expectedWebView: expectedWebView,
          code: "ready_timeout",
          message: "The provider player did not become ready."
        )
      }
    }

    private func cancelReadyTimeout() {
      readyTimeout?.invalidate()
      readyTimeout = nil
    }

    private func failAndDetach(
      expectedWebView: WKWebView,
      code: String,
      message: String
    ) {
      guard
        !disposed,
        expectedWebView === webView
      else {
        return
      }
      destroyCurrentWebView()
      channel.invokeMethod(
        "platformFailure",
        arguments: ["code": code, "message": message]
      )
    }

    private func destroyCurrentWebView() {
      cancelReadyTimeout()
      bridgeConnected = false
      bridgeEventReceived = false
      bootstrapLoadPending = false
      connectionNonce = nil

      let current = webView
      webView = nil
      if let handlerName = scriptHandlerName {
        current?.configuration.userContentController
          .removeScriptMessageHandler(forName: handlerName)
      }
      scriptHandlerName = nil
      current?.stopLoading()
      current?.navigationDelegate = nil
      current?.uiDelegate = nil
      current?.removeFromSuperview()
    }

    private func dispose() {
      guard !disposed else {
        return
      }
      disposed = true
      channel.setMethodCallHandler(nil)
      destroyCurrentWebView()
    }

    private func finiteDouble(_ value: Any?) -> Double? {
      guard let number = value as? NSNumber else {
        return nil
      }
      if CFGetTypeID(number) == CFBooleanGetTypeID() {
        return nil
      }
      let parsed = number.doubleValue
      return parsed.isFinite ? parsed : nil
    }

    private func makeNonce() -> String? {
      var bytes = [UInt8](repeating: 0, count: 32)
      let byteCount = bytes.count
      let status = bytes.withUnsafeMutableBytes { buffer in
        guard let address = buffer.baseAddress else {
          return errSecParam
        }
        return SecRandomCopyBytes(kSecRandomDefault, byteCount, address)
      }
      guard status == errSecSuccess else {
        return nil
      }
      return Data(bytes)
        .base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
    }

    private func sha256(_ value: String) -> String {
      SHA256.hash(data: Data(value.utf8))
        .map { String(format: "%02X", $0) }
        .joined()
    }

    private func connectionEnvelope(nonce: String) -> String? {
      let envelope: [String: Any] = [
        "version": 1,
        "kind": "connect",
        "type": "playerPort",
        "payload": ["nonce": nonce],
      ]
      guard
        JSONSerialization.isValidJSONObject(envelope),
        let data = try? JSONSerialization.data(withJSONObject: envelope)
      else {
        return nil
      }
      return String(data: data, encoding: .utf8)
    }

    private func isExactPlayerDocument(_ url: URL?) -> Bool {
      guard
        let url,
        let components = URLComponents(
          url: url,
          resolvingAgainstBaseURL: false
        ),
        components.scheme?.lowercased() == "https",
        components.host?.caseInsensitiveCompare(Self.playerHost) == .orderedSame,
        components.port == nil,
        components.query == nil,
        components.fragment == nil,
        components.path.isEmpty || components.path == "/"
      else {
        return false
      }
      return true
    }

    private func isAllowedProviderFrameDocument(_ url: URL) -> Bool {
      if url.absoluteString == "about:blank" {
        return true
      }
      guard
        url.scheme?.lowercased() == "https",
        let host = url.host?.lowercased(),
        !Self.externalAccountHosts.contains(host)
      else {
        return false
      }
      return Self.providerFrameHostSuffixes.contains { suffix in
        host == suffix || host.hasSuffix(".\(suffix)")
      }
    }
  }

  private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
      self.delegate = delegate
      super.init()
    }

    func userContentController(
      _ userContentController: WKUserContentController,
      didReceive message: WKScriptMessage
    ) {
      delegate?.userContentController(
        userContentController,
        didReceive: message
      )
    }
  }
#endif
