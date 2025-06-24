import SwiftUI
import PencilKit
import PDFKit

struct MyPDFViewPresentable: UIViewRepresentable {
    @Binding var data: Data
    @Binding var isEditing: Bool
    
    func makeUIView(context: Context) -> MyPDFView {
        let pdfView = MyPDFView(data: self.data)
        context.coordinator.pdfView = pdfView
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: MyPDFView, context: Context) {
        pdfView.setCanvasDelegate(isEditing ? context.coordinator : nil)
        pdfView.showToolPicker(isEnabled: isEditing)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: MyPDFViewPresentable
        var pdfView: MyPDFView?
        
        init(_ parent: MyPDFViewPresentable) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            Task { @MainActor in
                guard let pdfView = self.pdfView
                else { return }
                
                guard let newData = pdfView.getDataWithAnnotations()
                else { return }
                
                self.parent.data = newData
            }
        }
    }
}
