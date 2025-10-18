import Foundation
import simd

struct ColorStop {
    let position: Float
    let color: SIMD3<Float>
    
    init(_ position: Float, _ r: Float, _ g: Float, _ b: Float) {
        self.position = position
        self.color = SIMD3<Float>(r, g, b)
    }
}

struct MandelbrotColorScheme {
    let name: String
    let stops: [ColorStop]
    let reversed: Bool
    let powerCurve: Float
    
    init(name: String, stops: [ColorStop], reversed: Bool = false, powerCurve: Float = 1.0) {
        self.name = name
        self.stops = stops
        self.reversed = reversed
        self.powerCurve = powerCurve
    }
    
    func color(at t: Float) -> SIMD3<Float> {
        var t = t
        if reversed {
            t = 1.0 - t
        }
        t = pow(t, powerCurve)
        
        guard stops.count > 1 else {
            return stops.first?.color ?? SIMD3<Float>(0, 0, 0)
        }
        
        if t <= stops.first!.position {
            return stops.first!.color
        }
        if t >= stops.last!.position {
            return stops.last!.color
        }
        
        for i in 0..<(stops.count - 1) {
            let start = stops[i]
            let end = stops[i + 1]
            
            if t >= start.position && t <= end.position {
                let factor = (t - start.position) / (end.position - start.position)
                return start.color + (end.color - start.color) * factor
            }
        }
        
        return stops.last!.color
    }
}

struct ColorSchemes {
    static let all: [MandelbrotColorScheme] = [
        aurora,
        cosmic,
        oceanDepth,
        rainbow,
        classic,
        universe
    ]
    
    static let aurora = MandelbrotColorScheme(
        name: "Aurora",
        stops: [
            ColorStop(0.0, 0.02, 0.02, 0.15),
            ColorStop(0.2, 0.1, 0.3, 0.5),
            ColorStop(0.5, 0.3, 0.6, 0.7),
            ColorStop(0.8, 0.9, 0.6, 0.3),
            ColorStop(1.0, 1.0, 0.95, 0.85)
        ]
    )
    
    static let cosmic = MandelbrotColorScheme(
        name: "Cosmic",
        stops: [
            ColorStop(0.0, 1.0, 1.0, 1.0),
            ColorStop(0.2, 0.95, 0.85, 0.7),
            ColorStop(0.4, 0.5, 0.4, 0.6),
            ColorStop(0.7, 0.1, 0.05, 0.15),
            ColorStop(1.0, 0.0, 0.0, 0.0)
        ],
        reversed: true
    )
    
    static let oceanDepth = MandelbrotColorScheme(
        name: "Ocean Depth",
        stops: [
            ColorStop(0.0, 0.02, 0.02, 0.15),
            ColorStop(0.33, 0.1, 0.3, 0.5),
            ColorStop(0.66, 0.9, 0.6, 0.3),
            ColorStop(1.0, 1.0, 0.95, 0.85)
        ]
    )
    
    static let rainbow = MandelbrotColorScheme(
        name: "Rainbow",
        stops: [
            ColorStop(0.0, 0.5, 0.0, 0.5),
            ColorStop(0.17, 0.0, 0.0, 1.0),
            ColorStop(0.33, 0.0, 0.5, 1.0),
            ColorStop(0.5, 0.0, 1.0, 0.5),
            ColorStop(0.67, 1.0, 1.0, 0.0),
            ColorStop(0.83, 1.0, 0.5, 0.0),
            ColorStop(1.0, 1.0, 0.0, 0.0)
        ],
        powerCurve: 2.2
    )
    
    static let classic = MandelbrotColorScheme(
        name: "Classic",
        stops: [
            ColorStop(0.0, 0.0, 0.0, 0.0),
            ColorStop(0.16, 0.0, 0.28, 0.50),
            ColorStop(0.42, 0.92, 0.76, 0.0),
            ColorStop(0.6425, 1.0, 1.0, 1.0),
            ColorStop(1.0, 0.0, 0.0, 0.0)
        ],
        powerCurve: 0.5
    )
    
    static let universe = MandelbrotColorScheme(
        name: "Universe",
        stops: [
            ColorStop(0.0, 0.0, 0.0, 0.05),
            ColorStop(0.2, 0.2, 0.0, 0.4),
            ColorStop(0.4, 0.0, 0.2, 0.6),
            ColorStop(0.6, 0.8, 0.2, 0.5),
            ColorStop(0.85, 0.9, 0.95, 1.0),
            ColorStop(1.0, 0.9, 0.95, 1.0)
        ],
        powerCurve: 0.7
    )
}

