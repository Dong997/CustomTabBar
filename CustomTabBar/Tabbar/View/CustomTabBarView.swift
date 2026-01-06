import UIKit
import SnapKit

/// 自定义标签栏视图代理协议
protocol CustomTabBarViewDelegate: AnyObject {
    /// 选中某个标签项时触发
    /// - Parameters:
    ///   - view: 触发事件的 CustomTabBarView
    ///   - index: 被选中项的索引
    func customTabBarView(_ view: CustomTabBarView, didSelectIndex index: Int)
}

/// 自定义标签栏视图
///
/// 支持两种样式：
/// - frostedGlass: 毛玻璃效果，带有浮动的指示器，适用于现代风格的界面。
/// - plain: 朴素效果，无背景毛玻璃，无浮动指示器，适用于简约风格。
///
/// 支持中间突出的“大按钮”样式（通过配置 TabItemConfiguration.isProminent 实现）。
final class CustomTabBarView: UIView {
    
    /// 标签栏样式枚举
    enum Style {
        /// 毛玻璃样式：带圆角、阴影、模糊背景和浮动指示器
        case frostedGlass
        /// 朴素样式：无圆角、无阴影、普通背景，类似原生 UITabBar
        case plain
    }
    
    /// 代理对象，接收点击回调
    weak var delegate: CustomTabBarViewDelegate?
    
    /// 当前样式，修改后会自动应用
    var style: Style = .frostedGlass {
        didSet {
            applyStyle()
        }
    }
    
    /// plain模式下，Item距离顶部的间距，默认为8
    ///
    /// 仅在 style 为 .plain 时生效，用于调整图标和文字在垂直方向上的位置。
    var plainTopSpacing: CGFloat = 8 {
        didSet {
            if style == .plain {
                safeAreaInsetsDidChange()
            }
        }
    }
    
    /// 是否启用自定义图片着色
    ///
    /// - true: 选中状态下图片会被渲染为 selectedTintColor
    /// - false: 图片保持原色（适用于多彩图标）
    var isCustomImageTintEnabled: Bool = true {
        didSet {
            itemViews.forEach { $0.setCustomImageTintEnabled(isCustomImageTintEnabled) }
            prominentOverlayItemView?.setCustomImageTintEnabled(isCustomImageTintEnabled)
        }
    }
    
