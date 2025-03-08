import SwiftUI
import PencilKit
import PDFKit

struct MyPDFView: UIViewRepresentable {
    @Binding var data: Data
    @Binding var isEditing: Bool
    
    private let toolPicker = PKToolPicker()
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.pageOverlayViewProvider = context.coordinator
        pdfView.document = context.coordinator.document
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let currentPage = pdfView.currentPage,
           let overlayView = context.coordinator.pageToViewMapping[currentPage],
           self.isEditing != context.coordinator.isToolPickerAlreadyShow {
            
            context.coordinator.isToolPickerAlreadyShow = self.isEditing
            pdfView.isInMarkupMode = self.isEditing
            overlayView.isUserInteractionEnabled = self.isEditing
            self.toolPicker.setVisible(self.isEditing, forFirstResponder: overlayView)
            
            if self.isEditing {
                self.toolPicker.addObserver(overlayView)
                overlayView.becomeFirstResponder()
            } else {
                self.toolPicker.removeObserver(overlayView)
                overlayView.resignFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, data: self.data)
    }
    
    class Coordinator: NSObject, PDFDocumentDelegate, PDFPageOverlayViewProvider, PKCanvasViewDelegate {
        var parent: MyPDFView
        var data: Data
        
        var document: PDFDocument
        var pageToViewMapping = [PDFPage: PKCanvasView]()
        var isToolPickerAlreadyShow = false

        init(_ parent: MyPDFView, data: Data) {
            let document = PDFDocument(data: data)!
            self.document = document
            self.parent = parent
            self.data = data
            
            super.init()
            document.delegate = self
        }
        
        // When start annotating, remove our annotation then load to `PKCanvasView`
        // so we can edit back the drawing
        func initDrawingAnnotations(page: PDFPage) -> Optional<PKDrawing> {
            var pkDrawing: PKDrawing? = nil
            
            for annotate in page.annotations {
                for annotateKey in annotate.annotationKeyValues.keys {
                    if let baseKey = annotateKey.base as? String,
                       baseKey == "/\(MyPDFAnnotation.drawingAnnotationKey)" {
                        guard let base64String = annotate.value(forAnnotationKey: PDFAnnotationKey(rawValue: MyPDFAnnotation.drawingAnnotationKey)) as? String,
                              let data = Data(base64Encoded: base64String),
                              let drawing = try? PKDrawing(data: data)
                        else { continue }
                        
                        pkDrawing = drawing
                    }
                    
                    if let baseKey = annotateKey.base as? String,
                       baseKey.contains("/\(MyPDFAnnotation.drawingAnnotationKey)") {
                        page.removeAnnotation(annotate)
                    }
                }
            }
            
            return pkDrawing
        }
        
        func addDrawAnnotations(from fromDocument: PDFDocument) -> Optional<Data> {
            var pageToAnnotationMapping = [PDFPage: PDFAnnotation]()
            
            for i in 0...fromDocument.pageCount-1 {
                if let fromPage = fromDocument.page(at: i),
                   let overlayView = self.pageToViewMapping[fromPage] {
                    
                    
                    // Create an annotation of our custom subclass
                    let newAnnotation = MyPDFAnnotation(
                        bounds: overlayView.bounds,
                        forType: .ink,
                        withProperties: nil,
                        drawing: overlayView.drawing
                    )
                    
                    // Add our custom data
                    // TODO: use same custom data used by Apple's `File Preview` so we can edit each other
                    // let codedData = try! NSKeyedArchiver.archivedData(withRootObject: canvasView.drawing, requiringSecureCoding: true)
                    let codedData = overlayView.drawing.dataRepresentation().base64EncodedString()
                    let annotationKey = PDFAnnotationKey(rawValue: MyPDFAnnotation.drawingAnnotationKey)
                    newAnnotation.setValue(codedData, forAnnotationKey: annotationKey)
                    
                    // Add our annotation to the page
                    fromPage.addAnnotation(newAnnotation)
                    
                    // Store the annotation related to page to remove it later
                    pageToAnnotationMapping[fromPage] = newAnnotation
                }
            }
            
            // Delete annotation after data with annotation returned
            // so only display annotation in pencil canvas on screen
            // but no on the PDF page
            // TODO: Look for better implementation if any, feels like this implementation not really good
            defer {
                for (page, annotation) in pageToAnnotationMapping {
                    page.removeAnnotation(annotation)
                }
            }
            
            // Save the document to data representation
            //let options: [PDFDocumentWriteOption: Bool] = [
            //    // To "burn" the annotation to the real page
            //    .burnInAnnotationsOption: true,
            //    // To make any image in PDF saved as JPEG
            //    .saveImagesAsJPEGOption: true,
            //    // Downsample the image to max high DPI of screen resolution
            //    .optimizeImagesForScreenOption: true
            //]
            if let resultData = fromDocument.dataRepresentation() {
                return resultData
            }
            
            return nil
        }
        
        // MARK: PDF Document Delegate
        func classForPage() -> AnyClass {
            return PDFPage.self
        }
        
        // MARK: Canvas View Kit Delegate
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            DispatchQueue.global(qos: .background).sync {
                if let data = self.addDrawAnnotations(from: self.document) {
//                    TODO: Fix this, updating data from UI update
//                    self.parent.data = data
                }
            }
        }
        
        // MARK: Overlay Delegate
        func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
            if let overlayView = self.pageToViewMapping[page] {
                return overlayView
            }
            
            let canvasView = PKCanvasView(frame: .zero)
            canvasView.delegate = self
            canvasView.drawingPolicy = .pencilOnly
            canvasView.backgroundColor = .clear
            
            if let drawing = self.initDrawingAnnotations(page: page) {
                canvasView.drawing = drawing
            }
            
            self.pageToViewMapping[page] = canvasView
            return canvasView
        }
    }
}
