import UIKit

extension UIColor {
    private(set) static var cB1: UIColor = UIColor.darkModeColor(lightColor: UIColor.green, darkColor: UIColor.blue)
    private(set) static var cBackViewColor: UIColor = JKDarkModeUtil.colorLightDark(lightColor: UIColor.hexStringColor(hexString: "#FAFAFA"), darkColor: UIColor.hexStringColor(hexString: "#121212"))
    private(set) static var cN1: UIColor = JKDarkModeUtil.colorLightDark(lightColor: UIColor.hexStringColor(hexString: "#333333"), darkColor: UIColor.hexStringColor(hexString: "#FFFFFF").withAlphaComponent(0.85))
    private(set) static var cN2: UIColor = JKDarkModeUtil.colorLightDark(lightColor: UIColor.hexStringColor(hexString: "#999999"), darkColor: UIColor.hexStringColor(hexString: "#FFFFFF").withAlphaComponent(0.6))
    private(set) static var cN3: UIColor = JKDarkModeUtil.colorLightDark(lightColor: UIColor.hexStringColor(hexString: "#666666"), darkColor: UIColor.hexStringColor(hexString: "#FFFFFF").withAlphaComponent(0.4))
    private(set) static var cN4: UIColor = UIColor.darkModeColor(lightColor: UIColor.hexStringColor(hexString: "#EBEBEB"), darkColor: UIColor.hexStringColor(hexString: "#FFFFFF").withAlphaComponent(0.10))
    private(set) static var cN5: UIColor = UIColor.darkModeColor(lightColor: UIColor.white, darkColor: UIColor.red)

    static var random: UIColor {
        UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}
