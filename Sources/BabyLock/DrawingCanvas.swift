// DrawingCanvas.swift — Sensory rainbow canvas & particle system
// Interactive drawing with rainbow trails, confetti particles, and geometric shapes

import AppKit

// MARK: - Rainbow Palette

struct RainbowPalette {
    static let colors: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [
        (255/255, 82/255,  82/255),   // Coral Red
        (255/255, 145/255, 0/255),    // Orange
        (255/255, 215/255, 64/255),   // Warm Gold
        (118/255, 255/255, 3/255),    // Lime Green
        (0/255,   230/255, 118/255),  // Spring Green
        (24/255,  255/255, 255/255),  // Electric Teal
        (68/255,  138/255, 255/255),  // Sky Blue
        (124/255, 77/255,  255/255),  // Violet
        (224/255, 64/255,  251/255),  // Purple
        (255/255, 64/255,  129/255),  // Hot Pink
    ]

    static func color(at index: Int) -> NSColor {
        let c = colors[index % colors.count]
        return NSColor(red: c.r, green: c.g, blue: c.b, alpha: 1.0)
    }

    static var count: Int { colors.count }
}

// MARK: - Data Structures

struct TrailSegment {
    var x1: CGFloat, y1: CGFloat
    var x2: CGFloat, y2: CGFloat
    var colorIndex: Int
    var createdAt: CFTimeInterval
    let lifetime: CFTimeInterval = 2.0
    let thickness: CGFloat = 18.0

    var age: CFTimeInterval { CACurrentMediaTime() - createdAt }
    var alpha: CGFloat { max(0, 1.0 - CGFloat(age / lifetime)) }
    var isExpired: Bool { age >= lifetime }
}

struct Particle {
    var x: CGFloat, y: CGFloat
    var vx: CGFloat, vy: CGFloat
    var colorIndex: Int
    var createdAt: CFTimeInterval
    let lifetime: CFTimeInterval = 1.2
    let gravity: CGFloat = 400.0
    var size: CGFloat = 8.0
    var shape: ParticleShape = .star

    enum ParticleShape {
        case star, heart, circle
    }

    var age: CFTimeInterval { CACurrentMediaTime() - createdAt }
    var alpha: CGFloat { max(0, 1.0 - CGFloat(age / lifetime)) }
    var isExpired: Bool { age >= lifetime }

    mutating func update(dt: CGFloat) {
        x += vx * dt
        y += vy * dt
        vy += gravity * dt
    }
}

struct StampedShape {
    var x: CGFloat, y: CGFloat
    var colorIndex: Int
    var createdAt: CFTimeInterval
    var shapeType: ShapeType
    let lifetime: CFTimeInterval = 3.0
    var size: CGFloat = 40.0

    enum ShapeType: CaseIterable {
        case circle, square, triangle, star, diamond, hexagon
    }

    var age: CFTimeInterval { CACurrentMediaTime() - createdAt }
    var alpha: CGFloat { max(0, 1.0 - CGFloat(age / lifetime)) }
    var isExpired: Bool { age >= lifetime }
}

// MARK: - Drawing Canvas View

class DrawingCanvasView: NSView {

    // Bounded pools (zero allocation during animation)
    static let MAX_TRAIL_SEGMENTS = 512
    static let MAX_PARTICLES = 128
    static let MAX_SHAPES = 32

    private var trails: [TrailSegment] = []
    private var particles: [Particle] = []
    private var shapes: [StampedShape] = []

    private var currentColorIndex = 0
    private var lastMousePos: NSPoint?
    private var animationTimer: Timer?
    private var lastUpdateTime: CFTimeInterval = 0

