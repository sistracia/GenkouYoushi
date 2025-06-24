import PDFKit
import PencilKit

class MyPDFPageOverlay: NSObject {
    let toolPicker = PKToolPicker()
    // To be able to use `MyCanvasView` in `MyPDFView`
    var pageToViewMapping = [MyPDFPage: PKCanvasView]()
}

extension MyPDFPageOverlay: PDFPageOverlayViewProvider {
    func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        guard let page = page as? MyPDFPage else { return nil }
        
        if let overlayView = self.pageToViewMapping[page] {
            return overlayView
        }
        
        let canvasView = PKCanvasView(frame: .zero)
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isUserInteractionEnabled = false

        toolPicker.addObserver(canvasView)
        
        if let drawing = MyPDFAnnotation.initDrawingAnnotations(page: page) {
            canvasView.drawing = drawing
        }
        
        page.canvasView = canvasView
        self.pageToViewMapping[page] = canvasView
        return canvasView
    }
    
    func pdfView(_ view: PDFView, willRemove overlayView: UIView, for page: PDFPage) {
        guard let overlayView = overlayView as? PKCanvasView
        else { return }
        
        guard let page = page as? MyPDFPage
        else { return }
        
        toolPicker.removeObserver(overlayView)
        page.canvasView = overlayView
        pageToViewMapping.removeValue(forKey: page)
    }
}
