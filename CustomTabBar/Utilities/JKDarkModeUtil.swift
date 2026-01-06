import UIKit

class JKDarkModeUtil {
    /// 根据当前的主题模式返回对应的颜色
    /// - Parameters:
    ///   - lightColor: 浅色模式下的颜色
    ///   - darkColor: 深色模式下的颜色
    /// - Returns: 动态颜色
    static func colorLightDark(lightColor: UIColor, darkColor: UIColor) -> UIColor {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return darkColor
            } else {
                return lightColor
            }
        }
    }
}
