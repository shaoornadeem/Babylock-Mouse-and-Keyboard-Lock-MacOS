// OverlayWindow.swift — Fullscreen overlay & floating HUD
// Transparent topmost windows for phonics cards, drawing, and lock indicator

import AppKit

// MARK: - Overlay Manager

class OverlayManager {
    private var overlayWindows: [NSWindow] = []
    private var hudWindow: NSWindow?
    private var overlayViews: [OverlayContentView] = []
    private var hudView: LockHUDView?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Show / Hide

    func show() {
        hide() // Clear any existing

        // Create an overlay window for each screen
        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen)
            let contentView = OverlayContentView(frame: screen.frame)
            window.contentView = contentView
            window.orderFrontRegardless()
            overlayWindows.append(window)
            overlayViews.append(contentView)
        }

        // Create HUD on primary screen
        if let mainScreen = NSScreen.main {
            createHUD(on: mainScreen)
        }
    }

    func hide() {
        for view in overlayViews {
            view.drawingCanvas.isActive = false
        }
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
        overlayViews.removeAll()

        hudWindow?.orderOut(nil)
        hudWindow = nil
        hudView = nil
    }

    // MARK: - Window Creation

    private func createOverlayWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.level = .screenSaver
        window.backgroundColor = NSColor.black.withAlphaComponent(0.15)
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isReleasedWhenClosed = false
        return window
    }

    private func createHUD(on screen: NSScreen) {
        let hudWidth: CGFloat = 380
        let hudHeight: CGFloat = 80
        let padding: CGFloat = 20

        let hudFrame = NSRect(
            x: screen.frame.maxX - hudWidth - padding,
            y: screen.frame.maxY - hudHeight - padding - 25, // Account for menu bar
            width: hudWidth,
            height: hudHeight
        )

        let window = NSWindow(
            contentRect: hudFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isReleasedWhenClosed = false

        let hud = LockHUDView(frame: NSRect(x: 0, y: 0, width: hudWidth, height: hudHeight))
        window.contentView = hud
        window.orderFrontRegardless()

        hudWindow = window
        hudView = hud
    }

    // MARK: - Content Updates

    func showPhonicsCard(letter: String, word: String, emoji: String) {
        let duration = appState.cardDuration.seconds
        for view in overlayViews {
            view.showCard(topText: emoji, bottomText: "\(letter) is for \(word)!", duration: duration)
        }
    }

    func showNumberCard(digit: String, word: String, emoji: String) {
        let duration = appState.cardDuration.seconds
        for view in overlayViews {
            view.showCard(topText: emoji, bottomText: "\(digit) — \(word)", duration: duration)
        }
    }

    func showThemeCard(name: String, emoji: String) {
        let duration = appState.cardDuration.seconds
        for view in overlayViews {
            view.showCard(topText: emoji, bottomText: name, duration: duration)
        }
    }

    func showNoteVisualization(noteIndex: Int) {
        let colors = RainbowPalette.colors
        let c = colors[noteIndex % colors.count]
        let color = NSColor(red: c.r, green: c.g, blue: c.b, alpha: 1.0)
        for view in overlayViews {
            view.showNoteFlash(color: color, noteIndex: noteIndex)
        }
    }

    func updateHUD(timeRemaining: String, mode: String) {
        let hint = appState.shortcutSettings.hudInstructionText
        let chordNames = "\(appState.shortcutSettings.chordKey1Name)+\(appState.shortcutSettings.chordKey2Name)"
        hudView?.update(timeRemaining: timeRemaining, mode: mode, shortcutHint: hint, chordNames: chordNames)
    }

    func updateHoldProgress(_ progress: Double) {
        hudView?.updateHoldProgress(progress)
    }

    // MARK: - Drawing Mode

    func activateDrawingMode() {
        for view in overlayViews {
            view.drawingCanvas.isActive = true
        }
    }

    func deactivateDrawingMode() {
        for view in overlayViews {
            view.drawingCanvas.isActive = false
        }
    }

    func feedMousePosition(_ point: NSPoint) {
        for view in overlayViews {
            view.drawingCanvas.addMousePosition(point)
        }
    }

    func feedClickBurst(at point: NSPoint) {
        for view in overlayViews {
            view.drawingCanvas.addClickBurst(at: point)
        }
    }

    func feedKeyStamp() {
        for view in overlayViews {
            view.drawingCanvas.addKeyStamp(at: nil)
        }
    }
}

// MARK: - Overlay Content View

class OverlayContentView: NSView {

    let drawingCanvas: DrawingCanvasView
    private var cardLayer: CALayer?
    private var cardEmojiLayer: CATextLayer?
    private var cardTextLayer: CATextLayer?
    private var noteFlashLayer: CALayer?

    override init(frame frameRect: NSRect) {
        drawingCanvas = DrawingCanvasView(frame: NSRect(origin: .zero, size: frameRect.size))
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        addSubview(drawingCanvas)
        setupCardLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        drawingCanvas.frame = bounds
    }

