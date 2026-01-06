# TabBar 组件

这是一个基于 Swift 实现的灵活且可定制的 TabBar 组件，具有自定义 UI、流畅的动画效果，并基于 `UIPageViewController` 进行导航管理。

## 概览

该 TabBar 组件旨在替代标准的 `UITabBarController`，提供更强的定制能力。它将导航逻辑 (`TabContainerController`)、视觉表现 (`CustomTabBarView`) 和配置 (`TabItemConfiguration`) 进行了分离。

## 核心组件

- **TabContainerController**: 主容器视图控制器，负责管理内容视图控制器和自定义 TabBar。
- **CustomTabBarView**: TabBar 的视觉视图，支持多种风格（毛玻璃、扁平）和动画。
- **TabItemConfiguration**: 定义单个 Tab 元素的外观和行为。
- **TabRoute**: 将 `TabItemConfiguration` 与 `UIViewController` 关联起来。

## 配置说明

### TabItemConfiguration (Tab项配置)

使用 `TabItemConfigurationModel` 或通过遵循 `TabItemConfiguration` 协议来定义 Tab 项。

```swift
let homeConfig = TabItemConfigurationModel(
    title: "首页",
    normalImage: UIImage(named: "home_normal"),
    selectedImage: UIImage(named: "home_selected"),
    isProminent: false, // 设置为 true 可展示为凸起的大按钮
    badgeValue: nil
)
```

| 属性 | 描述 |
|----------|-------------|
| `title` | 图标下方显示的标题文本。 |
| `normalImage` | 未选中状态下的图片。 |
| `selectedImage` | 选中状态下的图片。 |
| `lottieAnimationResourcePath` | Lottie 动画资源路径（如支持）。 |
| `isProminent` | 如果为 `true`，该项将显示为凸起的主要操作按钮（通常在中间）。 |
| `requiresAuthentication` | 标记选中此 Tab 是否需要登录检查或权限验证。 |
| `badgeValue` | 初始角标数字（可选）。 |

### CustomTabBarView (自定义TabBar视图)

可以直接在 `CustomTabBarView` 上配置视觉风格和行为，或者通过 `TabContainerController` 进行配置。

| 属性 | 描述 | 默认值 |
|----------|-------------|---------|
| `style` | `.frostedGlass` (悬浮毛玻璃) 或 `.plain` (标准扁平)。 | `.frostedGlass` |
| `indicatorInsets` | 选中指示器（毛玻璃效果）的内边距。负值表示向外扩张。 | `(-4, -4, -4, -4)` |
| `plainTopSpacing` | `.plain` 风格下 Item 距离顶部的间距。 | `8` |
| `isCustomImageTintEnabled` | 是否对图片应用自定义着色。 | `true` |

### TabContainerController (Tab容器控制器)

主控制器在初始化时接受配置。

```swift
let tabController = TabContainerController(
    routes: [homeRoute, profileRoute],
    initialSelectedIndex: 0,
    tabBarStyle: .frostedGlass,
    tabBarBottomOffset: 20,
    selectionPolicy: { request in
        // 处理选中逻辑（例如：权限检查）
        return .allow
    },
    selectionDidCommit: { request in
        // 处理选中后的操作
    }
)
```

| 参数 | 描述 |
|-----------|-------------|
| `routes` | 定义 Tab 的 `TabRoute` 数组。 |
| `initialSelectedIndex` | 启动时默认选中的 Tab 索引。 |
| `restorationKey` | 用于恢复上次选中 Tab 的 UserDefaults 键值。 |
| `shouldRestoreSelection` | 是否恢复上次选中的 Tab。 |
| `tabBarStyle` | TabBar 的视觉风格。 |
| `tabBarBottomOffset` | TabBar 的底部边距（适用于悬浮风格）。 |
| `indicatorInsets` | 选中指示器（毛玻璃效果）的内边距，默认为 `(-4, -4, -4, -4)`。 |

## 方法说明

### TabContainerController 控制方法

以下方法可用于在运行时动态控制 TabBar 的行为和状态：

