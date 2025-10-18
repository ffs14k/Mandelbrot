import UIKit
import simd

class GestureHandler {
    var center: Binding<SIMD2<Float>>
    var zoom: Binding<Float>
    
    struct Binding<T> {
        let get: () -> T
        let set: (T) -> Void
        
        var wrappedValue: T {
            get { get() }
            set { set(newValue) }
        }
    }
    
    init(center: Binding<SIMD2<Float>>, zoom: Binding<Float>) {
        self.center = center
        self.zoom = zoom
    }
    
    func handlePan(_ gesture: UIPanGestureRecognizer, in view: UIView) {
        guard gesture.state == .changed else { return }
        
        let translation = gesture.translation(in: view)
        let aspectRatio = Float(view.bounds.width / view.bounds.height)
        
        let dx = -Float(translation.x) / Float(view.bounds.width) * 2.0 * aspectRatio / zoom.wrappedValue
        let dy = Float(translation.y) / Float(view.bounds.height) * 2.0 / zoom.wrappedValue
        
        var currentCenter = center.wrappedValue
        currentCenter.x += dx
        currentCenter.y += dy
        center.set(currentCenter)
        
        gesture.setTranslation(.zero, in: view)
    }
    
    func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.state == .began || gesture.state == .changed else { return }
        
        zoom.set(zoom.wrappedValue * Float(gesture.scale))
        gesture.scale = 1.0
    }
    
    func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        zoom.set(zoom.wrappedValue * 2.0)
    }
}

