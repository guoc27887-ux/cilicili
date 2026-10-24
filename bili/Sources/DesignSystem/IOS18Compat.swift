import SwiftUI

// iOS 18 compatibility shims for APIs introduced in iOS 26.
//
// The project originally targeted iOS 26.1. These helpers keep the iOS 26
// code path identical in behavior and appearance, while iOS 18 falls back to
// the closest pre-iOS 26 equivalent (usually a material background, a plain
// spacer, or no scroll-edge treatment at all). Every iOS 26-only symbol is
// referenced exclusively inside `if #available(iOS 26, *)` branches so the
// module compiles with an iOS 18 deployment target.

// MARK: - Glass effect container

/// Drop-in replacement for SwiftUI's `GlassEffectContainer` (iOS 26).
/// On iOS 18 the container's cross-view glass blending is unavailable, so the
/// content renders directly; the child views' own `bili*GlassEffect` modifiers
/// already fall back to `.ultraThinMaterial` backgrounds there.
struct CompatGlassEffectContainer<Content: View>: View {
    let spacing: CGFloat?
    @ViewBuilder let content: () -> Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        if #available(iOS 26, *) {
            CompatGlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}

// MARK: - Glass effect

private struct CompatGlassEffectModifier<GlassShape: Shape>: ViewModifier {
    let interactive: Bool
    let shape: GlassShape

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(
                .regular.interactive(interactive),
                in: shape
            )
        } else {
            content.background(.ultraThinMaterial, in: shape)
        }
    }
}

extension View {
    /// Equivalent of `glassEffect(.regular[.interactive()], in:)` on iOS 26,
    /// with an `.ultraThinMaterial` background fallback on iOS 18.
    @ViewBuilder
    func compatGlassEffect<S: Shape>(
        interactive: Bool = false,
        in shape: S
    ) -> some View {
        modifier(
            CompatGlassEffectModifier(interactive: interactive, shape: shape)
        )
    }
}

// MARK: - Scroll edge effects

extension View {
    /// Equivalent of `scrollEdgeEffectStyle(.soft, for:)` on iOS 26.
    /// Scroll edge effects do not exist before iOS 26, so this is a no-op
    /// on iOS 18.
    @ViewBuilder
    func compatScrollEdgeEffectStyleSoft(for edges: Edge.Set) -> some View {
        if #available(iOS 26, *) {
            scrollEdgeEffectStyle(.soft, for: edges)
        } else {
            self
        }
    }
}

// MARK: - Tab bar minimize behavior

private struct CompatTabBarMinimizeBehaviorModifier: ViewModifier {
    let minimizeOnScroll: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.tabBarMinimizeBehavior(minimizeOnScroll ? .onScrollDown : .never)
        } else {
            content
        }
    }
}

extension View {
    /// Equivalent of `tabBarMinimizeBehavior(_:)` on iOS 26. Tab bars cannot
    /// minimize on scroll before iOS 26, so this is a no-op on iOS 18.
    func compatTabBarMinimizeBehavior(_ minimizeOnScroll: Bool) -> some View {
        modifier(CompatTabBarMinimizeBehaviorModifier(minimizeOnScroll: minimizeOnScroll))
    }
}

// MARK: - Toolbar spacer

/// Equivalent of `ToolbarSpacer(.flexible, placement:)` on iOS 26. Before
/// iOS 26 a plain `Spacer()` inside a toolbar provided the same flexible
/// space, so it is used as the fallback.
struct CompatFlexibleToolbarSpacer: ToolbarContent {
    let placement: ToolbarItemPlacement

    var body: some ToolbarContent {
        if #available(iOS 26, *) {
            ToolbarSpacer(.flexible, placement: placement)
        } else {
            Spacer()
        }
    }
}

// MARK: - Safe area bar

extension View {
    /// Equivalent of `safeAreaBar(edge: .top, alignment: .leading, spacing:)`
    /// on iOS 26, falling back to `safeAreaInset` on iOS 18.
    @ViewBuilder
    func compatTopSafeAreaBar<Accessory: View>(
        spacing: CGFloat = 0,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) -> some View {
        if #available(iOS 26, *) {
            safeAreaBar(edge: .top, alignment: .leading, spacing: spacing) {
                accessory()
            }
        } else {
            safeAreaInset(edge: .top, alignment: .leading, spacing: spacing) {
                accessory()
            }
        }
    }
}

// MARK: - Tab view bottom accessory

extension View {
    /// Equivalent of `tabViewBottomAccessory(isEnabled:content:)` on iOS 26.
    /// On iOS 18 the accessory is approximated with a bottom safe-area inset
    /// shown under the same `isEnabled` condition.
    @ViewBuilder
    func compatTabViewBottomAccessory<Accessory: View>(
        isEnabled: Bool,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) -> some View {
        if #available(iOS 26, *) {
            tabViewBottomAccessory(isEnabled: isEnabled) {
                accessory()
            }
        } else if isEnabled {
            safeAreaInset(edge: .bottom, spacing: 0) {
                accessory()
            }
        } else {
            self
        }
    }
}
