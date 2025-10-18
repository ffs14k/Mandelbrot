import Foundation

enum RendererType: String, CaseIterable {
    case metal = "Metal"
    case coreGraphics = "Core Graphics"
    
    var icon: String {
        switch self {
        case .metal: return "cpu.fill"
        case .coreGraphics: return "paintbrush.fill"
        }
    }
    
    var description: String {
        switch self {
        case .metal:
            return "GPU-accelerated rendering for smooth performance"
        case .coreGraphics:
            return "CPU-based rendering with precise calculations"
        }
    }
}

