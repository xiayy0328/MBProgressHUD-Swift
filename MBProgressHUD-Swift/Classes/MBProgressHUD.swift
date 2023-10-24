//
//  MBProgressHUD.swift
//  MBProgressHUD-Swift
//
//  Created by Xyy on 2021/4/29.
//

import UIKit
import CoreGraphics

/// 定义MBProgressHUDDelegate
public protocol MBProgressHUDDelegate {
    func hudWasHidden(_ hud: MBProgressHUD)
}

extension MBProgressHUDDelegate {
    func hudWasHidden(_ hud: MBProgressHUD) { }
}

/// MBProgressHUD
open class MBProgressHUD: UIView {
    
    /// 模式
    public enum Mode {
        case indeterminate
        case determinate
        case determinateHorizontalBar
        case annularDeterminate
        case customView
        case text
    }
    
    /// 动画方式
    public enum Animation {
        case fade
        case zoom
        case zoomOut
        case zoomIn
    }
    
    /// 进度
    public var progress: Float = 0.0 {
        didSet {
            if(oldValue != progress) {
                if let progressView = indicator as? MBProgressView {
                    progressView.progress = progress
                }
            }
        }
    }
    
    /// 进度对象
    public var progressObject: Progress? {
        didSet {
            if(oldValue !== progressObject) {
                setProgressDisplayLinkEnabled(true)
            }
        }
    }
    
    /// 自定义视图
    public var customView: UIView? {
        didSet {
            if(oldValue != customView && mode == .customView) {
                updateIndicators()
            }
        }
    }
    
    /// 模式
    public var mode: Mode = .indeterminate {
        didSet {
            if(mode != oldValue) {
                updateIndicators()
            }
        }
    }
    
    /// 容器颜色
    public var contentColor = UIColor(white: 0, alpha: 0.7) {
        didSet {
            if (oldValue != contentColor) {
                updateViews(forColor: contentColor)
            }
        }
    }
    
    /// 常量
    let defaultPadding: CGFloat = 4.0
    let defaultLabelFontSize: CGFloat = 16.0
    let defaultDetailsLabelFontSize: CGFloat = 12.0
    
    public static let maxOffset: CGFloat = 1000000.0
    public var bezelView: MBProgressHUDBackgroundView?
    public var backgroundView: MBProgressHUDBackgroundView?
    
    /// 内容子视图
    public var label: UILabel?
    public var detailsLabel: UILabel?
    public var button: UIButton?
    public var removeFromSuperViewOnHide: Bool = false
    
    public var animationType: Animation = .fade
    public var offset: CGPoint = CGPoint(x: 0, y: 0)
    public var margin: CGFloat = 20.0
    public var minSize: CGSize = CGSize.zero
    public var isSquare = false
    public var isDefaultMotionEffectsEnabled = true
    public var minShowTime: TimeInterval = 0.0
    public var completionBlock: (() -> Void)?
    public var delegate: MBProgressHUDDelegate?
    public var graceTime: TimeInterval = 0.0
    
    var activityIndicatorColor: UIColor?
    var isUseAnimation: Bool?
    var isFinished: Bool = true
    var indicator: UIView?
    var showStarted: Date?
    var paddingConstraints: [NSLayoutConstraint]?
    var bezelConstraints: [NSLayoutConstraint]?
    var topSpacer: UIView?
    var bottomSpacer: UIView?
    var graceTimer: Timer?
    var minShowTimer: Timer?
    var hideDelayTimer: Timer?
    
    var progressObjectDisplayLink: CADisplayLink? {
        willSet {
            if newValue !== progressObjectDisplayLink {
                progressObjectDisplayLink?.invalidate()
            }
        }
        didSet {
            if oldValue !== progressObjectDisplayLink {
                progressObjectDisplayLink?.add(to: .main, forMode: .default)
            }
        }
    }
    
    public class func show(addedToView view: UIView, animated: Bool) -> MBProgressHUD {
        let hud = MBProgressHUD(withView: view)
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(animated: animated)
        return hud;
    }
    
