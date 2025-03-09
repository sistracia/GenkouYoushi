import PDFKit

class MyPDFPage: PDFPage {
    // To attach `PKCanvasViewDelegate` in `UIViewRepresentable`
    var canvasView: MyCanvasView?
}
