import PDFKit

class MyPDFPageOverlay: NSObject {
    // To be able to use `MyCanvasView` in `MyPDFView`
    var pageToViewMapping = [MyPDFPage: MyCanvasView]()
}

extension MyPDFPageOverlay: PDFPageOverlayViewProvider {
    func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        guard let page = page as? MyPDFPage else { return nil }
        
        if let overlayView = self.pageToViewMapping[page] {
            return overlayView
        }
        
        let canvasView = MyCanvasView(frame: .zero)
        if let drawing = MyPDFAnnotation.initDrawingAnnotations(page: page) {
            canvasView.canvasView.drawing = drawing
        }
        
        page.canvasView = canvasView
        self.pageToViewMapping[page] = canvasView
        return canvasView
    }
}