    @discardableResult
    public class func hide(addedToView view: UIView, animated: Bool) -> Bool {
        let hud = hudForView(view)
        if (hud != nil) {
            hud?.removeFromSuperViewOnHide = true
            hud?.hide(animated: animated)
            return true
        }
        return false
    }
    
    public class func hudForView(_ view: UIView) -> MBProgressHUD? {
        let subviews = view.subviews.reversed()
        for subview in subviews {
            if (subview is MBProgressHUD) {
                return subview as? MBProgressHUD
            }
        }
        return nil
    }
    
    // MARK: Lifecycle
    func commonInit() {
        self.isOpaque = false
        self.backgroundColor = UIColor.clear
        
        self.alpha = 0
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.layer.allowsGroupOpacity = false

        setupViews()
        updateIndicators()
        registerForNotifications()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    convenience init(withView view: UIView) {
        self.init(frame: view.bounds)
    }
    
    // MARK: Show & Hide
    public func show(animated: Bool) {
        assert(Thread.isMainThread, "Progresshud needs to be accessed on the main thread.")
        minShowTimer?.invalidate()
        isUseAnimation = animated
        isFinished = false
        if ( graceTime > 0.0) {
            let timer = Timer(timeInterval: graceTime, target: self, selector: #selector(handleGraceTimer(_:)), userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: .common)
            graceTimer = timer
        } else {
            showUsingAnimation(animated)
        }
    }
    
    public func hide(animated: Bool) {
        assert(Thread.isMainThread, "Progresshud needs to be accessed on the main thread.")
        graceTimer?.invalidate()
        isUseAnimation = animated
        isFinished = true
        if (minShowTime > 0.0 && showStarted != nil) {
            let interval = Date().timeIntervalSince(showStarted!)
            if(interval < minShowTime) {
                let timer = Timer(timeInterval: (minShowTime - interval), target: self, selector: #selector(handleMinShowTimer(_:)), userInfo: nil, repeats: false)
                RunLoop.current.add(timer, forMode: .common)
                minShowTimer = timer
            }
        } else {
            hideUsingAnimation(isUseAnimation!)
        }
    }
    
    public func hide(animated: Bool, afterDelay delay: TimeInterval) {
        let timer = Timer(timeInterval: delay, target: self, selector: #selector(handleHideTimer(_:)), userInfo: animated, repeats: false)
        RunLoop.current.add(timer, forMode: .common)
        hideDelayTimer = timer
    }
    
    // MARK: Timer callbacks
    @objc func handleGraceTimer(_ timer: Timer) {
        if(!isFinished) {
            showUsingAnimation(isUseAnimation!)
        }
    }
    
    @objc func handleMinShowTimer(_ timer: Timer) {
        hideUsingAnimation(isUseAnimation!)
    }
    
    @objc func handleHideTimer(_ timer: Timer) {
        hide(animated: timer.userInfo as! Bool)
    }
    
    // MARK: Internal show & hide operations
    func showUsingAnimation(_ animation: Bool) {
        bezelView?.layer.removeAllAnimations()
        backgroundView?.layer.removeAllAnimations()
        hideDelayTimer?.invalidate()
        showStarted = Date()
        alpha = 1.0
        setProgressDisplayLinkEnabled(true)
        if(animation) {
            animateIn(true, withType: animationType, completion: nil)
        } else {
            self.bezelView?.alpha = 1
            self.backgroundView?.alpha = 1
        }
    }
    
    func hideUsingAnimation(_ animated: Bool) {
        if (animated && showStarted != nil) {
            self.showStarted = nil
            animateIn(false, withType: animationType, completion: { finished in
                self.done()
            })
        } else {
            showStarted = nil
            bezelView?.alpha = 0
            backgroundView?.alpha = 1
            done()
        }
    }
    
    func animateIn(_ animatingIn: Bool, withType: Animation, completion: ((Bool) -> Void)?) {
        var type = withType
        if (type == .zoom) {
            type = animatingIn ? .zoomIn : .zoomOut
        }
        
        let small = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let large = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
        if (animatingIn && bezelView?.alpha == 0.0 && type == .zoomIn) {
            bezelView?.transform = small
        } else if (animatingIn && bezelView?.alpha == 0.0 && type == .zoomOut) {
            bezelView?.transform = large
        }
        
        let animations = { () -> Void in
            if (animatingIn) {
                self.bezelView?.transform = .identity
            } else if(!animatingIn && type == .zoomIn) {
                self.bezelView?.transform = large
            } else if(!animatingIn && type == .zoomOut) {
                self.bezelView?.transform = small
            }
            
            self.bezelView?.alpha = animatingIn ? 1.0 : 0.0
            self.backgroundView?.alpha = animatingIn ? 1.0: 0.0
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .beginFromCurrentState, animations: animations, completion: completion)
        
    }
    
    func done() {
        hideDelayTimer?.invalidate()
        setProgressDisplayLinkEnabled(false)
        
        if (isFinished) {
            alpha = 0
            if (removeFromSuperViewOnHide) {
                removeFromSuperview()
            }
        }
        
        if let completed = completionBlock {
            completed()
        }
        
        if delegate != nil {
            delegate?.hudWasHidden(self)
        }
    }
    
    // MARK: UI
    func setupViews() {
        let defaultColor = contentColor
        
        backgroundView = MBProgressHUDBackgroundView(frame: self.bounds)
        backgroundView?.style = .solidColor
        backgroundView?.backgroundColor = UIColor.clear
        backgroundView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView?.alpha = 0
        addSubview(backgroundView!)
        
        bezelView = MBProgressHUDBackgroundView()
        bezelView?.translatesAutoresizingMaskIntoConstraints = false
        bezelView?.layer.cornerRadius = 5
        bezelView?.alpha = 0
        addSubview(bezelView!)
        updateBezelMotionEffects()
        
        label = UILabel()
        label?.adjustsFontSizeToFitWidth = false
        label?.textAlignment = .center
        label?.textColor = defaultColor
        label?.font = UIFont.boldSystemFont(ofSize: defaultLabelFontSize)
        label?.isOpaque = false
        label?.numberOfLines = 0
        label?.backgroundColor = UIColor.clear
        
        detailsLabel = UILabel()
        detailsLabel?.adjustsFontSizeToFitWidth = false
        detailsLabel?.textAlignment = .center
        detailsLabel?.textColor = defaultColor
        detailsLabel?.font = UIFont.boldSystemFont(ofSize: defaultDetailsLabelFontSize)
        detailsLabel?.isOpaque = false
        detailsLabel?.numberOfLines = 0
        detailsLabel?.backgroundColor = UIColor.clear
        
        button = MBProgressHUDRoundedButton()
        button?.titleLabel?.textAlignment = .center
        button?.titleLabel?.font = UIFont.boldSystemFont(ofSize: defaultDetailsLabelFontSize)
        button?.setTitleColor(defaultColor, for: .normal)
        
        for view: UIView in [label!, detailsLabel!, button!] {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998.0), for: .horizontal)
            view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998.0), for: .vertical)
            bezelView?.addSubview(view)
        }
        
        topSpacer = UIView()
        topSpacer?.translatesAutoresizingMaskIntoConstraints = false
        topSpacer?.isHidden = true
        bezelView?.addSubview(topSpacer!)
        
        bottomSpacer = UIView()
        bottomSpacer?.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer?.isHidden = true
        bezelView?.addSubview(bottomSpacer!)
    }
    
