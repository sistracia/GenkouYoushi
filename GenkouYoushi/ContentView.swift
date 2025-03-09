import SwiftUI
import PencilKit
import PDFKit

struct ContentView: View {
    @Binding var document: GenkouYoushiDocument
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack {
            if document.pdfData.isEmpty {
                Button {
                    document.pdfData = initStroke()
                } label: {
                    Text("Create Paper")
                }.buttonStyle(.borderedProminent)
            } else {
                MyPDFViewX(data: $document.pdfData, isEditing: $isEditing)
            }
        }.toolbar {
            ToolbarItemGroup {
                if !document.pdfData.isEmpty {
                    Toggle(isOn: $isEditing) {
                        Image(systemName: "pencil.tip.crop.circle")
                    }
                }
            }
        }
    }
    
    func initStroke() -> Data {
        let pageMaxWidth: CGFloat = 1600
        let pageMaxHeight: CGFloat = 2400
        
        let blockStartHeight: CGFloat = pageMaxHeight -  pageMaxWidth
        let cellSize: CGFloat = 80
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageMaxWidth, height: pageMaxHeight))
        let pdf = renderer.pdfData { context in
            context.beginPage()
            
            let path = UIBezierPath()
            
            // Draw vertical lines
            for i in stride(from: cellSize, to: pageMaxWidth, by: cellSize) {
                path.move(to: CGPoint(x: i, y: blockStartHeight))
                path.addLine(to:  CGPoint(x: i, y: pageMaxHeight))
                path.stroke()
            }
            
            // Draw horizontal lines
            for i in stride(from: blockStartHeight, to: pageMaxHeight, by: cellSize) {
                path.move(to: CGPoint(x: 0, y: i))
                path.addLine(to:  CGPoint(x: pageMaxHeight, y: i))
                path.stroke()
            }
        }
        
        return pdf
    }
    
}

struct MyPDFViewX: UIViewRepresentable {
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
