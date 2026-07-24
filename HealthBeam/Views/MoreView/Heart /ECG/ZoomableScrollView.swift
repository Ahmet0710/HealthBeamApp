import SwiftUI

struct ZoomableScrollView<Content: View>: UIViewControllerRepresentable {
    private var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIViewController(context: Context) -> ContainerViewController<Content> {
        let viewController = ContainerViewController(hostingController: context.coordinator.hostingController)
        viewController.configureScrollView(delegate: context.coordinator)
        return viewController
    }

    func updateUIViewController(_ uiViewController: ContainerViewController<Content>, context: Context) {
        context.coordinator.hostingController.rootView = self.content
        uiViewController.updateContentSize()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(hostingController: UIHostingController(rootView: self.content))
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>

        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController.view
        }
    }
}

final class ContainerViewController<Content: View>: UIViewController {
    let scrollView = UIScrollView()
    let hostingController: UIHostingController<Content>

    init(hostingController: UIHostingController<Content>) {
        self.hostingController = hostingController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        scrollView.backgroundColor = .white
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        addChild(hostingController)
        hostingController.loadViewIfNeeded()

        guard let hostedView = hostingController.view else {
            return
        }
        hostedView.backgroundColor = .white
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.frame = scrollView.bounds

        scrollView.addSubview(hostedView)
        hostingController.didMove(toParent: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentSize()
    }

    func configureScrollView(delegate: UIScrollViewDelegate) {
        scrollView.delegate = delegate
        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 1.0
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
    }

    func updateContentSize() {
        hostingController.loadViewIfNeeded()

        guard let hostedView = hostingController.view else {
            return
        }
        hostedView.backgroundColor = .white
        hostedView.frame.size = hostingController.sizeThatFits(
            in: CGSize(
                width: scrollView.bounds.width,
                height: CGFloat.greatestFiniteMagnitude
            )
        )
        scrollView.contentSize = hostedView.frame.size
    }
}
