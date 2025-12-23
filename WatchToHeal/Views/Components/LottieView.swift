import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    var name: String
    var loopMode: LottieLoopMode = .playOnce
    var animationSpeed: CGFloat = 1.0
    var playTrigger: Bool = false
    var initialProgress: AnimationProgressTime = 0 // Added to set initial frame
    var onComplete: (() -> Void)? = nil

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView()
        animationView.tag = 1001
        
        DotLottieFile.named(name) { result in
            switch result {
            case .success(let file):
                animationView.loadAnimation(from: file)
                setupAnimation(animationView, in: view)
            case .failure:
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
        animationView.currentProgress = initialProgress // Set initial progress
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        // ONLY play if playTrigger is true during setup
        if playTrigger {
            animationView.play { finished in
                if finished {
                    onComplete?()
                }
            }
        }
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let animationView = uiView.viewWithTag(1001) as? LottieAnimationView {
            if playTrigger && !animationView.isAnimationPlaying {
                animationView.play { finished in
                    if finished {
                        onComplete?()
                    }
                }
            } else if !playTrigger {
                animationView.stop()
                animationView.currentProgress = 0
            }
        }
    }
}
