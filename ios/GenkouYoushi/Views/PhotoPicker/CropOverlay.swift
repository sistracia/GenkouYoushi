// Thanks to Claude
import SwiftUI

struct CropOverlay: View {
    let image: UIImage
    @Binding var cropRect: CGRect
    @Binding var lockAspectRatio: Bool
    @Binding var aspectRatio: CGFloat
    
    @State private var isDragging = false
    @State private var lastDragPosition: CGPoint?
    
    @State private var position = CGPoint(x: 100, y: 100)
    
    // Minimum allowed crop size
    private let minCropSize: CGFloat = 50
    
    enum DragCorner {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        case entire
    }
    
    var body: some View {
        GeometryReader { geometry in
            let displayScale = min(
                geometry.size.width / image.size.width,
                geometry.size.height / image.size.height
            )
            
            ZStack {
                // The image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Semi-transparent overlay
                Rectangle()
                    .mask(
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .overlay(
                                // Cutout for crop area
                                Rectangle()
                                    .frame(
                                        width: cropRect.width * displayScale,
                                        height: cropRect.height * displayScale
                                    )
                                    .position(
                                        x: cropRect.midX * displayScale + geometry.size.width / 2 - image.size.width * displayScale / 2,
                                        y: cropRect.midY * displayScale + geometry.size.height / 2 - image.size.height * displayScale / 2
                                    )
                                    .blendMode(.destinationOut)
                            )
                    )
                
                // Crop rectangle outline
                Rectangle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .contentShape(Rectangle())
                    .frame(
                        width: cropRect.width * displayScale,
                        height: cropRect.height * displayScale
                    )
                    .position(
                        x: cropRect.midX * displayScale + geometry.size.width / 2 - image.size.width * displayScale / 2,
                        y: cropRect.midY * displayScale + geometry.size.height / 2 - image.size.height * displayScale / 2
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                handleDrag(value: value, corner: .entire, geometry: geometry, displayScale: displayScale)
                            }
                            .onEnded { _ in
                                isDragging = false
                                lastDragPosition = nil
                            }
                    )
                
                // Corner handlers
                ForEach(corners, id: \.0) { corner, position in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .position(
                            x: position.x * displayScale + geometry.size.width / 2 - image.size.width * displayScale / 2,
                            y: position.y * displayScale + geometry.size.height / 2 - image.size.height * displayScale / 2
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    handleDrag(value: value, corner: corner, geometry: geometry, displayScale: displayScale)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    lastDragPosition = nil
                                    // Save current aspect ratio if locked
                                    if lockAspectRatio {
                                        aspectRatio = cropRect.width / cropRect.height
                                    }
                                }
                        )
                }
            }
        }
    }
    
    private var corners: [(DragCorner, CGPoint)] {
        [
            (.topLeft, CGPoint(x: cropRect.minX, y: cropRect.minY)),
            (.topRight, CGPoint(x: cropRect.maxX, y: cropRect.minY)),
            (.bottomLeft, CGPoint(x: cropRect.minX, y: cropRect.maxY)),
            (.bottomRight, CGPoint(x: cropRect.maxX, y: cropRect.maxY))
        ]
    }
    
    private func handleDrag(value: DragGesture.Value, corner: DragCorner, geometry: GeometryProxy, displayScale: CGFloat) {
        let dragPosition = value.location
        
        // Convert from view coordinates to image coordinates
        let imageOriginX = geometry.size.width / 2 - image.size.width * displayScale / 2
        let imageOriginY = geometry.size.height / 2 - image.size.height * displayScale / 2
        
        let currentPositionInImage = CGPoint(
            x: (dragPosition.x - imageOriginX) / displayScale,
            y: (dragPosition.y - imageOriginY) / displayScale
        )
        
        if !isDragging {
            isDragging = true
            lastDragPosition = currentPositionInImage
            return
        }
        
        guard let lastPosition = lastDragPosition else { return }
        let deltaX = currentPositionInImage.x - lastPosition.x
        let deltaY = currentPositionInImage.y - lastPosition.y
        
        // Update crop rectangle based on which corner is being dragged
        var newRect = cropRect
        
        if corner == .entire {
            // Move the entire rectangle
            newRect.origin.x += deltaX
            newRect.origin.y += deltaY
            
            // Ensure it stays within image bounds
            if newRect.minX < 0 { newRect.origin.x = 0 }
            if newRect.minY < 0 { newRect.origin.y = 0 }
            if newRect.maxX > image.size.width { newRect.origin.x = image.size.width - newRect.width }
            if newRect.maxY > image.size.height { newRect.origin.y = image.size.height - newRect.height }
        } else {
            // Handle corner resizing while respecting aspect ratio if locked
            if lockAspectRatio {
                switch corner {
                case .topLeft:
                    let maxDelta = min(deltaX, deltaY)
                    let heightDelta = maxDelta
                    let widthDelta = maxDelta * aspectRatio
                    
                    newRect.origin.x += widthDelta
                    newRect.size.width -= widthDelta
                    newRect.origin.y += heightDelta
                    newRect.size.height -= heightDelta
                case .topRight:
                    // Opposite sign for width delta (grows to right)
                    let heightDelta = deltaY
                    let widthDelta = -heightDelta * aspectRatio
                    
                    newRect.size.width += widthDelta
                    newRect.origin.y += heightDelta
                    newRect.size.height -= heightDelta
                case .bottomLeft:
                    // Opposite sign for height delta (grows downward)
                    let widthDelta = deltaX
                    let heightDelta = -widthDelta / aspectRatio
                    
                    newRect.origin.x += widthDelta
                    newRect.size.width -= widthDelta
                    newRect.size.height += heightDelta
                case .bottomRight:
                    // Both dimensions grow
                    let maxDelta = max(deltaX, deltaY)
                    let heightDelta = maxDelta
                    let widthDelta = heightDelta * aspectRatio
                    
                    newRect.size.width += widthDelta
                    newRect.size.height += heightDelta
                default:
                    break
                }
            } else {
                switch corner {
                case .topLeft:
                    newRect.origin.x += deltaX
                    newRect.size.width -= deltaX
                    newRect.origin.y += deltaY
                    newRect.size.height -= deltaY
                case .topRight:
                    newRect.size.width += deltaX
                    newRect.origin.y += deltaY
                    newRect.size.height -= deltaY
                case .bottomLeft:
                    newRect.origin.x += deltaX
                    newRect.size.width -= deltaX
                    newRect.size.height += deltaY
                case .bottomRight:
                    newRect.size.width += deltaX
                    newRect.size.height += deltaY
                default:
                    break
                }
                
            }
        }
        
        // Ensure crop rectangle stays within image bounds and maintains minimum size
        if newRect.width >= minCropSize && newRect.height >= minCropSize &&
            newRect.minX >= 0 && newRect.minY >= 0 &&
            newRect.maxX <= image.size.width && newRect.maxY <= image.size.height {
            cropRect = newRect
        }
        
        lastDragPosition = currentPositionInImage
    }
}

