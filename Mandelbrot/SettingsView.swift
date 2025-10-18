import SwiftUI

struct SettingsView: View {
    @State private var selectedRenderer: RendererType = .metal
    @State private var maxIterations = 100
    @State private var colorScheme = 0
    @State private var autoPlaySpeed: Float = 1.0
    @State private var navigateToVisualization = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Text("MANDELBROT")
                        .font(.system(size: 28, weight: .thin, design: .default))
                        .foregroundColor(.black)
                        .kerning(3)
                        .padding(.top, 60)
                    
                    Spacer()
                    
                    VStack(spacing: 0) {
                        settingRow(
                            title: "RENDERER",
                            content: {
                                HStack(spacing: 8) {
                                    ForEach(RendererType.allCases, id: \.self) { type in
                                        Button(action: {
                                            selectedRenderer = type
                                        }) {
                                            Text(type.rawValue)
                                                .font(.system(size: 13))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(selectedRenderer == type ? Color.black : Color.white)
                                                .foregroundColor(selectedRenderer == type ? .white : .black)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                                )
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        )
                        
                        separator()
                        
                        settingRow(
                            title: "COLOR",
                            content: {
                                FlowLayout(spacing: 8) {
                                    ForEach(0..<ColorSchemes.all.count, id: \.self) { index in
                                        Button(action: {
                                            colorScheme = index
                                        }) {
                                            Text(ColorSchemes.all[index].name)
                                                .font(.system(size: 13))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(colorScheme == index ? Color.black : Color.white)
                                                .foregroundColor(colorScheme == index ? .white : .black)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                                )
                                                .cornerRadius(16)
                                        }
                                    }
                                }
                            }
                        )
                        
                        separator()
                        
                        settingRow(
                            title: "DETAIL",
                            content: {
                                HStack {
                                    Slider(value: Binding(
                                        get: { Double(maxIterations) },
                                        set: { maxIterations = Int($0) }
                                    ), in: 50...500, step: 10)
                                    .tint(.black)
                                    
                                    Text("\(maxIterations)")
                                        .foregroundColor(.black)
                                        .frame(width: 50)
                                }
                            }
                        )
                        
                        separator()
                        
                        settingRow(
                            title: "SPEED",
                            content: {
                                HStack(spacing: 8) {
                                    speedButton(speed: 1.0)
                                    speedButton(speed: 5.0)
                                    speedButton(speed: 10.0)
                                }
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        navigateToVisualization = true
                    }) {
                        Text("RUN")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.black)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToVisualization) {
                VisualizationView(
                    rendererType: selectedRenderer,
                    initialMaxIterations: maxIterations,
                    initialColorScheme: colorScheme,
                    autoPlaySpeed: autoPlaySpeed
                )
                .navigationBarBackButtonHidden(true)
            }
        }
    }
    
    @ViewBuilder
    private func settingRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black.opacity(0.5))
            
            content()
        }
        .padding(.vertical, 20)
    }
    
    private func separator() -> some View {
        Rectangle()
            .fill(Color.black.opacity(0.1))
            .frame(height: 1)
    }
    
    private func speedButton(speed: Float) -> some View {
        Button(action: { autoPlaySpeed = speed }) {
            Text("x\(Int(speed))")
                .font(.system(size: 14, weight: autoPlaySpeed == speed ? .bold : .regular))
                .foregroundColor(autoPlaySpeed == speed ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(autoPlaySpeed == speed ? Color.black : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(12)
        }
    }
}

#Preview {
    SettingsView()
}

