// Thanks to Claude
import SwiftUI

struct ImageCropperX: View {
    let image: UIImage
    @Binding var cropRect: CGRect
    @Binding var lockAspectRatio: Bool
    @Binding var aspectRatio: CGFloat
    
    @State private var isDragging = false
    @State private var lastDragPosition: CGPoint?
    
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
                    .fill(Color.black.opacity(0.5))
                    .mask(
                        ZStack {
                            Rectangle()
                            
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
                        }
                    )
                
                // Crop rectangle outline
                Rectangle()
                    .strokeBorder(Color.white, lineWidth: 2)
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

// Usage in your app
struct ContentViewY: View {
    @State private var selectedImage: UIImage? = nil
    @State private var croppedImage : UIImage? = nil
    
    @State private var showImagePicker = false
    @State private var showCropper = false
    
    @State private var cropRect: CGRect = .zero
    @State private var lockAspectRatio: Bool = false
    @State private var aspectRatio: CGFloat = 1.0 // Default 1:1
    
    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                
                Button("Crop Image") {
                    if let selectedImage = selectedImage {
                        cropRect = getImageRect(image: selectedImage)
                    }
                    showCropper = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Button("Select Image") {
                    showImagePicker = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            // Use PHPickerViewController or UIImagePickerController here
            // This is placeholder code
            Button("Simulate image selection") {
                selectedImage = UIImage(named: "launch_background")
                showImagePicker = false
            }
        }
        .fullScreenCover(isPresented: $showCropper) {
            if let image = croppedImage ?? selectedImage {
                VStack {
                    
                    ImageCropperX(image: image, cropRect: $cropRect, lockAspectRatio: $lockAspectRatio, aspectRatio: $aspectRatio)
                    // Toolbar with aspect ratio controls
                    Toggle("Lock Ratio", isOn: $lockAspectRatio)
                        .onChange(of: lockAspectRatio) { prevLocked, isLocked in
                            if isLocked {
                                // Save current aspect ratio when locking
                                aspectRatio = cropRect.width / cropRect.height
                            }
                        }
                    
                    // Bottom toolbar with action buttons
                    HStack {
                        Button("Cancel") {
                            // Handle cancel action
                            if let selectedImage = selectedImage {
                                self.cropRect = getImageRect(image: selectedImage)
                            }
                            self.croppedImage = nil
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        Button("Crop") {
                            // Use the cropRect to perform the actual cropping
                            let croppedImage = cropImage(image: image, cropRect: cropRect)
                            if let croppedImage = croppedImage {
                                self.cropRect = getImageRect(image: croppedImage)
                            }
                            self.croppedImage = croppedImage
                            // Handle the cropped image (e.g., save it or pass it to another view)
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private func getImageRect(image: UIImage) -> CGRect {
        // Initialize crop rectangle to cover most of the image
        let imageSize = image.size
        let initialSize = CGSize(
            width: imageSize.width * 0.8,
            height: imageSize.height * 0.8
        )
        let initialOrigin = CGPoint(
            x: (imageSize.width - initialSize.width) / 2,
            y: (imageSize.height - initialSize.height) / 2
        )
        return CGRect(origin: initialOrigin, size: initialSize)
    }
    
    // Function to actually crop the image
    private func cropImage(image: UIImage, cropRect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Scale the crop rect to match the image's actual size
        let scaledCropRect = CGRect(
            x: cropRect.origin.x * image.scale,
            y: cropRect.origin.y * image.scale,
            width: cropRect.width * image.scale,
            height: cropRect.height * image.scale
        )
        
        guard let croppedCGImage = cgImage.cropping(to: scaledCropRect) else { return nil }
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
        
        return croppedImage
    }
}

// Preview for testing
struct ImageCropper_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewY()
    }
}
