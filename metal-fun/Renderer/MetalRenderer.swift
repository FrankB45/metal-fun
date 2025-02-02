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
    
    //HUD to display FPS and other useful info
    var hudLayer: CATextLayer?
    
    //Used to calculate FPS
    private var lastFrameTime: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var elapsedTimeAccumulator: CFTimeInterval = 0
    private var frameTimeList: [CFTimeInterval] = []
    
    public private(set) var currentFPS: Double = 0
    public private(set) var averageFrameTime: Double = 0
    
    
    
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
        
        
        // *** Setup the Heads-Up Display (HUD) overlay ***
        // Ensure the view is layer-backed.
        metalView.wantsLayer = true
        
        // Create the CATextLayer.
        let hud = CATextLayer()
        // Position it in the top left corner. (Adjust the y coordinate based on the view’s coordinate system.)
        // Note: On macOS, (0,0) is at the bottom-left, so we subtract from view.bounds.height.
        let layerWidth: CGFloat = 200
        let layerHeight: CGFloat = 50
        let xPos: CGFloat = 10
        let yPos: CGFloat = metalView.bounds.height
        hud.frame = CGRect(x: xPos, y: yPos, width: layerWidth, height: layerHeight)
        
        hud.foregroundColor = NSColor.white.cgColor  // Use UIColor.white.cgColor on iOS
        hud.fontSize = 14
        hud.alignmentMode = .left
        // Ensure the text looks sharp on high-resolution displays.
        hud.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        hud.string = "FPS: --\nFrame Time: --"
        
        // Add the text layer to the view’s layer.
        metalView.layer?.addSublayer(hud)
        self.hudLayer = hud
    
        
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
        
        //-----------
        //Used for FPS
        // Measure the time elapsed since the last frame
        let currentTime: CFTimeInterval = CACurrentMediaTime()
        if lastFrameTime == 0 {
            lastFrameTime = currentTime
        }
        
        let deltaTime = currentTime - lastFrameTime
        frameTimeList += [deltaTime]
        lastFrameTime = currentTime
        
        //Accumulate elasped time and count frames
        elapsedTimeAccumulator += deltaTime
        frameCount += 1
        
        //Once per second, compute and store the FPS
        if elapsedTimeAccumulator >= 1 {
            currentFPS = Double(frameCount) / elapsedTimeAccumulator
            elapsedTimeAccumulator = 0
            frameCount = 0
            
            if !frameTimeList.isEmpty {
                averageFrameTime = frameTimeList.reduce(0, +) / Double(frameTimeList.count)
                averageFrameTime = averageFrameTime * 1000
            } else {
                averageFrameTime = 0  // Set to 0 if no frames were recorded
            }
            frameTimeList.removeAll()
            
            // Update the CATextLayer on the main thread.
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.hudLayer?.string = String(format: "FPS: %d\nFrame Time: %.4f ms", Int(self.currentFPS), self.averageFrameTime)
            }
        }
        
        
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
