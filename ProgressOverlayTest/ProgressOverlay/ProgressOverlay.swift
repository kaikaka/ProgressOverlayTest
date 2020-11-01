//
//  ProgressOverlay.swift
//  ProgressOverlayTest
//
//  Created by xiangkai yin on 16/9/7.
//  Copyright © 2016年 kuailao_2. All rights reserved.
//
//
//  swift 重写 MBProgressOverlay

import UIKit


public enum ProgressOverlayAnimation:Int {
    /// Opacity animation (不透明度动画)
    case fade
    // Opacity + scale animation (zoom in when appearing zoom out when disappearing) 不透明度+缩放动画（出现时放大缩小消失时）
    case zoom
    // Opacity + scale animation (zoom out style) 不透明度+缩放动画（缩小）
    case zoomOut
    // Opacity + scale animation (zoom in style) 不透明度+缩放动画（放大）
    case zoomIn
}

public enum ProgressOverlayMode: Int {
    /// UIActivityIndicatorView.
    case indeterminate
    /// A round, pie-chart like, progress view. (一个圆，像饼图一样的进度条视图)
    case determinate
    /// Horizontal progress bar. (水平进度条)
    case determinateHorizontalBar
    /// Ring-shaped progress view. (环形进度条)
    case annularDeterminate
    /// Shows a custom view. (显示自定义视图)
    case customView
    /// Shows only labels. (仅显示标签)
    case text
}

let ProgressOverlayMaxOffset:CGFloat = (UIScreen.main.bounds.size.height - 120)/2

let PODefaultLabelFontSize:CGFloat = 16.0
let PODefaultPadding = 4.0
let PODefaultDetailsLabelFontSize:CGFloat = 12.0

typealias ProgressOverlayCompletionBlock = ()-> ()

/*
 * Displays a simple Overlay window containing a progress indicator and two optional labels for short messages.
 *
 * This is a simple drop-in class for displaying a progress Overlay view similar to Apple's private UIProgressOverlay class.
 * The ProgressOverlay window spans over the entire space given to it by the initWithFrame: constructor and catches all
 * user input on this region, thereby preventing the user operations on components below the view.
 *
 * @note To still allow touches to pass through the Overlay, you can set Overlay.userInteractionEnabled = NO.
 * @attention ProgressOverlay is a UI class and should therefore only be accessed on the main thread.
 *  一个简单的覆盖窗口，用来显示包含进度指示器和短消息两种可选标签
 */
class ProgressOverlay: UIView {
    
    // MARK: - Properties
    
    /// The animation type that should be used when the Overlay is shown and hidden. default fade (动画显示和隐藏的类型，默认 fade)
    var animationType: ProgressOverlayAnimation!
    
    fileprivate var modeProperty:ProgressOverlayMode = .indeterminate
    
    /// ProgressOverlay operation mode. The default is Indeterminate. (ProgressOverlay 显示模式 ，默认是 Indeterminate)
    var mode:ProgressOverlayMode  {
        set {
            if newValue != modeProperty {
                modeProperty = newValue
                self.updateIndicators()
            }
        }
        get {
            return modeProperty
        }
    }
    
    /* The amount of space between the ProgressOverlay edge and the ProgressOverlay elements (labels, indicators or custom views).
     * This also represents the minimum bezel distance to the edge of the Overlay view.
     * Defaults to 20.f
     * (labels, indicators or custom views) 与 边缘之间的间距 默认 20.0
     */
    var margin:CGFloat = 20
    
    fileprivate var minSizeProperty:CGSize = CGSize.zero
    /**
     The minimum size of the Overlay bezel. Defaults to CGSizeZero (no minimum size).
     */
    var minSize:CGSize {
        set {
            if !newValue.equalTo(minSizeProperty) {
                minSizeProperty = newValue
                DispatchQueue.main.async(execute: { () -> Void in
                    self.setNeedsUpdateConstraints()
                })
            }
        }
        get {
            return minSizeProperty
        }
    }
    
    /**
     Force the Overlay dimensions to be equal if possible. (正方形)
     */
    var square = false
    
    fileprivate var offsetProperty:CGPoint = CGPoint.zero
    /**
     * The bezel offset relative to the center of the view. You can use ProgressOverlayMaxOffset
     * and -ProgressOverlayMaxOffset to move the Overlay all the way to the screen edge in each direction.
     * E.g., CGPointMake(0.f, ProgressOverlayMaxOffset) would position the Overlay centered on the bottom edge.
     */
    var offset:CGPoint {
        set {
            if !offsetProperty.equalTo(newValue) {
                offsetProperty = newValue
                DispatchQueue.main.async(execute: { () -> Void in
                    self.setNeedsUpdateConstraints()
                })
            }
        }
        get {
            return self.offsetProperty
        }
    }
    
    /// When enabled, the bezel center gets slightly affected by the device accelerometer data. Defaults to true (是否被加速计影响)
    var defaultMotionEffectsEnabled:Bool!
    
    fileprivate var contentColorProperty:UIColor = UIColor.init(white: 0.0, alpha: 0.7)
    
    /* A color that gets forwarded to all labels and supported indicators. Also sets the tintColor ()
     * for custom views on iOS 7+. Set to nil to manage color individually.
     * (labels 和 indicators) 的颜色
     */
    var contentColor:UIColor {
        set {
            if newValue != contentColorProperty {
                self.contentColorProperty = newValue
                self.updateViewsForColor(newValue)
            }
        }
        get {
            return self.contentColorProperty
        }
    }
    
    /**
     Called after the Overlay is hiden.
     */
    var completionBlock:ProgressOverlayCompletionBlock?
    
    /// View covering the entire overlay area, placed behind bezelView. (最后面的覆盖区域)
    var backgroundView:OverlayBackgroundView!
    
