import UIKit
import WebKit

class DaumAddressSearchViewController: UIViewController {
    
    private var webView: WKWebView!
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    var onAddressSelected: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebView()
        loadDaumPostcode()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "주소 검색"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "취소",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        
        // Loading Indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .systemBlue
        
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        loadingIndicator.startAnimating()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        // 개발자 도구 활성화 (디버깅용)
        if #available(iOS 16.4, *) {
            configuration.preferences.isElementFullscreenEnabled = true
        }
        
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "addressCallback")
        configuration.userContentController = userContentController
        
        // JavaScript 콘솔 로그를 iOS 콘솔로 출력
        let consoleLogScript = """
            console.log = function(message) {
                window.webkit.messageHandlers.consoleLog.postMessage(message);
            };
        """
        let script = WKUserScript(source: consoleLogScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(script)
        userContentController.add(self, name: "consoleLog")
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isHidden = true
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadDaumPostcode() {
        let htmlString = """
        <!DOCTYPE html>
        <html lang="ko">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>주소 검색</title>
            <style>
                * { 
                    margin: 0; 
                    padding: 0; 
                    box-sizing: border-box; 
                }
                html, body { 
                    width: 100%; 
                    height: 100%; 
                    overflow: hidden;
                }
                #postcode { 
                    width: 100%; 
                    height: 100vh; 
                }
            </style>
        </head>
        <body>
            <div id="postcode"></div>
            
            <script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
            <script>
                window.onload = function() {
                    var checkDaum = setInterval(function() {
                        if (window.daum && window.daum.Postcode) {
                            clearInterval(checkDaum);
                            
                            new daum.Postcode({
                                oncomplete: function(data) {
                                    var fullAddress = data.address;
                                    
                                    // 건물명이 있고, 공동주택일 경우 추가
                                    if(data.addressType === 'R'){
                                        if(data.bname !== '' && /[동|로|가]$/g.test(data.bname)){
                                            fullAddress += ' ' + data.bname;
                                        }
                                        if(data.buildingName !== '' && data.apartment === 'Y'){
                                            fullAddress += ' (' + data.buildingName + ')';
                                        }
                                    }
                                    
                                    window.webkit.messageHandlers.addressCallback.postMessage(fullAddress);
                                },
                                onclose: function(state) {
                                    if(state === 'FORCE_CLOSE'){
                                        window.webkit.messageHandlers.addressCallback.postMessage('');
                                    }
                                },
                                width: '100%',
                                height: '100%'
                            }).embed('postcode');
                        }
                    }, 100);
                };
            </script>
        </body>
        </html>
        """
        
        // 임시 디렉터리에 HTML 파일 저장
        let tempDir = FileManager.default.temporaryDirectory
        let htmlFileURL = tempDir.appendingPathComponent("postcode.html")
        
        do {
            try htmlString.write(to: htmlFileURL,
                               atomically: true,
                               encoding: .utf8)
        } catch {
            print(" HTML 저장 실패:", error)
            return
        }
        
        // 파일 URL로 로드
        webView.loadFileURL(htmlFileURL, allowingReadAccessTo: tempDir)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension DaumAddressSearchViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("웹뷰 네비게이션 완료")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadingIndicator.stopAnimating()
            self.webView.isHidden = false
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("웹뷰 로드 실패: \(error.localizedDescription)")
        loadingIndicator.stopAnimating()
        showErrorAlert()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("웹뷰 provisional 로드 실패: \(error.localizedDescription)")
        loadingIndicator.stopAnimating()
        showErrorAlert()
    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(
            title: "오류",
            message: "주소 검색 서비스를 불러올 수 없습니다. 인터넷 연결을 확인해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - WKUIDelegate
extension DaumAddressSearchViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }
}

extension DaumAddressSearchViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        // JavaScript 콘솔 로그 출력
        if message.name == "consoleLog" {
            print(" JS Console: \(message.body)")
            return
        }
        
        // 주소 메시지 처리
        if message.name == "addressCallback" {
            print(" 주소 메시지 수신: \(message.body)")
            
            if let address = message.body as? String, !address.isEmpty {
                DispatchQueue.main.async {
                    self.onAddressSelected?(address)
                    self.dismiss(animated: true)
                }
            } else {
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            }
        }
    }
}
