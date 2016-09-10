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
  case Fade
  // Opacity + scale animation (zoom in when appearing zoom out when disappearing) 不透明度+缩放动画（出现时放大缩小消失时）
  case Zoom
  // Opacity + scale animation (zoom out style) 不透明度+缩放动画（缩小）
  case ZoomOut
  // Opacity + scale animation (zoom in style) 不透明度+缩放动画（放大）
  case ZoomIn
}

public enum ProgressOverlayMode: Int {
  /// UIActivityIndicatorView.
  case Indeterminate
  /// A round, pie-chart like, progress view. (一个圆，像饼图一样的进度条视图)
  case Determinate
  /// Horizontal progress bar. (水平进度条)
  case DeterminateHorizontalBar
  /// Ring-shaped progress view. (环形进度条)
  case AnnularDeterminate
  /// Shows a custom view. (显示自定义视图)
  case CustomView
  /// Shows only labels. (仅显示标签)
  case Text
}

let ProgressOverlayMaxOffset:CGFloat = (UIScreen.mainScreen().bounds.size.height - 120)/2

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
  
  private var modeProperty:ProgressOverlayMode = .Indeterminate
  
  /// ProgressOverlay operation mode. The default is Indeterminate. (ProgressOverlay 显示模式 ，默认是 Indeterminate)
  var mode:ProgressOverlayMode  {
    set(newValue) {
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
  
  private var minSizeProperty:CGSize = CGSizeZero
  /**
   The minimum size of the Overlay bezel. Defaults to CGSizeZero (no minimum size).
   */
  var minSize:CGSize {
    set (newValue) {
      if !CGSizeEqualToSize(newValue, minSizeProperty) {
        minSizeProperty = newValue
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
  
  private var offsetProperty:CGPoint = CGPointZero
  /**
   * The bezel offset relative to the center of the view. You can use ProgressOverlayMaxOffset
   * and -ProgressOverlayMaxOffset to move the Overlay all the way to the screen edge in each direction.
   * E.g., CGPointMake(0.f, ProgressOverlayMaxOffset) would position the Overlay centered on the bottom edge.
   */
  var offset:CGPoint {
    set(newValue) {
      if !CGPointEqualToPoint(offsetProperty, newValue) {
        offsetProperty = newValue
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
  
  private var contentColorProperty:UIColor = UIColor.init(white: 0.0, alpha: 0.7)
  
  /* A color that gets forwarded to all labels and supported indicators. Also sets the tintColor ()
   * for custom views on iOS 7+. Set to nil to manage color individually.
   * (labels 和 indicators) 的颜色
   */
  var contentColor:UIColor {
    set (newValue) {
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
  private var bezelView:OverlayBackgroundView!
  
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
  var minShowTimer:NSTimer?
  var graceTimer:NSTimer?
  var userAnimation:Bool = true
  var finished:Bool = false
  var hideDelayTimer:NSTimer?
  var showStarted:NSDate?
  var progressObjectDisplayLink: CADisplayLink?
  var bezelConstraints = []
  var paddingConstraints = []
  
  
  // MARK: - Class methods
  
  internal class func showOnView(view:UIView! ,animated:Bool) -> ProgressOverlay {
    let overlay = ProgressOverlay.init(view: view)
    overlay.removeFromSuperViewOnHide = true
    view.addSubview(overlay)
    overlay.showAnimated(animated)
    return overlay
  }
  
  internal class func hideAllOverlaysForView(view:UIView! ,animated:Bool) -> Bool {
    if let overlay:ProgressOverlay = self.hideForView(view) {
      overlay.removeFromSuperViewOnHide = true
      overlay.hideAnimated(animated)
      return true
    }
    return false
  }
  
  internal class func hideForView(view:UIView!) -> ProgressOverlay? {
    
    for subView in view.subviews {
      if subView .isKindOfClass(self) {
        return subView as? ProgressOverlay
      }
    }
    return nil
  }
  // MARK: - Lifecycle
  
  private func commonInit() {
    // Set default values for properties (设置)
    animationType = .Fade
    mode = .Indeterminate
    margin = 20.0
    defaultMotionEffectsEnabled = true
    
    // Default color (默认颜色)
    contentColor = UIColor.init(white: 0.0, alpha: 0.7)
    
    // Transparent background (透明背景)
    self.opaque = false
    self.backgroundColor = UIColor.clearColor()
    
    // Make it invisible for now (当前不可见)
    self.alpha = 0.0
    self.autoresizingMask = UIViewAutoresizing.init(rawValue: UIViewAutoresizing.FlexibleWidth.rawValue | UIViewAutoresizing.FlexibleHeight.rawValue)
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
  
  private func setupViews() {
    let defaultColor = self.contentColor
    
    let backgroundView = OverlayBackgroundView.init(frame: self.bounds)
    backgroundView.style = .SolidColor
    backgroundView.backgroundColor = UIColor.clearColor()
    backgroundView.autoresizingMask = UIViewAutoresizing.init(rawValue: UIViewAutoresizing.FlexibleWidth.rawValue | UIViewAutoresizing.FlexibleHeight.rawValue)
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
    label.textAlignment = .Center
    label.textColor = defaultColor
    label.font = UIFont.boldSystemFontOfSize(PODefaultLabelFontSize)
    label.opaque = false
    label.backgroundColor = UIColor.clearColor()
    self.label = label
    
    let detailsLabel = UILabel()
    detailsLabel.adjustsFontSizeToFitWidth = false
    detailsLabel.textAlignment = .Center
    detailsLabel.textColor = defaultColor
    detailsLabel.numberOfLines = 0
    detailsLabel.font = UIFont.boldSystemFontOfSize(PODefaultDetailsLabelFontSize)
    detailsLabel.opaque = false
    detailsLabel.backgroundColor = UIColor.clearColor()
    self.detailsLabel = detailsLabel
    
    let button = OverlayRoundedButton(type:.Custom)
    button.titleLabel?.textAlignment = .Center
    button.titleLabel?.font = UIFont.boldSystemFontOfSize(PODefaultDetailsLabelFontSize)
    button.setTitleColor(defaultColor, forState: .Normal)
    self.button = button
    
    for view in [label,detailsLabel,button] {
      view.translatesAutoresizingMaskIntoConstraints = false
      view.setContentCompressionResistancePriority(998, forAxis: .Horizontal)
      view.setContentCompressionResistancePriority(998, forAxis: .Vertical)
      bezelView.addSubview(view)
    }
    
    let topSpacer = UIView()
    topSpacer.translatesAutoresizingMaskIntoConstraints = false
    topSpacer.hidden = true
    bezelView.addSubview(topSpacer)
    self.topSpacer = topSpacer
    
    let bottomSpacer = UIView()
    bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
    bottomSpacer.hidden = true
    bezelView.addSubview(bottomSpacer)
    self.bottomSpacer = bottomSpacer
  }
  
  func updateIndicators() {
    
    var isActivityIndicator = false
    var isRoundIndicator = false
    var indicator = self.indicator
    if  indicator != nil{
      isActivityIndicator = indicator!.isKindOfClass(UIActivityIndicatorView.classForCoder())
      isRoundIndicator = indicator!.isKindOfClass(OverlayBackgroundView)
    }
    let mode = self.mode
    if mode == ProgressOverlayMode.Indeterminate {
      if !isActivityIndicator {
        // Update to indeterminate indicator (更新)
        indicator?.removeFromSuperview()
        indicator = UIActivityIndicatorView.init(activityIndicatorStyle: .WhiteLarge)
        (indicator as! UIActivityIndicatorView).startAnimating()
        self.bezelView.addSubview(indicator!)
      }
    } else if (mode == ProgressOverlayMode.DeterminateHorizontalBar) {
      // Update to bar determinate indicator
      indicator?.removeFromSuperview()
      indicator = OverlayBarProgressView()
      self.bezelView.addSubview(indicator!)
    } else if (mode == ProgressOverlayMode.Determinate || mode == ProgressOverlayMode.AnnularDeterminate) {
      if !isRoundIndicator {
        // Update to determinante indicator
        indicator?.removeFromSuperview()
        indicator = OverlayRoundProgressView.init()
        self.bezelView.addSubview(indicator!)
      }
      if mode == ProgressOverlayMode.AnnularDeterminate {
        (indicator as! OverlayRoundProgressView).annular = true
      }
    } else if (mode == ProgressOverlayMode.CustomView && self.customView != indicator) {
      indicator?.removeFromSuperview()
      indicator = self.customView
      self.bezelView.addSubview(indicator!)
    } else if (mode == ProgressOverlayMode.Text) {
      indicator?.removeFromSuperview()
      indicator = nil
    }
    indicator?.translatesAutoresizingMaskIntoConstraints = false
    self.indicator = indicator
    
    if indicator?.respondsToSelector(#selector(self.forProgress(_:))) == true {
        indicator?.setValue(self.progress, forKey: "progress")
    }
    
    indicator?.setContentCompressionResistancePriority(998, forAxis: .Horizontal)
    indicator?.setContentCompressionResistancePriority(998, forAxis: .Vertical)
    
    self.updateViewsForColor(self.contentColor)
    self.setNeedsUpdateConstraints()
  }
  
  func updateViewsForColor(color:UIColor) {
    
    self.label.textColor = color
    self.detailsLabel.textColor = color
    self.button.setTitleColor(color, forState: .Normal)
    
    //UIAppearance settings are prioritized. If they are preset the set color is ignored.  (UIAppearance 设置优先级)
    let indicator = self.indicator
    if indicator?.isKindOfClass(UIActivityIndicatorView.classForCoder()) == true {
      let appearance:UIActivityIndicatorView?
      appearance = UIActivityIndicatorView.appearanceWhenContainedInInstancesOfClasses([ProgressOverlay.classForCoder()])
      
      if  appearance?.color == nil {
        (indicator as! UIActivityIndicatorView).color = color
      }
    } else if indicator?.isKindOfClass(OverlayRoundProgressView.classForCoder()) == true {
      let opView = (indicator as! OverlayRoundProgressView)
      opView.progressTintColor = color
      opView.backgroundTintColor = color.colorWithAlphaComponent(0.1)
    } else if indicator?.isKindOfClass(OverlayBarProgressView.classForCoder()) == true {
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
      let effectX:UIInterpolatingMotionEffect = UIInterpolatingMotionEffect.init(keyPath: "center.x", type: .TiltAlongHorizontalAxis)
      effectX.maximumRelativeValue = effectOffset
      effectX.minimumRelativeValue = -effectOffset
      
      let effectY:UIInterpolatingMotionEffect = UIInterpolatingMotionEffect.init(keyPath: "center.y", type: .TiltAlongVerticalAxis)
      effectY.maximumRelativeValue = effectOffset
      effectY.minimumRelativeValue = -effectOffset
      
      let group:UIMotionEffectGroup = UIMotionEffectGroup.init()
      group.motionEffects = [effectX,effectY]
      bezelView.addMotionEffect(group)
      
    } else {
      let effects = bezelView.motionEffects
      for effect in effects {
        bezelView.removeMotionEffect(effect)
      }
    }
  }
  
  // MARK: - Layout
  
  override func updateConstraints() {
    
    let bezel = self.bezelView
    let topSpacer = self.topSpacer
    let bottomSpacer = self.bottomSpacer
    let margin:CGFloat = self.margin
    var bezelConstraints = Array<NSLayoutConstraint>()
    let metrics = ["margin":margin]
    
    var subviews = [self.topSpacer,self.label,self.detailsLabel,self.button,self.bottomSpacer]
    if self.indicator != nil {
      subviews.insert(self.indicator, atIndex: 1)
    }
    
    // Remove existing constraints
    self.removeConstraints(self.constraints)
    topSpacer.removeConstraints(topSpacer.constraints)
    bottomSpacer.removeConstraints(bottomSpacer.constraints)
    
    if self.bezelConstraints.count > 0 {
      bezel.removeConstraints(self.bezelConstraints as! [NSLayoutConstraint])
      self.bezelConstraints = []
    }
    
    // Center bezel in container (self), applying the offset if set (控制约束
    let offset = self.offset
    var centeringConstraints:Array = Array<NSLayoutConstraint>()
    centeringConstraints.append(NSLayoutConstraint.init(item: bezel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: offset.x))
    centeringConstraints.append(NSLayoutConstraint.init(item: bezel, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: offset.y))
    self.applyPriority(999, constraints: centeringConstraints)
    self.addConstraints(centeringConstraints)
    
    // Ensure minimum side margin is kept (保证最小的侧边)
    var sideConstraints = Array<NSLayoutConstraint>()
    sideConstraints += NSLayoutConstraint.constraintsWithVisualFormat("|-(>=margin)-[bezel]-(>=margin)-|", options: .DirectionLeadingToTrailing, metrics: metrics, views: ["bezel":bezel])
    sideConstraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-(>=margin)-[bezel]-(>=margin)-|", options: .DirectionLeadingToTrailing, metrics: metrics, views: ["bezel":bezel])
    self.applyPriority(999, constraints: sideConstraints)
    self.addConstraints(sideConstraints)
    
    // Minmum bezel size,if set (bezel 最小尺寸)
    let minimumSize = self.minSize
    if !CGSizeEqualToSize(minimumSize, CGSizeZero) {
      var minSizeConstraints = Array<NSLayoutConstraint>()
      minSizeConstraints.append(NSLayoutConstraint.init(item: bezel, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: minimumSize.width))
      minSizeConstraints.append(NSLayoutConstraint.init(item: bezel, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: minimumSize.height))
      self.applyPriority(997, constraints: minSizeConstraints)
      bezelConstraints += minSizeConstraints
    }
    
    // Square aspect ratio, if set (宽高比)
    if self.square {
      let square = NSLayoutConstraint.init(item: bezel, attribute: .Height, relatedBy: .Equal, toItem: bezel, attribute: .Width, multiplier: 1.0, constant: 0)
      square.priority = 997
      bezelConstraints.append(square)
    }
    
    // Top and bottom spacing (上下边距)
    topSpacer.addConstraint(NSLayoutConstraint.init(item: topSpacer, attribute: .Height, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: margin))
    bottomSpacer.addConstraint(NSLayoutConstraint.init(item: bottomSpacer, attribute: .Height, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: margin))
    
    // Top and bottom spaces should be equal (上下边距应保持一致)
    bezelConstraints.append(NSLayoutConstraint.init(item: topSpacer, attribute: .Height, relatedBy: .Equal, toItem: bottomSpacer, attribute: .Height, multiplier: 1.0, constant: 0.0))
    
    // Layout subviews in bezel (重置子视图约束)
    
    var paddingConstraints = Array<NSLayoutConstraint>()
    let subViewsNS = subviews as NSArray
  
    subViewsNS.enumerateObjectsUsingBlock { (view, idx, stop) in
      // Center in bezel （居中）
      bezelConstraints.append(NSLayoutConstraint.init(item: view, attribute: .CenterX, relatedBy: .Equal, toItem: bezel, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
      // Ensure the minimum edge margin is kept
      bezelConstraints += NSLayoutConstraint.constraintsWithVisualFormat("|-(>=margin)-[view]-(>=margin)-|", options: .DirectionLeadingToTrailing, metrics: metrics, views: ["view":view])
      
      // Element spacing
      if idx == 0 {
        // First, ensure spacing to bezel edge
        bezelConstraints.append(NSLayoutConstraint.init(item: view, attribute: NSLayoutAttribute.Top, relatedBy: .Equal, toItem: bezel, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0.0))
      } else if (idx == subViewsNS.count - 1) {
        // Last, ensure spacing to bezel edge
        bezelConstraints.append(NSLayoutConstraint.init(item: view, attribute: NSLayoutAttribute.Bottom, relatedBy: .Equal, toItem: bezel, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0.0))
      }
      if idx > 0 {
        // Has previous
        let padding = NSLayoutConstraint.init(item: view, attribute: NSLayoutAttribute.Top, relatedBy: .Equal, toItem: subViewsNS[idx - 1], attribute: .Bottom, multiplier: 1.0, constant: 0.0)
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
    
    self.paddingConstraints.enumerateObjectsUsingBlock { (pad, idx, stop) in
      let padding = pad as! NSLayoutConstraint
      let firstView = padding.firstItem
      let secondView = padding.secondItem
      
      let firstVisible = !firstView.hidden && !CGSizeEqualToSize(firstView.intrinsicContentSize(), CGSizeZero)
      let secondVisible = !secondView!.hidden && !CGSizeEqualToSize(secondView!.intrinsicContentSize(), CGSizeZero)
      
      // Set if both views are visible or if there's a visible view on top that doesn't have padding
      // added relative to the current view yet
      padding.constant = CGFloat((firstVisible && (secondVisible || hasVisibleAncestors)) ? PODefaultPadding : 0.0)
      if hasVisibleAncestors || secondVisible {
        hasVisibleAncestors = true
      }
    }
  }
  
  func applyPriority(priority:UILayoutPriority,constraints:Array<AnyObject>) {
    for constraint in constraints {
      let conPro = constraint as! NSLayoutConstraint
      conPro.priority = priority
    }
  }
  
  // MARK: - Show & Hide
  
  func showAnimated(animated:Bool) {
    assert(NSThread.isMainThread(), "ProgressOverlay needs to be accessed on the main thread.")
    self.minShowTimer?.invalidate()
    self.userAnimation = animated
    self.finished = false
    
    if self.graceTime > 0.0 {
      let timer = NSTimer.init(timeInterval: self.graceTime, target: self, selector: #selector(self.handleGraceTimer(_:)), userInfo: nil, repeats: false)
      NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
      self.graceTimer = timer
    } else {
      self.showUsingAnimation(animated)
    }
  }
  
  func hideAnimated(animated:Bool) {
    assert(NSThread.isMainThread(), "ProgressOverlay needs to be accessed on the main thread.")
    self.graceTimer?.invalidate()
    self.finished = true
    // If the minShow time is set, calculate how long the Overlay was shown,
    // and postpone the hiding operation if necessary
    if self.minShowTime > 0.0 && (self.showStarted != nil) {
      let interv:NSTimeInterval = NSDate().timeIntervalSinceDate(self.showStarted!)
      if interv < self.minShowTime {
        let timer = NSTimer.init(timeInterval: self.minShowTime - interv, target: self, selector: #selector(self.handleMinShowTimer(_:)), userInfo: nil, repeats: false)
        NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
        self.minShowTimer = timer
        return
      }
    }
    // ... otherwise hide the Overlay immediately
    self.hideUsingAnimation(self.userAnimation)
  }
  
  func hideAnimated(animated:Bool,delay:NSTimeInterval) {
    let timer = NSTimer.init(timeInterval:delay, target: self, selector: #selector(self.handleHideTimer(_:)), userInfo: animated, repeats: false)
    NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    self.hideDelayTimer = timer
  }
  // MARK: - Timer Callbacks
  
  func handleGraceTimer(theTimer:NSTimer) {
    if !self.finished {
      self.showUsingAnimation(self.userAnimation)
    }
  }
  
  func handleMinShowTimer(theTimer:NSTimer) {
    self.hideUsingAnimation(self.userAnimation)
  }
  
  func handleHideTimer(theTimer:NSTimer) {
    self.hideAnimated((theTimer.userInfo?.boolValue)!)
  }
  
  // MARK: - Internal show & hide operations
  
  private func showUsingAnimation(animated:Bool) {
    //Cancel any previous animations
    self.bezelView.layer.removeAllAnimations()
    self.backgroundView.layer.removeAllAnimations()
    
    //Cancel any scheduled hideDelayed: calls
    self.hideDelayTimer?.invalidate()
    
    self.showStarted = NSDate()
    self.alpha = 1.0
    
    // Needed in case we hide and re-show with the same NSProgress object attached.
    self.setNSProgressDisplayLinkEnabled(true)
    
    if animated {
      self.animteIn(true, type: self.animationType, completion: {_ in })
    } else {
      self.backgroundView.alpha = 1.0
    }
  }
  
  private func hideUsingAnimation(animated:Bool) {
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
  
  private func animteIn(animatingIn:Bool,type:ProgressOverlayAnimation,completion:(finished:Bool) -> ()){
    var type = type
    if type == ProgressOverlayAnimation.Zoom {
      type = animatingIn ? ProgressOverlayAnimation.ZoomIn : ProgressOverlayAnimation.ZoomOut
    }
    let small = CGAffineTransformMakeScale(0.5, 0.5)
    let large = CGAffineTransformMakeScale(1.5, 1.5)
    
    let bezelView = self.bezelView
    if animatingIn && bezelView.alpha == 0.0 && type == ProgressOverlayAnimation.ZoomIn {
      bezelView.transform = small
    } else if animatingIn && bezelView.alpha == 0.0 && type == ProgressOverlayAnimation.ZoomOut {
      bezelView.transform = large
    }
    
    let animations = {
      if animatingIn {
        bezelView.transform = CGAffineTransformIdentity
      } else if !animatingIn && type == ProgressOverlayAnimation.ZoomIn {
        bezelView.transform = large
      } else if !animatingIn && type == ProgressOverlayAnimation.ZoomOut {
        bezelView.transform = small
      }
      bezelView.alpha = animatingIn ? 1.0 : 0.0
      self.backgroundView.alpha = animatingIn ? 1.0 : 0.0
    }
    //Spring animations are nicer (弹性动画)
    UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .BeginFromCurrentState, animations: animations, completion: completion)
  }
  
  private func done() {
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
  
  private func setNSProgressDisplayLinkEnabled (enabled:Bool) {
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
  
  func updateProgressFormProgressObject() {
    self.progress = (self.progressObject?.fractionCompleted)!
  }
  
  // MARK: - Properties 
  
  private var customViewProperty:UIView = UIView.init()
  /// The UIView (e.g., a UIImageView) to be shown when the Overlay is in CustomView.
  /// The view should implement intrinsicContentSize for proper sizing. For best results use approximately 37 by 37 pixels.
  var customView:UIView {
    set (newValue) {
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
  var graceTime:NSTimeInterval = 0.0
  
  /*
   * The minimum time (in seconds) that the Overlay is shown.
   * This avoids the problem of the Overlay being shown and than instantly hidden.
   * Defaults to 0 (no minimum show time).
   */
  var minShowTime:NSTimeInterval = 0.0
  
  /// Removes the Overlay from its parent view when hidden. (自动隐藏)
  var removeFromSuperViewOnHide:Bool = true
  
  /// The NSProgress object feeding the progress information to the progress indicator. (进度指示器)
  private var progressObject:NSProgress?
  
  private var progress:Double = 0.0
  func forProgress(pro:Double) {
    if pro != progress {
      progress = pro
      let indicator = self.indicator
      if self.respondsToSelector(#selector(self.forProgress(_:))) {
        indicator?.setValue(pro, forKey: "progress")
      }
    }
  }
  
  // MARK: - Notifications
  
  func registerForNotifications() {
    let nc = NSNotificationCenter.defaultCenter()
    nc.addObserver(self, selector: #selector(self.statusBarOrientationDidChange(_:)), name: UIApplicationDidChangeStatusBarOrientationNotification, object: nil)
  }
  
  func unregisterFromNofifications(){
    let nc = NSNotificationCenter.defaultCenter()
    nc.removeObserver(self, name: UIApplicationDidChangeStatusBarOrientationNotification, object: nil)
    
  }
  
  func statusBarOrientationDidChange(nofification:NSNotification) {
    
    if self.superview != nil {
      self.updateForCurrentOrientationAnimated(true)
    }
    
  }
  
  func updateForCurrentOrientationAnimated(animated:Bool) {
    // Stay in sync with the superview in any case
    if self.superview != nil {
      self.bounds = (self.superview?.bounds)!
    }
    
  }
}

public enum OverlayBackgroundStyle {
  /// Solid color background (纯色背景)
  case SolidColor
  /// UIVisualEffectView background view (模糊视图)
  case Blur
}

class OverlayBackgroundView: UIView {
  
  private var effectView:UIVisualEffectView?
  
  /* Defaults to Blur on iOS 7 or later and SolidColor otherwise.
   * 背景样式
   */
  private var styleProperty:OverlayBackgroundStyle = .Blur
  
  /// The background style.
  var style:OverlayBackgroundStyle {
    set (newValue) {
      if styleProperty != newValue {
        self.styleProperty = newValue
        self.updateForBackgroundStyle()
      }
    }
    get {
      return self.styleProperty
    }
  }
  
  private var colorProperty:UIColor = UIColor.init(white: 0.8, alpha: 0.6)
  /// The background color or the blur tint color. (背景颜色)
  var color:UIColor {
    set (newValue) {
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
    
    style = .Blur
    color = UIColor.init(white: 0.8, alpha: 0.6)
    self.clipsToBounds = true
    
    self.updateForBackgroundStyle()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Layout
  
  override func intrinsicContentSize() -> CGSize {
    //Smallest size possible. Content pushes against this. (最小尺寸)
    return CGSizeZero
  }
  
  // MARK: - Views
  
  func updateForBackgroundStyle() {
    let  style = self.style
    if style == .Blur {
      // UIBlurEffect 毛玻璃
      let effect = UIBlurEffect.init(style: .Light)
      
      let effectView = UIVisualEffectView.init(effect: effect)
      self.addSubview(effectView)
      effectView.frame = self.frame
      effectView.autoresizingMask = UIViewAutoresizing.init(rawValue: UIViewAutoresizing.FlexibleHeight.rawValue | UIViewAutoresizing.FlexibleWidth.rawValue)
      self.backgroundColor = self.color
      self.layer.allowsGroupOpacity = false
      self.effectView = effectView
      
    } else {
      self.effectView?.removeFromSuperview()
      self.effectView = nil
      self.backgroundColor = self.color
    }
  }
  
  func updateViewsForColor(color:UIColor) {
    if self.style == .Blur {
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
    let height = CGRectGetHeight(self.bounds)
    // ceil 用于返回大于或者等于指定表达式的最小整数
    self.layer.cornerRadius = ceil(height/2.0)
  }
  
  override func intrinsicContentSize() -> CGSize {

    // Only show if we have associated control events (只显示相关的控制事件)
    if self.allControlEvents().rawValue == 0 {
      return CGSizeZero
    }
    var size:CGSize = super.intrinsicContentSize()
    // Add some side padding
    size.width += 20.0
    return size
  }
  
  // MARK: - Color
  
  override func setTitleColor(color: UIColor?, forState state: UIControlState) {
    super.setTitleColor(color, forState: state)
    // Update related colors (更新相关颜色)
    
  }
  
  override var highlighted: Bool {
    set (newValue) {
      super.highlighted = newValue
      let baseColor:UIColor = self.titleColorForState(.Selected)!
      self.backgroundColor = highlighted ? baseColor.colorWithAlphaComponent(0.1) : UIColor.clearColor()
    }
    get {
      return super.highlighted
    }
  }
}

/// OverlayBarProgressView
class OverlayBarProgressView: UIView {
  
  private var progressProperty:CGFloat!
  /// Progress (0.0 to 1.0)
  var progress:CGFloat {
    set (newValue) {
      if  newValue != progressProperty {
        self.progressProperty = newValue
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          self.setNeedsDisplay()
        })
      }
    }
    get {
      return self.progressProperty
    }
  }
  
  private var progressColorProperty:UIColor = UIColor.whiteColor()
  
  /// Bar progress color.
  /// Defaults to white [UIColor whiteColor].
  var progressColor:UIColor {
    set (newValue) {
      if  newValue != progressColorProperty && !progressColorProperty.isEqual(newValue) {
        self.progressColorProperty = newValue
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          self.setNeedsDisplay()
        })
      }
    }
    get {
      return self.progressColorProperty
    }
  }
  
  private var progressRemainingColorProperty:UIColor = UIColor.clearColor()
  
  /// Bar background color.
  /// Defaults to white [UIColor whiteColor].
  var progressRemainingColor:UIColor {
    set (newValue) {
      if  newValue != progressRemainingColorProperty && !progressRemainingColorProperty.isEqual(newValue) {
        self.progressRemainingColorProperty = newValue
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          self.setNeedsDisplay()
        })
      }
    }
    get {
      return self.progressRemainingColorProperty
    }
  }
  
  /// Bar border line color.
  var lineColor:UIColor = UIColor.whiteColor()
  
  // MARK: - Lifecycle
  
  convenience init () {
    self.init(frame: CGRectMake(0.0, 0.0, 120.0, 120.0))
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.backgroundColor = UIColor.clearColor()
    self.opaque = false
    self.progress = 0.0
    self.progressColor = UIColor.whiteColor()
    self.progressRemainingColor = UIColor.clearColor()
    self.lineColor = UIColor.whiteColor()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Layout
  
  override func intrinsicContentSize() -> CGSize {
    return CGSizeMake(120.0, 10.0)
  }
  
  // MARK: - Drawing
  
  override func drawRect(rect: CGRect) {
    
    let context = UIGraphicsGetCurrentContext()
    CGContextSetLineWidth(context, 2)
    CGContextSetStrokeColorWithColor(context, lineColor.CGColor)
    CGContextSetFillColorWithColor(context, self.progressRemainingColor.CGColor)
    
    // Draw background
    var radius = (rect.size.height / 2) - 2
    CGContextMoveToPoint(context, 2, rect.size.height/2)
    CGContextAddArcToPoint(context, 2, 2, radius + 2, 2, radius)
    CGContextAddLineToPoint(context, rect.size.width - radius - 2, 2)
    CGContextAddArcToPoint(context, rect.size.width - 2, 2, rect.size.width - 2, rect.size.height / 2, radius)
    CGContextAddArcToPoint(context, rect.size.width - 2, rect.size.height - 2, rect.size.width - radius - 2, rect.size.height - 2, radius)
    CGContextAddLineToPoint(context, radius + 2, rect.size.height - 2)
    CGContextAddArcToPoint(context, 2, rect.size.height - 2, 2, rect.size.height/2, radius)
    CGContextFillPath(context)
    
    // Draw border
    CGContextMoveToPoint(context, 2, rect.size.height/2)
    CGContextAddArcToPoint(context, 2, 2, radius + 2, 2, radius)
    CGContextAddLineToPoint(context, rect.size.width - radius - 2, 2)
    CGContextAddArcToPoint(context, rect.size.width - 2, 2, rect.size.width - 2, rect.size.height / 2, radius)
    CGContextAddArcToPoint(context, rect.size.width - 2, rect.size.height - 2, rect.size.width - radius - 2, rect.size.height - 2, radius)
    CGContextAddLineToPoint(context, radius + 2, rect.size.height - 2)
    CGContextAddArcToPoint(context, 2, rect.size.height - 2, 2, rect.size.height/2, radius)
    CGContextStrokePath(context)
    
    CGContextSetFillColorWithColor(context, self.progressColor.CGColor)
    radius = radius - 2
    let amount = self.progress * rect.size.width
    
    // Progress in the middle area
    if (amount >= radius + 4 && amount <= (rect.size.width - radius - 4)) {
      CGContextMoveToPoint(context, 4, rect.size.height/2)
      CGContextAddArcToPoint(context, 4, 4, radius + 4, 4, radius)
      CGContextAddLineToPoint(context, amount, 4)
      CGContextAddLineToPoint(context, amount, radius + 4)
      
      CGContextMoveToPoint(context, 4, rect.size.height/2)
      CGContextAddArcToPoint(context, 4, rect.size.height - 4, radius + 4, rect.size.height - 4, radius)
      CGContextAddLineToPoint(context, amount, rect.size.height - 4)
      CGContextAddLineToPoint(context, amount, radius + 4)
      
      CGContextFillPath(context)
    }
      
      // Progress in the right arc
    else if (amount > radius + 4) {
      let x = amount - (rect.size.width - radius - 4)
      
      CGContextMoveToPoint(context, 4, rect.size.height/2)
      CGContextAddArcToPoint(context, 4, 4, radius + 4, 4, radius)
      CGContextAddLineToPoint(context, rect.size.width - radius - 4, 4)
      var angle = -acos(x/radius)
      if (isnan(angle)){
        angle = 0
      }
      CGContextAddArc(context, rect.size.width - radius - 4, rect.size.height/2, radius, CGFloat(M_PI), angle, 0)
      CGContextAddLineToPoint(context, amount, rect.size.height/2)
      
      CGContextMoveToPoint(context, 4, rect.size.height/2)
      CGContextAddArcToPoint(context, 4, rect.size.height - 4, radius + 4, rect.size.height - 4, radius)
      CGContextAddLineToPoint(context, rect.size.width - radius - 4, rect.size.height - 4)
      angle = acos(x/radius)
      if (isnan(angle)) {
       angle = 0
      }
      CGContextAddArc(context, rect.size.width - radius - 4, rect.size.height/2, radius, -CGFloat(M_PI), angle, 1)
      CGContextAddLineToPoint(context, amount, rect.size.height/2)
      
      CGContextFillPath(context)
    }
      // Progress is in the left arc
    else if (amount < radius + 4 && amount > 0) {
      CGContextMoveToPoint(context, 4, rect.size.height/2)
      CGContextAddArcToPoint(context, 4, 4, radius + 4, 4, radius)
      CGContextAddLineToPoint(context, radius + 4, rect.size.height/2)
      
      CGContextMoveToPoint(context, 4, rect.size.height/2)
      CGContextAddArcToPoint(context, 4, rect.size.height - 4, radius + 4, rect.size.height - 4, radius)
      CGContextAddLineToPoint(context, radius + 4, rect.size.height/2)
      
      CGContextFillPath(context)
    }
  }
}

class OverlayRoundProgressView: UIView {
  
  private var progressProperty:CGFloat!
  /// Progress (0.0 to 1.0)
  var progress:CGFloat {
    set (newValue) {
      if  newValue != progressProperty {
        self.progressProperty = newValue
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
  
  private var progressTintColorProperty:UIColor = UIColor.init(white: 1.0, alpha: 1.0)
  
  /// Indicator progress color.
  /// Defaults to white [UIColor whiteColor].
  var progressTintColor:UIColor {
    set (newValue) {
      if  newValue != progressTintColorProperty && !progressTintColorProperty.isEqual(newValue) {
        self.progressTintColorProperty = newValue
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
          self.setNeedsDisplay()
        })
      }
    }
    get {
      return self.progressTintColorProperty
    }
  }
  
  private var backgroundTintColorProperty:UIColor = UIColor.init(white: 1.0, alpha: 1.0)
  
  /// Indicator background (non-progress) color.
  /// Defaults to translucent white (alpha 0.1).
  var backgroundTintColor:UIColor {
    set (newValue) {
      if  newValue != backgroundTintColorProperty && !backgroundTintColorProperty.isEqual(newValue) {
        self.backgroundTintColorProperty = newValue
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
    self.init(frame: CGRectMake(0.0, 0.0, 37.0, 37.0))
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.backgroundColor = UIColor.clearColor()
    self.opaque = false
    self.progress = 0.0
    self.progressTintColor = UIColor.init(white: 1.0, alpha: 1.0)
    self.backgroundTintColor = UIColor.init(white: 1.0, alpha: 1.0)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Layout
  
  override func intrinsicContentSize() -> CGSize {
    return CGSizeMake(37.0, 37.0)
  }
  
  // MARK: - Drawing
  
  override func drawRect(rect: CGRect) {
    let context = UIGraphicsGetCurrentContext()
    if self.annular {
      // Draw background
      let lineWidth:CGFloat = 2.0
      let processBackgroundPath = UIBezierPath.init()
      processBackgroundPath.lineWidth = lineWidth
      processBackgroundPath.lineCapStyle = .Butt
      let center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
      let radius = (self.bounds.size.width - lineWidth)/2
      let startAngle:CGFloat = -CGFloat(M_PI/2) //90 degrees
      var endAngle:CGFloat = (2 * CGFloat(M_PI)) + startAngle
      processBackgroundPath.addArcWithCenter(center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
      self.backgroundTintColor.set()
      processBackgroundPath.stroke()
      
      // Draw progress
      let  processPath = UIBezierPath.init()
      processPath.lineCapStyle = .Square
      processPath.lineWidth = lineWidth
      endAngle = self.progress * 2 * CGFloat(M_PI) + startAngle
      processPath.addArcWithCenter(center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
      self.progressTintColor.set()
      processPath.stroke()
      
    } else {
      // Draw background
      let lineWidth:CGFloat = 2.0
      let allRect = self.bounds
      let circleRect = CGRectInset(allRect, lineWidth/2.0, lineWidth/2.0)
      let center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
      self.progressTintColor.setStroke()
      self.backgroundTintColor.setFill()
      CGContextSetLineWidth(context, lineWidth)
      CGContextStrokeEllipseInRect(context, circleRect)
      let startAngle = -CGFloat(M_PI) / 2.0
      let processPath = UIBezierPath()
      processPath.lineCapStyle = .Butt
      processPath.lineWidth = lineWidth * 2.0
      
      let radius = CGRectGetWidth(self.bounds)/2.0 - processPath.lineWidth / 2.0
      let endAngle = self.progress * 2.0 * CGFloat(M_PI) + startAngle
      processPath.addArcWithCenter(center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
      CGContextSetBlendMode(context, .Copy)
      self.progressTintColor.set()
      processPath.stroke()
    }
  }
  
}
