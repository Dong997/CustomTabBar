import UIKit

extension UIColor {
    /// 根据当前的主题模式返回对应的颜色
    /// - Parameters:
    ///   - lightColor: 浅色模式下的颜色
    ///   - darkColor: 深色模式下的颜色
    /// - Returns: 动态颜色
    static func darkModeColor(lightColor: UIColor, darkColor: UIColor) -> UIColor {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return darkColor
            } else {
                return lightColor
            }
        }
    }
    
    /// 从十六进制字符串创建颜色
    /// - Parameters:
    ///   - hexString: 十六进制字符串 (例如 "#FFFFFF" 或 "FFFFFF")
    ///   - alpha: 透明度，默认为 1.0
    /// - Returns: 对应的 UIColor，如果格式不正确则返回灰色
    static func hexStringColor(hexString: String, alpha: CGFloat = 1.0) -> UIColor {
        var cString: String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}