    var isActive = false {
        didSet {
            if isActive {
                startAnimation()
            } else {
                stopAnimation()
                clear()
            }
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Animation Loop

    func startAnimation() {
        guard animationTimer == nil else { return }
        lastUpdateTime = CACurrentMediaTime()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = CGFloat(now - lastUpdateTime)
        lastUpdateTime = now

        // Update particles
        for i in 0..<particles.count {
            particles[i].update(dt: dt)
        }

        // Remove expired elements
        trails.removeAll { $0.isExpired }
        particles.removeAll { $0.isExpired }
        shapes.removeAll { $0.isExpired }

        needsDisplay = true
    }

    func clear() {
        trails.removeAll()
        particles.removeAll()
        shapes.removeAll()
        lastMousePos = nil
        needsDisplay = true
    }

    // MARK: - Input Handling (called from event tap)

    func addMousePosition(_ point: NSPoint) {
        let flipped = NSPoint(x: point.x, y: bounds.height - point.y)

        if let last = lastMousePos {
            let dist = hypot(flipped.x - last.x, flipped.y - last.y)
            if dist > 2.0 { // Min distance threshold
                let segment = TrailSegment(
                    x1: last.x, y1: last.y,
                    x2: flipped.x, y2: flipped.y,
                    colorIndex: currentColorIndex,
                    createdAt: CACurrentMediaTime()
                )

                if trails.count >= DrawingCanvasView.MAX_TRAIL_SEGMENTS {
                    trails.removeFirst()
                }
                trails.append(segment)

                // Slowly cycle rainbow color
                if dist > 20 {
                    currentColorIndex = (currentColorIndex + 1) % RainbowPalette.count
                }
            }
        }
        lastMousePos = flipped
    }

    func addClickBurst(at point: NSPoint) {
        let flipped = NSPoint(x: point.x, y: bounds.height - point.y)

        // Spawn 16 confetti particles
        for _ in 0..<16 {
            guard particles.count < DrawingCanvasView.MAX_PARTICLES else { break }

            let angle = CGFloat.random(in: 0..<(.pi * 2))
            let speed = CGFloat.random(in: 150...450)

            var particle = Particle(
                x: flipped.x, y: flipped.y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed * -1, // Flip for Cocoa coords
                colorIndex: Int.random(in: 0..<RainbowPalette.count),
                createdAt: CACurrentMediaTime()
            )
            particle.size = CGFloat.random(in: 6...14)
            particle.shape = [Particle.ParticleShape.star, .heart, .circle].randomElement()!
            particles.append(particle)
        }
    }

    func addKeyStamp(at point: NSPoint?) {
        let pos = point ?? NSPoint(
            x: CGFloat.random(in: 100...(bounds.width - 100)),
            y: CGFloat.random(in: 100...(bounds.height - 100))
        )

        guard shapes.count < DrawingCanvasView.MAX_SHAPES else { return }

        shapes.append(StampedShape(
            x: pos.x, y: pos.y,
            colorIndex: currentColorIndex,
            createdAt: CACurrentMediaTime(),
            shapeType: StampedShape.ShapeType.allCases.randomElement()!,
            size: CGFloat.random(in: 30...60)
        ))

        currentColorIndex = (currentColorIndex + 1) % RainbowPalette.count
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.clear(bounds)

        // Draw trails
        for trail in trails {
            let color = RainbowPalette.color(at: trail.colorIndex).withAlphaComponent(trail.alpha)
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(trail.thickness * trail.alpha)
            ctx.setLineCap(.round)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: trail.x1, y: trail.y1))
            ctx.addLine(to: CGPoint(x: trail.x2, y: trail.y2))
            ctx.strokePath()

            // Glow effect
            if trail.alpha > 0.3 {
                let glowColor = RainbowPalette.color(at: trail.colorIndex).withAlphaComponent(trail.alpha * 0.3)
                ctx.setStrokeColor(glowColor.cgColor)
                ctx.setLineWidth(trail.thickness * trail.alpha * 2.5)
                ctx.beginPath()
                ctx.move(to: CGPoint(x: trail.x1, y: trail.y1))
                ctx.addLine(to: CGPoint(x: trail.x2, y: trail.y2))
                ctx.strokePath()
            }
        }

        // Draw shapes
        for shape in shapes {
            let color = RainbowPalette.color(at: shape.colorIndex).withAlphaComponent(shape.alpha)
            ctx.setFillColor(color.cgColor)
            drawShape(ctx: ctx, shape: shape)
        }

        // Draw particles
        for particle in particles {
            let color = RainbowPalette.color(at: particle.colorIndex).withAlphaComponent(particle.alpha)
            ctx.setFillColor(color.cgColor)
            let rect = CGRect(x: particle.x - particle.size/2,
                            y: particle.y - particle.size/2,
                            width: particle.size, height: particle.size)
            switch particle.shape {
            case .circle:
                ctx.fillEllipse(in: rect)
            case .star:
                drawStar(ctx: ctx, center: CGPoint(x: particle.x, y: particle.y),
                        size: particle.size, points: 5)
            case .heart:
                drawHeart(ctx: ctx, center: CGPoint(x: particle.x, y: particle.y),
                         size: particle.size)
            }
        }
    }

