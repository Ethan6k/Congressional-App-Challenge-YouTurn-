//
//  YouTurnLogo.swift
//  TestApp
//
//  The YouTurn logo drawn in code from Branding/YouTurnLogo.svg, so it stays
//  sharp at any size: a gray line going down, curving around, and turning
//  back up as an amber arrow.
//

import SwiftUI

struct YouTurnLogo: View {
    /// Draw the navy rounded square behind the mark.
    var showsBackground = true

    var body: some View {
        Canvas { context, size in
            // The SVG is 180 × 180 units; scale it to whatever size we're given.
            let scale = min(size.width, size.height) / 180
            context.scaleBy(x: scale, y: scale)

            if showsBackground {
                context.fill(
                    Path(roundedRect: CGRect(x: 0, y: 0, width: 180, height: 180), cornerRadius: 40),
                    with: .color(Theme.navy)
                )
            }

            // Left side: straight down, then curve to the bottom middle.
            var down = Path()
            down.move(to: CGPoint(x: 58, y: 50))
            down.addArc(tangent1End: CGPoint(x: 58, y: 153), tangent2End: CGPoint(x: 90, y: 153), radius: 32)
            context.stroke(down, with: .color(Theme.slate), style: StrokeStyle(lineWidth: 14))

            // Right side: curve from the bottom middle and head back up.
            var up = Path()
            up.move(to: CGPoint(x: 90, y: 153))
            up.addArc(tangent1End: CGPoint(x: 122, y: 153), tangent2End: CGPoint(x: 122, y: 58), radius: 32)
            up.addLine(to: CGPoint(x: 122, y: 58))
            context.stroke(up, with: .color(Theme.amber), style: StrokeStyle(lineWidth: 14, lineCap: .round))

            // Arrowhead
            var arrow = Path()
            arrow.move(to: CGPoint(x: 100, y: 60))
            arrow.addLine(to: CGPoint(x: 122, y: 26))
            arrow.addLine(to: CGPoint(x: 144, y: 60))
            arrow.closeSubpath()
            context.fill(arrow, with: .color(Theme.amber))
            context.stroke(arrow, with: .color(Theme.amber), style: StrokeStyle(lineWidth: 5, lineJoin: .round))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("YouTurn logo")
    }
}

#Preview {
    YouTurnLogo()
        .frame(width: 200)
        .padding()
}
