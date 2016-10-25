// The MIT License (MIT)
//
// Copyright (c) 2015-2016 litt1e-p ( https://github.com/litt1e-p )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import UIKit
import ObjectiveC

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


let kLPFPSTraceLabelTag = 100001

open class LPFPS: NSObject
{
    static let sharedFPS: LPFPS = {
        let instance = LPFPS()
        return instance
    } ()
    
    internal var autoStopWhenTabBarChanged: Bool   = false
    fileprivate var lastTimeInterval: TimeInterval = 0
    fileprivate var traceCount: UInt               = 0
    fileprivate var hasStarted: Bool               = false
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActiveNotification), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActiveNotification), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    deinit {
        displayLink.isPaused = true
        displayLink.remove(from: RunLoop.current, forMode: RunLoopMode.commonModes)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func displayLinkTrace(_ link: CADisplayLink) {
        guard lastTimeInterval != 0 else {lastTimeInterval = link.timestamp; return}
        traceCount      += 1
        let interval     = link.timestamp - lastTimeInterval
        guard interval  >= 1 else {return}
        lastTimeInterval = link.timestamp
        let fps          = Double(traceCount) / interval
        traceCount       = 0
        fpsLabel.text    = "\(Int(fps)) FPS"
    }
    
    open func start() {
        let rootVcSubViews = UIApplication.shared.keyWindow?.rootViewController?.view.subviews
        guard rootVcSubViews?.count > 0 else {return}
        for v in rootVcSubViews! {
            if v.isKind(of: UILabel.self) && v.tag == kLPFPSTraceLabelTag {
                return
            }
        }
        hasStarted = true
        UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(fpsLabel)
    }
    
    open func stop() {
        let rootVcSubViews = UIApplication.shared.keyWindow?.rootViewController?.view.subviews
        guard rootVcSubViews?.count > 0 else {return}
        for v in rootVcSubViews! {
            if v.isKind(of: UILabel.self) && v.tag == kLPFPSTraceLabelTag {
                v.removeFromSuperview()
                hasStarted = false
                return
            }
        }
    }
    
    @objc fileprivate func applicationDidBecomeActiveNotification() {
        displayLink.isPaused = false
    }
    
    @objc fileprivate func applicationWillResignActiveNotification() {
        displayLink.isPaused = true
    }
    
    fileprivate lazy var displayLink: CADisplayLink = {
        let dl = CADisplayLink(target: self, selector: #selector(displayLinkTrace(_:)))
        dl.isPaused = true
        dl.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
        return dl
    } ()
    
    internal lazy var fpsLabel: UILabel = {
        let lb             = UILabel(frame: CGRect(x: (UIScreen.main.bounds.size.width-50) / 2 + 50, y: 0, width: 50, height: 20))
        lb.font            = UIFont.boldSystemFont(ofSize: 12.0)
        lb.textColor       = UIColor(red: 14.0/255.0, green: 200.0/255.0, blue: 36.0/255.0, alpha: 1.0)
        lb.backgroundColor = .clear
        lb.textAlignment   = .right
        lb.tag             = kLPFPSTraceLabelTag
        return lb
    } ()
}

public extension UITabBarController
{
    open override class func initialize() {
        if self !== UITabBarController.self {
            return
        }
        var _ = {
            let viewAppearSelector            = #selector(UITabBarController.viewWillAppear(_:))
            let swizzledViewAppearSelector    = #selector(self.swizzled_viewWillAppear(_:))
            let viewDisappearSelector         = #selector(UITabBarController.viewDidDisappear(_:))
            let swizzledViewDisappearSelector = #selector(self.swizzled_viewDidDisappear(_:))
            
            let viewAppearMethod            = class_getInstanceMethod(self, viewAppearSelector)
            let swizzledViewAppearMethod    = class_getInstanceMethod(self, swizzledViewAppearSelector)
            let viewDisappearMethod         = class_getInstanceMethod(self, viewDisappearSelector)
            let swizzledViewDisappearMethod = class_getInstanceMethod(self, swizzledViewDisappearSelector)
            
            let didAddAppearMethod = class_addMethod(self, viewAppearSelector, method_getImplementation(swizzledViewAppearMethod), method_getTypeEncoding(swizzledViewAppearMethod))
            let didAddDisappearMethod = class_addMethod(self, viewDisappearSelector, method_getImplementation(swizzledViewDisappearMethod), method_getTypeEncoding(swizzledViewDisappearMethod))
            
            if didAddAppearMethod {
                class_replaceMethod(self, swizzledViewAppearSelector, method_getImplementation(viewAppearMethod), method_getTypeEncoding(viewAppearMethod))
            } else {
                method_exchangeImplementations(viewAppearMethod, swizzledViewAppearMethod);
            }
            if didAddDisappearMethod {
                class_replaceMethod(self, swizzledViewDisappearSelector, method_getImplementation(viewDisappearMethod), method_getTypeEncoding(viewDisappearMethod))
            } else {
                method_exchangeImplementations(viewDisappearMethod, swizzledViewDisappearMethod)
            }

        } ()
    }
    
    @objc fileprivate func swizzled_viewWillAppear(_ animated: Bool) {
        self.swizzled_viewWillAppear(animated)
        guard fpsTracerInited() else {return}
        let fpsTracer = LPFPS.sharedFPS
        guard !fpsTracer.autoStopWhenTabBarChanged else {return}
        fpsTracer.start()
    }
    
    @objc fileprivate func swizzled_viewDidDisappear(_ animated: Bool) {
        self.swizzled_viewDidDisappear(animated)
        guard fpsTracerInited() else {return}
        let fpsTracer = LPFPS.sharedFPS
        guard fpsTracer.autoStopWhenTabBarChanged else {return}
        fpsTracer.stop()
    }
    
    fileprivate func fpsTracerInited() -> Bool {
        return LPFPS.sharedFPS.hasStarted
    }
}
