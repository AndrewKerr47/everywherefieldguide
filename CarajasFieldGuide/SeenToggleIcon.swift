import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// SeenToggleIcon.swift
// Carajás Field Guide
//
// SwiftUI recreation of the seen/unseen toggle icons.
// Matches SVG spec exactly: 47×24pt pill, 12pt radius circle, checkmark path.
//
// Unseen: grey pill outline, grey circle left, grey checkmark (invisible)
// Seen:   grey pill outline, green circle right, white checkmark
// ─────────────────────────────────────────────────────────────────────────────

struct SeenToggleIcon: View {

    let isSeen: Bool

    // SVG constants
    private let width: CGFloat  = 47
    private let height: CGFloat = 24
    private let circleR: CGFloat = 12
    private let strokeColor = Color(hex: "5B5B5B")
    private let seenGreen   = Color(hex: "5FDB63")

    var body: some View {
        ZStack {
            // ── Pill outline ──────────────────────────────────────────────────
            Capsule()
                .stroke(strokeColor, lineWidth: 1)
                .frame(width: width, height: height)

            // ── Circle — left (unseen) or right (seen) ────────────────────────
            Circle()
                .fill(isSeen ? seenGreen : strokeColor)
                .frame(width: circleR * 2, height: circleR * 2)
                .offset(x: isSeen ? (width / 2 - circleR) : -(width / 2 - circleR))

            // ── Checkmark — white when seen, hidden when unseen ───────────────
            // SVG path: M29,12.667 L33.216,17 L41,9 (in 47×24 space)
            // Normalised to centre of right circle at (35,12)
            CheckmarkShape()
                .stroke(
                    isSeen ? Color.white : Color.clear,
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(width: width, height: height)
        }
        .frame(width: width, height: height)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Checkmark shape
// ─────────────────────────────────────────────────────────────────────────────
// SVG path in 47×24 space:
//   M 29 12.6667 L 33.2162 17 L 41 9
// Matches the right circle centred at (35, 12)

private struct CheckmarkShape: Shape {

    func path(in rect: CGRect) -> Path {
        // Scale from SVG 47×24 to actual rect
        let sx = rect.width  / 47
        let sy = rect.height / 24

        var path = Path()
        path.move(to:    CGPoint(x: 29 * sx, y: 12.6667 * sy))
        path.addLine(to: CGPoint(x: 33.2162 * sx, y: 17 * sy))
        path.addLine(to: CGPoint(x: 41 * sx, y: 9 * sy))
        return path
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────────────────────────────────────

#Preview {
    VStack(spacing: 24) {
        SeenToggleIcon(isSeen: false)
        SeenToggleIcon(isSeen: true)
    }
    .padding()
    .background(Color.black)
}
