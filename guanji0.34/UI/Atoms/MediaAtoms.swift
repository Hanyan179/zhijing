import SwiftUI
import AVKit
import Combine

public struct VideoEntry: View {
    public let src: String
    public init(src: String) { self.src = src }
    
    @State private var showFullScreen = false
    
    private var resolvedURL: URL? {
        if src.hasPrefix("http") || src.hasPrefix("file") {
            return URL(string: src)
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return docs?.appendingPathComponent(src)
    }
    
    public var body: some View {
        if let url = resolvedURL {
            ZStack(alignment: .bottomTrailing) {
                // Use VideoPlayer but disable interaction if possible or use AVPlayerLayer
                // Actually, tapping VideoPlayer might toggle controls.
                // To force "Tap to Fullscreen", we can put an invisible button on top.
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(minHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .disabled(true) // Disable native controls in timeline
                
                // Invisible overlay for tap action
                Color.black.opacity(0.001)
                    .onTapGesture {
                        showFullScreen = true
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .fullScreenCover(isPresented: $showFullScreen) {
                FullScreenVideoPlayer(url: url)
            }
        } else {
            ZStack {
                Rectangle().fill(Color.gray.opacity(0.2))
                VStack {
                    Image(systemName: "video.slash")
                    Text("Invalid Video Source").font(.caption)
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

public struct FullScreenVideoPlayer: View {
    public let url: URL
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            VideoPlayer(player: AVPlayer(url: url))
                .ignoresSafeArea()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding()
            .padding(.top, 40) // Adjust for status bar if needed
        }
    }
}

public struct FullScreenImageView: View {
    public let src: String
    @Environment(\.dismiss) private var dismiss
    
    private var resolvedURL: URL? {
        if src.hasPrefix("http") || src.hasPrefix("file") {
            return URL(string: src)
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return docs?.appendingPathComponent(src)
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: resolvedURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                         .aspectRatio(contentMode: .fit)
                         .ignoresSafeArea()
                case .failure:
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.white)
                        Text("Failed to load image")
                            .foregroundColor(.white)
                    }
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                @unknown default:
                    EmptyView()
                }
            }
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding()
            .padding(.top, 40)
        }
    }
}

public struct ImageEntry: View {
    public let src: String
    public init(src: String) { self.src = src }
    @State private var loaded = false
    @State private var showFullScreen = false
    
    public var body: some View {
        ZStack {
            if !loaded {
                Rectangle().fill(Colors.slateLight).overlay(ProgressView()).transition(.opacity)
            }
            AsyncImage(url: resolvedURL) { phase in
                switch phase {
                case .empty:
                    Color.clear
                case .success(let image):
                    image.resizable().scaledToFill().grayscale(0.2).onAppear { loaded = true }
                case .failure:
                    VStack(spacing: 8) {
                        Image(systemName: "photo").foregroundColor(.gray)
                        Text(NSLocalizedString("noImageSource", comment: "")).font(Typography.fontEngraved).foregroundColor(.gray)
                    }
                @unknown default:
                    Color.clear
                }
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            showFullScreen = true
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenImageView(src: src)
        }
    }
    
    private var resolvedURL: URL? {
        if src.hasPrefix("http") || src.hasPrefix("file") {
            return URL(string: src)
        }
        // Assume local filename in Documents Directory
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return docs?.appendingPathComponent(src)
    }
}

class AudioPlayerController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var progress: Double = 0.0
    @Published var samples: [Double] = Array(repeating: 0.1, count: 40)
    var player: AVAudioPlayer?
    private var displayLink: CADisplayLink?
    
    func play(url: URL) {
        if isPlaying { pause(); return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            if player == nil {
                player = try AVAudioPlayer(contentsOf: url)
                player?.delegate = self
                player?.prepareToPlay()
            }
            player?.play()
            isPlaying = true
            startAnimation()
        } catch {
            print("Playback error: \(error)")
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopAnimation()
    }
    
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        stopAnimation()
        progress = 0
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.stopAnimation()
            self.progress = 1.0 // Ensure full completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.progress = 0 // Reset after delay
            }
        }
    }
    
    private func startAnimation() {
        stopAnimation()
        displayLink = CADisplayLink(target: self, selector: #selector(updatePhase))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updatePhase() {
        guard let p = player, p.isPlaying else { return }
        withAnimation(.linear(duration: 0.1)) {
            self.progress = p.currentTime / p.duration
        }
    }
    
    func processAudio(url: URL, count: Int = 40) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let file = try AVAudioFile(forReading: url)
                let format = file.processingFormat
                let frameCount = Int64(file.length)
                // Skip if file is too long (limit to ~10 mins for analysis to avoid OOM)
                if frameCount > 44100 * 600 {
                     DispatchQueue.main.async { self.samples = Array(repeating: 0.2, count: count) }
                     return
                }
                
                let samplesPerSegment = frameCount / Int64(count)
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return }
                try file.read(into: buffer)
                
                guard let channelData = buffer.floatChannelData?[0] else { return }
                
                var newSamples: [Double] = []
                
                for i in 0..<count {
                    let start = Int64(i) * samplesPerSegment
                    let end = min(start + samplesPerSegment, frameCount)
                    var sum: Float = 0
                    
                    // Optimization: Don't read every sample if segment is huge
                    let step = max(1, Int(end - start) / 100)
                    
                    for j in stride(from: Int(start), to: Int(end), by: step) {
                        let sample = channelData[j]
                        sum += sample * sample
                    }
                    
                    let rms = sqrt(sum / Float((end - start) / Int64(step)))
                    newSamples.append(Double(rms))
                }
                
                // Normalize
                if let max = newSamples.max(), max > 0.001 {
                    newSamples = newSamples.map { max > 0 ? max * 0.1 + $0 / max * 0.9 : 0.1 } // Keep some baseline
                } else {
                    newSamples = Array(repeating: 0.1, count: count)
                }
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.samples = newSamples
                    }
                }
            } catch {
                print("Waveform processing failed: \(error)")
                DispatchQueue.main.async { self.samples = Array(repeating: 0.2, count: count) }
            }
        }
    }
}

