import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {
    
    var webView: WKWebView!
    
    // 你的初始数据
    let initialHTML = """
    <p>维修工单（点击图片可缩放）</p>
    <p>
        <img src="https://43.133.55.168/files/files/2025/12/29/d2f955bf-b65c-415b-a561-43ac23946f77.jpg">
    </p>
    <p>修改update内容...</p>
    """

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupNavigationBar()
    }

    func setupWebView() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // --- 核心 HTML/CSS/JS 代码 ---
        let editorHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body { margin: 0; padding: 20px; font-family: -apple-system; font-size: 17px; }
                [contenteditable] { outline: none; min-height: 400px; }
                
                /* 图片选中的样式 */
                img { max-width: 100%; height: auto; transition: box-shadow 0.2s; position: relative; }
                .selected-img { box-shadow: 0 0 0 2px #007AFF; }
                
                /* 缩放手柄样式 */
                .resizer-handle {
                    width: 20px; height: 20px;
                    background: #007AFF;
                    border: 2px solid white;
                    border-radius: 10px;
                    position: absolute;
                    display: none; /* 默认隐藏 */
                    z-index: 100;
                }
            </style>
        </head>
        <body>
            <div id="editor" contenteditable="true">\(initialHTML)</div>
            
            <!-- 缩放手柄 HTML -->
            <div id="resizer" class="resizer-handle"></div>

            <script>
                var editor = document.getElementById('editor');
                var resizer = document.getElementById('resizer');
                var currentImg = nil;

                // 监听点击事件，处理图片选中
                editor.addEventListener('click', function(e) {
                    if (e.target.tagName === 'IMG') {
                        selectImage(e.target);
                    } else {
                        hideResizer();
                    }
                });

                function selectImage(img) {
                    currentImg = img;
                    // 给图片加蓝框
                    document.querySelectorAll('img').forEach(i => i.classList.remove('selected-img'));
                    img.classList.add('selected-img');
                    
                    // 显示并定位手柄在图片右下角
                    updateHandlePosition();
                    resizer.style.display = 'block';
                }

                function hideResizer() {
                    if(currentImg) currentImg.classList.remove('selected-img');
                    currentImg = null;
                    resizer.style.display = 'none';
                }

                function updateHandlePosition() {
                    if (!currentImg) return;
                    var rect = currentImg.getBoundingClientRect();
                    resizer.style.top = (rect.bottom + window.scrollY - 10) + 'px';
                    resizer.style.left = (rect.right + window.scrollX - 10) + 'px';
                }

                // 手柄拖动逻辑
                resizer.addEventListener('touchstart', function(e) {
                    e.preventDefault();
                    var startX = e.touches[0].clientX;
                    var startWidth = currentImg.clientWidth;

                    function onTouchMove(e) {
                        var diff = e.touches[0].clientX - startX;
                        var newWidth = startWidth + diff;
                        if (newWidth > 50) { // 最小宽度限制
                            currentImg.style.width = newWidth + 'px';
                            currentImg.style.height = 'auto'; // 保持比例
                            updateHandlePosition();
                        }
                    }

                    function onTouchEnd() {
                        window.removeEventListener('touchmove', onTouchMove);
                        window.removeEventListener('touchend', onTouchEnd);
                    }

                    window.addEventListener('touchmove', onTouchMove);
                    window.addEventListener('touchend', onTouchEnd);
                });

                // 页面滚动时更新手柄位置
                window.addEventListener('scroll', updateHandlePosition);
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(editorHTML, baseURL: nil)
    }

    func setupNavigationBar() {
        title = "工单编辑"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "获取HTML", style: .done, target: self, action: #selector(saveContent))
    }

    @objc func saveContent() {
        webView.evaluateJavaScript("document.getElementById('editor').innerHTML") { (result, _) in
            if let html = result as? String {
                print("--- 修改后的 HTML ---")
                print(html) // 这里你会看到 img 标签里多了 style="width: xxx px"
            }
        }
    }

    // 信任 IP 地址证书
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
