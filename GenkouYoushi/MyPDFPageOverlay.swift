import PDFKit

class MyPDFPageOverlay: NSObject, PDFPageOverlayViewProvider {

    var pageToViewMapping = [PDFPage: MyCanvasView]()

    func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        if let overlayView = self.pageToViewMapping[page] {
            return overlayView
        }

        let canvasView = MyCanvasView(frame: .zero)
        self.pageToViewMapping[page] = canvasView
        return canvasView
    }
}
