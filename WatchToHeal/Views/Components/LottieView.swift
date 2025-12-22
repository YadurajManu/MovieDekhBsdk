import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    var name: String
    var loopMode: LottieLoopMode = .playOnce
    var animationSpeed: CGFloat = 1.0
    var onComplete: (() -> Void)? = nil

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView()
        
        // Try loading as .lottie first then fallback to .json
        DotLottieFile.named(name) { result in
            switch result {
            case .success(let file):
                animationView.loadAnimation(from: file)
                setupAnimation(animationView, in: view)
            case .failure:
                // Fallback to standard json search if .lottie isn't found/ready
                animationView.animation = LottieAnimation.named(name)
                setupAnimation(animationView, in: view)
            }
        }
        
        return view
    }

    private func setupAnimation(_ animationView: LottieAnimationView, in view: UIView) {
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        animationView.play { finished in
            if finished {
                onComplete?()
            }
        }
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
