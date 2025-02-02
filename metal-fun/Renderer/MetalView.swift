//
//  MetalView.swift
//  metal-fun
//
//  Created by Frank Baiata on 1/18/25.
//
import SwiftUI
import MetalKit

//NSView because we are on MacOS and if we were on iOS then it would be UIView
struct MetalView: NSViewRepresentable {
    
    // Coordinator for managing MTKView interactions
    // Part of the NSViewRepresentable Protocol
    // It provides a way to create and manage a custom coordinator object, which acts as the delegate or intermediary for interactions between the AppKit view (MTKView) and the SwiftUI component (MetalView).
    func makeCoordinator() -> MetalRenderer {
        MetalRenderer(metalView: view)
    }

    // Metal view instance
    var view: MTKView = {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = MTLClearColorMake(0.68, 0.85, 0.90, 1.0)
        mtkView.enableSetNeedsDisplay = false
        return mtkView
    }()

    // Create and configure the NSView
    func makeNSView(context: Context) -> MTKView {
        view.delegate = context.coordinator // Set the Metal renderer as the delegate
        return view
    }

    // Update the NSView
    func updateNSView(_ nsView: MTKView, context: Context) {
        // Update Metal view if needed (e.g., handle SwiftUI state changes)
        nsView.setNeedsDisplay(nsView.bounds)
    }
}