    /// 指示器（毛玻璃）的内边距，负值表示向外扩张。默认为 (-4, -4, -4, -4)
    var indicatorInsets: UIEdgeInsets = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4) {
        didSet {
            updateIndicator(animated: false)
        }
    }
    
    private struct Constants {
        static let frostedHeight: CGFloat = 64
        static let plainHeight: CGFloat = 44
        static let contentInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        static let plainContentInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        static let itemSpacing: CGFloat = 6
        static let borderWidth: CGFloat = 0.5
        static let cornerRadius: CGFloat = 24
        static let normalTintColor = UIColor.cN2
        static let selectedTintColor = UIColor.systemBlue
        static let normalTitleColor = UIColor.cN2
        static let selectedTitleColor = UIColor.systemBlue
    }
    
    // MARK: - UI Components
    
    private let backgroundEffectView = UIVisualEffectView()
    private let vibrancyEffectView = UIVisualEffectView()
    private let indicatorView = UIView()
    private let stackView = UIStackView()
    private let borderLayer = CAShapeLayer()
    
    // MARK: - State Properties
    
    private var itemViews: [CustomTabBarItemView] = []
    private weak var prominentPlaceholderItemView: CustomTabBarItemView?
    private var prominentOverlayItemView: CustomTabBarItemView?
    private var prominentItemIndex: Int?
    private var selectionAnimator: UIViewPropertyAnimator?
    private var selectedIndex: Int = 0
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Layout
    
    override var intrinsicContentSize: CGSize {
        switch style {
        case .frostedGlass:
            return CGSize(width: UIView.noIntrinsicMetric, height: Constants.frostedHeight)
        case .plain:
            // For plain style, the total height is 44 + device safe area bottom
            // We use window.safeAreaInsets to avoid being affected by additionalSafeAreaInsets set on the controller
            let bottomInset = window?.safeAreaInsets.bottom ?? safeAreaInsets.bottom
            let totalHeight = Constants.plainHeight + bottomInset
            return CGSize(width: UIView.noIntrinsicMetric, height: totalHeight)
        }
    }
    
    /// 推荐高度（仅用于毛玻璃模式参考）
    static var preferredHeight: CGFloat {
        Constants.frostedHeight
    }
    
    /// 当前实际高度
    var currentHeight: CGFloat {
        switch style {
        case .frostedGlass:
            return Constants.frostedHeight
        case .plain:
            let bottomInset = window?.safeAreaInsets.bottom ?? safeAreaInsets.bottom
            return Constants.plainHeight + bottomInset
        }
    }
    
    // MARK: - Public Methods
    
    /// 配置标签栏
    /// - Parameters:
    ///   - items: 标签项配置数组
    ///   - selectedIndex: 初始选中的索引
    func configure(items: [TabItemConfiguration], selectedIndex: Int) {
        self.selectedIndex = selectedIndex
        prominentOverlayItemView?.removeFromSuperview()
        prominentOverlayItemView = nil
        prominentPlaceholderItemView = nil
        prominentItemIndex = items.firstIndex(where: { $0.isProminent })
        itemViews.forEach { $0.removeFromSuperview() }
        itemViews.removeAll()
        
        for (index, item) in items.enumerated() {
            let itemView = CustomTabBarItemView()
            itemView.setCustomImageTintEnabled(isCustomImageTintEnabled)
            itemView.setProminentEnabled(false)
            itemView.configure(
                title: item.title,
                normalImage: item.normalImage,
                selectedImage: item.selectedImage,
                badgeValue: item.badgeValue,
                isSelected: index == selectedIndex
            )
            itemView.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            itemView.tag = index
            itemView.accessibilityIdentifier = "customTabBarItem.\(index)"
            
            if prominentItemIndex == index {
                itemView.alpha = 0.0
                itemView.isUserInteractionEnabled = false
                prominentPlaceholderItemView = itemView
            }
            
            itemViews.append(itemView)
            stackView.addArrangedSubview(itemView)
        }
        
        if let prominentItemIndex, items.indices.contains(prominentItemIndex) {
            let prominentItem = items[prominentItemIndex]
            let overlayItemView = CustomTabBarItemView()
            overlayItemView.setCustomImageTintEnabled(isCustomImageTintEnabled)
            overlayItemView.setProminentEnabled(true)
            overlayItemView.configure(
                title: prominentItem.title,
                normalImage: prominentItem.normalImage,
                selectedImage: prominentItem.selectedImage,
                badgeValue: prominentItem.badgeValue,
                isSelected: prominentItemIndex == selectedIndex
            )
            overlayItemView.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            overlayItemView.tag = prominentItemIndex
            overlayItemView.accessibilityIdentifier = "customTabBarItem.prominent.\(prominentItemIndex)"
            addSubview(overlayItemView)
            bringSubviewToFront(overlayItemView)
            prominentOverlayItemView = overlayItemView
        }
        
        setNeedsLayout()
        layoutIfNeeded()
        updateIndicator(animated: false)
    }
    
    /// 设置选中项
    /// - Parameters:
    ///   - index: 目标索引
    ///   - animated: 是否执行动画
    func setSelectedIndex(_ index: Int, animated: Bool) {
        guard itemViews.indices.contains(index) else {
            return
        }
        selectedIndex = index
        for (itemIndex, itemView) in itemViews.enumerated() {
            itemView.setSelected(itemIndex == index, animated: animated)
        }
        if let prominentItemIndex, let prominentOverlayItemView, prominentItemIndex == prominentOverlayItemView.tag {
            prominentOverlayItemView.setSelected(prominentItemIndex == index, animated: animated)
        }
        updateIndicator(animated: animated)
    }
    
    /// 更新指定项的图片
    /// - Parameters:
    ///   - normalImage: 普通状态图片
    ///   - selectedImage: 选中状态图片
    ///   - index: 目标索引
    func updateImages(normalImage: UIImage?, selectedImage: UIImage?, at index: Int) {
        guard itemViews.indices.contains(index) else {
            return
        }
        itemViews[index].updateImages(normalImage: normalImage, selectedImage: selectedImage)
        if prominentItemIndex == index {
            prominentOverlayItemView?.updateImages(normalImage: normalImage, selectedImage: selectedImage)
        }
    }
    
    /// 更新指定项的角标
    /// - Parameters:
    ///   - value: 角标数值（nil 或 0 隐藏）
    ///   - index: 目标索引
    func updateBadgeValue(_ value: Int?, at index: Int) {
        guard itemViews.indices.contains(index) else {
            return
        }
        itemViews[index].updateBadgeValue(value)
        if prominentItemIndex == index {
            prominentOverlayItemView?.updateBadgeValue(value)
        }
    }
    
    // MARK: - Private Methods
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let borderPath: UIBezierPath
        switch style {
        case .frostedGlass:
            layer.cornerRadius = Constants.cornerRadius
            backgroundEffectView.layer.cornerRadius = Constants.cornerRadius
            backgroundEffectView.clipsToBounds = true
            borderPath = UIBezierPath(roundedRect: bounds, cornerRadius: Constants.cornerRadius)
            layer.shadowPath = borderPath.cgPath
        case .plain:
            layer.cornerRadius = 0
            backgroundEffectView.layer.cornerRadius = 0
            backgroundEffectView.clipsToBounds = true
            borderPath = UIBezierPath()
            borderPath.move(to: CGPoint(x: 0, y: 0))
            borderPath.addLine(to: CGPoint(x: bounds.width, y: 0))
            layer.shadowPath = nil
        }
        borderLayer.path = borderPath.cgPath
        updateIndicator(animated: false)
        layoutProminentItemIfNeeded()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateMaterials()
    }
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        invalidateIntrinsicContentSize()
        
        // Update stack view constraints based on style and safe area
        stackView.snp.remakeConstraints { make in
            switch style {
            case .frostedGlass:
                make.edges.equalToSuperview().inset(Constants.contentInsets)
            case .plain:
                // For plain style, we need to respect the safe area bottom inset
                // The top inset is kept consistent with contentInsets.top
                let safeBottom = window?.safeAreaInsets.bottom ?? safeAreaInsets.bottom
                let bottomInset = safeBottom > 0 ? safeBottom : Constants.plainContentInsets.bottom
                // If we have safe area, we don't need top padding to be as large, keep it minimal to center content in 44pt area
                make.top.equalToSuperview().inset(plainTopSpacing)
                make.left.right.equalToSuperview().inset(Constants.plainContentInsets.left)
                make.bottom.equalToSuperview().inset(bottomInset)
            }
        }
    }
    
    private func setupView() {
        isAccessibilityElement = false
        layer.masksToBounds = false
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: 14)
        
        addSubview(backgroundEffectView)
        backgroundEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        backgroundEffectView.contentView.addSubview(indicatorView)
        indicatorView.backgroundColor = Constants.selectedTintColor.withAlphaComponent(0.08)
        indicatorView.layer.cornerRadius = Constants.cornerRadius - 8
        indicatorView.isUserInteractionEnabled = false
        
        backgroundEffectView.contentView.addSubview(vibrancyEffectView)
        vibrancyEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = Constants.itemSpacing
        
        vibrancyEffectView.contentView.addSubview(stackView)
        // Initial constraints setup - will be updated in safeAreaInsetsDidChange or applyStyle
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Constants.contentInsets)
        }
        
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.cN4.cgColor
        borderLayer.lineWidth = Constants.borderWidth
        borderLayer.lineCap = .square
        layer.addSublayer(borderLayer)
        
        applyStyle()
    }
    
    private func applyStyle() {
        // Trigger constraint update when style changes
        if window != nil {
            safeAreaInsetsDidChange()
        }
        
        switch style {
        case .frostedGlass:
            indicatorView.isHidden = false
            layer.shadowOpacity = 0.12
        case .plain:
            indicatorView.isHidden = true
            layer.shadowOpacity = 0
        }
        updateMaterials()
        setNeedsLayout()
    }
    
    private func updateMaterials() {
        switch style {
        case .frostedGlass:
            if UIAccessibility.isReduceTransparencyEnabled {
                backgroundEffectView.effect = nil
                backgroundEffectView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.96)
                vibrancyEffectView.effect = nil
            } else {
                let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
                backgroundEffectView.effect = blurEffect
                backgroundEffectView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.12)
                vibrancyEffectView.effect = nil
            }
        case .plain:
            backgroundEffectView.effect = nil
            backgroundEffectView.backgroundColor = UIColor.systemBackground
            vibrancyEffectView.effect = nil
        }
    }
    
    private func updateIndicator(animated: Bool) {
        guard indicatorView.isHidden == false else {
            return
        }
        guard itemViews.indices.contains(selectedIndex) else {
            indicatorView.frame = .zero
            return
        }
        
        let itemView = itemViews[selectedIndex]
        let targetFrame = backgroundEffectView.convert(itemView.frame, from: stackView)
            .inset(by: indicatorInsets)
        
        selectionAnimator?.stopAnimation(true)
        selectionAnimator = nil
        
        let previousCenterX = indicatorView.center.x
        let targetCenterX = targetFrame.midX
        let deltaX = targetCenterX - previousCenterX
        let stretchScaleX = min(1.18, 1.0 + abs(deltaX) / 320.0)
        
        let updates = { [weak self] in
            guard let self else { return }
            self.indicatorView.bounds = CGRect(origin: .zero, size: targetFrame.size)
            self.indicatorView.center = CGPoint(x: targetFrame.midX, y: targetFrame.midY)
        }
        
        if animated {
            indicatorView.transform = CGAffineTransform(scaleX: stretchScaleX, y: 1.0)
            let animator = UIViewPropertyAnimator(duration: 0.42, dampingRatio: 0.82, animations: updates)
            selectionAnimator = animator
            animator.addCompletion { [weak self] _ in
                guard let self else { return }
                UIView.animate(withDuration: 0.18, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
                    self.indicatorView.transform = .identity
                })
            }
            animator.startAnimation()
        } else {
            indicatorView.transform = .identity
            updates()
        }
    }
    
    @objc private func handleTap(_ sender: UIControl) {
        delegate?.customTabBarView(self, didSelectIndex: sender.tag)
    }

    private func layoutProminentItemIfNeeded() {
        guard let prominentPlaceholderItemView, let prominentOverlayItemView else {
            return
        }
        let placeholderFrame = stackView.convert(prominentPlaceholderItemView.frame, to: self)
        prominentOverlayItemView.setBaseTransform(.identity)
        
        let overlayHeight = max(placeholderFrame.height, prominentOverlayItemView.prominentRequiredHitHeight)
        prominentOverlayItemView.bounds = CGRect(x: 0, y: 0, width: placeholderFrame.width, height: overlayHeight)
        prominentOverlayItemView.center = CGPoint(x: placeholderFrame.midX, y: placeholderFrame.midY)
        prominentOverlayItemView.layoutIfNeeded()
        
        let prominentCenterInTabBar = prominentOverlayItemView.convert(prominentOverlayItemView.prominentBackgroundCenterPoint, to: self)
        let translationY = -prominentCenterInTabBar.y
        prominentOverlayItemView.setBaseTransform(CGAffineTransform(translationX: 0, y: translationY))
    }
}

