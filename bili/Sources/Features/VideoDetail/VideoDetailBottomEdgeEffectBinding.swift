import UIKit

/// Own only our interaction; leave the system toolbar and scroll geometry intact.
/// The scroll edge effect APIs exist only on iOS 26; on iOS 18 the owning
/// scroll view skips the binding entirely (see below).
@available(iOS 26, *)
@MainActor
final class VideoDetailBottomEdgeEffectBinding {
    private var interaction: UIScrollEdgeElementContainerInteraction?
    private weak var scrollView: UIScrollView?
    private var originalStyle: UIScrollEdgeEffect.Style?
    private var originalHidden = false

    func update(scrollView: UIScrollView, container: UIView?, enabled: Bool, isActiveContent: Bool = true) {
        guard enabled, let container else {
            detach()
            return
        }
        if self.scrollView !== scrollView {
            detach()
            self.scrollView = scrollView
            originalStyle = scrollView.bottomEdgeEffect.style
            originalHidden = scrollView.bottomEdgeEffect.isHidden
        }
        // Both pages remain visible during the crossfade. Keep their setting-driven
        // style until blur is disabled; only transfer the toolbar interaction.
        if scrollView.bottomEdgeEffect.style != .soft {
            scrollView.bottomEdgeEffect.style = .soft
        }
        if scrollView.bottomEdgeEffect.isHidden {
            scrollView.bottomEdgeEffect.isHidden = false
        }
        guard isActiveContent else {
            detachInteraction()
            return
        }
        if interaction?.view === container { return }
        detachInteraction()
        let interaction = UIScrollEdgeElementContainerInteraction()
        interaction.scrollView = scrollView
        interaction.edge = .bottom
        container.addInteraction(interaction)
        self.interaction = interaction
    }

    func detach() {
        detachInteraction()
        if let scrollView, let originalStyle {
            scrollView.bottomEdgeEffect.style = originalStyle
            scrollView.bottomEdgeEffect.isHidden = originalHidden
        }
        scrollView = nil
        originalStyle = nil
    }

    private func detachInteraction() {
        if let interaction {
            interaction.view?.removeInteraction(interaction)
            interaction.scrollView = nil
        }
        interaction = nil
    }
}

@MainActor
final class VideoDetailEdgeEffectScrollView: UIScrollView {
    private var edgeBindingStorage: AnyObject?

    @available(iOS 26, *)
    private var edgeBinding: VideoDetailBottomEdgeEffectBinding {
        if let existing = edgeBindingStorage as? VideoDetailBottomEdgeEffectBinding {
            return existing
        }
        let binding = VideoDetailBottomEdgeEffectBinding()
        edgeBindingStorage = binding
        return binding
    }

    private var bottomEdgeBlurEnabled = false
    private var isActiveContent = false

    func configureBottomEdgeEffect(enabled: Bool, isActiveContent: Bool) {
        bottomEdgeBlurEnabled = enabled
        self.isActiveContent = isActiveContent
        updateBottomEdgeBinding()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateBottomEdgeBinding()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBottomEdgeBinding()
    }

    private func updateBottomEdgeBinding() {
        // Scroll edge effects are iOS 26-only; on iOS 18 there is nothing to bind.
        guard #available(iOS 26, *) else { return }
        guard bottomEdgeBlurEnabled, window != nil else {
            edgeBinding.detach()
            return
        }
        var responder: UIResponder? = self
        while let current = responder {
            if let controller = current as? UIViewController,
               let navigation = controller.navigationController {
                let toolbar = navigation.toolbar
                edgeBinding.update(scrollView: self, container: toolbar,
                                   enabled: !navigation.isToolbarHidden && toolbar?.isHidden == false,
                                   isActiveContent: isActiveContent)
                return
            }
            responder = current.next
        }
        edgeBinding.detach()
    }
}