    private func setupCardLayers() {
        // Card background
        let card = CALayer()
        card.cornerRadius = 30
        card.backgroundColor = NSColor.black.withAlphaComponent(0.7).cgColor
        card.borderColor = NSColor.white.withAlphaComponent(0.3).cgColor
        card.borderWidth = 2
        card.isHidden = true
        card.shadowColor = NSColor.black.cgColor
        card.shadowOpacity = 0.5
        card.shadowRadius = 20
        card.shadowOffset = CGSize(width: 0, height: -5)
        layer?.addSublayer(card)
        cardLayer = card

        // Emoji text
        let emojiLayer = CATextLayer()
        emojiLayer.fontSize = 120
        emojiLayer.alignmentMode = .center
        emojiLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        emojiLayer.isHidden = true
        layer?.addSublayer(emojiLayer)
        cardEmojiLayer = emojiLayer

        // Word text
        let textLayer = CATextLayer()
        textLayer.fontSize = 35
        textLayer.alignmentMode = .center
        textLayer.foregroundColor = NSColor.white.cgColor
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        textLayer.isHidden = true
        let font = NSFont.systemFont(ofSize: 35, weight: .bold)
        textLayer.font = font
        layer?.addSublayer(textLayer)
        cardTextLayer = textLayer

        // Note flash
        let flash = CALayer()
        flash.isHidden = true
        flash.opacity = 0
        layer?.addSublayer(flash)
        noteFlashLayer = flash
    }

    private var hideWorkItem: DispatchWorkItem?

    func showCard(topText: String, bottomText: String, duration: Double) {
        guard let card = cardLayer, let emoji = cardEmojiLayer, let text = cardTextLayer else { return }

        // Cancel previous hide timer so card stays full duration
        hideWorkItem?.cancel()
        hideWorkItem = nil

        let cardWidth: CGFloat = 480
        let cardHeight: CGFloat = 320
        let centerX = bounds.midX - cardWidth / 2
        let centerY = bounds.midY - cardHeight / 2

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Cancel any lingering fade out animation
        card.removeAnimation(forKey: "fadeOut")
        emoji.removeAnimation(forKey: "fadeOut")
        text.removeAnimation(forKey: "fadeOut")
        card.opacity = 1.0
        emoji.opacity = 1.0
        text.opacity = 1.0

        card.frame = CGRect(x: centerX, y: centerY, width: cardWidth, height: cardHeight)
        card.isHidden = false

        emoji.frame = CGRect(x: centerX, y: centerY + cardHeight * 0.35, width: cardWidth, height: 140)
        emoji.string = topText
        emoji.isHidden = false

        text.frame = CGRect(x: centerX, y: centerY + 28, width: cardWidth, height: 60)
        text.string = bottomText
        text.isHidden = false

        CATransaction.commit()

        // Spring-bounce animation: scale 0.4 → 1.15 → 1.0
        let scaleAnim = CASpringAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 0.4
        scaleAnim.toValue = 1.0
        scaleAnim.damping = 8
        scaleAnim.stiffness = 200
        scaleAnim.mass = 0.8
        scaleAnim.duration = scaleAnim.settlingDuration

        card.add(scaleAnim, forKey: "springScale")
        emoji.add(scaleAnim, forKey: "springScale")
        text.add(scaleAnim, forKey: "springScale")

        // Auto-hide after the configured duration
        let workItem = DispatchWorkItem { [weak self] in
            self?.hideCard()
        }
        self.hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    private func hideCard() {
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 1.0
        fadeOut.toValue = 0.0
        fadeOut.duration = 0.3

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.cardLayer?.isHidden = true
            self?.cardEmojiLayer?.isHidden = true
            self?.cardTextLayer?.isHidden = true
            self?.cardLayer?.opacity = 1.0
            self?.cardEmojiLayer?.opacity = 1.0
            self?.cardTextLayer?.opacity = 1.0
        }

        cardLayer?.add(fadeOut, forKey: "fadeOut")
        cardEmojiLayer?.add(fadeOut, forKey: "fadeOut")
        cardTextLayer?.add(fadeOut, forKey: "fadeOut")
        cardLayer?.opacity = 0
        cardEmojiLayer?.opacity = 0
        cardTextLayer?.opacity = 0

        CATransaction.commit()
    }

    func showNoteFlash(color: NSColor, noteIndex: Int) {
        guard let flash = noteFlashLayer else { return }

        let barWidth: CGFloat = bounds.width / 26.0
        let x = barWidth * CGFloat(noteIndex)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        flash.frame = CGRect(x: x, y: 0, width: barWidth, height: bounds.height)
        flash.backgroundColor = color.withAlphaComponent(0.4).cgColor
        flash.isHidden = false
        flash.opacity = 1.0
        CATransaction.commit()

        // Fade out
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 0.6
        fadeOut.toValue = 0.0
        fadeOut.duration = 0.5

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.noteFlashLayer?.isHidden = true
            self?.noteFlashLayer?.opacity = 0
        }
        flash.add(fadeOut, forKey: "flash")
        flash.opacity = 0
        CATransaction.commit()
    }
}

