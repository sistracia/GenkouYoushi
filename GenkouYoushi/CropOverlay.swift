import SwiftUI

struct CropOverlay: View {
    @Binding var cropRect: CGRect
    var imageSize: CGSize
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay covering the entire view
            Rectangle()
                .opacity(0.5)
                .frame(width: imageSize.width, height: imageSize.height)
                .mask(
                    Rectangle()
                        .overlay(
                            Rectangle()
                                .frame(
                                    width: cropRect.width,
                                    height: cropRect.height
                                )
                                .position(x: cropRect.midX, y: cropRect.midY)
                                .blendMode(.destinationOut)
                        )
                )
            
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
                .overlay(
                    CropBorderHandles(cropRect: $cropRect, imageSize: imageSize)
                )
        }
    }
}

struct CropBorderHandles: View {
    @Binding var cropRect: CGRect
    var imageSize: CGSize
    let minSize: CGFloat = 50
    
    var body: some View {
        ZStack {
            // Top-left handle
            CropHandle(position: CGPoint(x: cropRect.minX, y: cropRect.minY))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // For unlock aspect ratio
                            // let newOrigin = CGPoint(
                            //     x: min(max(value.location.x, 0), cropRect.maxX - minSize),
                            //     y: min(max(value.location.y, 0), cropRect.maxY - minSize)
                            // )
                            // let newSize = CGSize(
                            //     width: cropRect.maxX - newOrigin.x,
                            //     height: cropRect.maxY - newOrigin.y
                            // )
                            // cropRect = CGRect(origin: newOrigin, size: newSize)
                            
                            let newX = min(max(value.location.x, 0), cropRect.maxX - minSize)
                            let newOrigin = CGPoint(x: newX,
                                                    y: cropRect.minY - (cropRect.minX - newX))
                            cropRect = CGRect(origin: newOrigin,
                                              size: CGSize(width: cropRect.maxX - newOrigin.x,
                                                           height: cropRect.maxY - newOrigin.y))
                        }
                )
            
            // Top-right handle
            CropHandle(position: CGPoint(x: cropRect.maxX, y: cropRect.minY))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // For unlock aspect ratio
                            // let newWidth = min(max(value.location.x - cropRect.minX, minSize), imageSize.width - cropRect.minX)
                            // let newY = min(max(value.location.y, 0), cropRect.maxY - minSize)
                            
                            // cropRect = CGRect(
                            //     origin: CGPoint(x: cropRect.minX, y: newY),
                            //     size: CGSize(width: newWidth, height: cropRect.maxY - newY)
                            // )
                            
                            let newY = min(max(value.location.y, 0), cropRect.maxY - minSize)
                            let newHeight = cropRect.maxY - newY
                            cropRect = CGRect(origin: CGPoint(x: cropRect.minX, y: newY),
                                              size: CGSize(width: newHeight, height: newHeight))
                        }
                )
            
            // Bottom-left handle
            CropHandle(position: CGPoint(x: cropRect.minX, y: cropRect.maxY))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // For unlock aspect ratio
                            // let newWidth = min(max(cropRect.maxX - value.location.x, minSize), cropRect.maxX)
                            // let newHeight = min(max(value.location.y - cropRect.minY, minSize), imageSize.height - cropRect.minY)
                            // cropRect = CGRect(
                            //     origin: CGPoint(x: value.location.x, y: cropRect.minY),
                            //     size: CGSize(width: newWidth, height: newHeight)
                            // )
                            
                            let newOrigin = CGPoint(x: cropRect.minX - (cropRect.minX - min(max(value.location.x, 0), cropRect.maxX - minSize)),
                                                    y: cropRect.minY)
                            let newWidth = cropRect.maxX - newOrigin.x
                            cropRect = CGRect(
                                origin: newOrigin,
                                size: CGSize(width: newWidth, height: newWidth))
                        }
                )
            
            // Bottom-right handle
            CropHandle(position: CGPoint(x: cropRect.maxX, y: cropRect.maxY))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // For unlock aspect ratio
                            // let newWidth = min(max(value.location.x - cropRect.minX, minSize), imageSize.width - cropRect.minX)
                            // let newHeight = min(max(value.location.y - cropRect.minY, minSize), imageSize.height - cropRect.minY)
                            // cropRect.size = CGSize(width: newWidth, height: newHeight)
                            
                            let newWidth = min(max(value.location.x - cropRect.minX, minSize), imageSize.width - cropRect.minX)
                            cropRect = CGRect(origin: cropRect.origin,
                                              size: CGSize(width: newWidth, height: newWidth))
                        }
                )
        }
    }
}

struct CropHandle: View {
    var position: CGPoint
    
    var body: some View {
        Circle()
            .frame(width: 20, height: 20)
            .foregroundColor(.white)
            .position(position)
    }
}

extension UIImage {
    // Ref: https://stackoverflow.com/a/48110726/29628503
    public func croppedImage(renderSize: CGSize, in rect: CGRect) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        
        // It somehow rotated
        let originalWidth = CGFloat(cgImage.height)
        let originalHeight = CGFloat(cgImage.width)
        let scaledWidth = renderSize.width
        let scaledHeight = renderSize.height
        
        let scaleWidth = originalWidth / scaledWidth
        let scaleHeight = originalHeight / scaledHeight
        
        let scaledX = rect.origin.x
        let scaledY = rect.origin.y
        let scaledWidthToTranslate = rect.width
        let scaledHeightToTranslate = rect.height
        
        let originalX = scaledX * scaleWidth
        let originalY = scaledY * scaleHeight
        let originalWidthTranslated = scaledWidthToTranslate * scaleWidth
        let originalHeightTranslated = scaledHeightToTranslate * scaleHeight
        
        let convertedRect = CGRect(
            x: originalX,
            y: originalY,
            width: originalWidthTranslated,
            height: originalHeightTranslated)
        
        let rad: (Double) -> CGFloat = { deg in
            return CGFloat(deg / 180.0 * .pi)
        }
        var rectTransform: CGAffineTransform
        switch imageOrientation {
        case .left:
            let rotation = CGAffineTransform(rotationAngle: rad(90))
            rectTransform = rotation.translatedBy(x: 0, y: -size.height)
        case .right:
            let rotation = CGAffineTransform(rotationAngle: rad(-90))
            rectTransform = rotation.translatedBy(x: -size.width, y: 0)
        case .down:
            let rotation = CGAffineTransform(rotationAngle: rad(-180))
            rectTransform = rotation.translatedBy(x: -size.width, y: -size.height)
        default:
            rectTransform = .identity
        }
        rectTransform = rectTransform.scaledBy(x: scale, y: scale)
        let transformedRect = convertedRect.applying(rectTransform)
        if let imageRef = cgImage.cropping(to: transformedRect) {
            return UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
        }
        return nil
    }
}

#Preview {
    @Previewable @State var cropRect: CGRect = CGRect(x: 100, y: 100, width: 200, height: 200)
    
    Image(systemName: "photo.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 500, height: 500)
        .overlay(
            GeometryReader { geometry in
                CropOverlay(cropRect: $cropRect, imageSize: geometry.size)
            }
        )
}