    /// The view containing the labels and indicator (or customView). (包含标签和指示（或自定义视图）的视图。)
    fileprivate var bezelView:OverlayBackgroundView!
    
    /// A label that holds an optional short message to be displayed below the activity indicator. The Overlay is automatically resized to fit
    /// the entire text. (自适应文本内容标签)
    var label:UILabel!
    
    /// A label that holds an optional details message displayed below the labelText message. The details text can span multiple lines. (显示在下方的多行文本标签)
    var detailsLabel:UILabel!
    
    /// A button that is placed below the labels. Visible only if a target / action is added. (放置在标签下方的按钮)
    var button:UIButton!
    
    var topSpacer:UIView!
    var bottomSpacer:UIView!
    var indicator:UIView?
    var minShowTimer:Timer?
    var graceTimer:Timer?
    var userAnimation:Bool = true
    var finished:Bool = false
    var hideDelayTimer:Timer?
    var showStarted:Date?
    var progressObjectDisplayLink: CADisplayLink?
    var bezelConstraints = [NSLayoutConstraint]()
    var paddingConstraints = [NSLayoutConstraint]()
    
    
    // MARK: - Class methods
    
    internal class func showOnView(_ view:UIView! ,animated:Bool) -> ProgressOverlay {
        let overlay = ProgressOverlay.init(view: view)
        overlay.removeFromSuperViewOnHide = true
        view.addSubview(overlay)
        overlay.showAnimated(animated)
        return overlay
    }
    
    internal class func hideAllOverlaysForView(_ view:UIView! ,animated:Bool) -> Bool {
        if let overlay:ProgressOverlay = self.hideForView(view) {
            overlay.removeFromSuperViewOnHide = true
            overlay.hideAnimated(animated)
            return true
        }
        return false
    }
    
    internal class func hideForView(_ view:UIView!) -> ProgressOverlay? {
        
        for subView in view.subviews {
            if subView .isKind(of: self) {
                return subView as? ProgressOverlay
            }
        }
        return nil
    }
    // MARK: - Lifecycle
    
