//
//  MetalRenderer.swift
//  metal-fun
//
//  Created by Frank Baiata on 1/18/25.
//

import MetalKit

class MetalRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue?
    var pipelineState: MTLRenderPipelineState?
    
    init(metalView: MTKView) {
        self.device = metalView.device
        self.commandQueue = self.device?.makeCommandQueue()
        
        //Build Pipeline State
        if let device = self.device {
            self.pipelineState = PipelineBuilder.buildPipeline(device: device, vertexFunctionName:"vertexShader", fragmentFunctionName:"fragmentShader")
        }
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        //Handle size changes
    }
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else { return }
        
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
        
        //add rendering commands here
        //renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        // 1. Set the pipeline state
        if let pipelineState = self.pipelineState {
            renderEncoder?.setRenderPipelineState(pipelineState)
        }
        // 2. Issue draw calls (Triangle time!!!)
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        // 3. Finish encoding
        renderEncoder?.endEncoding()
        
        // Present and Commit
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}

class PipelineBuilder {
    static func buildPipeline(device: MTLDevice, vertexFunctionName: String, fragmentFunctionName: String) -> MTLRenderPipelineState? {
        //Load the metal default library
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to created Default Library");
            return nil
        }
        //Prepare descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineDescriptor.vertexFunction = library.makeFunction(name: vertexFunctionName)
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: fragmentFunctionName)
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do{
            //Create a pipeline state
            let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            return pipelineState
        } catch {
            print("Failed to create pipeline state: \(error)")
            return nil
        }
        
    }
}
