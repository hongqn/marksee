import Testing
import AppKit
@testable import MarkSeeCore

@Suite("ScrollEventForwarding")
@MainActor
struct ScrollEventForwardingTests {

    // MARK: - outermostNestedScrollView

    @Test("returns nil when view has no scroll view ancestor")
    func noScrollView() {
        let leaf = NSView()
        let parent = NSView()
        parent.addSubview(leaf)
        #expect(outermostNestedScrollView(from: leaf) == nil)
    }

    @Test("returns nil when only one scroll view in the chain")
    func singleScrollView() {
        let leaf = NSView()
        let scroll = NSScrollView()
        scroll.addSubview(leaf)
        #expect(outermostNestedScrollView(from: leaf) == nil)
    }

    @Test("returns outermost when two scroll views are nested")
    func twoNestedScrollViews() {
        let leaf = NSView()
        let inner = NSScrollView()
        let outer = NSScrollView()
        inner.addSubview(leaf)
        outer.addSubview(inner)

        let result = outermostNestedScrollView(from: leaf)
        #expect(result === outer)
    }

    @Test("returns outermost when three scroll views are nested")
    func threeNestedScrollViews() {
        let leaf = NSView()
        let inner = NSScrollView()
        let middle = NSScrollView()
        let outer = NSScrollView()
        inner.addSubview(leaf)
        middle.addSubview(inner)
        outer.addSubview(middle)

        let result = outermostNestedScrollView(from: leaf)
        #expect(result === outer)
    }

    @Test("non-scrollview ancestors between scroll views are ignored")
    func intermediatePlainViews() {
        let leaf = NSView()
        let inner = NSScrollView()
        let plain = NSView()
        let outer = NSScrollView()
        inner.addSubview(leaf)
        plain.addSubview(inner)
        outer.addSubview(plain)

        let result = outermostNestedScrollView(from: leaf)
        #expect(result === outer)
    }

    @Test("custom minimumNesting: returns nil when depth is below threshold")
    func customMinimumNestingNotMet() {
        let leaf = NSView()
        let scroll = NSScrollView()
        scroll.addSubview(leaf)
        // Require 3 levels but only 1 present
        #expect(outermostNestedScrollView(from: leaf, minimumNesting: 3) == nil)
    }

    @Test("custom minimumNesting: returns outermost when depth meets threshold")
    func customMinimumNestingMet() {
        let leaf = NSView()
        let inner = NSScrollView()
        let outer = NSScrollView()
        inner.addSubview(leaf)
        outer.addSubview(inner)
        // Require only 1 level — any scroll view qualifies
        let result = outermostNestedScrollView(from: leaf, minimumNesting: 1)
        #expect(result === outer)
    }

    // MARK: - isMainlyVertical

    @Test("true when deltaY dominates and is non-zero")
    func mainlyVertical() {
        #expect(isMainlyVertical(deltaX: 0, deltaY: 10))
        #expect(isMainlyVertical(deltaX: 1, deltaY: 10))
        #expect(isMainlyVertical(deltaX: -1, deltaY: -5))
    }

    @Test("false when deltaY is zero")
    func zeroVertical() {
        #expect(!isMainlyVertical(deltaX: 0, deltaY: 0))
        #expect(!isMainlyVertical(deltaX: 5, deltaY: 0))
    }

    @Test("false when deltaX dominates")
    func mainlyHorizontal() {
        #expect(!isMainlyVertical(deltaX: 10, deltaY: 1))
        #expect(!isMainlyVertical(deltaX: -10, deltaY: 3))
    }

    @Test("false when deltaX equals deltaY (not strictly dominant)")
    func equalDeltas() {
        #expect(!isMainlyVertical(deltaX: 5, deltaY: 5))
        #expect(!isMainlyVertical(deltaX: -3, deltaY: 3))
    }
}
