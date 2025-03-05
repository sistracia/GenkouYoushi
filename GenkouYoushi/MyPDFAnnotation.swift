import PDFKit
import PencilKit

class MyPDFAnnotation: PDFAnnotation {
    
    // Our custom annotation key.
    // `AAPL:AKExtras` is key used by `File Preview` annotation
    // TODO: Use the same key as the one Apple use so we can edit each other annotation
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
           let canvas = page.canvasView {
            let image = canvas.canvasView.drawing.image(from: canvas.canvasView.drawing.bounds, scale: 1)
            image.draw(in: canvas.canvasView.drawing.bounds)
        }
        
        context.restoreGState()
        UIGraphicsPopContext()
    }
}

extension MyPDFAnnotation {
    // When start annotating, remove our annotation then load to `PKCanvasView`
    // so we can edit back the drawing
    static func initDrawingAnnotations(page: PDFPage) -> Optional<PKDrawing> {
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
    
    static func addDrawAnnotations(from fromDocument: PDFDocument) -> Optional<Data> {
        var pageToAnnotationMapping = [PDFPage: PDFAnnotation]()
        
        for i in 0...fromDocument.pageCount-1 {
            if let fromPage = fromDocument.page(at: i),
               let fromPage = fromPage as? MyPDFPage,
               let canvasView = fromPage.canvasView?.canvasView {
                
                let mediaBoxBounds = fromPage.bounds(for: .mediaBox)
                let mediaBoxHeight = fromPage.bounds(for: .mediaBox).height
                let properties = [MyPDFAnnotation.drawingMediaBoxAnnotationKey:NSNumber(
                    value: mediaBoxHeight
                )]
                
                // Create an annotation of our custom subclass
                let newAnnotation = MyPDFAnnotation(
                    bounds: mediaBoxBounds,
                    forType: .stamp,
                    withProperties: properties
                )
                
                // Add our custom data
                // TODO: use same custom data used by Apple's `File Preview` so we can edit each other
                // let codedData = try! NSKeyedArchiver.archivedData(withRootObject: canvasView.drawing, requiringSecureCoding: true)
                let codedData = canvasView.drawing.dataRepresentation().base64EncodedString()
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
}
