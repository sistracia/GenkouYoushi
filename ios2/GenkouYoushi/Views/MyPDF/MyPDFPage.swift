import PDFKit
import PencilKit

class MyPDFPage: PDFPage {
    // To attach `PKCanvasViewDelegate` in `UIViewRepresentable`
    var canvasView: PKCanvasView?
}
