import PDFKit

class MyPDFAnnotation: PDFAnnotation {
    
    // Our custom annotation key.
    // Use the same key as apple use in their `File Preview`
    // so we can edit each other annotation
    static let drawingAnnotationKey = "AAPL:AKExtras"
    
    static let drawingMediaBoxAnnotationKey: String = "\(drawingAnnotationKey):Height"
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard let pdfPageMediaBoxHeightKey = self.value(forAnnotationKey: PDFAnnotationKey(rawValue: MyPDFAnnotation.drawingMediaBoxAnnotationKey)) as? NSNumber
        else { return }
        
        let verticalShiftValue = CGFloat(truncating: pdfPageMediaBoxHeightKey)

        UIGraphicsPushContext(context)
        context.saveGState()
        
        let transform = CGAffineTransform(scaleX: 1.0, y: -1.0).translatedBy(x: 0.0, y: -verticalShiftValue)
        context.concatenate(transform)

        if let page = page as? MyPDFPage,
           let canvas = page.myCanvasView {
            let image = canvas.canvasView.drawing.image(from: canvas.canvasView.drawing.bounds, scale: 1)
            image.draw(in: canvas.canvasView.drawing.bounds)
        }
        
        context.restoreGState()
        UIGraphicsPopContext()
    }
}

extension MyPDFAnnotation {
    static func foo() {
        
    }
}