- **`selectTab(at index: Int, animated: Bool)`**
  通过代码切换到指定的 Tab 索引。
  - `index`: 目标 Tab 的索引。
  - `animated`: 是否使用过渡动画。

- **`setTabBarBadgeValue(_ value: Int?, at index: Int)`**
  更新指定 Tab 的角标数字。
  - `value`: 角标数值，传入 `nil` 或 `0` 隐藏角标。
  - `index`: 目标 Tab 的索引。

- **`updateItemImages(normalImage: UIImage?, selectedImage: UIImage?, at index: Int)`**
  动态更新指定 Tab 的图标。
  - `normalImage`: 未选中状态的图片。
  - `selectedImage`: 选中状态的图片。
  - `index`: 目标 Tab 的索引。

- **`setCustomImageTintEnabled(_ enabled: Bool)`**
  切换是否对 Tab 图标应用自定义着色。
  - `enabled`: `true` 表示使用统一的主题色渲染图标；`false` 表示保持图标原色（适用于多彩图标）。

- **`setTabBarLayoutLocked(_ locked: Bool)`**
  锁定/解锁 TabBar 布局。
  - `locked`: `true` 暂停布局更新，`false` 恢复。通常在转场动画期间使用，防止布局错乱。

- **`setTabBarHidden(_ hidden: Bool, animated: Bool)`**
  控制 TabBar 的显示与隐藏。
  - `hidden`: 是否隐藏。
  - `animated`: 是否使用动画。
  - **注意**: 当子控制器 `hidesBottomBarWhenPushed = true` 时，系统会自动管理，无需手动调用此方法。

### 代理方法 (TabBarControlDelegate)

子控制器可以通过遵循 `TabBarControlDelegate` 协议或直接通过 `UIResponder` 链访问这些方法：

```swift
// 在任意子控制器中调用
self.tabBarControlDelegate?.setTabBarBadgeValue(5, at: 0)
self.tabBarControlDelegate?.selectTab(at: 1)
```

## 扩展性与自定义

### 1. 中间突出按钮 (Prominent Button)

在 `TabItemConfiguration` 中设置 `isProminent: true` 即可创建一个突出的中间按钮（通常用于“发布”或“扫描”功能）。

```swift
let publishConfig = TabItemConfigurationModel(
    title: "发布",
    normalImage: UIImage(named: "plus"),
    selectedImage: UIImage(named: "plus_selected"),
    isProminent: true // 开启突出样式
)
```

- 突出按钮会显示为一个带有圆形背景的大图标。
- 支持点击事件拦截，可在 `selectionPolicy` 中处理特殊逻辑（如弹出模态视图而不是切换 Tab）。

### 2. 权限与登录控制

利用 `selectionPolicy` 回调，可以在 Tab 切换发生前进行拦截：

```swift
let tabController = TabContainerController(...) { request in
    let config = request.configuration
    
    // 检查该 Tab 是否需要登录
    if config.requiresAuthentication && !User.current.isLoggedIn {
        // 跳转登录页
        LoginManager.shared.showLogin()
        // 阻止 Tab 切换
        return .prevent
    }
    
    return .allow
}
```

## 使用示例

```swift
// 1. 定义路由 (Routes)
let homeVC = HomeViewController()
let homeConfig = TabItemConfigurationModel(title: "首页", normalImage: img1, selectedImage: img2)
let homeRoute = TabRoute(configuration: homeConfig, viewController: homeVC)

let profileVC = ProfileViewController()
let profileConfig = TabItemConfigurationModel(title: "我的", normalImage: img3, selectedImage: img4)
let profileRoute = TabRoute(configuration: profileConfig, viewController: profileVC)

// 2. 初始化容器 (Initialize Container)
let tabContainer = TabContainerController(
    routes: [homeRoute, profileRoute],
    tabBarStyle: .frostedGlass
) { request in
    return .allow
} selectionDidCommit: { _ in }

// 3. 设置为根控制器 (Use as Root)
window.rootViewController = tabContainer
```