public struct AudioEntry: View {
    @StateObject private var controller = AudioPlayerController()
    public let duration: String
    public let content: String?
    public let url: String?
    
    public init(duration: String, content: String? = nil, url: String? = nil) { 
        self.duration = duration
        self.content = content 
        self.url = url
    }
    
    private var audioURL: URL? {
        guard let path = url else { return nil }
        if path.hasPrefix("file") { return URL(string: path) }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return docs?.appendingPathComponent(path)
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button(action: {
                    if let u = audioURL { controller.play(url: u) }
                }) {
                    ZStack {
                        Circle().fill(controller.isPlaying ? Colors.slateText : .white)
                        Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill").foregroundColor(controller.isPlaying ? .white : .gray)
                    }
                }
                .frame(width: 40, height: 40)
                
                // Waveform
                GeometryReader { geo in
                    HStack(alignment: .center, spacing: 2) {
                        ForEach(controller.samples.indices, id: \.self) { i in
                            let h = max(4, CGFloat(controller.samples[i]) * 30) // Max height 30
                            Capsule()
                                .fill(i < Int(Double(controller.samples.count) * controller.progress) ? Colors.slateText : Colors.systemGray.opacity(0.3))
                                .frame(width: 3, height: h)
                        }
                    }
                    .frame(height: 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 40)
                
                Spacer()
                Text(duration).font(Typography.fontEngraved).foregroundColor(Colors.systemGray)
            }
            if let txt = (content?.trimmingCharacters(in: .whitespacesAndNewlines)), !txt.isEmpty {
                Text(txt).font(.system(size: 14)).foregroundColor(Colors.slateText).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            if let u = audioURL {
                controller.processAudio(url: u)
            }
        }
        .onDisappear {
            controller.stop()
        }
    }
}

public struct SpecialContentRenderer: View {
    public let entry: JournalEntry?
    public let fallback: String?
    public let textStyle: Font?
    public init(entry: JournalEntry?, fallback: String? = nil, textStyle: Font? = nil) { self.entry = entry; self.fallback = fallback; self.textStyle = textStyle }
    public var body: some View {
        Group {
            if let e = entry {
                switch e.type {
                case .mixed:
                    if let blocks = e.metadata?.blocks {
                        VStack(spacing: 12) {
                            ForEach(Array(blocks.enumerated()), id: \.offset) { _, b in
                                renderBlock(b)
                            }
                        }
                    }
                case .image:
                    VStack(alignment: .leading, spacing: 6) {
                        let def = "https://images.unsplash.com/photo-1517701604599-bb29b5dd73ad?q=80&w=1000&auto=format&fit=crop"
                        ImageEntry(src: e.url ?? def)
                        if let c = e.content { Text(c).font(textStyle ?? .system(size: 14)).foregroundColor(Colors.systemGray) }
                    }
                case .audio:
                    AudioEntry(duration: e.metadata?.duration ?? "00:15", content: e.content, url: e.url)
                case .video:
                    VStack(alignment: .leading, spacing: 6) {
                        VideoEntry(src: e.url ?? "")
                        if let c = e.content { Text(c).font(textStyle ?? .system(size: 14)).foregroundColor(Colors.systemGray) }
                    }
                case .file:
                    FileEntry(url: e.url, name: e.content ?? "File")
                default:
                    Text(e.content ?? "").font(textStyle ?? .system(size: 14)).foregroundColor(Colors.slateText).frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text(fallback ?? NSLocalizedString("dataNotFound", comment: "")).font(.system(size: 12)).foregroundColor(Colors.systemGray)
            }
        }
    }
    @ViewBuilder
    private func renderBlock(_ b: ContentBlock) -> some View {
        switch b.type {
        case .text:
            Text(b.content).font(textStyle ?? .system(size: 14)).foregroundColor(Colors.slateText).frame(maxWidth: .infinity, alignment: .leading)
        case .image:
            VStack(alignment: .leading, spacing: 4) {
                let def = "https://images.unsplash.com/photo-1519865885898-a54a6f2c7eea?q=80&w=1000&auto=format&fit=crop"
                let src = b.url ?? (b.content.isEmpty ? def : b.content)
                ImageEntry(src: src)
                if b.content.count > 0 {
                    Text(b.content).font(.system(size: 12)).foregroundColor(Colors.systemGray)
                }
            }
        case .audio:
            AudioEntry(duration: b.duration ?? "00:15", content: b.content, url: b.url)
        case .video:
            VStack(alignment: .leading, spacing: 4) {
                VideoEntry(src: b.url ?? "")
                if !b.content.isEmpty {
                    Text(b.content).font(.system(size: 12)).foregroundColor(Colors.systemGray)
                }
            }
        case .file:
            FileEntry(url: b.url, name: b.content)
        case .mixed:
            EmptyView()
        }
    }
}

public struct FileEntry: View {
    public let url: String?
    public let name: String
    
    @State private var showShareSheet = false
    
    private var fileURL: URL? {
        guard let path = url else { return nil }
        if path.hasPrefix("file") { return URL(string: path) }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return docs?.appendingPathComponent(path)
    }
    
    public var body: some View {
        Button(action: {
            if fileURL != nil { showShareSheet = true }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "doc.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Colors.indigo)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Colors.slateText)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .sheet(isPresented: $showShareSheet) {
            if let u = fileURL {
                ShareSheet(activityItems: [u])
            }
        }
    }
}
