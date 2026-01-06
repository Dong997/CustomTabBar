import UIKit
import SnapKit

class TabContainerController: UIViewController, TabBarControlDelegate {
    private struct Constants {
        static let tabBarHorizontalInset: CGFloat = 16
    }
    
    /// TabBar 的视觉风格枚举
    enum TabBarStyle {
        /// 毛玻璃悬浮风格
        case frostedGlass
        /// 朴素（扁平）风格
        case plain
    }
    
    /// Tab 配置路由集合
    private let routes: [TabRoute]
    /// 状态恢复的 Key
    private let restorationKey: String
    /// 是否需要恢复选中状态
    private let shouldRestoreSelection: Bool
    /// 触觉反馈生成器
    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        
    /// 内容页控制器（使用 UIPageViewController 实现）
    private lazy var pageViewController: UIPageViewController = {
        let viewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        // 禁止左右滚动
        // viewController.dataSource = self
        viewController.delegate = self
        return viewController
    }()
    
    /// 自定义 TabBar 视图
    private lazy var tabBarView: CustomTabBarView = {
        let view = CustomTabBarView()
        view.delegate = self
        return view
    }()

    private var tabBarBottomConstraint: Constraint?
    private var coordinator: TabCoordinator?
    private var selectedRouteViewController: UIViewController?
    private var currentSnapshotView: UIView?
    private var isSettingPageViewController: Bool = false
    
    /// TabBar 布局锁定状态（用于防止转场期间的布局错乱）
    private var isTabBarLayoutLocked: Bool = false
    private var tabBarLayoutLockCount: Int = 0
    /// TabBar 被导航栏遮挡的状态
    private var isTabBarCoveredByNavigation: Bool = false
    private var pendingInitialSelection: (index: Int, trigger: TabCoordinator.SelectionTrigger)?
    private var didApplyInitialSelection: Bool = false
    
    /// 当前 TabBar 的视觉风格
    public var tabBarStyle: TabBarStyle {
        didSet {
            applyTabBarStyle()
        }
    }
    
    /// TabBar 底部间距偏移量
    public var tabBarBottomOffset: CGFloat {
        didSet {
            if isViewLoaded {
                updateTabBarInsetsIfNeeded()
            }
        }
    }
    
