import SwiftUI
import UIKit

struct CoreGraphicsView: UIViewRepresentable {
    @Binding var center: SIMD2<Float>
    @Binding var zoom: Float
    @Binding var maxIterations: Int
    @Binding var colorScheme: Int
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MandelbrotCanvasView {
        let view = MandelbrotCanvasView()
        view.backgroundColor = .black
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        view.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: MandelbrotCanvasView, context: Context) {
        uiView.fractalCenter = center
        uiView.zoom = zoom
        uiView.maxIterations = maxIterations
        uiView.colorScheme = colorScheme
        uiView.setNeedsDisplay()
    }
    
    class Coordinator {
        var parent: CoreGraphicsView
        var gestureHandler: GestureHandler
        
        init(_ parent: CoreGraphicsView) {
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

class MandelbrotCanvasView: UIView {
    var fractalCenter: SIMD2<Float> = SIMD2<Float>(-0.7, 0.0)
    var zoom: Float = 0.6
    var maxIterations: Int = 100
    var colorScheme: Int = 0
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let scale: CGFloat = 0.5
        let width = Int(bounds.width * scale)
        let height = Int(bounds.height * scale)
        let aspectRatio = Float(width) / Float(height)
        
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        
        DispatchQueue.concurrentPerform(iterations: height) { py in
            for px in 0..<width {
                let normalizedX = Float(px) / Float(width) - 0.5
                let normalizedY = Float(py) / Float(height) - 0.5
                let x = normalizedX * 2.0 * aspectRatio / zoom + fractalCenter.x
                let y = normalizedY * 2.0 / zoom + fractalCenter.y
                
                var zx: Float = 0.0
                var zy: Float = 0.0
                var iteration = 0
                
                while iteration < maxIterations {
                    let zx2 = zx * zx
                    let zy2 = zy * zy
                    
                    if zx2 + zy2 > 4.0 {
                        break
                    }
                    
                    let temp = zx2 - zy2 + x
                    zy = 2.0 * zx * zy + y
                    zx = temp
                    iteration += 1
                }
                
                let color: (r: UInt8, g: UInt8, b: UInt8)
                if iteration == maxIterations {
                    color = (0, 0, 0)
                } else {
                    let t = Float(iteration) / Float(maxIterations)
                    let scheme = ColorSchemes.all[colorScheme]
                    let rgb = scheme.color(at: t)
                    color = (
                        UInt8(rgb.x * 255),
                        UInt8(rgb.y * 255),
                        UInt8(rgb.z * 255)
                    )
                }
                
                let index = (py * width + px) * 4
                pixels[index] = color.r
                pixels[index + 1] = color.g
                pixels[index + 2] = color.b
                pixels[index + 3] = 255
            }
        }
        
        if let cgImage = createCGImage(from: pixels, width: width, height: height) {
            context.interpolationQuality = .none
            context.draw(cgImage, in: bounds)
        }
    }
    
    func createCGImage(from pixels: [UInt8], width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let providerRef = CGDataProvider(data: Data(pixels) as CFData) else {
            return nil
        }
        
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}

