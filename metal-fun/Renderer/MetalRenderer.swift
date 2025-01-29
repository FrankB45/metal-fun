//
//  MetalRenderer.swift
//  metal-fun
//
//  Created by Frank Baiata on 1/18/25.
//

import MetalKit

let triangleVertices: [MetalVertex] = [
    MetalVertex(position: SIMD2<Float>(250, -250), color: SIMD4<Float>(1, 0, 0, 1)),
    MetalVertex(position: SIMD2<Float>(-250, -250), color: SIMD4<Float>(0, 1, 0, 1)),
    MetalVertex(position: SIMD2<Float>(0, 250), color: SIMD4<Float>(0, 0, 1, 1))
]

var vertexBuffer: MTLBuffer?
var viewportSizeBuffer: MTLBuffer?

class MetalRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue?
    var pipelineState: MTLRenderPipelineState?
    var viewportSize: vector_uint2 = vector_uint2(0, 0)
    
    init(metalView: MTKView) {
        self.device = metalView.device
        self.commandQueue = self.device?.makeCommandQueue()
        
        
        //Build Buffers for Vertex Function
        let vertexDataSize = MemoryLayout<MetalVertex>.stride * triangleVertices.count
        vertexBuffer = device?.makeBuffer(bytes: triangleVertices, length: vertexDataSize, options: .storageModeShared)
        
        let viewportSizeDataSize = MemoryLayout<vector_uint2>.stride
        viewportSizeBuffer = device?.makeBuffer(bytes: &viewportSize, length: viewportSizeDataSize, options: .storageModeShared)
        
        //Build Pipeline State
        if let device = self.device {
            self.pipelineState = PipelineBuilder.buildPipeline(device: device, vertexFunctionName:"vertexShader", fragmentFunctionName:"fragmentShader")
        }
    
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        //Handle size changes
        viewportSize.x = UInt32(size.width)
        viewportSize.y = UInt32(size.height)
        
        // Update the viewport size buffer
        let bufferPointer = viewportSizeBuffer?.contents()
        bufferPointer?.copyMemory(from: &viewportSize, byteCount: MemoryLayout<vector_uint2>.size)
        
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
        
        // Bind the vertex buffer at index 0
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: Int(MetalVertexInputIndexVertices.rawValue))
            
        // Bind the viewport size buffer at index 1
        renderEncoder?.setVertexBuffer(viewportSizeBuffer, offset: 0, index: Int(MetalVertexInputIndexViewportSize.rawValue))
            
        
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
    static func buildPipeline(device: MTLDevice, label: String? = "Simple Pipeline", vertexFunctionName: String, fragmentFunctionName: String) -> MTLRenderPipelineState? {
        //Load the metal default library
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to created Default Library");
            return nil
        }
        //Prepare descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineDescriptor.label = label
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
