import UIKit

/// 标签栏控制代理协议
///
/// 用于在视图控制器层级中向上传递标签栏相关的控制指令，
/// 如锁定布局、更新角标、切换标签等。
@MainActor
protocol TabBarControlDelegate: AnyObject {
    
    /// 设置标签栏布局锁定状态
    ///
    /// 当锁定状态为 true 时，标签栏将暂停布局更新，通常用于转场动画或特定交互场景。
    /// - Parameter locked: 是否锁定布局
    func setTabBarLayoutLocked(_ locked: Bool)
    
    /// 导航栈变更通知
    ///
    /// 当子控制器的导航栈发生变化（如 push/pop）时调用，
    /// 用于通知容器控制器更新标签栏的显示状态（如隐藏/显示）。
    /// - Parameter navigationController: 发生变更的导航控制器
    func navigationStackDidChange(in navigationController: UINavigationController)
    
    /// 设置标签项的角标数值
    ///
    /// - Parameters:
    ///   - value: 角标数值。传入 nil 或 0 隐藏角标。
    ///   - index: 标签项的索引
    func setTabBarBadgeValue(_ value: Int?, at index: Int)
    
    /// 选中指定索引的标签
    ///
    /// - Parameter index: 目标标签的索引
    func selectTab(at index: Int)
}

extension UIResponder {
    
    /// 查找响应链中的标签栏控制代理
    ///
    /// 通过响应链递归查找最近的遵循 `TabBarControlDelegate` 协议的对象（通常是 `TabContainerController`）。
    /// 这允许任意深度的子视图控制器直接访问标签栏控制功能。
    var tabBarControlDelegate: TabBarControlDelegate? {
        if let delegate = self as? TabBarControlDelegate {
            return delegate
        }
        return next?.tabBarControlDelegate
    }
}
