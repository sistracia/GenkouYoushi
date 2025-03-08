import SwiftUI

struct ContentView: View {
    @Binding var document: GenkouYoushiDocument
    @State private var isEditing: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if document.pdfData.isEmpty {
                    Text("Create paper first")
                } else {
                    MyPDFView(data: $document.pdfData, isEditing: $isEditing)
                }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if document.pdfData.isEmpty {
                        Button {
                            document.pdfData = initStroke(geometry: geometry)
                        } label: {
                            Text("Create Paper")
                        }
                    } else {
                        Toggle(isOn: $isEditing) {
                            Image(systemName: "pencil.tip.crop.circle")
                        }
                    }
                }
            }
        }
    }
    
    func initStroke(geometry: GeometryProxy) -> Data {
        let pageMaxWidth: CGFloat = geometry.size.width
        let pageMaxHeight: CGFloat = geometry.size.height
        
        let blockStartHeight: CGFloat = pageMaxHeight -  pageMaxWidth
        let cellSize: CGFloat = 51
        
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

#Preview {
    @Previewable @State var document = GenkouYoushiDocument()
    ContentView(document: $document)
}