extension UIImage {
    // Function to actually crop the image
    func cropImage(cropRect: CGRect) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: .up)
    }
    
    func fixOrientation() -> UIImage {
        // If the orientation is already up, no need to fix
        if self.imageOrientation == .up {
            return self
        }
        
        // Create a CGContext to draw the rotated image
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        
        // Draw the image in the correct orientation
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        self.draw(in: rect)
        
        // Get the normalized image
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

#Preview {
    @Previewable @State var image = UIImage(named: "launch_background")!
    @Previewable @State var croppedImage: UIImage? =  nil
    @Previewable @State var cropRect: CGRect = CGRect(x: 0, y: 0, width: 50, height: 50)
    @Previewable @State var lockAspectRatio: Bool = true
    @Previewable @State var aspectRatio: CGFloat = 1
    
    var img: UIImage {
        croppedImage ?? image
    }
    
    VStack {
        CropOverlay(image: img, cropRect: $cropRect, lockAspectRatio: $lockAspectRatio, aspectRatio: $aspectRatio)
        
        Toggle(isOn: $lockAspectRatio) {
            Text("Lock Ratio")
        }
        .onChange(of: lockAspectRatio) { _, isLocked in
            if isLocked {
                // Save current aspect ratio when locking
                aspectRatio = cropRect.width / cropRect.height
            }
        }
        
        HStack(spacing: 25) {
            Button {
                croppedImage = nil
                cropRect = CGRect(x: 0, y: 0, width: 50, height: 50)
            } label: {
                Text("Reset")
            }
            
            Button {
                croppedImage = image.cropImage(cropRect: cropRect)!
                cropRect = CGRect(x: 0, y: 0, width: 50, height: 50)
            } label: {
                Text("Crop Image")
            }
            
        }
    }
}