    func updateIndicators() {
        switch mode {
        case .indeterminate:
            if indicator as? UIActivityIndicatorView == nil {
                // Update to indeterminate mode
                indicator?.removeFromSuperview()
                let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
                activityIndicator.startAnimating()
                indicator = activityIndicator
                bezelView?.addSubview(activityIndicator)
            }
        case .determinateHorizontalBar:
            indicator?.removeFromSuperview()
            indicator = MBBarProgressView()
            bezelView?.addSubview(indicator!)
        case .determinate:
            if !(indicator is MBRoundProgressView) {
                // Update to determinante indicator
                indicator?.removeFromSuperview()
                indicator = MBRoundProgressView()
                bezelView?.addSubview(indicator!)
            }
        case .annularDeterminate:
            if !(indicator is MBAnnularProgressView) {
                // Update to annular determinate indicator
                indicator?.removeFromSuperview()
                indicator = MBAnnularProgressView()
                bezelView?.addSubview(indicator!)
            }
        case .customView:
            if customView != nil && customView !== indicator {
                // Update custom view indicator
                indicator?.removeFromSuperview()
                indicator = customView
                bezelView?.addSubview(customView!)
            }
        case .text:
            indicator?.removeFromSuperview()
            indicator = nil
        }
        
        indicator?.translatesAutoresizingMaskIntoConstraints = false
        if let progressView = indicator as? MBProgressView {
            progressView.progress = progress
        }
        
        indicator?.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998), for: .horizontal)
        indicator?.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998), for: .vertical)
        
        updateViews(forColor: contentColor)
        setNeedsUpdateConstraints()
    }
    
    func updateViews(forColor color: UIColor) {
        label?.textColor = color
        detailsLabel?.textColor = color
        button?.setTitleColor(color, for: .normal)
        
        if let activityIndicator = indicator as? UIActivityIndicatorView {
            activityIndicator.color = color
        } else if let barProgressView = indicator as? MBBarProgressView {
            barProgressView.progressColor = color
            barProgressView.lineColor = color
        } else if let circleProgressView = indicator as? MBCircleProcessView {
            circleProgressView.progressTintColor = color
            circleProgressView.backgroundTintColor = color.withAlphaComponent(0.1)
        }
    }
    
    func updateBezelMotionEffects() {
        if (isDefaultMotionEffectsEnabled) {
            let effectOffset: CGFloat = 10.0
            let effectX = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            effectX.maximumRelativeValue = effectOffset
            effectX.minimumRelativeValue = -effectOffset
            
            let effectY = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongHorizontalAxis)
            effectY.maximumRelativeValue = effectOffset
            effectY.minimumRelativeValue = -effectOffset
            
            let group = UIMotionEffectGroup()
            group.motionEffects = [effectX, effectY]
            bezelView?.addMotionEffect(group)
        } else {
            if let effects = bezelView?.motionEffects {
                for effect in effects {
                    bezelView?.removeMotionEffect(effect)
                }
            }
        }
    }
    
    // MARK: Layout
    public override func updateConstraints() {
        let metrics = ["margin": margin]
        
        var subviews: [UIView] = [topSpacer!, label!, detailsLabel!, button!, bottomSpacer!]
        if (indicator != nil) {
            subviews.insert(indicator!, at: 1)
        }
        
        // Remove existing constraints
        removeConstraints(constraints)
        topSpacer?.removeConstraints(topSpacer!.constraints)
        bottomSpacer?.removeConstraints(bottomSpacer!.constraints)
        if (bezelConstraints != nil) {
            bezelView?.removeConstraints(bezelConstraints!)
            bezelConstraints = [NSLayoutConstraint]()
        } else {
            bezelConstraints = [NSLayoutConstraint]()
        }
        
        // Center bezel in container (self), apply the offset if set
        var centeringConstraints = [NSLayoutConstraint]()
        centeringConstraints.append(NSLayoutConstraint(item: bezelView!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: offset.x))
        centeringConstraints.append(NSLayoutConstraint(item: bezelView!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: offset.y))
        apply(priority: UILayoutPriority(rawValue: 998), toConstraints: centeringConstraints)
        addConstraints(centeringConstraints)
        
        // Ensure minimum side margin is kept
        var sideConstraints = [NSLayoutConstraint]()
        sideConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-(>=margin)-[bezel]-(>=margin)-|", options: .alignAllTop, metrics: metrics, views: ["bezel": bezelView!]))
        sideConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=margin)-[bezel]-(>=margin)-|", options: .alignAllTop, metrics: metrics, views: ["bezel": bezelView!]))
        self.apply(priority: UILayoutPriority(rawValue: 999), toConstraints: sideConstraints)
        self.addConstraints(sideConstraints)
        
        // Minimum bezel size, if set
        let minimumSize = minSize
        if (minimumSize != CGSize.zero) {
            var miniSizeConstraints = [NSLayoutConstraint]()
            miniSizeConstraints.append(NSLayoutConstraint(item: bezelView!, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: minimumSize.width))
            miniSizeConstraints.append(NSLayoutConstraint(item: bezelView!, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: minimumSize.height))
            self.apply(priority: UILayoutPriority(rawValue: 997), toConstraints: miniSizeConstraints)
            bezelConstraints?.append(contentsOf: miniSizeConstraints)
        }
        
        // Square aspect ratio, if set
        if(isSquare) {
            let square = NSLayoutConstraint(item: bezelView!, attribute: .height, relatedBy: .equal, toItem: bezelView!, attribute: .width, multiplier: 1, constant: 0)
            square.priority = UILayoutPriority(rawValue: 997)
            bezelConstraints?.append(square)
        }
        
        // Top and bottom spacing
        topSpacer?.addConstraint(NSLayoutConstraint(item: topSpacer!, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: margin))
        bottomSpacer?.addConstraint(NSLayoutConstraint(item: bottomSpacer!, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: margin))
        // Top and bottom spaces should be equal
        bezelConstraints?.append(NSLayoutConstraint(item: topSpacer!, attribute: .height, relatedBy: .equal, toItem: bottomSpacer!, attribute: .height, multiplier: 1, constant: 0))
        
        // Layout subviews in bezel
        paddingConstraints = [NSLayoutConstraint]()
        for (index, view) in subviews.enumerated() {
            // Center in bezel
            bezelConstraints?.append(NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: bezelView!, attribute: .centerX, multiplier: 1, constant: 0))
            // Ensure the minimum edge margin is kept
            bezelConstraints?.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-(>=margin)-[view]-(>=margin)-|", options: .alignAllTop, metrics: metrics, views: ["view": view]))
            // Element spacing
            if (index == 0) {
                // First, ensure spacing to bezel edge
                bezelConstraints?.append(NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: bezelView!, attribute: .top, multiplier: 1, constant: 0))
            } else if (index == subviews.count - 1) {
                // Last, ensure spacing to bezel edge
                bezelConstraints?.append(NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: bezelView!, attribute: .bottom, multiplier: 1, constant: 0))
            }
            
            if (index > 0) {
                // Has previous
                let padding = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: subviews[index - 1], attribute: .bottom, multiplier: 1, constant: 0)
                bezelConstraints?.append(padding)
                paddingConstraints?.append(padding)
            }
        }
        
        bezelView?.addConstraints(bezelConstraints!)
        updatePaddingConstraints()
        
        super.updateConstraints()
    }
    
    public override func layoutSubviews() {
        if (!needsUpdateConstraints()) {
            updatePaddingConstraints()
        }
        super.layoutSubviews()
    }
    
    func updatePaddingConstraints() {
        var hasVisibleAncestors = false
        for (_, padding) in paddingConstraints!.enumerated() {
            let firstView = padding.firstItem as! UIView
            let secondView = padding.secondItem as! UIView
            let firstVisible = !firstView.isHidden && firstView.intrinsicContentSize != CGSize.zero
            let secondVisible = !secondView.isHidden && secondView.intrinsicContentSize != CGSize.zero
            padding.constant = (firstVisible && (secondVisible || hasVisibleAncestors)) ? defaultPadding : 0
            hasVisibleAncestors = hasVisibleAncestors || secondVisible
        }
    }
    
    func apply(priority: UILayoutPriority, toConstraints constraints: [NSLayoutConstraint]) {
        for constraint in constraints {
            constraint.priority = priority
        }
    }
    
    // MARK: Progress
    func setProgressDisplayLinkEnabled(_ enabled: Bool) {
        if(enabled && (progressObject != nil)) {
            if(progressObjectDisplayLink == nil) {
                self.progressObjectDisplayLink = CADisplayLink(target: self, selector: #selector(updateProgressFromProgressObject))
            }
        } else {
            progressObjectDisplayLink = nil
        }
    }
    
    @objc func updateProgressFromProgressObject() {
        progress = Float((progressObject?.fractionCompleted)!)
    }
    
    // MARK: Notifications
    func registerForNotifications() {
        #if !os(tvOS)
            let nc = NotificationCenter.default
            nc.addObserver(self, selector: #selector(statusBarOrientationDidChange(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        #endif
    }
    
    func unregisterFormNotifications() {
        #if !os(tvOS)
            let nc = NotificationCenter.default
            nc.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        #endif
    }
    
#if !os(tvOS)
    @objc func statusBarOrientationDidChange(_ notification: NSNotification) {
        if (superview != nil) {
            updateForCurrentOrientation(animated: true)
        }
    }
#endif
    func updateForCurrentOrientation(animated: Bool) {
        // Stay in sync with the superview in any case
        if let superView = self.superview {
            frame = superView.bounds
        }
    }
}


public class MBProgressHUDBackgroundView: UIView {
    
    public enum BackgroundStyle {
        case solidColor, blur
    }
    
    public var style: BackgroundStyle? {
        didSet {
            updateForBackgroundStyle()
        }
    }
    
    public var color: UIColor? {
        didSet {
            assert(color != nil, "The color should not be nil.")
            updateViews(forColor: color!)
        }
    }
    
    var effectView: UIVisualEffectView?
    #if !os(tvOS)
    var toolbar: UIToolbar?
    #endif
    
    // MARK: Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        style = .blur
        color = UIColor(white: 0.8, alpha: 0.6)
        
        self.clipsToBounds = true
        updateForBackgroundStyle()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Layout
    public override var intrinsicContentSize: CGSize {
        return CGSize.zero
    }
    
    // MARK: Views
    func updateForBackgroundStyle() {
        if (style == .blur) {
            let effect = UIBlurEffect(style: .light)
            effectView = UIVisualEffectView(effect: effect)
            self.addSubview(effectView!)
            effectView?.frame = self.bounds
            effectView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            backgroundColor = color
            layer.allowsGroupOpacity = false
        } else {
            effectView?.removeFromSuperview()
            effectView = nil
            backgroundColor = color
        }
    }
    
    func updateViews(forColor color: UIColor) {
        backgroundColor = color
    }
}

class MBProgressHUDRoundedButton: UIButton {
    // MARK: Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderWidth = 1.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        // Rounded corners
        let height = self.bounds.height
        self.layer.cornerRadius = height / 2.0
    }
    
    override var intrinsicContentSize: CGSize {
        if(self.allControlEvents == UIControl.Event(rawValue: 0)) {
            return CGSize.zero
        }
        var size = super.intrinsicContentSize
        size.width += 20.0
        return size
    }
    
    // MARK: Color
    override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state)
        // Update related colors
        let highlighted = isHighlighted
        isHighlighted = highlighted
        self.layer.borderColor = color?.cgColor
    }
    
    override var isHighlighted: Bool {
        didSet {
            let baseColor = self.titleColor(for: .selected)
            backgroundColor = isHighlighted ? baseColor?.withAlphaComponent(0.1) : UIColor.clear
        }
    }
}


