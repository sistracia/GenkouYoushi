import PDFKit
import PencilKit

class MyPDFAnnotation: PDFAnnotation {
    
    // Our custom annotation key.
    // `AAPL:AKExtras` is key used by Apple's `File Preview` annotation
    // TODO: Use the same key as the one Apple use so we can edit each other annotation
    static let drawingAnnotationKey = "AAPL:AKExtras_XYZ"
    
    private var drawing: PKDrawing
    
    init(bounds: CGRect, forType annotationType: PDFAnnotationSubtype, withProperties properties: [AnyHashable : Any]?, drawing: PKDrawing) {
        self.drawing = drawing
        super.init(bounds: bounds, forType: annotationType, withProperties: properties)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        UIGraphicsPushContext(context)
        context.saveGState()
        
        let image = self.drawing.image(from: self.drawing.bounds, scale: 1)
        image.draw(in: self.drawing.bounds)
        
        context.restoreGState()
        UIGraphicsPopContext()
    }
}