    /// 初始化 Tab 容器控制器
    /// - Parameters:
    ///   - routes: Tab 路由集合
    ///   - initialSelectedIndex: 初始选中的索引
    ///   - restorationKey: 状态恢复 Key
    ///   - shouldRestoreSelection: 是否恢复选中状态
    ///   - tabBarStyle: TabBar 风格
    ///   - tabBarBottomOffset: 底部间距
    ///   - selectionPolicy: 选中策略闭包
    ///   - selectionDidCommit: 选中确认闭包
    init(
        routes: [TabRoute],
        initialSelectedIndex: Int = 0,
        restorationKey: String = "tabContainer.selectedIndex",
        shouldRestoreSelection: Bool = false,
        tabBarStyle: TabBarStyle = .frostedGlass,
        tabBarBottomOffset: CGFloat? = nil,
        selectionPolicy: @escaping (TabCoordinator.SelectionRequest) -> TabCoordinator.SelectionDecision,
        selectionDidCommit: @escaping (TabCoordinator.SelectionRequest) -> Void
    ) {
        self.routes = routes
        self.restorationKey = restorationKey
        self.shouldRestoreSelection = shouldRestoreSelection
        self.tabBarStyle = tabBarStyle
        switch tabBarStyle {
        case .frostedGlass:
            self.tabBarBottomOffset = tabBarBottomOffset ?? 20
        case .plain:
            self.tabBarBottomOffset = tabBarBottomOffset ?? 0
        }
        super.init(nibName: nil, bundle: nil)
        
        coordinator = TabCoordinator(
            routes: routes,
            initialSelectedIndex: initialSelectedIndex,
            selectionPolicy: selectionPolicy,
            selectionDidCommit: { [weak self] request in
                self?.commitSelection(
                    fromIndex: request.fromIndex,
                    toIndex: request.toIndex,
                    route: request.route,
                    trigger: request.trigger
                )
                selectionDidCommit(request)
            },
            selectionDidDeny: { [weak self] request in
                self?.handleSelectionDenied(request)
            }
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var currentSelectedIndex: Int {
        coordinator?.selectedIndex ?? 0
    }
    
    var selectedViewController: UIViewController? {
        selectedRouteViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        setupTabBar()
        updateTabBarInsetsIfNeeded()
        
        if shouldRestoreSelection {
            let restoredIndex = UserDefaults.standard.object(forKey: restorationKey) as? Int
            if let restoredIndex, routes.indices.contains(restoredIndex) {
                pendingInitialSelection = (restoredIndex, .restoration)
            } else {
                pendingInitialSelection = (currentSelectedIndex, .programmatic)
            }
        } else {
            pendingInitialSelection = (currentSelectedIndex, .programmatic)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyInitialSelectionIfNeeded()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateTabBarInsetsIfNeeded()
    }
    
    /// 设置 TabBar 布局是否锁定
    /// - Parameter locked: 是否锁定
    func setTabBarLayoutLocked(_ locked: Bool) {
        if locked {
            tabBarLayoutLockCount += 1
        } else {
            tabBarLayoutLockCount = max(tabBarLayoutLockCount - 1, 0)
        }
        isTabBarLayoutLocked = tabBarLayoutLockCount > 0
    }
    
    /// 设置指定 Tab 的角标数值
    /// - Parameters:
    ///   - value: 角标数值（nil 为隐藏）
    ///   - index: Tab 索引
    func setTabBarBadgeValue(_ value: Int?, at index: Int) {
        tabBarView.updateBadgeValue(value, at: index)
    }
    
    /// 选中指定 Tab
    /// - Parameters:
    ///   - index: 目标索引
    func selectTab(at index: Int) {
        selectTab(at: index, animated: true)
    }
    
    /// 选中指定 Tab
    /// - Parameters:
    ///   - index: 目标索引
    ///   - animated: 是否动画
    func selectTab(at index: Int, animated: Bool = true) {
        let didSelect = coordinator?.requestSelection(to: index, trigger: .programmatic) ?? false
        if didSelect {
            tabBarView.setSelectedIndex(index, animated: animated)
        }
    }
    
    /// 更新指定 Tab 的图标
    /// - Parameters:
    ///   - normalImage: 普通状态图片
    ///   - selectedImage: 选中状态图片
    ///   - index: Tab 索引
    func updateItemImages(normalImage: UIImage?, selectedImage: UIImage?, at index: Int) {
        tabBarView.updateImages(normalImage: normalImage, selectedImage: selectedImage, at: index)
    }
    
    /// 设置是否启用自定义图片着色
    /// - Parameter enabled: 是否启用
    func setCustomImageTintEnabled(_ enabled: Bool) {
        tabBarView.isCustomImageTintEnabled = enabled
    }
    
    func handleSelectionDenied(_ request: TabCoordinator.SelectionRequest) {
    }
    
    private func setupLayout() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        view.addSubview(tabBarView)
       
        tabBarView.style = resolvedTabBarViewStyle()
        
        pageViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        pageViewController.didMove(toParent: self)
        
        setupTabBarConstraints()
    }
    
    private func setupTabBarConstraints() {
        tabBarView.snp.remakeConstraints { make in
            switch tabBarStyle {
            case .frostedGlass:
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(Constants.tabBarHorizontalInset)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-Constants.tabBarHorizontalInset)
            case .plain:
                make.left.right.equalToSuperview()
            }
            tabBarBottomConstraint = make.bottom.equalTo(view.snp.bottom).constraint
        }
    }
    
    private func applyTabBarStyle() {
        guard isViewLoaded else {
            return
        }
        tabBarView.style = resolvedTabBarViewStyle()
        setupTabBarConstraints()
        updateTabBarInsetsIfNeeded()
        view.layoutIfNeeded()
    }
    
    private func resolvedTabBarViewStyle() -> CustomTabBarView.Style {
        switch tabBarStyle {
        case .frostedGlass:
            return .frostedGlass
        case .plain:
            return .plain
        }
    }

    private func updateTabBarInsetsIfNeeded() {
        if isTabBarCoveredByNavigation {
            additionalSafeAreaInsets.bottom = 0
            tabBarBottomConstraint?.update(offset: -tabBarBottomOffset)
            return
        }
        
        let systemSafeAreaBottomInset: CGFloat
        if let windowInset = view.window?.safeAreaInsets.bottom {
            systemSafeAreaBottomInset = windowInset
        } else {
            systemSafeAreaBottomInset = max(view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom, 0)
        }
        additionalSafeAreaInsets.bottom = max(tabBarView.currentHeight - systemSafeAreaBottomInset + tabBarBottomOffset, 0)
        // Ensure that for plain style, we account for the safe area height that is already included in currentHeight
        if tabBarStyle == .plain {
             additionalSafeAreaInsets.bottom = max(tabBarView.currentHeight - systemSafeAreaBottomInset, 0)
        }
        
        tabBarBottomConstraint?.update(offset: -tabBarBottomOffset)
    }

    private func setupTabBar() {
        tabBarView.configure(items: routes.map { $0.configuration }, selectedIndex: currentSelectedIndex)
    }
    
    
    func commitSelection(fromIndex: Int, toIndex: Int, route: TabRoute, trigger: TabCoordinator.SelectionTrigger) {
        selectionFeedbackGenerator.selectionChanged()
        selectionFeedbackGenerator.prepare()
        
        if shouldRestoreSelection {
            UserDefaults.standard.set(toIndex, forKey: restorationKey)
            UserDefaults.standard.synchronize()
        }
        
        tabBarView.setSelectedIndex(toIndex, animated: trigger != .restoration)
        transitionToRoute(route, fromIndex: fromIndex, toIndex: toIndex, animated: trigger != .restoration)
    }
    
    private func transitionToRoute(_ route: TabRoute, fromIndex: Int, toIndex: Int, animated: Bool) {
        let nextViewController = route.viewController
        let currentVisibleViewController = pageViewController.viewControllers?.first
        if currentVisibleViewController === nextViewController {
            selectedRouteViewController = nextViewController
            updateTabBarCoveredByNavigationForSelectedViewController()
            updateTabBarPresentation(animated: false)
            return
        }
        
        let direction: UIPageViewController.NavigationDirection = toIndex >= fromIndex ? .forward : .reverse
        let shouldAnimateTransition = animated && pageViewController.view.window != nil && currentVisibleViewController != nil
        
        isSettingPageViewController = true
        selectedRouteViewController = nextViewController
        pageViewController.setViewControllers([nextViewController], direction: direction, animated: shouldAnimateTransition) { [weak self] _ in
            self?.isSettingPageViewController = false
        }
        
        updateTabBarCoveredByNavigationForSelectedViewController()
        updateTabBarPresentation(animated: false)
    }
    
    private func indexForViewController(_ viewController: UIViewController) -> Int? {
        routes.firstIndex(where: { $0.viewController === viewController })
    }
    
    private func updateTabBarCoveredByNavigationForSelectedViewController() {
        let selectedNavigationController = (selectedRouteViewController as? UINavigationController)
            ?? (selectedRouteViewController?.children.first as? UINavigationController)
        let shouldCoverTabBar = (selectedNavigationController?.viewControllers.count ?? 1) > 1
            && (selectedNavigationController?.topViewController?.hidesBottomBarWhenPushed ?? false)
        setTabBarCoveredByNavigation(shouldCoverTabBar)
    }

    private func applyInitialSelectionIfNeeded() {
        guard didApplyInitialSelection == false else {
            return
        }
        guard let pendingInitialSelection else {
            return
        }
        guard view.bounds.width > 0, view.bounds.height > 0 else {
            return
        }

        didApplyInitialSelection = true
        self.pendingInitialSelection = nil
        _ = coordinator?.requestSelection(to: pendingInitialSelection.index, trigger: pendingInitialSelection.trigger)
    }
    
    private func updateTabBarPresentation(animated: Bool) {
        tabBarView.transform = .identity
        tabBarView.alpha = 1.0

        if isTabBarCoveredByNavigation {
            view.bringSubviewToFront(pageViewController.view)
        } else {
            view.bringSubviewToFront(tabBarView)
        }
    }
    
    private func setTabBarCoveredByNavigation(_ covered: Bool) {
        guard isTabBarCoveredByNavigation != covered else {
            return
        }
        isTabBarCoveredByNavigation = covered
        updateTabBarInsetsIfNeeded()
        updateTabBarPresentation(animated: false)
        view.layoutIfNeeded()
    }
    
    func navigationStackDidChange(in navigationController: UINavigationController) {
        let selectedNavigationController = (selectedRouteViewController as? UINavigationController)
            ?? (selectedRouteViewController?.children.first as? UINavigationController)
        
        guard selectedNavigationController === navigationController else {
            return
        }
        
        let shouldCoverTabBar = navigationController.viewControllers.count > 1 && (navigationController.topViewController?.hidesBottomBarWhenPushed ?? false)
        if shouldCoverTabBar {
            setTabBarCoveredByNavigation(true)
            return
        }

        guard isTabBarCoveredByNavigation else {
            setTabBarCoveredByNavigation(false)
            return
        }

        guard let coordinator = navigationController.transitionCoordinator else {
            setTabBarCoveredByNavigation(false)
            return
        }

        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self else { return }
            self.setTabBarCoveredByNavigation(false)
        }) { [weak self] context in
            guard let self else { return }
            if context.isCancelled {
                self.setTabBarCoveredByNavigation(true)
            }
        }
    }
}

