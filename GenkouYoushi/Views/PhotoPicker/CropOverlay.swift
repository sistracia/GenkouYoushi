import SwiftUI

struct CropOverlay: View {
    var image: UIImage
    
    @Binding var cropRect: CGRect
    @Binding var lockRatio: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Semi-transparent overlay covering the entire view
                Rectangle()
                    .opacity(0.5)
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
                        CropBorderHandles(cropRect: $cropRect, lockRatio: $lockRatio, imageSize: image.size)
                    )
            }
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
    public func croppedImage(in rect: CGRect) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        
        // Scale the crop rect to match the image's actual size
        let scaledCropRect = CGRect(
            x: rect.origin.x,
            y: rect.origin.y,
            width: rect.width,
            height: rect.height
        )
        
        guard let croppedCGImage = cgImage.cropping(to: scaledCropRect) else { return nil }
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: scale, orientation: imageOrientation)
        
        return croppedImage
    }
}

#Preview {
    @Previewable @State var cropRect: CGRect = CGRect(x: 50, y: 25, width: 150, height: 150)
    @Previewable @State var lockRatio = true
    @Previewable @State var image = UIImage(named: "launch_background")!
    @Previewable @State var croppedImage: UIImage? =  nil
    
    VStack {
        CropOverlay(image: croppedImage ?? image, cropRect: $cropRect, lockRatio: $lockRatio)
        
        Toggle(isOn: $lockRatio) {
            Text("Lock Ratio")
        }
        
        HStack(spacing: 25) {
            Button {
                croppedImage = nil
            } label: {
                Text("Reset")
            }
            
            Button {
                croppedImage = image.croppedImage(in: cropRect)!
            } label: {
                Text("Crop Image")
            }
            
        }
    }
}
