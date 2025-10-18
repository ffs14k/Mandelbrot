import SwiftUI
import Darwin

struct VisualizationView: View {
    @Environment(\.dismiss) private var dismiss
    
    let rendererType: RendererType
    let initialMaxIterations: Int
    let initialColorScheme: Int
    let autoPlaySpeed: Float
    
    @State private var center = SIMD2<Float>(-0.7, 0.0)
    @State private var zoom: Float = 0.6
    @State private var maxIterations: Int
    @State private var colorScheme: Int
    
    @State private var isPlaying = true
    @State private var currentSpeed: Float
    @State private var animationTime: Double = 0
    @State private var animationTask: Task<Void, Never>?
    @State private var cyclePhase: Int = 0
    @State private var cpuUsage: Double = 0
    @State private var memoryUsage: Double = 0
    @State private var fps: Int = 0
    
    init(rendererType: RendererType, initialMaxIterations: Int, initialColorScheme: Int, autoPlaySpeed: Float) {
        self.rendererType = rendererType
        self.initialMaxIterations = initialMaxIterations
        self.initialColorScheme = initialColorScheme
        self.autoPlaySpeed = autoPlaySpeed
        _maxIterations = State(initialValue: 20)
        _colorScheme = State(initialValue: initialColorScheme)
        _currentSpeed = State(initialValue: autoPlaySpeed)
    }
    
    var body: some View {
        ZStack {
            if rendererType == .metal {
                MetalView(
                    center: $center,
                    zoom: $zoom,
                    maxIterations: $maxIterations,
                    colorScheme: $colorScheme
                )
                .ignoresSafeArea()
            } else {
                CoreGraphicsView(
                    center: $center,
                    zoom: $zoom,
                    maxIterations: $maxIterations,
                    colorScheme: $colorScheme
                )
                .ignoresSafeArea()
            }
            
            VStack {
                HStack(alignment: .center) {
                    Button(action: {
                        animationTask?.cancel()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    performanceBar
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            zoom *= 2.0
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        Button(action: {
                            zoom *= 0.5
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "minus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 70)
                }
                
                playbar
            }
        }
        .navigationBarHidden(true)
        .task {
            await startAutoPlay()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }
    
    private var performanceBar: some View {
        HStack(spacing: 8) {
            Text("CPU \(Int(cpuUsage))%")
            Text("•")
            Text("MEM \(Int(memoryUsage))MB")
            Text("•")
            Text("ITER \(maxIterations)")
            Text("•")
            Text("\(fps) FPS")
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
    }
    
    private var playbar: some View {
        HStack(spacing: 0) {
            playButton(
                icon: isPlaying ? "pause.fill" : "play.fill",
                action: { togglePlay() }
            )
            
            separator()
            
            playButton(
                icon: "arrow.counterclockwise",
                action: { resetView() }
            )
            
            separator()
            
            speedButton(speed: 1.0)
            separator()
            speedButton(speed: 5.0)
            separator()
            speedButton(speed: 10.0)
        }
        .frame(height: 50)
        .background(Color.black)
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: -5)
    }
    
    private func playButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
    }
    
    private func speedButton(speed: Float) -> some View {
        Button(action: {
            currentSpeed = speed
        }) {
            Text("x\(Int(speed))")
                .font(.system(size: 16, weight: currentSpeed == speed ? .bold : .regular))
                .foregroundColor(currentSpeed == speed ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(currentSpeed == speed ? Color.white : Color.clear)
        }
    }
    
    private func separator() -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.3))
            .frame(width: 1, height: 30)
    }
    
    private func togglePlay() {
        isPlaying.toggle()
        if isPlaying {
            animationTask = Task {
                await startAutoPlay()
            }
        } else {
            animationTask?.cancel()
        }
    }
    
    private func startAutoPlay() async {
        animationTask?.cancel()
        
        animationTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            guard !Task.isCancelled else { return }
            
            let updateInterval: UInt64 = 200_000_000 / UInt64(currentSpeed)
            var frameCount = 0
            var lastFPSTime = Date()
            
            Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 16_000_000)
                    await MainActor.run {
                        updatePerformanceMetrics()
                    }
                }
            }
            
            while !Task.isCancelled && isPlaying {
                try? await Task.sleep(nanoseconds: updateInterval)
                
                guard !Task.isCancelled else { break }
                
                await MainActor.run {
                    let iterationStep = max(1, Int(5 * currentSpeed))
                    maxIterations += iterationStep
                    
                    frameCount += 1
                    let now = Date()
                    if now.timeIntervalSince(lastFPSTime) >= 1.0 {
                        fps = frameCount
                        frameCount = 0
                        lastFPSTime = now
                    }
                }
            }
        }
    }
    
    private func updatePerformanceMetrics() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            memoryUsage = Double(info.resident_size) / 1024.0 / 1024.0
        }
        
        var totalUsageOfCPU: Double = 0.0
        var threadsList = UnsafeMutablePointer<thread_act_t>(bitPattern: 0)
        var threadsCount = mach_msg_type_number_t(0)
        
        let threadsResult = task_threads(mach_task_self_, &threadsList, &threadsCount)
        
        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }
                
                if infoResult == KERN_SUCCESS {
                    let threadBasicInfo = threadInfo
                    if threadBasicInfo.flags != TH_FLAGS_IDLE {
                        totalUsageOfCPU += Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
                    }
                }
            }
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        }
        
        cpuUsage = totalUsageOfCPU
    }
    
    private func nextCycle() {
        maxIterations = 20
    }
    
    private func resetView() {
        center = SIMD2<Float>(-0.7, 0.0)
        zoom = 0.6
        maxIterations = 20
        animationTime = 0
        cyclePhase = 0
    }
}



