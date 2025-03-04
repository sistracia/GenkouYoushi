import SwiftUI
import PencilKit
import PDFKit

struct ContentView: View {
    @Binding var document: GenkouYoushiDocument
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack {
            Button {
                isEditing = true
            } label: {
                Text("Start Editing")
            }
            MyPDFViewX(data: $document.pdfData, isEditing: $isEditing)
        }
    }
}

struct MyPDFViewX: UIViewRepresentable {
    @Binding var data: Data
    @Binding var isEditing: Bool
    
    func makeUIView(context: Context) -> MyPDFView {
        let pdfView = MyPDFView()
        pdfView.loadPDF(data: self.data)
        context.coordinator.pdfView = pdfView
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: MyPDFView, context: Context) {
        attachCanvasDelegate(document: pdfView.document, context: context)
        pdfView.showToolPicker(isEnabled: isEditing)
    }
    
    func attachCanvasDelegate(document: PDFDocument?, context: Context) {
        guard let document = document else { return }
        
        for i in 0...document.pageCount-1 {
            if let page = document.page(at: i),
               let page = page as? MyPDFPage,
               let canvasView = page.canvasView?.canvasView {
                // For listen to `canvasViewDrawingDidChange`
                canvasView.delegate = context.coordinator
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: MyPDFViewX
        var pdfView: PDFView?
        
        init(_ parent: MyPDFViewX) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            if let pdfView = self.pdfView,
               let data = MyPDFAnnotation.addDrawAnnotations(pdfView: pdfView) {
                self.parent.data = data
            }
            
        }
    }
}

#Preview {
    ContentView(document: .constant(GenkouYoushiDocument()))
}