    fileprivate func commonInit() {
        // Set default values for properties (设置)
        animationType = .fade
        mode = .indeterminate
        margin = 20.0
        defaultMotionEffectsEnabled = true
        
        // Default color (默认颜色)
        contentColor = UIColor.init(white: 0.0, alpha: 0.7)
        
        // Transparent background (透明背景)
        self.isOpaque = false
        self.backgroundColor = UIColor.clear
        
        // Make it invisible for now (当前不可见)
        self.alpha = 0.0
        self.autoresizingMask = UIView.AutoresizingMask.init(rawValue: UIView.AutoresizingMask.flexibleWidth.rawValue | UIView.AutoresizingMask.flexibleHeight.rawValue)
        // group opacity (这项属性默认是启用的。当它被启用时，一些动画将会变得不流畅，它也可以在layer层上被控制)
        self.layer.allowsGroupOpacity = false
        
        self.setupViews()
        self.updateIndicators()
        self.registerForNotifications()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    convenience init(view:UIView) {
        self.init(frame:view.bounds)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    deinit {
        self.unregisterFromNofifications()
    }
    
    // MARK: - UI
    
    fileprivate func setupViews() {
        let defaultColor = self.contentColor
        
        let backgroundView = OverlayBackgroundView.init(frame: self.bounds)
        backgroundView.style = .solidColor
        backgroundView.backgroundColor = UIColor.clear
        backgroundView.autoresizingMask = UIView.AutoresizingMask.init(rawValue: UIView.AutoresizingMask.flexibleWidth.rawValue | UIView.AutoresizingMask.flexibleHeight.rawValue)
        backgroundView.alpha = 0.0
        self.addSubview(backgroundView)
        self.backgroundView = backgroundView
        
        let bezelView = OverlayBackgroundView()
        bezelView.translatesAutoresizingMaskIntoConstraints = false
        bezelView.layer.cornerRadius = 5.0
        bezelView.alpha = 0.0
        self.addSubview(bezelView)
        self.bezelView = bezelView
        self.updateBezelMotionEffects()
        
        let label = UILabel()
        //文本自动适应宽度
        label.adjustsFontSizeToFitWidth = false
        label.textAlignment = .center
        label.textColor = defaultColor
        label.font = UIFont.boldSystemFont(ofSize: PODefaultLabelFontSize)
        label.isOpaque = false
        label.backgroundColor = UIColor.clear
        self.label = label
        
        let detailsLabel = UILabel()
        detailsLabel.adjustsFontSizeToFitWidth = false
        detailsLabel.textAlignment = .center
        detailsLabel.textColor = defaultColor
        detailsLabel.numberOfLines = 0
        detailsLabel.font = UIFont.boldSystemFont(ofSize: PODefaultDetailsLabelFontSize)
        detailsLabel.isOpaque = false
        detailsLabel.backgroundColor = UIColor.clear
        self.detailsLabel = detailsLabel
        
        let button = OverlayRoundedButton(type:.custom)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: PODefaultDetailsLabelFontSize)
        button.setTitleColor(defaultColor, for: UIControl.State())
        self.button = button
        
        for view in [label,detailsLabel,button] {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998), for: .horizontal)
            view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998), for: .vertical)
            bezelView.addSubview(view)
        }
        
        let topSpacer = UIView()
        topSpacer.translatesAutoresizingMaskIntoConstraints = false
        topSpacer.isHidden = true
        bezelView.addSubview(topSpacer)
        self.topSpacer = topSpacer
        
        let bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer.isHidden = true
        bezelView.addSubview(bottomSpacer)
        self.bottomSpacer = bottomSpacer
    }
    
    func updateIndicators() {
        
        var isActivityIndicator = false
        var isRoundIndicator = false
        var indicator = self.indicator
        if  indicator != nil{
            isActivityIndicator = indicator!.isKind(of: UIActivityIndicatorView.classForCoder())
            isRoundIndicator = indicator!.isKind(of: OverlayBackgroundView.self)
        }
        let mode = self.mode
        if mode == ProgressOverlayMode.indeterminate {
            if !isActivityIndicator {
                // Update to indeterminate indicator (更新)
                indicator?.removeFromSuperview()
                indicator = UIActivityIndicatorView.init(style: .whiteLarge)
                (indicator as! UIActivityIndicatorView).startAnimating()
                self.bezelView.addSubview(indicator!)
            }
        } else if (mode == ProgressOverlayMode.determinateHorizontalBar) {
            // Update to bar determinate indicator
            indicator?.removeFromSuperview()
            indicator = OverlayBarProgressView()
            self.bezelView.addSubview(indicator!)
        } else if (mode == ProgressOverlayMode.determinate || mode == ProgressOverlayMode.annularDeterminate) {
            if !isRoundIndicator {
                // Update to determinante indicator
                indicator?.removeFromSuperview()
                indicator = OverlayRoundProgressView.init()
                self.bezelView.addSubview(indicator!)
            }
            if mode == ProgressOverlayMode.annularDeterminate {
                (indicator as! OverlayRoundProgressView).annular = true
            }
        } else if (mode == ProgressOverlayMode.customView && self.customView != indicator) {
            indicator?.removeFromSuperview()
            indicator = self.customView
            self.bezelView.addSubview(indicator!)
        } else if (mode == ProgressOverlayMode.text) {
            indicator?.removeFromSuperview()
            indicator = nil
        }
        indicator?.translatesAutoresizingMaskIntoConstraints = false
        self.indicator = indicator
        
        if indicator?.responds(to: #selector(self.forProgress(_:))) == true {
            indicator?.setValue(self.progress, forKey: "progress")
        }
        
        indicator?.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998), for: .horizontal)
        indicator?.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998), for: .vertical)
        
        self.updateViewsForColor(self.contentColor)
        self.setNeedsUpdateConstraints()
    }
    
    func updateViewsForColor(_ color:UIColor) {
        
        self.label.textColor = color
        self.detailsLabel.textColor = color
        self.button.setTitleColor(color, for: UIControl.State())
        
        //UIAppearance settings are prioritized. If they are preset the set color is ignored.  (UIAppearance 设置优先级)
        let indicator = self.indicator
        if indicator?.isKind(of: UIActivityIndicatorView.classForCoder()) == true {
            let appearance:UIActivityIndicatorView?
            appearance = UIActivityIndicatorView.appearance(whenContainedInInstancesOf: [ProgressOverlay.classForCoder() as! UIAppearanceContainer.Type])
            
            if  appearance?.color == nil {
                (indicator as! UIActivityIndicatorView).color = color
            }
        } else if indicator?.isKind(of: OverlayRoundProgressView.classForCoder()) == true {
            let opView = (indicator as! OverlayRoundProgressView)
            opView.progressTintColor = color
            opView.backgroundTintColor = color.withAlphaComponent(0.1)
        } else if indicator?.isKind(of: OverlayBarProgressView.classForCoder()) == true {
            let obpView = indicator as! OverlayBarProgressView
            obpView.progressColor = color
            obpView.lineColor = color
        } else {
            indicator?.tintColor = color
        }
        
    }
    
    func updateBezelMotionEffects() {
        let bezelView = self.bezelView
        
        if self.defaultMotionEffectsEnabled == true {
            //视觉差效果
            let effectOffset:Float = 10.0
            let effectX:UIInterpolatingMotionEffect = UIInterpolatingMotionEffect.init(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            effectX.maximumRelativeValue = effectOffset
            effectX.minimumRelativeValue = -effectOffset
            
            let effectY:UIInterpolatingMotionEffect = UIInterpolatingMotionEffect.init(keyPath: "center.y", type: .tiltAlongVerticalAxis)
            effectY.maximumRelativeValue = effectOffset
            effectY.minimumRelativeValue = -effectOffset
            
            let group:UIMotionEffectGroup = UIMotionEffectGroup.init()
            group.motionEffects = [effectX,effectY]
            bezelView?.addMotionEffect(group)
            
        } else {
            let effects = bezelView?.motionEffects
            for effect in effects! {
                bezelView?.removeMotionEffect(effect)
            }
        }
    }
    
    // MARK: - Layout
    
    override func updateConstraints() {
        
        let bezel = self.bezelView!
        let topSpacer = self.topSpacer!
        let bottomSpacer = self.bottomSpacer!
        let margin:CGFloat = self.margin
        var bezelConstraints = Array<NSLayoutConstraint>()
        let metrics = ["margin":margin]
        
        var subviews = [self.topSpacer,self.label,self.detailsLabel,self.button,self.bottomSpacer]
        if self.indicator != nil {
            subviews.insert(self.indicator, at: 1)
        }
        
        // Remove existing constraints
        self.removeConstraints(self.constraints)
        topSpacer.removeConstraints(topSpacer.constraints)
        bottomSpacer.removeConstraints(bottomSpacer.constraints)
        
        if self.bezelConstraints.count > 0 {
            bezel.removeConstraints(self.bezelConstraints )
            self.bezelConstraints = []
        }
        
        // Center bezel in container (self), applying the offset if set (控制约束
        let offset = self.offset
        var centeringConstraints:Array = [NSLayoutConstraint]()
        
        centeringConstraints.append(NSLayoutConstraint.init(item: bezel, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: offset.x))
        centeringConstraints.append(NSLayoutConstraint.init(item: bezel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: offset.y))
        self.applyPriority(UILayoutPriority(rawValue: 999), constraints: centeringConstraints)
        self.addConstraints(centeringConstraints)
        
        // Ensure minimum side margin is kept (保证最小的侧边 VFL)
        var sideConstraints = Array<NSLayoutConstraint>()
        sideConstraints += NSLayoutConstraint.constraints(withVisualFormat: "|-(>=margin)-[bezel]-(>=margin)-|", options: NSLayoutConstraint.FormatOptions(), metrics: metrics, views: ["bezel":bezel])
        sideConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=margin)-[bezel]-(>=margin)-|", options: NSLayoutConstraint.FormatOptions(), metrics: metrics, views: ["bezel":bezel])
        self.applyPriority(UILayoutPriority(rawValue: 999), constraints: sideConstraints)
        self.addConstraints(sideConstraints)
        
        // Minmum bezel size,if set (bezel 最小尺寸)
        let minimumSize = self.minSize
        if !minimumSize.equalTo(CGSize.zero) {
            var minSizeConstraints = Array<NSLayoutConstraint>()
            minSizeConstraints.append(NSLayoutConstraint.init(item: bezel, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: minimumSize.width))
            minSizeConstraints.append(NSLayoutConstraint.init(item: bezel, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: minimumSize.height))
            self.applyPriority(UILayoutPriority(rawValue: 997), constraints: minSizeConstraints)
            bezelConstraints += minSizeConstraints
        }
        
        // Square aspect ratio, if set (宽高比)
        if self.square {
            let square = NSLayoutConstraint.init(item: bezel, attribute: .height, relatedBy: .equal, toItem: bezel, attribute: .width, multiplier: 1.0, constant: 0)
            square.priority = UILayoutPriority(rawValue: 997)
            bezelConstraints.append(square)
        }
        
        // Top and bottom spacing (上下边距)
        topSpacer.addConstraint(NSLayoutConstraint.init(item: topSpacer, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: margin))
        bottomSpacer.addConstraint(NSLayoutConstraint.init(item: bottomSpacer, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: margin))
        
        // Top and bottom spaces should be equal (上下边距应保持一致)
        bezelConstraints.append(NSLayoutConstraint.init(item: topSpacer, attribute: .height, relatedBy: .equal, toItem: bottomSpacer, attribute: .height, multiplier: 1.0, constant: 0.0))
        
        // Layout subviews in bezel (重置子视图约束)
        
        var paddingConstraints = Array<NSLayoutConstraint>()
        let subViewsNS:NSArray = subviews as NSArray
        
        for (idx,view) in subviews.enumerated() {
            
            // Center in bezel （居中）
            bezelConstraints.append(NSLayoutConstraint.init(item: view!, attribute: .centerX, relatedBy: .equal, toItem: bezel, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            // Ensure the minimum edge margin is kept
            bezelConstraints += NSLayoutConstraint.constraints(withVisualFormat: "|-(>=margin)-[view]-(>=margin)-|", options: NSLayoutConstraint.FormatOptions(), metrics: metrics, views: ["view":view!])
            
            // Element spacing
            if idx == 0 {
                // First, ensure spacing to bezel edge
                bezelConstraints.append(NSLayoutConstraint.init(item: view!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: .equal, toItem: bezel, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0))
            } else if (idx == subViewsNS.count - 1) {
                // Last, ensure spacing to bezel edge
                bezelConstraints.append(NSLayoutConstraint.init(item: view!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: .equal, toItem: bezel, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0.0))
            }
            if idx > 0 {
                // Has previous
                let itemView:UIView = subViewsNS[idx - 1] as! UIView
                let padding = NSLayoutConstraint.init(item: view!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: .equal, toItem: itemView, attribute: .bottom, multiplier: 1.0, constant: 0.0)
                bezelConstraints.append(padding)
                paddingConstraints.append(padding)
            }
        }
        
        bezel.addConstraints(bezelConstraints)
        self.bezelConstraints = bezelConstraints
        
        self.paddingConstraints = paddingConstraints
        
        self.updatePaddingConstraints()
        super.updateConstraints()
    }
    
    override func layoutSubviews() {
        if !self.needsUpdateConstraints() {
            self.updatePaddingConstraints()
        }
        super.layoutSubviews()
    }
    
    func updatePaddingConstraints() {
        // Set padding dynamically, depending on whether the view is visible or not (根据是否可见来设置视图)
        var hasVisibleAncestors = false
        
        for (_,pad) in self.paddingConstraints.enumerated() {
            let padding = pad
            let firstView = padding.firstItem
            let secondView = padding.secondItem
            
            let firstVisible = !(firstView?.isHidden)! && !(firstView?.intrinsicContentSize.equalTo(CGSize.zero))!
            let secondVisible = !secondView!.isHidden && !secondView!.intrinsicContentSize.equalTo(CGSize.zero)
            
            // Set if both views are visible or if there's a visible view on top that doesn't have padding
            // added relative to the current view yet
            padding.constant = CGFloat((firstVisible && (secondVisible || hasVisibleAncestors)) ? PODefaultPadding : 0.0)
            if hasVisibleAncestors || secondVisible {
                hasVisibleAncestors = true
            }
        }
    }
    
    func applyPriority(_ priority:UILayoutPriority,constraints:Array<AnyObject>) {
        for constraint in constraints {
            let conPro = constraint as! NSLayoutConstraint
            conPro.priority = priority
        }
    }
    
    // MARK: - Show & Hide
    
    func showAnimated(_ animated:Bool) {
        assert(Thread.isMainThread, "ProgressOverlay needs to be accessed on the main thread.")
        self.minShowTimer?.invalidate()
        self.userAnimation = animated
        self.finished = false
        
        if self.graceTime > 0.0 {
            let timer = Timer.init(timeInterval: self.graceTime, target: self, selector: #selector(self.handleGraceTimer(_:)), userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
            self.graceTimer = timer
        } else {
            self.showUsingAnimation(animated)
        }
    }
    
    func hideAnimated(_ animated:Bool) {
        assert(Thread.isMainThread, "ProgressOverlay needs to be accessed on the main thread.")
        self.graceTimer?.invalidate()
        self.finished = true
        // If the minShow time is set, calculate how long the Overlay was shown,
        // and postpone the hiding operation if necessary
        if self.minShowTime > 0.0 && (self.showStarted != nil) {
            let interv:TimeInterval = Date().timeIntervalSince(self.showStarted!)
            if interv < self.minShowTime {
                let timer = Timer.init(timeInterval: self.minShowTime - interv, target: self, selector: #selector(self.handleMinShowTimer(_:)), userInfo: nil, repeats: false)
                RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
                self.minShowTimer = timer
                return
            }
        }
        // ... otherwise hide the Overlay immediately
        self.hideUsingAnimation(self.userAnimation)
    }
    
    func hideAnimated(_ animated:Bool,delay:TimeInterval) {
        let timer = Timer.init(timeInterval:delay, target: self, selector: #selector(self.handleHideTimer(_:)), userInfo: animated, repeats: false)
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        self.hideDelayTimer = timer
    }
    // MARK: - Timer Callbacks
    
    @objc func handleGraceTimer(_ theTimer:Timer) {
        if !self.finished {
            self.showUsingAnimation(self.userAnimation)
        }
    }
    
    @objc func handleMinShowTimer(_ theTimer:Timer) {
        self.hideUsingAnimation(self.userAnimation)
    }
    
    @objc func handleHideTimer(_ theTimer:Timer) {
        
        self.hideAnimated(((theTimer.userInfo! as AnyObject).boolValue)!)
    }
    
    // MARK: - Internal show & hide operations
    
    fileprivate func showUsingAnimation(_ animated:Bool) {
        //Cancel any previous animations
        self.bezelView.layer.removeAllAnimations()
        self.backgroundView.layer.removeAllAnimations()
        
        //Cancel any scheduled hideDelayed: calls
        self.hideDelayTimer?.invalidate()
        
        self.showStarted = Date()
        self.alpha = 1.0
        
        // Needed in case we hide and re-show with the same NSProgress object attached.
        self.setNSProgressDisplayLinkEnabled(true)
        
        if animated {
            self.animteIn(true, type: self.animationType, completion: {_ in })
        } else {
            self.backgroundView.alpha = 1.0
        }
    }
    
    fileprivate func hideUsingAnimation(_ animated:Bool) {
        if animated && (self.showStarted != nil) {
            self.showStarted = nil
            self.animteIn(false, type: self.animationType, completion: { (finished) in
                self.done()
            })
        } else {
            self.showStarted = nil
            self.bezelView.alpha = 0.0
            self.backgroundView.alpha = 1.0
            self.done()
        }
    }
    
    fileprivate func animteIn(_ animatingIn:Bool,type:ProgressOverlayAnimation,completion:@escaping (_ finished:Bool) -> ()){
        var type = type
        if type == ProgressOverlayAnimation.zoom {
            type = animatingIn ? ProgressOverlayAnimation.zoomIn : ProgressOverlayAnimation.zoomOut
        }
        let small = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let large = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
        let bezelView = self.bezelView
        if animatingIn && bezelView?.alpha == 0.0 && type == ProgressOverlayAnimation.zoomIn {
            bezelView?.transform = small
        } else if animatingIn && bezelView?.alpha == 0.0 && type == ProgressOverlayAnimation.zoomOut {
            bezelView?.transform = large
        }
        
        let animations = {
            if animatingIn {
                bezelView?.transform = CGAffineTransform.identity
            } else if !animatingIn && type == ProgressOverlayAnimation.zoomIn {
                bezelView?.transform = large
            } else if !animatingIn && type == ProgressOverlayAnimation.zoomOut {
                bezelView?.transform = small
            }
            bezelView?.alpha = animatingIn ? 1.0 : 0.0
            self.backgroundView.alpha = animatingIn ? 1.0 : 0.0
        }
        //Spring animations are nicer (弹性动画)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .beginFromCurrentState, animations: animations, completion: completion)
    }
    
    fileprivate func done() {
        // Cancel any scheduled hideDelayed: calls (取消延迟)
        self.hideDelayTimer?.invalidate()
        self.setNSProgressDisplayLinkEnabled(false)
        
        if self.finished {
            self.alpha = 0.0
            if self.removeFromSuperViewOnHide {
                self.removeFromSuperview()
            }
        }
        
        if let comBlock = self.completionBlock {
            comBlock()
        }
        
    }
    
    // MARK: - NSProgress
    
    fileprivate func setNSProgressDisplayLinkEnabled (_ enabled:Bool) {
        // We're using CADisplayLink, because NSProgress can change very quickly and observing it may starve the main thread,
        // so we're refreshing the progress only every frame draw
        if enabled && (self.progressObject != nil) {
            if self.progressObjectDisplayLink == nil {
                self.progressObjectDisplayLink = CADisplayLink.init(target: self, selector: #selector(self.updateProgressFormProgressObject))
            }
        } else {
            self.progressObjectDisplayLink = nil
        }
    }
    
    @objc func updateProgressFormProgressObject() {
        self.progress = (self.progressObject?.fractionCompleted)!
    }
    
    // MARK: - Properties
    
    fileprivate var customViewProperty:UIView = UIView.init()
    /// The UIView (e.g., a UIImageView) to be shown when the Overlay is in CustomView.
    /// The view should implement intrinsicContentSize for proper sizing. For best results use approximately 37 by 37 pixels.
    var customView:UIView {
        set {
            if newValue != customViewProperty {
                customViewProperty = newValue
                self.updateIndicators()
            }
        }
        get {
            return customViewProperty
        }
    }
    
    /* Grace period is the time (in seconds) that the invoked method may be run without
     * showing the Overlay. If the task finishes before the grace time runs out, the Overlay will
     * not be shown at all.
     * This may be used to prevent Overlay display for very short tasks.
     * Defaults to 0 (no grace time).
     */
    var graceTime:TimeInterval = 0.0
    
    /*
     * The minimum time (in seconds) that the Overlay is shown.
     * This avoids the problem of the Overlay being shown and than instantly hidden.
     * Defaults to 0 (no minimum show time).
     */
    var minShowTime:TimeInterval = 0.0
    
    /// Removes the Overlay from its parent view when hidden. (自动隐藏)
    var removeFromSuperViewOnHide:Bool = true
    
    /// The NSProgress object feeding the progress information to the progress indicator. (进度指示器)
    fileprivate var progressObject:Progress?
    
    fileprivate var progress:Double = 0.0
    @objc func forProgress(_ pro:Double) {
        if pro != progress {
            progress = pro
            let indicator = self.indicator
            if self.responds(to: #selector(self.forProgress(_:))) {
                indicator?.setValue(pro, forKey: "progress")
            }
        }
    }
    
    // MARK: - Notifications
    
    func registerForNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.statusBarOrientationDidChange(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    func unregisterFromNofifications(){
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        
    }
    
    @objc func statusBarOrientationDidChange(_ nofification:Notification) {
        
        if self.superview != nil {
            self.updateForCurrentOrientationAnimated(true)
        }
        
    }
    
    func updateForCurrentOrientationAnimated(_ animated:Bool) {
        // Stay in sync with the superview in any case
        if self.superview != nil {
            self.bounds = (self.superview?.bounds)!
        }
        
    }
}

public enum OverlayBackgroundStyle {
    /// Solid color background (纯色背景)
    case solidColor
    /// UIVisualEffectView background view (模糊视图)
    case blur
}

class OverlayBackgroundView: UIView {
    
    fileprivate var effectView:UIVisualEffectView?
    
    /* Defaults to Blur on iOS 7 or later and SolidColor otherwise.
     * 背景样式
     */
    fileprivate var styleProperty:OverlayBackgroundStyle = .blur
    
    /// The background style.
    var style:OverlayBackgroundStyle {
        set {
            if styleProperty != newValue {
                self.styleProperty = newValue
                self.updateForBackgroundStyle()
            }
        }
        get {
            return self.styleProperty
        }
    }
    
    fileprivate var colorProperty:UIColor = UIColor.init(white: 0.8, alpha: 0.6)
    /// The background color or the blur tint color. (背景颜色)
    var color:UIColor {
        set {
            if colorProperty != newValue && !newValue.isEqual(colorProperty) {
                self.colorProperty = newValue
                self.updateViewsForColor(newValue)
            }
        }
        get {
            return self.colorProperty
        }
    }
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        style = .blur
        color = UIColor.init(white: 0.8, alpha: 0.6)
        self.clipsToBounds = true
        
        self.updateForBackgroundStyle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override var intrinsicContentSize : CGSize {
        //Smallest size possible. Content pushes against this. (最小尺寸)
        return CGSize.zero
    }
    
    // MARK: - Views
    
    func updateForBackgroundStyle() {
        let  style = self.style
        if style == .blur {
            // UIBlurEffect 毛玻璃
            let effect = UIBlurEffect.init(style: .light)
            
            let effectView = UIVisualEffectView.init(effect: effect)
            self.addSubview(effectView)
            effectView.frame = self.frame
            effectView.autoresizingMask = UIView.AutoresizingMask.init(rawValue: UIView.AutoresizingMask.flexibleHeight.rawValue | UIView.AutoresizingMask.flexibleWidth.rawValue)
            self.backgroundColor = self.color
            self.layer.allowsGroupOpacity = false
            self.effectView = effectView
            
        } else {
            self.effectView?.removeFromSuperview()
            self.effectView = nil
            self.backgroundColor = self.color
        }
    }
    
    func updateViewsForColor(_ color:UIColor) {
        if self.style == .blur {
            self.backgroundColor = self.color
        } else {
            self.backgroundColor = self.color
        }
    }
}

/// RoundedButton 圆角按钮
class OverlayRoundedButton: UIButton {
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        let layer:CALayer = self.layer
        layer.borderWidth = 1.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        //Fully rounded corners (圆角)
        let height = self.bounds.height
        // ceil 用于返回大于或者等于指定表达式的最小整数
        self.layer.cornerRadius = ceil(height/2.0)
    }
    
    override var intrinsicContentSize : CGSize {
        
        // Only show if we have associated control events (只显示相关的控制事件)
        if self.allControlEvents.rawValue == 0 {
            return CGSize.zero
        }
        var size:CGSize = super.intrinsicContentSize
        // Add some side padding
        size.width += 20.0
        return size
    }
    
    // MARK: - Color
    
    override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state)
        // Update related colors (更新相关颜色)
        
    }
    
    override var isHighlighted: Bool {
        set {
            super.isHighlighted = newValue
            let baseColor:UIColor = self.titleColor(for: .selected)!
            self.backgroundColor = isHighlighted ? baseColor.withAlphaComponent(0.1) : UIColor.clear
        }
        get {
            return super.isHighlighted
        }
    }
}

/// OverlayBarProgressView
class OverlayBarProgressView: UIView {
    
    fileprivate var progressProperty:CGFloat!
    /// Progress (0.0 to 1.0)
    var progress:CGFloat {
        set {
            if  newValue != progressProperty {
                self.progressProperty = newValue
                DispatchQueue.main.async(execute: { () -> Void in
                    self.setNeedsDisplay()
                })
            }
        }
        get {
            return self.progressProperty
        }
    }
    
    fileprivate var progressColorProperty:UIColor = UIColor.white
    
    /// Bar progress color.
    /// Defaults to white [UIColor whiteColor].
    var progressColor:UIColor {
        set {
            if  newValue != progressColorProperty && !progressColorProperty.isEqual(newValue) {
                self.progressColorProperty = newValue
                DispatchQueue.main.async(execute: { () -> Void in
                    self.setNeedsDisplay()
                })
            }
        }
        get {
            return self.progressColorProperty
        }
    }
    
    fileprivate var progressRemainingColorProperty:UIColor = UIColor.clear
    
    /// Bar background color.
    /// Defaults to white [UIColor whiteColor].
    var progressRemainingColor:UIColor {
        set {
            if  newValue != progressRemainingColorProperty && !progressRemainingColorProperty.isEqual(newValue) {
                self.progressRemainingColorProperty = newValue
                DispatchQueue.main.async(execute: { () -> Void in
                    self.setNeedsDisplay()
                })
            }
        }
        get {
            return self.progressRemainingColorProperty
        }
    }
    
    /// Bar border line color.
    var lineColor:UIColor = UIColor.white
    
    // MARK: - Lifecycle
    
    convenience init () {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 120.0, height: 120.0))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        self.progress = 0.0
        self.progressColor = UIColor.white
        self.progressRemainingColor = UIColor.clear
        self.lineColor = UIColor.white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override var intrinsicContentSize : CGSize {
        return CGSize(width: 120.0, height: 10.0)
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(2)
        context?.setStrokeColor(lineColor.cgColor)
        context?.setFillColor(self.progressRemainingColor.cgColor)
        
        // Draw background
        var radius = (rect.size.height / 2) - 2
        context?.move(to: CGPoint(x: 2, y: rect.size.height/2))
        context?.addArc(tangent1End: CGPoint.init(x: 2, y: 2), tangent2End: CGPoint.init(x: radius + 2, y: 2), radius: radius)
        context?.addLine(to: CGPoint(x: rect.size.width - radius - 2, y: 2))
        context?.addArc(tangent1End: CGPoint.init(x: rect.size.width - 2, y: 2), tangent2End: CGPoint.init(x: rect.size.width - 2, y: rect.size.height / 2), radius: radius)
        context?.addArc(tangent1End: CGPoint.init(x: rect.size.width - 2, y: rect.size.height - 2), tangent2End: CGPoint.init(x: rect.size.width - radius - 2, y: rect.size.height - 2), radius: radius)
        context?.addLine(to: CGPoint(x: radius + 2, y: rect.size.height - 2))
        context?.addArc(tangent1End: CGPoint.init(x: 2, y: rect.size.height - 2), tangent2End: CGPoint.init(x: 2, y: rect.size.height/2), radius: radius)
        context?.fillPath()
        
        // Draw border
        context?.move(to: CGPoint(x: 2, y: rect.size.height/2))
        context?.addArc(tangent1End: CGPoint.init(x: 2, y: 2), tangent2End: CGPoint.init(x: radius + 2, y: 2), radius: radius)
        context?.addLine(to: CGPoint(x: rect.size.width - radius - 2, y: 2))
        context?.addArc(tangent1End: CGPoint.init(x: rect.size.width - 2, y: 2), tangent2End: CGPoint.init(x: rect.size.width - 2, y: rect.size.height / 2), radius: radius)
        context?.addArc(tangent1End: CGPoint.init(x: rect.size.width - 2, y: rect.size.height - 2), tangent2End: CGPoint.init(x: rect.size.width - radius - 2, y: rect.size.height - 2), radius: radius)
        context?.addLine(to: CGPoint(x: radius + 2, y: rect.size.height - 2))
        context?.addArc(tangent1End: CGPoint.init(x: 2, y: rect.size.height - 2), tangent2End: CGPoint.init(x: 2, y: rect.size.height/2), radius: radius)
        context?.strokePath()
        
        context?.setFillColor(self.progressColor.cgColor)
        radius = radius - 2
        let amount = self.progress * rect.size.width
        
        // Progress in the middle area
        if (amount >= radius + 4 && amount <= (rect.size.width - radius - 4)) {
            context?.move(to: CGPoint(x: 4, y: rect.size.height/2))
            context?.addArc(tangent1End: CGPoint.init(x: 4, y: 4), tangent2End: CGPoint.init(x: radius + 4, y: 4), radius: radius)
            context?.addLine(to: CGPoint(x: amount, y: 4))
            context?.addLine(to: CGPoint(x: amount, y: radius + 4))
            
            context?.move(to: CGPoint(x: 4, y: rect.size.height/2))
            context?.addArc(tangent1End: CGPoint.init(x: 4, y: rect.size.height - 4), tangent2End: CGPoint.init(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context?.addLine(to: CGPoint(x: amount, y: rect.size.height - 4))
            context?.addLine(to: CGPoint(x: amount, y: radius + 4))
            
            context?.fillPath()
        }
            
            // Progress in the right arc
        else if (amount > radius + 4) {
            let x = amount - (rect.size.width - radius - 4)
            
            context?.move(to: CGPoint(x: 4, y: rect.size.height/2))
            context?.addArc(tangent1End: CGPoint.init(x: 4, y: 4), tangent2End: CGPoint.init(x: radius + 4, y: 4), radius: radius)
            context?.addLine(to: CGPoint(x: rect.size.width - radius - 4, y: 4))
            var angle = -acos(x/radius)
            
            if (angle.isNaN){
                angle = 0
            }
            context?.addArc(center: CGPoint.init(x: rect.size.width - radius - 4, y:  rect.size.height/2), radius: radius, startAngle: CGFloat(Double.pi), endAngle: angle, clockwise: false)
            context?.addLine(to: CGPoint(x: amount, y: rect.size.height/2))
            
            context?.move(to: CGPoint(x: 4, y: rect.size.height/2))
            context?.addArc(tangent1End: CGPoint.init(x: 4, y: rect.size.height - 4), tangent2End: CGPoint.init(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context?.addLine(to: CGPoint(x: rect.size.width - radius - 4, y: rect.size.height - 4))
            angle = acos(x/radius)
            if (angle.isNaN) {
                angle = 0
            }
            context?.addArc(center: CGPoint.init(x: rect.size.width - radius - 4, y:  rect.size.height/2), radius: radius, startAngle: -CGFloat(Double.pi), endAngle: angle, clockwise: true)
            context?.addLine(to: CGPoint(x: amount, y: rect.size.height/2))
            
            context?.fillPath()
        }
            // Progress is in the left arc
        else if (amount < radius + 4 && amount > 0) {
            context?.move(to: CGPoint(x: 4, y: rect.size.height/2))
            context?.addArc(tangent1End: CGPoint.init(x: 4, y: 4), tangent2End: CGPoint.init(x: radius + 4, y: 4), radius: radius)
            context?.addLine(to: CGPoint(x: radius + 4, y: rect.size.height/2))
            
            context?.move(to: CGPoint(x: 4, y: rect.size.height/2))
            context?.addArc(tangent1End: CGPoint.init(x: 4, y: rect.size.height - 4), tangent2End: CGPoint.init(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context?.addLine(to: CGPoint(x: radius + 4, y: rect.size.height/2))
            
            context?.fillPath()
        }
    }
}

class OverlayRoundProgressView: UIView {
    
    fileprivate var progressProperty:CGFloat!
    /// Progress (0.0 to 1.0)
    var progress:CGFloat {
        set {
            if  newValue != progressProperty {
                self.progressProperty = newValue
                DispatchQueue.main.async(execute: { () -> Void in
                    self.setNeedsDisplay()
                })
            }
        }
        get {
            return self.progressProperty
        }
    }
    
    /// Display mode - false = round or true = annular. Defaults to round (显示模式，false 圆形，true 为环形)
    var annular = false
    
    fileprivate var progressTintColorProperty:UIColor = UIColor.init(white: 1.0, alpha: 1.0)
    
    /// Indicator progress color.
    /// Defaults to white [UIColor whiteColor].
    var progressTintColor:UIColor {
        set {
            if  newValue != progressTintColorProperty && !progressTintColorProperty.isEqual(newValue) {
                self.progressTintColorProperty = newValue
                DispatchQueue.main.async(execute: { () -> Void in
                    self.setNeedsDisplay()
                })
            }
        }
        get {
            return self.progressTintColorProperty
        }
    }
    
    fileprivate var backgroundTintColorProperty:UIColor = UIColor.init(white: 1.0, alpha: 1.0)
    
    /// Indicator background (non-progress) color.
    /// Defaults to translucent white (alpha 0.1).
    var backgroundTintColor:UIColor {
        set {
            if  newValue != backgroundTintColorProperty && !backgroundTintColorProperty.isEqual(newValue) {
                self.backgroundTintColorProperty = newValue
                DispatchQueue.main.async(execute: { () -> Void in
                    self.setNeedsDisplay()
                })
            }
        }
        get {
            return self.backgroundTintColorProperty
        }
    }
    
    // MARK: - Lifecycle
    
    convenience init () {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 37.0, height: 37.0))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        self.progress = 0.0
        self.progressTintColor = UIColor.init(white: 1.0, alpha: 1.0)
        self.backgroundTintColor = UIColor.init(white: 1.0, alpha: 1.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override var intrinsicContentSize : CGSize {
        return CGSize(width: 37.0, height: 37.0)
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        if self.annular {
            // Draw background
            let lineWidth:CGFloat = 2.0
            let processBackgroundPath = UIBezierPath.init()
            processBackgroundPath.lineWidth = lineWidth
            processBackgroundPath.lineCapStyle = .butt
            let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            let radius = (self.bounds.size.width - lineWidth)/2
            let startAngle:CGFloat = -CGFloat(Double.pi/2) //90 degrees
            var endAngle:CGFloat = (2 * CGFloat(Double.pi)) + startAngle
            processBackgroundPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            self.backgroundTintColor.set()
            processBackgroundPath.stroke()
            
            // Draw progress
            let  processPath = UIBezierPath.init()
            processPath.lineCapStyle = .square
            processPath.lineWidth = lineWidth
            endAngle = self.progress * 2 * CGFloat(Double.pi) + startAngle
            processPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            self.progressTintColor.set()
            processPath.stroke()
            
        } else {
            // Draw background
            let lineWidth:CGFloat = 2.0
            let allRect = self.bounds
            let circleRect = allRect.insetBy(dx: lineWidth/2.0, dy: lineWidth/2.0)
            let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            self.progressTintColor.setStroke()
            self.backgroundTintColor.setFill()
            context?.setLineWidth(lineWidth)
            context?.strokeEllipse(in: circleRect)
            let startAngle = -CGFloat(Double.pi) / 2.0
            let processPath = UIBezierPath()
            processPath.lineCapStyle = .butt
            processPath.lineWidth = lineWidth * 2.0
            
            let radius = self.bounds.width/2.0 - processPath.lineWidth / 2.0
            let endAngle = self.progress * 2.0 * CGFloat(Double.pi) + startAngle
            processPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            context?.setBlendMode(.copy)
            self.progressTintColor.set()
            processPath.stroke()
        }
    }
    
}