    // MARK: - Shape Drawing Helpers

    private func drawShape(ctx: CGContext, shape: StampedShape) {
        let center = CGPoint(x: shape.x, y: shape.y)
        let s = shape.size * CGFloat(min(1.0, shape.age * 4 + 0.3)) // Scale-in animation

        switch shape.shapeType {
        case .circle:
            ctx.fillEllipse(in: CGRect(x: center.x - s/2, y: center.y - s/2, width: s, height: s))
        case .square:
            ctx.fill(CGRect(x: center.x - s/2, y: center.y - s/2, width: s, height: s))
        case .triangle:
            ctx.beginPath()
            ctx.move(to: CGPoint(x: center.x, y: center.y + s/2))
            ctx.addLine(to: CGPoint(x: center.x - s/2, y: center.y - s/2))
            ctx.addLine(to: CGPoint(x: center.x + s/2, y: center.y - s/2))
            ctx.closePath()
            ctx.fillPath()
        case .star:
            drawStar(ctx: ctx, center: center, size: s, points: 5)
        case .diamond:
            ctx.beginPath()
            ctx.move(to: CGPoint(x: center.x, y: center.y + s/2))
            ctx.addLine(to: CGPoint(x: center.x - s/3, y: center.y))
            ctx.addLine(to: CGPoint(x: center.x, y: center.y - s/2))
            ctx.addLine(to: CGPoint(x: center.x + s/3, y: center.y))
            ctx.closePath()
            ctx.fillPath()
        case .hexagon:
            ctx.beginPath()
            for i in 0..<6 {
                let angle = CGFloat(i) * .pi / 3 - .pi / 6
                let px = center.x + cos(angle) * s/2
                let py = center.y + sin(angle) * s/2
                if i == 0 { ctx.move(to: CGPoint(x: px, y: py)) }
                else { ctx.addLine(to: CGPoint(x: px, y: py)) }
            }
            ctx.closePath()
            ctx.fillPath()
        }
    }

    private func drawStar(ctx: CGContext, center: CGPoint, size: CGFloat, points: Int) {
        let outerRadius = size / 2
        let innerRadius = outerRadius * 0.4
        ctx.beginPath()
        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let radius = (i % 2 == 0) ? outerRadius : innerRadius
            let px = center.x + cos(angle) * radius
            let py = center.y + sin(angle) * radius
            if i == 0 { ctx.move(to: CGPoint(x: px, y: py)) }
            else { ctx.addLine(to: CGPoint(x: px, y: py)) }
        }
        ctx.closePath()
        ctx.fillPath()
    }

    private func drawHeart(ctx: CGContext, center: CGPoint, size: CGFloat) {
        let s = size * 0.5
        ctx.beginPath()
        ctx.move(to: CGPoint(x: center.x, y: center.y - s * 0.4))
        ctx.addCurve(to: CGPoint(x: center.x, y: center.y + s),
                    control1: CGPoint(x: center.x - s, y: center.y - s),
                    control2: CGPoint(x: center.x - s * 0.3, y: center.y + s * 0.6))
        ctx.move(to: CGPoint(x: center.x, y: center.y - s * 0.4))
        ctx.addCurve(to: CGPoint(x: center.x, y: center.y + s),
                    control1: CGPoint(x: center.x + s, y: center.y - s),
                    control2: CGPoint(x: center.x + s * 0.3, y: center.y + s * 0.6))
        ctx.closePath()
        ctx.fillPath()
    }
}
