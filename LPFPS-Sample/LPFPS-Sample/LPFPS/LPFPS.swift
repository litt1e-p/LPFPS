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

let kLPFPSTraceLabelTag = 100001

class LPFPS: NSObject
{
    internal var autoStopWhenTabBarChanged: Bool = false
    private var lastTimeInterval: NSTimeInterval = 0
    private var traceCount: UInt                 = 0
    private var hasStarted: Bool                 = false
    
    class var sharedFPS: LPFPS {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: LPFPS?           = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = LPFPS()
        }
        return Static.instance!
    }
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationDidBecomeActiveNotification), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(applicationWillResignActiveNotification), name: UIApplicationWillResignActiveNotification, object: nil)
    }
    
    deinit {
        displayLink.paused = true
        displayLink.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @objc private func displayLinkTrace(link: CADisplayLink) {
        guard lastTimeInterval != 0 else {lastTimeInterval = link.timestamp; return}
        traceCount      += 1
        let interval     = link.timestamp - lastTimeInterval
        guard interval  >= 1 else {return}
        lastTimeInterval = link.timestamp
        let fps          = Double(traceCount) / interval
        traceCount       = 0
        fpsLabel.text    = "\(Int(fps)) FPS"
    }
    
    internal func start() {
        let rootVcSubViews = UIApplication.sharedApplication().keyWindow?.rootViewController?.view.subviews
        guard rootVcSubViews?.count > 0 else {return}
        for v in rootVcSubViews! {
            if v.isKindOfClass(UILabel.self) && v.tag == kLPFPSTraceLabelTag {
                return
            }
        }
        hasStarted = true
        UIApplication.sharedApplication().keyWindow?.rootViewController?.view.addSubview(fpsLabel)
    }
    
    internal func stop() {
        let rootVcSubViews = UIApplication.sharedApplication().keyWindow?.rootViewController?.view.subviews
        guard rootVcSubViews?.count > 0 else {return}
        for v in rootVcSubViews! {
            if v.isKindOfClass(UILabel.self) && v.tag == kLPFPSTraceLabelTag {
                v.removeFromSuperview()
                hasStarted = false
                return
            }
        }
    }
    
    @objc private func applicationDidBecomeActiveNotification() {
        displayLink.paused = false
    }
    
    @objc private func applicationWillResignActiveNotification() {
        displayLink.paused = true
    }
    
    private lazy var displayLink: CADisplayLink = {
        let dl = CADisplayLink(target: self, selector: #selector(displayLinkTrace(_:)))
        dl.paused = true
        dl.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        return dl
    } ()
    
    internal lazy var fpsLabel: UILabel = {
        let lb             = UILabel(frame: CGRectMake((UIScreen.mainScreen().bounds.size.width-50) / 2 + 50, 0, 50, 20))
        lb.font            = UIFont.boldSystemFontOfSize(12.0)
        lb.textColor       = UIColor(red: 14.0/255.0, green: 200.0/255.0, blue: 36.0/255.0, alpha: 1.0)
        lb.backgroundColor = .clearColor()
        lb.textAlignment   = .Right
        lb.tag             = kLPFPSTraceLabelTag
        return lb
    } ()
}

public extension UITabBarController
{
    public override class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        if self !== UITabBarController.self {
            return
        }
        dispatch_once(&Static.token) {
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
        }
    }
    
    @objc private func swizzled_viewWillAppear(animated: Bool) {
        self.swizzled_viewWillAppear(animated)
        guard fpsTracerInited() else {return}
        let fpsTracer = LPFPS.sharedFPS
        guard !fpsTracer.autoStopWhenTabBarChanged else {return}
        fpsTracer.start()
    }
    
    @objc private func swizzled_viewDidDisappear(animated: Bool) {
        self.swizzled_viewDidDisappear(animated)
        guard fpsTracerInited() else {return}
        let fpsTracer = LPFPS.sharedFPS
        guard fpsTracer.autoStopWhenTabBarChanged else {return}
        fpsTracer.stop()
    }
    
    private func fpsTracerInited() -> Bool {
        return LPFPS.sharedFPS.hasStarted
    }
}
