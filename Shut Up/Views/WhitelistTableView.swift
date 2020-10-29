//
//  WhitelistTableView.swift
//  Shut Up
//
//  Created by Ricky Romero on 7/19/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Cocoa

class WhitelistTableView: NSTableView {
    var dragHighlight = false

    override func awakeFromNib() {
        super.awakeFromNib()

        // Set up dragging destination
        var acceptedTypes: [NSPasteboard.PasteboardType] = [
            .color,
            .fileContents,
            .filePromise,
            .findPanelSearchOptions,
            .font,
            .html,
            .inkText,
            .multipleTextSelection,
            .pdf,
            .png,
            .postScript,
            .rtf,
            .rtfd,
            .ruler,
            .sound,
            .string,
            .tabularText,
            .textFinderOptions,
            .tiff,
            .vCard
        ]
        if #available(macOS 10.13, *) {
            acceptedTypes.append(.fileURL)
            acceptedTypes.append(.URL)
        }
        self.registerForDraggedTypes(acceptedTypes)
    }

    override func draw(_ dirtyRect: NSRect) {
        if dragHighlight {
            NSDrawButton(dirtyRect, dirtyRect)
        } else {
            super.draw(dirtyRect)
        }
    }
}

// MARK: NSDraggingDestination

extension WhitelistTableView {
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print(#function)
        dragHighlight = false
        setNeedsDisplay()
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print(#function)
        sender.draggingPasteboard.pasteboardItems?.forEach({ (item) in
            dump(item)
        })
        return true
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        print(#function)
        dump(sender.draggingSourceOperationMask)
        let allowedOperations = sender.draggingSourceOperationMask
//        return allowedOperations
        dragHighlight = true
        setNeedsDisplay()
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        dragHighlight = false
        setNeedsDisplay()
    }
}
