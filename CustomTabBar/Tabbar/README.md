‘
# TabBar Component

A flexible and customizable TabBar component implemented in Swift, featuring a custom UI, smooth animations, and `UIPageViewController` based navigation.

## Overview

The TabBar component is designed to replace the standard `UITabBarController` with a more customizable solution. It separates the navigation logic (`TabContainerController`), visual representation (`CustomTabBarView`), and configuration (`TabItemConfiguration`).

## Key Components

- **TabContainerController**: The main container view controller that manages the content view controllers and the custom tab bar.
- **CustomTabBarView**: The visual representation of the tab bar, supporting different styles (Frosted Glass, Plain) and animations.
- **TabItemConfiguration**: Defines the appearance and behavior of individual tab items.
- **TabRoute**: Links a `TabItemConfiguration` to a `UIViewController`.

## Configuration

### TabItemConfiguration

Define your tab items using `TabItemConfigurationModel` or by conforming to `TabItemConfiguration`.

```swift
let homeConfig = TabItemConfigurationModel(
    title: "Home",
    normalImage: UIImage(named: "home_normal"),
    selectedImage: UIImage(named: "home_selected"),
    isProminent: false, // Set to true for a larger, prominent center button
    badgeValue: nil
)
```

| Property | Description |
|----------|-------------|
| `title` | The title text displayed below the icon. |
| `normalImage` | The image for the unselected state. |
| `selectedImage` | The image for the selected state. |
| `lottieAnimationResourcePath` | Path to a Lottie animation (if supported). |
| `isProminent` | If `true`, this item is styled as a prominent action button (usually in the center). |
| `requiresAuthentication` | Flag to indicate if selecting this tab requires a login check. |
| `badgeValue` | Initial badge number (optional). |

### CustomTabBarView

The visual style and behavior can be configured directly on `CustomTabBarView` or via `TabContainerController`.

| Property | Description | Default |
|----------|-------------|---------|
| `style` | `.frostedGlass` (floating with blur) or `.plain` (standard flat). | `.frostedGlass` |
| `indicatorInsets` | Insets for the selection indicator (frosted glass effect). Negative values expand the indicator. | `(-4, -4, -4, -4)` |
| `plainTopSpacing` | Top spacing for items in `.plain` style. | `8` |
| `isCustomImageTintEnabled` | Whether to apply custom tint colors to images. | `true` |

### TabContainerController

The main controller accepts configuration during initialization.

```swift
let tabController = TabContainerController(
    routes: [homeRoute, profileRoute],
    initialSelectedIndex: 0,
    tabBarStyle: .frostedGlass,
    tabBarBottomOffset: 20,
    selectionPolicy: { request in
        // Handle selection logic (e.g., auth checks)
        return .allow
    },
    selectionDidCommit: { request in
        // Handle post-selection actions
    }
)
```

| Parameter | Description |
|-----------|-------------|
| `routes` | Array of `TabRoute` defining the tabs. |
| `initialSelectedIndex` | The index of the tab to select on launch. |
| `restorationKey` | UserDefaults key for restoring the last selected tab. |
| `shouldRestoreSelection` | Whether to restore the previously selected tab. |
| `tabBarStyle` | Visual style of the tab bar. |
| `tabBarBottomOffset` | Bottom margin for the tab bar (useful for floating styles). |
| `indicatorInsets` | Insets for the selection indicator (frosted glass effect). Default is `(-4, -4, -4, -4)`. |

## Methods

### TabContainerController Control Methods

The following methods can be used to control the TabBar behavior and state at runtime:

- **`selectTab(at index: Int, animated: Bool)`**
  Programmatically switches to the specified tab index.
  - `index`: The target tab index.
  - `animated`: Whether to animate the transition.

- **`setTabBarBadgeValue(_ value: Int?, at index: Int)`**
  Updates the badge number for a specific tab.
  - `value`: Badge number. Pass `nil` or `0` to hide.
  - `index`: The target tab index.

- **`updateItemImages(normalImage: UIImage?, selectedImage: UIImage?, at index: Int)`**
  Updates the icons for a specific tab dynamically.
  - `normalImage`: Image for the normal state.
  - `selectedImage`: Image for the selected state.
  - `index`: The target tab index.

- **`setCustomImageTintEnabled(_ enabled: Bool)`**
  Toggles the custom tint color application for tab icons.
  - `enabled`: `true` to use the uniform theme color; `false` to keep original image colors.

- **`setTabBarLayoutLocked(_ locked: Bool)`**
  Locks/unlocks the tab bar layout.
  - `locked`: `true` to pause layout updates, `false` to resume. Useful during transitions to prevent layout glitches.

- **`setTabBarHidden(_ hidden: Bool, animated: Bool)`**
  Controls the visibility of the TabBar.
  - `hidden`: Whether to hide the TabBar.
  - `animated`: Whether to animate the change.
  - **Note**: When `hidesBottomBarWhenPushed = true` is set on child controllers, the system manages this automatically.

### Delegate Methods (TabBarControlDelegate)

Child view controllers can access these methods by conforming to `TabBarControlDelegate` or traversing the `UIResponder` chain:

```swift
// Call from any child view controller
self.tabBarControlDelegate?.setTabBarBadgeValue(5, at: 0)
self.tabBarControlDelegate?.selectTab(at: 1)
```

## Extensibility & Customization

### 1. Prominent Button (Center Action)

Set `isProminent: true` in `TabItemConfiguration` to create a prominent center button (often used for "Publish" or "Scan" actions).

```swift
let publishConfig = TabItemConfigurationModel(
    title: "Publish",
    normalImage: UIImage(named: "plus"),
    selectedImage: UIImage(named: "plus_selected"),
    isProminent: true // Enable prominent style
)
```

- The prominent button appears with a circular background and larger icon.
- You can intercept tap events in `selectionPolicy` to handle special logic (e.g., presenting a modal instead of switching tabs).

### 2. Authentication & Login Control

Use the `selectionPolicy` callback to intercept tab switching:

```swift
let tabController = TabContainerController(...) { request in
    let config = request.configuration
    
    // Check if the tab requires login
    if config.requiresAuthentication && !User.current.isLoggedIn {
        // Show login screen
        LoginManager.shared.showLogin()
        // Prevent tab switching
        return .prevent
    }
    
    return .allow
}
```

## Usage Example

```swift
// 1. Define Routes
let homeVC = HomeViewController()
let homeConfig = TabItemConfigurationModel(title: "Home", normalImage: img1, selectedImage: img2)
let homeRoute = TabRoute(configuration: homeConfig, viewController: homeVC)

let profileVC = ProfileViewController()
let profileConfig = TabItemConfigurationModel(title: "Profile", normalImage: img3, selectedImage: img4)
let profileRoute = TabRoute(configuration: profileConfig, viewController: profileVC)

// 2. Initialize Container
let tabContainer = TabContainerController(
    routes: [homeRoute, profileRoute],
    tabBarStyle: .frostedGlass
) { request in
    return .allow
} selectionDidCommit: { _ in }

// 3. Use as Root
window.rootViewController = tabContainer
```
