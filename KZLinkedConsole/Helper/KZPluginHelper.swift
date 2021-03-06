//
// Created by Krzysztof Zabłocki on 08/12/15.
// Copyright (c) 2015 pixle. All rights reserved.
//

import Foundation
import AppKit

class KZPluginHelper: NSObject {
    static func runShellCommand(launchPath: String, arguments: [String]) -> String? {
        let pipe = NSPipe()
        let task = NSTask()
        task.launchPath = launchPath
        task.arguments = arguments
        task.standardOutput = pipe
        let file = pipe.fileHandleForReading
        task.launch()
        guard let result = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)?.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet()) else {
            return nil
        }
        return result as String
    }

    static func getViewByClassName(name: String, inContainer container: NSView) -> NSView? {
        guard let targetClass = NSClassFromString(name) else {
            return nil
        }
        for subview in container.subviews {
            if subview.isKindOfClass(targetClass) {
                return subview
            }

            if let view = getViewByClassName(name, inContainer: subview) {
                return view
            }
        }

        return nil
    }
}

//! MARK: Accessing private API

extension KZPluginHelper {
    static func workspacePath() -> String? {
        if let workspacePath = KZFunctions.workspacePath() {
            return workspacePath
        }
        
        guard let anyClass = NSClassFromString("IDEWorkspaceWindowController") as? NSObject.Type,
            let windowControllers = anyClass.valueForKey("workspaceWindowControllers") as? [NSObject],
            let window = NSApp.keyWindow ?? NSApp.windows.first else {
                Swift.print("Failed to establish workspace path")
                return nil
        }
        var workspace: NSObject?
        for controller in windowControllers {
            if controller.valueForKey("window")?.isEqual(window) == true {
                workspace = controller.valueForKey("_workspace") as? NSObject
            }
        }
        
        guard let workspacePath = workspace?.valueForKeyPath("representingFilePath._pathString") as? NSString else {
            Swift.print("Failed to establish workspace path")
            return nil
        }
        
        return workspacePath.stringByDeletingLastPathComponent as String
    }

    static func editorTextView(inWindow window: NSWindow? = NSApp.mainWindow) -> NSTextView? {
        guard let window = window,
            let windowController = window.windowController,
            let editor = windowController.valueForKeyPath("editorArea.lastActiveEditorContext.editor") else {
                return nil
        }

        let type = String(editor.dynamicType)
        if type != "NSKVONotifying_IDESourceCodeEditor" {
            NSLog(type)
            return nil
        }

        let textView = editor.valueForKey("textView") as? NSTextView
        return textView
    }

    static func consoleTextView(inWindow window: NSWindow? = NSApp.mainWindow) -> NSTextView? {
        guard let contentView = window?.contentView,
        let consoleTextView = KZPluginHelper.getViewByClassName("IDEConsoleTextView", inContainer: contentView) as? NSTextView else {
            return nil
        }
        return consoleTextView
    }
}
