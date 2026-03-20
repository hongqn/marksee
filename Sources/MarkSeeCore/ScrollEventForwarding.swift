import AppKit

/// Walks the ancestor chain of `view` collecting every `NSScrollView` encountered.
/// Returns the outermost one (last in the chain) when at least `minimumNesting` scroll
/// views are present — i.e. the pointer is inside nested scroll views.  Returns `nil`
/// when the view is inside fewer than `minimumNesting` scroll views (no nesting).
///
/// The default `minimumNesting` of 2 matches the MarkSee layout where a code-block's
/// horizontal scroller (inner) lives inside the document List's scroller (outer).
@MainActor
public func outermostNestedScrollView(
    from view: NSView,
    minimumNesting: Int = 2
) -> NSScrollView? {
    var scrollViews: [NSScrollView] = []
    var current: NSView? = view
    while let v = current {
        if let sv = v as? NSScrollView {
            scrollViews.append(sv)
        }
        current = v.superview
    }
    guard scrollViews.count >= minimumNesting else { return nil }
    return scrollViews.last
}

/// Returns `true` when `deltaY` is the dominant axis and non-zero — meaning the scroll
/// event should be treated as a vertical scroll and forwarded to the document scroller.
public func isMainlyVertical(deltaX: CGFloat, deltaY: CGFloat) -> Bool {
    deltaY != 0 && abs(deltaY) > abs(deltaX)
}