// MARK: ProgressView
class MBProgressView: UIView {
    var progress: Float = 0.0 {
        didSet {
            if(oldValue != progress) {
                setNeedsDisplay()
            }
        }
    }

}

class MBBarProgressView: MBProgressView {
    var lineColor = UIColor.white
    var progressRemainingColor = UIColor.clear {
        didSet {
            if(progressRemainingColor != oldValue) {
                setNeedsDisplay()
            }
        }
    }
    var progressColor = UIColor.white {
        didSet {
            if(progressColor != oldValue) {
                setNeedsDisplay()
            }
        }
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 120, height: 20))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Layout
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 120.0, height: 10.0)
    }
    
    // MARK: Drawing
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        context?.setLineWidth(2.0)
        context?.setStrokeColor(lineColor.cgColor)
        context?.setFillColor(progressRemainingColor.cgColor)
        
        // Draw background
        var radius = rect.size.height / 2 - 2.0
        context?.move(to: CGPoint(x: 2, y: rect.size.height / 2))
        context?.addArc(tangent1End: CGPoint(x: 2, y: 2), tangent2End: CGPoint(x: radius + 2.0, y: 2), radius: radius)
        context?.addLine(to: CGPoint(x: rect.size.width - radius - 2.0, y: 2))
        context?.addArc(tangent1End: CGPoint(x: rect.size.width - 2.0, y: 2), tangent2End: CGPoint(x: rect.size.width - 2, y: rect.size.height / 2), radius: radius)
        context?.addArc(tangent1End: CGPoint(x: rect.size.width - 2, y: rect.size.height - 2), tangent2End: CGPoint(x: rect.size.width - radius - 2, y: rect.size.height - 2), radius: radius)
        context?.addLine(to: CGPoint(x: radius + 2, y: rect.size.height - 2))
        context?.addArc(tangent1End: CGPoint(x: 2, y: rect.size.height - 2), tangent2End: CGPoint(x: 2, y: rect.size.height / 2), radius: radius)
        context?.fillPath()
        
        // Draw border
        context?.move(to: CGPoint(x: 2, y: rect.size.height / 2))
        context?.addArc(tangent1End: CGPoint(x: 2, y: 2), tangent2End: CGPoint(x: radius + 2.0, y: 2), radius: radius)
        context?.addLine(to: CGPoint(x: rect.size.width - radius - 2.0, y: 2))
        context?.addArc(tangent1End: CGPoint(x: rect.size.width - 2.0, y: 2), tangent2End: CGPoint(x: rect.size.width - 2, y: rect.size.height / 2), radius: radius)
        context?.addArc(tangent1End: CGPoint(x: rect.size.width - 2, y: rect.size.height - 2), tangent2End: CGPoint(x: rect.size.width - radius - 2, y: rect.size.height - 2), radius: radius)
        context?.addLine(to: CGPoint(x: radius + 2, y: rect.size.height - 2))
        context?.addArc(tangent1End: CGPoint(x: 2, y: rect.size.height - 2), tangent2End: CGPoint(x: 2, y: rect.size.height / 2), radius: radius)
        context?.strokePath()
        
        context?.setFillColor(progressColor.cgColor)
        radius = radius - 2.0
        let amount = CGFloat(progress) * rect.size.width
        // Progress in the middle area
        if (amount >= radius + 4.0 && amount <= (rect.size.width - radius - 4.0)) {
            context?.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context?.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: radius + 4, y: 4), radius: radius)
            context?.addLine(to: CGPoint(x: amount, y: 4.0))
            context?.addLine(to: CGPoint(x: amount, y: radius + 4))
            
            context?.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context?.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context?.addLine(to: CGPoint(x: amount, y: rect.size.height - 4))
            context?.addLine(to: CGPoint(x: amount, y: radius + 4))
            
            context?.fillPath()
        }
        // Progress in the right arc
        else if (amount > radius + 4) {
            let x = amount - (rect.size.width - radius - 4.0)
            
            context?.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context?.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: radius + 4, y: 4), radius: radius)
            context?.addLine(to: CGPoint(x: rect.size.width - radius - 4, y: 4))
            var angle = -acos(x / radius)
            if (angle.isNaN) {
                angle = 0.0
            }
            context?.addArc(center: CGPoint(x: rect.size.width - radius - 4, y: rect.size.height/2), radius: radius, startAngle: CGFloat.pi, endAngle: angle, clockwise: false)
            context?.addLine(to: CGPoint(x: amount, y: rect.size.height / 2))
            
            context?.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context?.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context?.addLine(to: CGPoint(x: rect.size.width - radius - 4, y: rect.size.height - 4))
            angle = acos(x / radius)
            if (angle.isNaN) {
                angle = 0.0
            }
            context?.addArc(center: CGPoint(x: rect.size.width - radius - 4, y: rect.size.height/2), radius: radius, startAngle: -CGFloat.pi, endAngle: angle, clockwise: true)
            context?.addLine(to: CGPoint(x: amount, y: rect.size.height / 2))
            
            context?.fillPath()
        }
        // Progress is in the left arc
        else if (amount < radius + 4 && amount > 0) {
            context?.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context?.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: radius + 4, y: 4), radius: radius)
            context?.addLine(to: CGPoint(x: radius + 4, y: rect.size.height / 2))
            
            context?.move(to: CGPoint(x: 4, y: rect.size.height / 2))
            context?.addArc(tangent1End: CGPoint(x: 4, y: rect.size.height - 4), tangent2End: CGPoint(x: radius + 4, y: rect.size.height - 4), radius: radius)
            context?.addLine(to: CGPoint(x: radius + 4, y: rect.size.height / 2))
            
            context?.fillPath()
        }
        
    }
}

