import PencilKit

class MyCanvasView: UIView {

    var canvasView: PKCanvasView = {
        let view = PKCanvasView()
        view.drawingPolicy = .anyInput
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()

    required init? (coder: NSCoder) {
        fatalError ("init(coder:) has not been implemented" )
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(canvasView)
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: topAnchor),
            canvasView.trailingAnchor.constraint(equalTo: trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])
    }
}
