import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    @Binding var center: SIMD2<Float>
    @Binding var zoom: Float
    @Binding var maxIterations: Int
    @Binding var colorScheme: Int
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        context.coordinator.setupMetal(view: mtkView)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        mtkView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        mtkView.addGestureRecognizer(pinchGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        mtkView.addGestureRecognizer(doubleTapGesture)
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var vertexBuffer: MTLBuffer!
        var gestureHandler: GestureHandler
        
        init(_ parent: MetalView) {
            self.parent = parent
            self.gestureHandler = GestureHandler(
                center: GestureHandler.Binding(
                    get: { parent.center },
                    set: { parent.center = $0 }
                ),
                zoom: GestureHandler.Binding(
                    get: { parent.zoom },
                    set: { parent.zoom = $0 }
                )
            )
        }
        
        func setupMetal(view: MTKView) {
            device = view.device
            commandQueue = device.makeCommandQueue()
            
            let vertices: [Float] = [
                -1.0, -1.0,
                 1.0, -1.0,
                -1.0,  1.0,
                 1.0,  1.0
            ]
            
            vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.stride, options: [])
            
            let library = device.makeDefaultLibrary()
            let vertexFunction = library?.makeFunction(name: "vertex_main")
            let fragmentFunction = library?.makeFunction(name: "fragment_main")
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            
            let vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0].format = .float2
            vertexDescriptor.attributes[0].offset = 0
            vertexDescriptor.attributes[0].bufferIndex = 0
            vertexDescriptor.layouts[0].stride = 2 * MemoryLayout<Float>.stride
            pipelineDescriptor.vertexDescriptor = vertexDescriptor
            
            pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor else { return }
            
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
            
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            
            let scheme = ColorSchemes.all[parent.colorScheme]
            let aspectRatio = Float(view.bounds.width / view.bounds.height)
            
            var uniforms = Uniforms(
                center: parent.center,
                zoom: parent.zoom,
                aspectRatio: aspectRatio,
                maxIterations: Int32(parent.maxIterations),
                colorStopCount: Int32(scheme.stops.count),
                powerCurve: scheme.powerCurve,
                reversed: scheme.reversed
            )
            
            var colorStops = scheme.stops.map { stop in
                MetalColorStop(position: stop.position, color: stop.color)
            }
            
            renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
            renderEncoder.setFragmentBytes(&colorStops, length: MemoryLayout<MetalColorStop>.stride * colorStops.count, index: 1)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            gestureHandler.handlePan(gesture, in: view)
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            gestureHandler.handlePinch(gesture)
        }
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            gestureHandler.handleDoubleTap(gesture)
        }
    }
}

struct Uniforms {
    var center: SIMD2<Float>
    var zoom: Float
    var aspectRatio: Float
    var maxIterations: Int32
    var colorStopCount: Int32
    var powerCurve: Float
    var reversed: Bool
}

struct MetalColorStop {
    var position: Float
    var color: SIMD3<Float>
}

