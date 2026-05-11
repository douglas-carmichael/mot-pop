import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct MotPopApp: App {
    @StateObject private var session = GameSession()

    #if os(macOS)
    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    #endif

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                #if os(macOS)
                .frame(width: 1100, height: 840)
                #endif
                .preferredColorScheme(.dark)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .help) {
                Button {
                    session.showHowToPlay = true
                } label: {
                    Text("menu.howToPlay")
                }
                .keyboardShortcut("?", modifiers: [.command])
            }
        }
        #endif
    }
}

struct RootView: View {
    @EnvironmentObject var session: GameSession

    var body: some View {
        ZStack {
            BackgroundGradient()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(36)

            if session.showHowToPlay {
                HowToPlayView(isPresented: Binding(
                    get: { session.showHowToPlay },
                    set: { session.showHowToPlay = $0 }
                ))
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: session.phase)
        .animation(.easeInOut(duration: 0.18), value: session.showHowToPlay)
    }

    @ViewBuilder
    private var content: some View {
        switch session.phase {
        case .menu:
            MenuView().transition(.opacity.combined(with: .move(edge: .bottom)))
        case .singlePlayerSetup:
            SinglePlayerSetupView().transition(.opacity)
        case .hostLobby:
            HostLobbyView().transition(.opacity)
        case .browsing:
            BrowseView().transition(.opacity)
        case .clientLobby:
            ClientLobbyView().transition(.opacity)
        case .countdown:
            CountdownView().transition(.opacity)
        case .playing:
            GameView().transition(.opacity)
        case .roundResults, .finalResults:
            ResultsView().transition(.opacity)
        }
    }
}

private struct BackgroundGradient: View {
    var body: some View {
        ZStack {
            Color.wgBackground
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    drawBlob(ctx: ctx, size: size,
                             color: Color.wgPrimary.opacity(0.30),
                             phase: t * 0.07,
                             cx: 0.20, cy: 0.25, radius: 360)
                    drawBlob(ctx: ctx, size: size,
                             color: Color.wgAccent.opacity(0.22),
                             phase: t * 0.05 + 1.7,
                             cx: 0.85, cy: 0.20, radius: 320)
                    drawBlob(ctx: ctx, size: size,
                             color: Color(red: 1.0, green: 0.55, blue: 0.78).opacity(0.20),
                             phase: t * 0.04 + 3.2,
                             cx: 0.65, cy: 0.85, radius: 380)
                }
                .blur(radius: 60)
                .blendMode(.plusLighter)
            }
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.45)],
                center: .center,
                startRadius: 320,
                endRadius: 900
            )
            .blendMode(.multiply)
        }
        .ignoresSafeArea()
    }

    private func drawBlob(ctx: GraphicsContext, size: CGSize,
                          color: Color, phase: Double,
                          cx: CGFloat, cy: CGFloat, radius: CGFloat) {
        let dx = CGFloat(cos(phase)) * 90
        let dy = CGFloat(sin(phase * 1.13)) * 70
        let center = CGPoint(x: size.width * cx + dx, y: size.height * cy + dy)
        let rect = CGRect(x: center.x - radius, y: center.y - radius,
                          width: radius * 2, height: radius * 2)
        ctx.fill(Path(ellipseIn: rect), with: .color(color))
    }
}