/// 自定义标签项视图
///
/// 内部组件，负责单个标签的图标、标题、角标和选中状态显示。
/// 支持普通模式和突出（Prominent）模式。
final class CustomTabBarItemView: UIControl {
    private struct Constants {
        static let imageSize = CGSize(width: 24, height: 24)
        static let titleFontSize: CGFloat = 11
        static let badgeMinSize = CGSize(width: 18, height: 18)
        static let badgeInsets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        static let normalTintColor = UIColor.cN2
        static let selectedTintColor = UIColor.systemBlue
        static let normalTitleColor = UIColor.cN2
        static let selectedTitleColor = UIColor.systemBlue
        static let prominentBackgroundSize = CGSize(width: 64, height: 64)
        static let prominentBorderWidth: CGFloat = 5
    }
    
    // MARK: - UI Components
    
    private let prominentBackgroundView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let badgeLabel = UILabel()
    
    // MARK: - State Properties
    
    private var isCustomImageTintEnabled: Bool = true
    private var normalImage: UIImage?
    private var selectedImage: UIImage?
    private var badgeValue: Int?
    private var baseTransform: CGAffineTransform = .identity
    private var isProminentEnabled: Bool = false
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Public Configuration
    
    /// 配置标签项内容
    /// - Parameters:
    ///   - title: 标题
    ///   - normalImage: 普通状态图片
    ///   - selectedImage: 选中状态图片
    ///   - badgeValue: 角标数值
    ///   - isSelected: 初始是否选中
    func configure(
        title: String,
        normalImage: UIImage?,
        selectedImage: UIImage?,
        badgeValue: Int?,
        isSelected: Bool
    ) {
        self.normalImage = normalImage
        self.selectedImage = selectedImage
        self.badgeValue = badgeValue
        
        titleLabel.text = title
        accessibilityLabel = title
        updateBadgeValue(badgeValue)
        setSelected(isSelected, animated: false)
    }
    