// MARK: - Lock HUD View

class LockHUDView: NSView {

    private let lockIconLabel = NSTextField(labelWithString: "🔒")
    private let timerLabel = NSTextField(labelWithString: "")
    private let instructionLabel = NSTextField(labelWithString: "Hold U+K 3s • ⌘⌃L")
    private var progressBarLayer: CALayer?
    private var currentModeStr = ""
    private var currentShortcutHint = ""
    private var currentChordNames = "U+K"

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.backgroundColor = NSColor(white: 0.1, alpha: 0.85).cgColor
        layer?.borderColor = NSColor(white: 1.0, alpha: 0.15).cgColor
        layer?.borderWidth = 1

        // Blur effect via NSVisualEffectView
        let blur = NSVisualEffectView(frame: bounds)
        blur.autoresizingMask = [.width, .height]
        blur.blendingMode = .behindWindow
        blur.material = .hudWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 16
        blur.layer?.masksToBounds = true
        addSubview(blur)

        // Lock icon
        lockIconLabel.font = NSFont.systemFont(ofSize: 24)
        lockIconLabel.alignment = .left
        lockIconLabel.frame = NSRect(x: 12, y: 28, width: 40, height: 40)
        addSubview(lockIconLabel)

        // Timer
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
        timerLabel.textColor = NSColor(red: 0.2, green: 0.85, blue: 1.0, alpha: 1.0)
        timerLabel.alignment = .left
        timerLabel.frame = NSRect(x: 48, y: 32, width: 220, height: 30)
        addSubview(timerLabel)

        // Instruction
        instructionLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        instructionLabel.textColor = NSColor(white: 0.85, alpha: 1.0)
        instructionLabel.alignment = .left
        instructionLabel.frame = NSRect(x: 12, y: 12, width: bounds.width - 24, height: 18)
        addSubview(instructionLabel)

        // Hold Progress Bar (background track)
        let barTrack = CALayer()
        barTrack.frame = CGRect(x: 12, y: 4, width: bounds.width - 24, height: 4)
        barTrack.backgroundColor = NSColor(white: 1.0, alpha: 0.15).cgColor
        barTrack.cornerRadius = 2
        layer?.addSublayer(barTrack)

        // Hold Progress Bar (fill)
        let barFill = CALayer()
        barFill.frame = CGRect(x: 12, y: 4, width: 0, height: 4)
        barFill.backgroundColor = NSColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 1.0).cgColor
        barFill.cornerRadius = 2
        layer?.addSublayer(barFill)
        progressBarLayer = barFill
    }

    func update(timeRemaining: String, mode: String, shortcutHint: String? = nil, chordNames: String? = nil) {
        currentModeStr = mode
        if let h = shortcutHint { currentShortcutHint = h }
        if let c = chordNames { currentChordNames = c }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if timeRemaining.isEmpty {
                self.timerLabel.stringValue = "LOCKED"
                self.timerLabel.textColor = NSColor(red: 0.2, green: 0.85, blue: 1.0, alpha: 1.0)
            } else {
                self.timerLabel.stringValue = timeRemaining
                self.timerLabel.textColor = NSColor(red: 1.0, green: 0.45, blue: 0.45, alpha: 1.0)
            }
            let hint = self.currentShortcutHint.isEmpty ? "Hold U+K 3s • ⌘⌃L" : self.currentShortcutHint
            self.instructionLabel.stringValue = "\(hint) • \(mode)"
            self.instructionLabel.textColor = NSColor(white: 0.85, alpha: 1.0)
        }
    }

    func updateHoldProgress(_ progress: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let maxW = self.bounds.width - 24
            let w = maxW * CGFloat(progress)

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.progressBarLayer?.frame = CGRect(x: 12, y: 4, width: w, height: 4)
            CATransaction.commit()

            if progress > 0 {
                let pct = Int(progress * 100)
                self.instructionLabel.stringValue = "⏳ Unlocking: \(pct)% (holding \(self.currentChordNames)...)"
                self.instructionLabel.textColor = NSColor(red: 0.3, green: 1.0, blue: 0.5, alpha: 1.0)
            } else {
                let modeText = self.currentModeStr.isEmpty ? "" : " • \(self.currentModeStr)"
                let hint = self.currentShortcutHint.isEmpty ? "Hold U+K 3s • ⌘⌃L" : self.currentShortcutHint
                self.instructionLabel.stringValue = "\(hint)\(modeText)"
                self.instructionLabel.textColor = NSColor(white: 0.8, alpha: 1.0)
            }
        }
    }
}
