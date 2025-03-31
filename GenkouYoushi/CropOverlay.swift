import SwiftUI

struct CropOverlay: View {
    @Binding var cropRect: CGRect
    @Binding var lockRatio: Bool
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
                    CropBorderHandles(cropRect: $cropRect, lockRatio: $lockRatio, imageSize: imageSize)
                )
        }
    }
}

struct CropBorderHandles: View {
    @Binding var cropRect: CGRect
    @Binding var lockRatio: Bool
    var imageSize: CGSize
    let minSize: CGFloat = 50
    
    var body: some View {
        ZStack {
            // Top-left handle
            CropHandle(position: CGPoint(x: cropRect.minX, y: cropRect.minY))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !lockRatio {
                                let newOrigin = CGPoint(
                                    x: min(max(value.location.x, 0), cropRect.maxX - minSize),
                                    y: min(max(value.location.y, 0), cropRect.maxY - minSize)
                                )
                                let newSize = CGSize(
                                    width: cropRect.maxX - newOrigin.x,
                                    height: cropRect.maxY - newOrigin.y
                                )
                                cropRect = CGRect(origin: newOrigin, size: newSize)
                            } else {
                                let newX = min(max(value.location.x, 0), cropRect.maxX - minSize)
                                let newY = min(cropRect.minY - ((cropRect.minX - newX) * (cropRect.height / cropRect.width)), cropRect.maxY - minSize)
                                let isReachLimit: Bool = newY <= 0
                                cropRect = isReachLimit ? cropRect : CGRect(origin: CGPoint(x:  newX, y: newY),
                                                                            size: CGSize(width: cropRect.maxX - newX,
                                                                                         height: cropRect.maxY - newY))
                            }
                        }
                )
            
            // Top-right handle
            CropHandle(position: CGPoint(x: cropRect.maxX, y: cropRect.minY))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !lockRatio {
                                let newY = min(max(value.location.y, 0), cropRect.maxY - minSize)
                                cropRect = CGRect(
                                    origin: CGPoint(x: cropRect.minX, y: newY),
                                    size: CGSize(width: min(max(value.location.x - cropRect.minX, minSize), imageSize.width - cropRect.minX),
                                                 height: cropRect.maxY - newY)
                                )
                            } else {
                                let newY = min(max(value.location.y, 0), cropRect.maxY - minSize)
                                let newHeight = cropRect.height + (cropRect.minY - newY)
                                cropRect = CGRect(origin: CGPoint(x: cropRect.minX, y: newY),
                                                  size: CGSize(width: (newHeight * (cropRect.width / cropRect.height)),
                                                               height: newHeight))
                            }
                        }
                )
            
            // Bottom-left handle
            CropHandle(position: CGPoint(x: cropRect.minX, y: cropRect.maxY))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !lockRatio {
                                cropRect = CGRect(
                                    origin: CGPoint(x: min(max(value.location.x, 0), cropRect.maxX - minSize),
                                                    y: cropRect.minY),
                                    size: CGSize(width: min(max(cropRect.maxX - value.location.x, minSize), cropRect.maxX),
                                                 height: min(max(value.location.y - cropRect.minY, minSize), imageSize.height - cropRect.minY))
                                )
                            } else {
                                let newX = min(max(value.location.x, 0), cropRect.maxX - minSize)
                                let maxHeight = imageSize.height - cropRect.minY
                                let newHeight = (cropRect.width + (cropRect.minX - newX)) / (cropRect.width / cropRect.height)
                                let isReachLimit: Bool = newHeight >= maxHeight
                                cropRect = isReachLimit ? cropRect : CGRect(origin: CGPoint(x: newX, y: cropRect.minY),
                                                                            size: CGSize(width: cropRect.width + (cropRect.minX - newX),
                                                                                         height: newHeight))
                            }
                        }
                )
            
            // Bottom-right handle
            CropHandle(position: CGPoint(x: cropRect.maxX, y: cropRect.maxY))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !lockRatio {
                                cropRect.size = CGSize(width: min(max(value.location.x - cropRect.minX, minSize), imageSize.width - cropRect.minX),
                                                       height: min(max(value.location.y - cropRect.minY, minSize), imageSize.height - cropRect.minY))
                            } else {
                                let maxWidth = imageSize.width - cropRect.minX
                                let newHeight = min(max(value.location.y - cropRect.minY, minSize), imageSize.height - cropRect.minY)
                                let newWidth = min(max(newHeight * (cropRect.width / cropRect.height), minSize), maxWidth)
                                let isReachLimit: Bool = newWidth >= maxWidth 
                                cropRect = isReachLimit ? cropRect : CGRect(origin: cropRect.origin,
                                                                            size: CGSize(width: newWidth, height: newHeight))
                            }
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
    @Previewable @State var cropRect: CGRect = CGRect(x: 50, y: 25, width: 250, height: 150)
    @Previewable @State var lockRatio = true
    
    VStack {
        Image(systemName: "photo.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 500, height: 500)
            .overlay(
                GeometryReader { geometry in
                    CropOverlay(cropRect: $cropRect, lockRatio: $lockRatio, imageSize: geometry.size)
                }
            )
        
        HStack {
            Toggle(isOn: $lockRatio) {
                Text("Lock Ratio")
            }
        }
    }
}
