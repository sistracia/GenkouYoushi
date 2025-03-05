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
        pdfView.setCanvasDelegate(context.coordinator)
        pdfView.showToolPicker(isEnabled: isEditing)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: MyPDFViewX
        var pdfView: MyPDFView?
        
        init(_ parent: MyPDFViewX) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            DispatchQueue.global(qos: .background).sync {
                if let pdfView = self.pdfView,
                   let data = pdfView.getDataWithAnnotations() {
                    self.parent.data = data
                }
            }
        }
    }
}

#Preview {
    ContentView(document: .constant(GenkouYoushiDocument()))
}
