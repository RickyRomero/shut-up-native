//
//  AddDomainCell.swift
//  Custom Text Field
//
//  Created by Ricky Romero on 6/13/20.
//  See LICENSE.md for license information.
//

import Cocoa

class AddDomainCell: NSTextFieldCell {
    let endPadding: CGFloat = 10
    let iconSize: CGFloat = 16
    let iconSpacer: CGFloat = 8
    let cornerRadius: CGFloat = 6

    let icon = NSImage(named: "NSAddTemplate")!

    func adjustedFrame(toVerticallyCenterText rect: NSRect) -> NSRect {
        // super would normally draw text at the top of the cell
        var titleRect = super.titleRect(forBounds: rect)

        let minimumHeight = cellSize(forBounds: rect).height
        titleRect.origin.y += (titleRect.height - minimumHeight) / 2
        titleRect.size.height = minimumHeight

        let leadingOffset = endPadding + iconSize + iconSpacer
        let trailingOffset = endPadding
        titleRect.origin.x += leadingOffset
        titleRect.size.width = rect.width - leadingOffset - trailingOffset

        return titleRect
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, event: event)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: adjustedFrame(toVerticallyCenterText: cellFrame), in: controlView)
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()

        controlView.wantsLayer = true
        controlView.layer?.masksToBounds = false
        controlView.layer?.shadowOffset = NSSize(width: 0, height: 4)
        controlView.layer?.shadowRadius = 4
        controlView.layer?.shadowOpacity = 0.5

        // Draw rounded rectangle
        let backgroundPath = NSBezierPath(roundedRect: cellFrame, xRadius: cornerRadius, yRadius: cornerRadius)
        backgroundColor?.setFill()
        backgroundPath.fill()

        // Draw plus icon
        NSColor.secondaryLabelColor.setFill()
        let centeringY = (cellFrame.height - iconSize) / 2
        var iconBounds = NSRect(x: endPadding, y: centeringY, width: iconSize, height: iconSize)
        ctx.clip(
            to: iconBounds,
            mask: icon.cgImage(
                forProposedRect: &iconBounds,
                context: NSGraphicsContext.current,
                hints: nil
            )!
        )
        ctx.fill(iconBounds)
        ctx.restoreGState()

        super.draw(withFrame: cellFrame, in: controlView)
    }

    override func drawFocusRingMask(withFrame cellFrame: NSRect, in _: NSView) {
        let ringPath = NSBezierPath(roundedRect: cellFrame, xRadius: cornerRadius, yRadius: cornerRadius)
        let maskColor = NSColor.black
        maskColor.setFill()
        ringPath.fill()
    }
}
