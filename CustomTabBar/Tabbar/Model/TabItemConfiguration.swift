import UIKit

/// 标签栏项配置协议，定义标签栏项的基本属性
protocol TabItemConfiguration {
    /// 标签栏项标题
    var title: String { get }
    /// 标签栏项未选中状态图标
    var normalImage: UIImage? { get }
    /// 标签栏项选中状态图标
    var selectedImage: UIImage? { get }
    /// 标签栏项的 Lottie 动画资源路径（如果支持动画）
    var lottieAnimationResourcePath: String? { get }
    /// 标签栏项是否突出显示（通常用于中间的大按钮）
    var isProminent: Bool { get }
    /// 标签栏项是否需要认证才能访问（例如需要登录）
    var requiresAuthentication: Bool { get }
    /// 标签栏项的分析统计标识符
    var analyticsIdentifier: String { get }
    /// 标签栏项的初始徽章值（nil 表示无徽章）
    var badgeValue: Int? { get }
}

// MARK: - TabItemConfigurationModel

/// 标签栏项配置模型，实现 TabItemConfiguration 协议
struct TabItemConfigurationModel: TabItemConfiguration {
    // MARK: - Properties
    
    /// 标签栏项标题
    let title: String
    /// 标签栏项未选中状态图标
    let normalImage: UIImage?
    /// 标签栏项选中状态图标
    let selectedImage: UIImage?
    /// 标签栏项的 Lottie 动画资源路径
    let lottieAnimationResourcePath: String?
    /// 标签栏项是否突出显示
    let isProminent: Bool
    /// 标签栏项是否需要认证才能访问
    let requiresAuthentication: Bool
    /// 标签栏项的分析统计标识符
    let analyticsIdentifier: String
    /// 标签栏项的初始徽章值
    let badgeValue: Int?
    
    // MARK: - Initialization
    
    /// 初始化标签栏项配置模型
    /// - Parameters:
    ///   - title: 标签栏项标题
    ///   - normalImage: 标签栏项未选中状态图标，默认为 nil
    ///   - selectedImage: 标签栏项选中状态图标，默认为 nil
    ///   - lottieAnimationResourcePath: 标签栏项的 Lottie 动画资源路径，默认为 nil
    ///   - isProminent: 标签栏项是否突出显示，默认为 false
    ///   - requiresAuthentication: 标签栏项是否需要认证才能访问，默认为 false
    ///   - analyticsIdentifier: 标签栏项的分析标识符，默认为标题
    ///   - badgeValue: 标签栏项的徽章值，默认为 nil
    init(
        title: String,
        normalImage: UIImage? = nil,
        selectedImage: UIImage? = nil,
        lottieAnimationResourcePath: String? = nil,
        isProminent: Bool = false,
        requiresAuthentication: Bool = false,
        analyticsIdentifier: String? = nil,
        badgeValue: Int? = nil
    ) {
        self.title = title
        self.normalImage = normalImage
        self.selectedImage = selectedImage
        self.lottieAnimationResourcePath = lottieAnimationResourcePath
        self.isProminent = isProminent
        self.requiresAuthentication = requiresAuthentication
        self.analyticsIdentifier = analyticsIdentifier ?? title
        self.badgeValue = badgeValue
    }
}
