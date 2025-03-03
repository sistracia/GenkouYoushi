import PDFKit
import PencilKit

class MyPDFView: PDFView, PDFDocumentDelegate {
    private let myOverlay = MyPDFPageOverlay()
    private let toolPicker = PKToolPicker()
    private var isToolPickerShow = false

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.autoScales = true
        self.pageOverlayViewProvider = self.myOverlay
        self.isInMarkupMode = true
    }

    func loadPDF(_ document: PDFDocument) {
        document.delegate = self
        self.document = document
    }

    func showToolPicker(isEnabled: Bool) {
        if (self.isToolPickerShow || !isEnabled) {
            return
        }

        guard let page = currentPage,
              let myCanvasView = myOverlay.pageToViewMapping[page]
        else { return }

        self.isToolPickerShow = true
        self.toolPicker.addObserver(myCanvasView.canvasView)
        self.toolPicker.setVisible(true, forFirstResponder: myCanvasView.canvasView)
        myCanvasView.canvasView.becomeFirstResponder()
    }
}
