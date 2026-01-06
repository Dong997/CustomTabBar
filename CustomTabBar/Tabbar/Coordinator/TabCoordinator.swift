import Foundation

/// 标签栏协调器，负责管理标签栏的选择逻辑和路由
final class TabCoordinator {
    /// 标签栏选择决策结果
    enum SelectionDecision {
        /// 允许选择，Tab 将会切换到目标索引
        case allow
        /// 拒绝选择，Tab 保持在当前索引不变
        case deny
    }
    
    /// 标签栏选择触发方式
    enum SelectionTrigger {
        /// 用户手动点击 TabBar Item 触发
        case user
        /// 通过代码调用 `selectTab` 触发
        case programmatic
        /// 应用状态恢复时触发
        case restoration
    }
    
    /// 标签栏选择请求，包含选择的上下文信息
    struct SelectionRequest {
        /// 从哪个标签索引开始切换
        let fromIndex: Int
        /// 目标标签索引
        let toIndex: Int
        /// 选择的触发方式
        let trigger: SelectionTrigger
        /// 目标标签对应的路由对象
        let route: TabRoute
    }
    
    // MARK: - Properties
    
    /// 标签栏路由列表，定义了所有的 Tab 项
    private let routes: [TabRoute]
    
    /// 选择策略闭包，用于决定是否允许从当前 Tab 切换到目标 Tab
    /// 例如：可以在此处进行登录检查，如果未登录则返回 .deny 并弹出登录页
    private let selectionPolicy: (SelectionRequest) -> SelectionDecision
    
    /// 选择提交回调，当 selectionPolicy 返回 .allow 且 Tab 切换完成后调用
    private let selectionDidCommit: (SelectionRequest) -> Void
    
    /// 选择拒绝回调，当 selectionPolicy 返回 .deny 时调用
    private let selectionDidDeny: (SelectionRequest) -> Void
    
    /// 当前选中的标签索引（只读）
    private(set) var selectedIndex: Int
    
    // MARK: - Initialization
    
    /// 初始化标签栏协调器
    /// - Parameters:
    ///   - routes: 标签栏路由列表
    ///   - initialSelectedIndex: 初始选中的标签索引
    ///   - selectionPolicy: 选择策略，决定是否允许标签切换
    ///   - selectionDidCommit: 选择提交回调，当标签切换成功时调用
    ///   - selectionDidDeny: 选择拒绝回调，当标签切换被拒绝时调用
    init(
        routes: [TabRoute],
        initialSelectedIndex: Int,
        selectionPolicy: @escaping (SelectionRequest) -> SelectionDecision,
        selectionDidCommit: @escaping (SelectionRequest) -> Void,
        selectionDidDeny: @escaping (SelectionRequest) -> Void
    ) {
        self.routes = routes
        self.selectedIndex = initialSelectedIndex
        self.selectionPolicy = selectionPolicy
        self.selectionDidCommit = selectionDidCommit
        self.selectionDidDeny = selectionDidDeny
    }
    
    // MARK: - Public Methods
    
    /// 获取指定索引的路由
    /// - Parameter index: 标签索引
    /// - Returns: 路由对象，如果索引无效则返回 nil
    func route(at index: Int) -> TabRoute? {
        guard routes.indices.contains(index) else {
            return nil
        }
        return routes[index]
    }
    
    /// 请求选择指定标签
    /// - Parameters:
    ///   - index: 要选择的标签索引
    ///   - trigger: 选择的触发方式
    /// - Returns: 是否成功选择标签
    func requestSelection(to index: Int, trigger: SelectionTrigger) -> Bool {
        guard let route = route(at: index) else {
            return false
        }
        
        let request = SelectionRequest(
            fromIndex: selectedIndex,
            toIndex: index,
            trigger: trigger,
            route: route
        )
        
        switch selectionPolicy(request) {
        case .deny:
            selectionDidDeny(request)
            return false
        case .allow:
            selectedIndex = index
            selectionDidCommit(request)
            return true
        }
    }
}