class MBCircleProcessView: MBProgressView {         // base class of Round and Annular viw
    // Indicator progress color, default white
    var progressTintColor: UIColor = UIColor.red {
        didSet {
            if oldValue != progressTintColor {
                setNeedsDisplay()
            }
        }
    }
    
    // Indicator background (non - progress) color, default to translucent white (alpha 0.1)
    var backgroundTintColor = UIColor(white: 1.0, alpha: 0.1) {
        didSet {
            if oldValue != backgroundTintColor {
                setNeedsDisplay()
            }
        }
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 37, height: 37))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Layout
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 37, height: 37)
    }
}

class MBRoundProgressView: MBCircleProcessView {
    // MARK: Drawing
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        let lineWidth: CGFloat = 2
        let allRect = bounds
        let circleRect = allRect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        progressTintColor.setStroke()
        context?.setLineWidth(lineWidth)
        context?.strokeEllipse(in: circleRect)
 
        // 90 degrees
        let startAngle = -(CGFloat.pi / 2.0)
        // Draw Progress
        let processPath = UIBezierPath()
        processPath.lineCapStyle = .butt
        processPath.lineWidth = lineWidth * 2.0
        let radius = bounds.width / 2.0 - processPath.lineWidth / 2
        let endAngle = CGFloat(progress * 2 * Float.pi) + startAngle
        let pathCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        processPath.addArc(withCenter: pathCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        // Ensure that we don't get color overlaping when progressTintColor alpha < 1
        context?.setBlendMode(.copy)
        progressTintColor.set()
        processPath.stroke()
    }
}

class MBAnnularProgressView: MBCircleProcessView {
    // MARK: Drawing
    override func draw(_ rect: CGRect) {
        // Draw background
        let lineWidth: CGFloat = 2.0
        let processBackgroundPath = UIBezierPath()
        processBackgroundPath.lineWidth = lineWidth
        processBackgroundPath.lineCapStyle = .butt
        let pathCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (bounds.size.width - lineWidth) / 2.0
        let startAngle = -(CGFloat.pi / 2)
        var endAngle = 2 * CGFloat.pi + startAngle
        processBackgroundPath.addArc(withCenter: pathCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        backgroundTintColor.set()
        processBackgroundPath.stroke()
        // Draw progress
        let processPath = UIBezierPath()
        processPath.lineCapStyle = .square
        processPath.lineWidth = lineWidth
        endAngle = CGFloat(progress * 2 * Float.pi) + startAngle
        processPath.addArc(withCenter: pathCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        progressTintColor.set()
        processPath.stroke()
    }
}

