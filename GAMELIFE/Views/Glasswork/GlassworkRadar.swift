//
//  GlassworkRadar.swift
//  GAMELIFE
//
//  Six-axis radar chart. Mirrors the SVG version in system.jsx — fill is a
//  radial cyan→pink gradient, stroke is a linear cyan→pink gradient,
//  vertices marked with a small ink dot.
//

import SwiftUI

struct GWRadar: View {
    let stats: [GWStat]
    var size: CGFloat = 200
    var dim: Bool = false

    var body: some View {
        ZStack {
            RingsLayer(stats: stats, size: size)
            SpokesLayer(stats: stats, size: size)
            FillLayer(stats: stats, size: size, dim: dim)
            StrokeLayer(stats: stats, size: size)
            VertexLayer(stats: stats, size: size)
            LabelsLayer(stats: stats, size: size)
        }
        .frame(width: size, height: size)
    }

    fileprivate static func angle(_ i: Int, count: Int) -> CGFloat {
        .pi * 2 * CGFloat(i) / CGFloat(count) - .pi / 2
    }

    fileprivate static func point(_ i: Int,
                                  _ t: CGFloat,
                                  count: Int,
                                  size: CGFloat) -> CGPoint {
        let r = size * 0.4
        let c = CGPoint(x: size / 2, y: size / 2)
        let a = angle(i, count: count)
        return CGPoint(x: c.x + cos(a) * r * t,
                       y: c.y + sin(a) * r * t)
    }
}

private struct RingsLayer: View {
    let stats: [GWStat]
    let size: CGFloat
    var body: some View {
        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { t in
            Path { p in
                for i in 0..<stats.count {
                    let pt = GWRadar.point(i, CGFloat(t),
                                           count: stats.count,
                                           size: size)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
            }
            .stroke(Color.white.opacity(0.07), lineWidth: 1)
        }
    }
}

private struct SpokesLayer: View {
    let stats: [GWStat]
    let size: CGFloat
    var body: some View {
        ForEach(0..<stats.count, id: \.self) { i in
            Path { p in
                p.move(to: CGPoint(x: size / 2, y: size / 2))
                p.addLine(to: GWRadar.point(i, 1,
                                            count: stats.count,
                                            size: size))
            }
            .stroke(Color.white.opacity(0.05), lineWidth: 1)
        }
    }
}

private struct StatPolygon: Shape {
    let stats: [GWStat]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)
        for i in 0..<stats.count {
            let t = CGFloat(stats[i].value) / CGFloat(stats[i].max)
            let pt = GWRadar.point(i, t, count: stats.count, size: size)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

private struct FillLayer: View {
    let stats: [GWStat]
    let size: CGFloat
    let dim: Bool
    var body: some View {
        StatPolygon(stats: stats)
            .fill(
                RadialGradient(
                    colors: [GW.cyan.opacity(dim ? 0.25 : 0.5),
                             GW.pink.opacity(dim ? 0.12 : 0.25)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.4
                )
            )
    }
}

private struct StrokeLayer: View {
    let stats: [GWStat]
    let size: CGFloat
    var body: some View {
        StatPolygon(stats: stats)
            .stroke(
                LinearGradient(colors: [GW.cyan, GW.pink],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing),
                style: StrokeStyle(lineWidth: 1.5, lineJoin: .round)
            )
    }
}

private struct VertexLayer: View {
    let stats: [GWStat]
    let size: CGFloat
    var body: some View {
        ForEach(0..<stats.count, id: \.self) { i in
            let t = CGFloat(stats[i].value) / CGFloat(stats[i].max)
            let p = GWRadar.point(i, t, count: stats.count, size: size)
            ZStack {
                Circle().fill(GW.ink)
                Circle().strokeBorder(
                    LinearGradient(colors: [GW.cyan, GW.pink],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
            }
            .frame(width: 6, height: 6)
            .position(p)
        }
    }
}

private struct LabelsLayer: View {
    let stats: [GWStat]
    let size: CGFloat
    var body: some View {
        ForEach(0..<stats.count, id: \.self) { i in
            let p = GWRadar.point(i, 1.18, count: stats.count, size: size)
            Text(stats[i].key)
                .font(GW.mono(10, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(GW.mute)
                .position(p)
        }
    }
}
