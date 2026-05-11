import SwiftUI

struct HowToPlayView: View {
    @Binding var isPresented: Bool
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                #if !os(tvOS)
                .onTapGesture { close() }
                #endif

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        IntroBlurb()
                        StepRow(number: 1,
                                systemImage: "rectangle.stack.fill",
                                accent: .wgPrimary,
                                title: "howto.step1.title",
                                detail: "howto.step1.body")
                        StepRow(number: 2,
                                systemImage: "text.bubble.fill",
                                accent: .wgAccent,
                                title: "howto.step2.title",
                                detail: "howto.step2.body")
                        ExampleSentence()
                        StepRow(number: 3,
                                systemImage: "timer",
                                accent: .wgWaiting,
                                title: "howto.step3.title",
                                detail: "howto.step3.body")
                        StepRow(number: 4,
                                systemImage: "rectangle.grid.2x2.fill",
                                accent: .wgGood,
                                title: "howto.step4.title",
                                detail: "howto.step4.body")
                        TipsBlock()
                        CreditsBlock()
                    }
                    .padding(28)
                }
            }
            .frame(maxWidth: 720, maxHeight: 640)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.wgBackground)
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(colors: [Color.wgPrimary.opacity(0.15), Color.wgAccent.opacity(0.06)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [Color.wgPrimary.opacity(0.5), Color.white.opacity(0.06)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.4)
            )
            .shadow(color: .black.opacity(0.55), radius: 30, y: 18)
            .scaleEffect(appeared ? 1 : 0.94)
            .opacity(appeared ? 1 : 0)
        }
        #if os(tvOS)
        .onExitCommand { close() }
        #endif
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { appeared = true }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 12) {
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [.wgPrimary, .wgAccent],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("howto.title")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button(action: close) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.wgMuted)
            }
            .buttonStyle(.plain)
            #if !os(tvOS)
            .keyboardShortcut(.cancelAction)
            #endif
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.18)) { appeared = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { isPresented = false }
    }
}

private struct IntroBlurb: View {
    var body: some View {
        Text("howto.intro")
            .font(.system(.title3, design: .rounded))
            .foregroundStyle(Color.wgMuted)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
    }
}

private struct StepRow: View {
    var number: Int
    var systemImage: String
    var accent: Color
    var title: LocalizedStringKey
    var detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent.opacity(0.20))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(accent.opacity(0.45), lineWidth: 1)
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(accent)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(String(format: NSLocalizedString("howto.stepNumber", value: "Step %d", comment: ""), number))
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(accent)
                        .textCase(.uppercase)
                        .tracking(1.5)
                }
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color.wgMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ExampleSentence: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "quote.opening")
                .foregroundStyle(Color.wgPrimary.opacity(0.6))
            (
                Text("howto.example.before")
                    .foregroundStyle(.white) +
                Text("howto.example.fill")
                    .foregroundStyle(Color.wgPrimary)
                    .fontWeight(.heavy) +
                Text("howto.example.after")
                    .foregroundStyle(.white)
            )
            .font(.system(.title3, design: .rounded))
            .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.wgPrimary.opacity(0.30), lineWidth: 1)
        )
    }
}

private struct TipsBlock: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill").foregroundStyle(Color.wgWaiting)
                Text("howto.tips.title")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 6) {
                TipBullet(text: "howto.tip1")
                TipBullet(text: "howto.tip2")
                TipBullet(text: "howto.tip3")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.wgWaiting.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.wgWaiting.opacity(0.20), lineWidth: 1)
        )
    }
}

private struct TipBullet: View {
    var text: LocalizedStringKey
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(Color.wgWaiting)
                .font(.system(.body, design: .rounded).weight(.bold))
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.wgMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct CreditsBlock: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill").foregroundStyle(Color.wgAccent)
                Text("howto.credits.title")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 10) {
                CreditEntry(role: "howto.credits.originalRole",
                            people: [
                                CreditPerson(name: "Amaury Crocquefer",
                                             email: "amaury@crocque.fr",
                                             link: "https://github.com/lapatatedouce59/wordGame"),
                                CreditPerson(name: "Amélie",
                                             email: "amelie@pmdapp.fr",
                                             link: "https://github.com/AisakaPMD")
                            ])
                CreditEntry(role: "howto.credits.portRole",
                            people: [
                                CreditPerson(name: "Douglas Carmichael",
                                             email: "dcarmich@dcarmichael.net",
                                             link: nil)
                            ])
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.wgAccent.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.wgAccent.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct CreditPerson {
    var name: String
    var email: String
    var link: String?
}

private struct CreditEntry: View {
    var role: LocalizedStringKey
    var people: [CreditPerson]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(role)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(Color.wgAccent)
                .textCase(.uppercase)
                .tracking(1.5)
            ForEach(people, id: \.name) { person in
                HStack(spacing: 6) {
                    Text(person.name)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white)
                    #if os(tvOS)
                    Text("·")
                        .foregroundStyle(Color.wgMuted)
                    Text(person.email)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.wgAccent)
                    #else
                    Text("·")
                        .foregroundStyle(Color.wgMuted)
                    if let url = URL(string: "mailto:\(person.email)") {
                        Link(person.email, destination: url)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color.wgAccent)
                    }
                    #endif
                    if let linkString = person.link {
                        Text("·")
                            .foregroundStyle(Color.wgMuted)
                        #if os(tvOS)
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 10))
                            Text(linkString.replacingOccurrences(of: "https://", with: ""))
                                .font(.system(.caption, design: .monospaced))
                        }
                        .foregroundStyle(Color.wgAccent)
                        #else
                        if let url = URL(string: linkString) {
                            Link(destination: url) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                        .font(.system(size: 10))
                                    Text(linkString.replacingOccurrences(of: "https://", with: ""))
                                        .font(.system(.caption, design: .monospaced))
                                }
                                .foregroundStyle(Color.wgAccent)
                            }
                        }
                        #endif
                    }
                }
            }
        }
    }
}
