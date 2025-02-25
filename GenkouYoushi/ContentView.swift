// Thanks to Claude and Deepseek

import SwiftUI
import PDFKit
import PencilKit

struct ContentView: View {
    @Binding var document: GenkouYoushiDocument
    
    @State private var canAnnotate: Bool = true
    @State private var isPencilOnly: Bool = true
    @State private var annotations: [PDFAnnotation] = []
    
    var body: some View {
        PDFKitAnnotationView(document: PDFDocument(data: document.pdfData)!, canAnnotate: $canAnnotate, annotations: $annotations)
            .edgesIgnoringSafeArea(.all)
    }
}

// This is a UIViewRepresentable wrapper for PDFView with annotation capabilities
struct PDFKitAnnotationView: UIViewRepresentable {
    // PDF document to display
    var document: PDFDocument
    // For handling annotations
    @Binding var canAnnotate: Bool
    @Binding var annotations: [PDFAnnotation]
    
    // Creates the PDFView
    func makeUIView(context: Context) -> PDFView {
        // Set up gesture recognizers
//        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
//        tapGesture.isEnabled = false
        
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
//        pdfView.isUserInteractionEnabled = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true)
//        pdfView.addGestureRecognizer(tapGesture)
        
        disableDoubleTapGestures(in: pdfView)
        
        return pdfView
    }
    
    // Helper function to disable double-tap gestures
    private func disableDoubleTapGestures(in pdfView: PDFView) {
        for gestureRecognizer in pdfView.gestureRecognizers ?? [] {
            if let tapGestureRecognizer = gestureRecognizer as? UITapGestureRecognizer {
                // Disable double-tap gestures
                if tapGestureRecognizer.numberOfTapsRequired == 2 {
                    tapGestureRecognizer.isEnabled = false
                }
            }
        }
    }
    
    // Updates the PDFView when SwiftUI state changes
    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
        
        // Update annotation mode - using main thread for UI updates
        DispatchQueue.main.async {
            if self.canAnnotate {
                context.coordinator.enableAnnotationMode(pdfView)
            } else {
                context.coordinator.disableAnnotationMode(pdfView)
            }
        }
    }
    
    // Makes a coordinator to handle events
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator class handles interactions and events
    class Coordinator: NSObject, PKToolPickerObserver, PDFViewDelegate, PKCanvasViewDelegate {
        var parent: PDFKitAnnotationView
        var annotationCanvas: PKCanvasView?
        var toolPicker: PKToolPicker?
        var currentPage: PDFPage?
        
        init(_ parent: PDFKitAnnotationView) {
            self.parent = parent
            super.init()
        }
        
        // Handle tap gestures
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard parent.canAnnotate, let pdfView = gesture.view as? PDFView else { return }
            
            let location = gesture.location(in: pdfView)
            if let page = pdfView.page(for: location, nearest: true) {
                setupAnnotationCanvas(for: page, in: pdfView)
            }
        }
        
        // Enable annotation mode
        func enableAnnotationMode(_ pdfView: PDFView) {
            // First check if we're already in annotation mode
            if annotationCanvas != nil {
                return // Already in annotation mode
            }
            
            pdfView.delegate = self
            
            // If already on a page, set up the canvas
            if let currentPage = pdfView.currentPage {
                setupAnnotationCanvas(for: currentPage, in: pdfView)
            }
        }
        
        // Disable annotation mode
        func disableAnnotationMode(_ pdfView: PDFView) {
            // Save any existing annotations before disabling
            removeAnnotationCanvas()
            pdfView.delegate = nil
        }
        
        // Set up the PencilKit canvas for the current page
        func setupAnnotationCanvas(for page: PDFPage, in pdfView: PDFView) {
            // Safely remove any existing canvas first
            removeAnnotationCanvas()
            
            self.currentPage = page
            
            // Get the page bounds in the PDF view's coordinate space
            let pageRect = pdfView.convert(page.bounds(for: pdfView.displayBox), from: page)
            
            // Create a canvas view with the correct bounds
            let canvasView = PKCanvasView(frame: pageRect)
            canvasView.delegate = self
            canvasView.drawingPolicy = .pencilOnly  // Default to pencil only
            canvasView.backgroundColor = .clear
            
            // Add the canvas as a subview at the right Z position
            pdfView.addSubview(canvasView)
            self.annotationCanvas = canvasView
            
            // Make sure the canvas is properly sized and positioned
            canvasView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                canvasView.topAnchor.constraint(equalTo: pdfView.topAnchor, constant: pageRect.origin.y),
                canvasView.leftAnchor.constraint(equalTo: pdfView.leftAnchor, constant: pageRect.origin.x),
                canvasView.widthAnchor.constraint(equalToConstant: pageRect.width),
                canvasView.heightAnchor.constraint(equalToConstant: pageRect.height)
            ])
            
            // Set up the tool picker for Apple Pencil
            let toolPicker = PKToolPicker()
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            toolPicker.addObserver(self)
            self.toolPicker = toolPicker
            
            canvasView.becomeFirstResponder()
        }
        
        // Remove the annotation canvas
        func removeAnnotationCanvas() {
            guard let canvas = annotationCanvas else { return }
            
            // Save any annotations before removing
            saveAnnotation(from: canvas)
            
            // Clean up tool picker
            if let toolPicker = self.toolPicker {
                toolPicker.setVisible(false, forFirstResponder: canvas)
                toolPicker.removeObserver(canvas)
                toolPicker.removeObserver(self)
                self.toolPicker = nil
            }
            
            // Remove the canvas from view hierarchy
            canvas.removeFromSuperview()
            self.annotationCanvas = nil
            self.currentPage = nil
        }
        
        // Save the drawn content as a PDF annotation
        func saveAnnotation(from canvas: PKCanvasView) {
            guard let page = currentPage, !canvas.drawing.strokes.isEmpty else { return }
            
            // Convert PKDrawing to a PDF annotation
            let bounds = canvas.bounds
            
            // Create an image from the drawing
            UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
            canvas.drawing.image(from: bounds, scale: UIScreen.main.scale).draw(in: bounds)
            
            if let image = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext()
                
                // Create a stamp annotation
                let annotation = PDFAnnotation(bounds: bounds, forType: .stamp, withProperties: nil)
                
                // Set the content as an image
                let iconKey = PDFAnnotationKey(rawValue: "AAPL:IconForType")
                annotation.setValue(image, forAnnotationKey: iconKey)
                
                // Add annotation to the page
                page.addAnnotation(annotation)
                
                // Update the parent's annotations array
                DispatchQueue.main.async {
                    self.parent.annotations.append(annotation)
                }
            }
        }
        
        // PDFViewDelegate methods
        func pdfViewPageChanged(_ pdfView: PDFView) {
            guard parent.canAnnotate, let newPage = pdfView.currentPage else { return }
            
            // Save current annotations before moving to a new page
            if let canvas = annotationCanvas {
                saveAnnotation(from: canvas)
            }
            
            // Set up canvas for the new page
            setupAnnotationCanvas(for: newPage, in: pdfView)
        }
        
        // PKCanvasViewDelegate method
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // This method is called when the user draws on the canvas
            // You could implement real-time saving here if needed
        }
    }
}

#Preview {
    ContentView(document: .constant(GenkouYoushiDocument()))
}