    /// 设置选中状态
    /// - Parameters:
    ///   - selected: 是否选中
    ///   - animated: 是否执行缩放动画
    func setSelected(_ selected: Bool, animated: Bool) {
        isSelected = selected
        accessibilityTraits = selected ? [.button, .selected] : [.button]
        
        let updates = { [weak self] in
            guard let self else { return }
            self.titleLabel.textColor = selected ? Constants.selectedTitleColor : Constants.normalTitleColor
            let selectionTransform = selected ? CGAffineTransform(scaleX: 1.04, y: 1.04) : .identity
            self.transform = self.baseTransform.concatenating(selectionTransform)
            
            if selected {
                self.updateImageViewImage(image: self.selectedImage ?? self.normalImage, isSelected: true)
            } else {
                self.updateImageViewImage(image: self.normalImage ?? self.selectedImage, isSelected: false)
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: updates)
        } else {
            updates()
        }
    }
    
    /// 更新图片资源
    func updateImages(normalImage: UIImage?, selectedImage: UIImage?) {
        self.normalImage = normalImage
        self.selectedImage = selectedImage
        setSelected(isSelected, animated: false)
    }
    
    /// 设置是否启用自定义图片着色
    func setCustomImageTintEnabled(_ enabled: Bool) {
        isCustomImageTintEnabled = enabled
        setSelected(isSelected, animated: false)
    }
    