extension TabContainerController: CustomTabBarViewDelegate {
    func customTabBarView(_ view: CustomTabBarView, didSelectIndex index: Int) {
        selectionFeedbackGenerator.prepare()
        _ = coordinator?.requestSelection(to: index, trigger: .user)
    }
}

extension TabContainerController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard isTabBarLayoutLocked == false else {
            return nil
        }
        guard let index = indexForViewController(viewController) else {
            return nil
        }
        let previousIndex = index - 1
        guard routes.indices.contains(previousIndex) else {
            return nil
        }
        return routes[previousIndex].viewController
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard isTabBarLayoutLocked == false else {
            return nil
        }
        guard let index = indexForViewController(viewController) else {
            return nil
        }
        let nextIndex = index + 1
        guard routes.indices.contains(nextIndex) else {
            return nil
        }
        return routes[nextIndex].viewController
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed else {
            return
        }
        guard isSettingPageViewController == false else {
            return
        }
        guard let currentViewController = pageViewController.viewControllers?.first else {
            return
        }
        guard let targetIndex = indexForViewController(currentViewController) else {
            return
        }
        
        let didSelect = coordinator?.requestSelection(to: targetIndex, trigger: .user) ?? false
        guard didSelect == false else {
            return
        }
        
        guard let previousViewController = previousViewControllers.first else {
            return
        }
        guard let previousIndex = indexForViewController(previousViewController) else {
            return
        }
        
        let direction: UIPageViewController.NavigationDirection = targetIndex >= previousIndex ? .reverse : .forward
        isSettingPageViewController = true
        pageViewController.setViewControllers([previousViewController], direction: direction, animated: true) { [weak self] _ in
            self?.isSettingPageViewController = false
        }
    }
}
