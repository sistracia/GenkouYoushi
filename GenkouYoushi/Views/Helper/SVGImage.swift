import SwiftUI
import SVGKit

// Thanks to DeepSeek
extension UIImage {
    static func imageFromBase64SVG(_ base64String: String) -> UIImage? {
        // Remove data URI prefix if present
        let cleanedString = base64String
            .replacingOccurrences(of: "data:image/svg+xml;base64,", with: "")
        
        guard let data = Data(base64Encoded: cleanedString) else {
            print("Failed to decode Base64 string")
            return nil
        }
        
        let svgImage = SVGKImage(data: data)
        return svgImage?.uiImage
    }
}