    /// 更新角标显示
    func updateBadgeValue(_ value: Int?) {
        badgeValue = value
        if let value, value > 0 {
            badgeLabel.isHidden = false
            badgeLabel.text = value > 99 ? "99+" : "\(value)"
        } else {
            badgeLabel.isHidden = true
            badgeLabel.text = nil
        }
        setNeedsLayout()
    }
    
    /// 设置基础变换（用于突出样式的位移）
    func setBaseTransform(_ transform: CGAffineTransform) {
        baseTransform = transform
        let selectionTransform = isSelected ? CGAffineTransform(scaleX: 1.04, y: 1.04) : .identity
        self.transform = baseTransform.concatenating(selectionTransform)
    }
    
    /// 设置是否启用突出模式
    ///
    /// 突出模式下会显示圆形背景，并调整图标位置。
    func setProminentEnabled(_ enabled: Bool) {
        isProminentEnabled = enabled
        prominentBackgroundView.isHidden = enabled == false
        titleLabel.isHidden = enabled
        
        if enabled {
            prominentBackgroundView.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.centerX.equalToSuperview()
                make.size.equalTo(Constants.prominentBackgroundSize)
            }
            
            imageView.snp.remakeConstraints { make in
                make.center.equalTo(prominentBackgroundView)
                make.size.equalTo(Constants.imageSize)
            }
            
            badgeLabel.snp.remakeConstraints { make in
                make.centerY.equalTo(prominentBackgroundView.snp.top).offset(6)
                make.left.equalTo(prominentBackgroundView.snp.right).offset(-14)
                make.height.greaterThanOrEqualTo(Constants.badgeMinSize.height)
                make.width.greaterThanOrEqualTo(Constants.badgeMinSize.width)
            }
        } else {
            prominentBackgroundView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalTo(imageView.snp.centerY)
                make.size.equalTo(Constants.prominentBackgroundSize)
            }
            
