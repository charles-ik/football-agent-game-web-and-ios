import SwiftUI

enum NativeTheme {
    static let green = Color(red: 0.06, green: 0.24, blue: 0.16)
    static let deepGreen = Color(red: 0.025, green: 0.10, blue: 0.075)
    static let gold = Color(red: 0.83, green: 0.65, blue: 0.28)
    static let cream = Color(red: 0.97, green: 0.95, blue: 0.89)
    static let ink = Color(red: 0.10, green: 0.13, blue: 0.11)
}

func money(_ value: Double) -> String {
    value.formatted(.currency(code: "GBP").precision(.fractionLength(0)))
}

struct GameCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.08)))
    }
}

struct HeroBanner: View {
    let image: String
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(height: 190)
                .clipped()
                .overlay(LinearGradient(colors: [.clear, .black.opacity(0.88)], startPoint: .top, endPoint: .bottom))
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(NativeTheme.gold)
                Text(title).font(.title2.bold()).foregroundStyle(.white)
                Text(detail).font(.subheadline).foregroundStyle(.white.opacity(0.82)).lineLimit(3)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct MetricTile: View {
    let label: String
    let value: String
    var systemImage: String
    var tint: Color = NativeTheme.gold

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(label, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit()).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(width: 138, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct SectionTitle: View {
    let title: String
    var detail: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.title3.bold())
            if let detail { Text(detail).font(.subheadline).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let detail: String
    var body: some View {
        ContentUnavailableView(title, systemImage: icon, description: Text(detail))
            .frame(maxWidth: .infinity, minHeight: 190)
    }
}

struct LockedFeatureView: View {
    let title: String
    let requirement: String
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "lock.fill")
        } description: {
            Text(requirement)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }
}

extension EventTone {
    var color: Color {
        switch self {
        case .good: .green
        case .neutral: .secondary
        case .warning: .orange
        case .urgent: .red
        }
    }
    var icon: String {
        switch self {
        case .good: "checkmark.circle.fill"
        case .neutral: "circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .urgent: "exclamationmark.octagon.fill"
        }
    }
}

struct PrimaryGameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(NativeTheme.deepGreen)
            .background(NativeTheme.gold.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