            imageView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(2)
                make.centerX.equalToSuperview()
                make.size.equalTo(Constants.imageSize)
            }
            
            badgeLabel.snp.remakeConstraints { make in
                make.centerY.equalTo(imageView.snp.top).offset(2)
                make.left.equalTo(imageView.snp.right).offset(-8)
                make.height.greaterThanOrEqualTo(Constants.badgeMinSize.height)
                make.width.greaterThanOrEqualTo(Constants.badgeMinSize.width)
            }
        }
        
        setSelected(isSelected, animated: false)
    }
    
    var prominentRequiredHitHeight: CGFloat {
        Constants.prominentBackgroundSize.height + 24
    }
    
    var prominentBackgroundCenterPoint: CGPoint {
        prominentBackgroundView.center
    }
    
    private func setupView() {
        isAccessibilityElement = true
        
        prominentBackgroundView.backgroundColor = .systemTeal
        prominentBackgroundView.layer.cornerRadius = Constants.prominentBackgroundSize.height / 2
        prominentBackgroundView.layer.borderColor = UIColor.white.cgColor
        prominentBackgroundView.layer.borderWidth = Constants.prominentBorderWidth
        prominentBackgroundView.layer.shadowColor = UIColor.black.cgColor
        prominentBackgroundView.layer.shadowOpacity = 0.14
        prominentBackgroundView.layer.shadowRadius = 14
        prominentBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 8)
        prominentBackgroundView.isHidden = true
        
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Constants.normalTintColor
        
        titleLabel.font = UIFont.systemFont(ofSize: Constants.titleFontSize, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.textColor = Constants.normalTitleColor
        
        badgeLabel.backgroundColor = .systemRed
        badgeLabel.textColor = .white
        badgeLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = Constants.badgeMinSize.height / 2
        badgeLabel.clipsToBounds = true
        badgeLabel.isHidden = true
        
        addSubview(prominentBackgroundView)
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(badgeLabel)
        
        prominentBackgroundView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(imageView.snp.centerY)
            make.size.equalTo(Constants.prominentBackgroundSize)
        }
        
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.centerX.equalToSuperview()
            make.size.equalTo(Constants.imageSize)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(3)
            make.left.right.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview().offset(-2)
        }
        
        badgeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(imageView.snp.top).offset(2)
            make.left.equalTo(imageView.snp.right).offset(-8)
            make.height.greaterThanOrEqualTo(Constants.badgeMinSize.height)
            make.width.greaterThanOrEqualTo(Constants.badgeMinSize.width)
        }
    }
    
    private func updateImageViewImage(image: UIImage?, isSelected: Bool) {
        guard let image else {
            imageView.image = nil
            return
        }
        
        if isProminentEnabled {
            imageView.tintColor = .white
            imageView.image = image.withRenderingMode(.alwaysTemplate)
            return
        }
        
        if isCustomImageTintEnabled {
            imageView.tintColor = isSelected ? Constants.selectedTintColor : Constants.normalTintColor
            imageView.image = image.withRenderingMode(.alwaysTemplate)
        } else {
            imageView.tintColor = nil
            imageView.image = image.withRenderingMode(.alwaysOriginal)
        }
    }
}
