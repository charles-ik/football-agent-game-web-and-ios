import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        Group {
            if let game = store.game {
                if let reason = game.gameOverReason {
                    GameOverView(reason: reason)
                } else {
                    GameRootView()
                }
            } else {
                NewGameView()
            }
        }
        .tint(NativeTheme.gold)
        .preferredColorScheme(.dark)
        .alert("Autosave needs attention", isPresented: Binding(
            get: { store.persistentError != nil },
            set: { if !$0 { store.persistentError = nil } }
        )) {
            Button("OK", role: .cancel) { store.persistentError = nil }
        } message: {
            Text(store.persistentError ?? "")
        }
    }
}

private struct NewGameView: View {
    @EnvironmentObject private var store: GameStore
    @State private var name = "Touchline Agency"
    @State private var seed = String(UInt64(Date().timeIntervalSince1970))

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image("scouting-ground")
                    .resizable().scaledToFill().frame(height: 290).clipped()
                    .overlay(LinearGradient(colors: [.clear, NativeTheme.deepGreen], startPoint: .top, endPoint: .bottom))
                    .accessibilityLabel("A football training ground at dawn")
                VStack(alignment: .leading, spacing: 12) {
                    Text("FOOTBALL AGENT").font(.caption.bold()).tracking(2).foregroundStyle(NativeTheme.gold)
                    Text("Build careers. Earn trust. Leave a legacy.").font(.largeTitle.bold())
                    Text("Start with one client and one scout. Every week brings choices across transfers, development, relationships and the business behind the game.")
                        .foregroundStyle(.secondary)
                    TextField("Agency name", text: $name)
                        .textInputAutocapitalization(.words).textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Agency name")
                    DisclosureGroup("Advanced") {
                        TextField("World seed", text: $seed).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                        Text("Use the same seed to recreate the same fictional football world.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Button("Begin your career") {
                        store.newGame(name: name, seed: UInt64(seed) ?? UInt64(Date().timeIntervalSince1970))
                    }
                    .buttonStyle(PrimaryGameButtonStyle())
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 20)
                if !store.slots.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(title: "Continue a career")
                        ForEach(store.slots) { slot in
                            Button { store.load(slot: slot.id) } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(slot.agencyName).font(.headline)
                                        Text("Season \(slot.season) · Week \(slot.week)").font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                }
                                .padding(14).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .padding(.bottom, 24)
        }
        .background(NativeTheme.deepGreen.ignoresSafeArea())
    }
}

private struct GameRootView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            OfficeView(selection: $selection)
                .safeAreaInset(edge: .bottom, spacing: 0) { ContinueBar() }
                .tabItem { Label("Office", systemImage: "building.2.fill") }.tag(0)
            ClientsView()
                .safeAreaInset(edge: .bottom, spacing: 0) { ContinueBar() }
                .tabItem { Label("Clients", systemImage: "person.2.fill") }.tag(1)
            ScoutingView()
                .safeAreaInset(edge: .bottom, spacing: 0) { ContinueBar() }
                .tabItem { Label("Scouting", systemImage: "binoculars.fill") }.tag(2)
            MarketView()
                .safeAreaInset(edge: .bottom, spacing: 0) { ContinueBar() }
                .tabItem { Label("Market", systemImage: "arrow.left.arrow.right") }.tag(3)
            MoreView()
                .safeAreaInset(edge: .bottom, spacing: 0) { ContinueBar() }
                .tabItem { Label("More", systemImage: "ellipsis") }.tag(4)
        }
        .sheet(isPresented: Binding(
            get: { store.game?.negotiation != nil },
            set: { if !$0, store.game?.negotiation != nil { _ = store.perform(.walkAway) } }
        )) {
            NegotiationSheet().presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible).interactiveDismissDisabled()
        }
        .sensoryFeedback(.success, trigger: store.game?.week)
        .overlay(alignment: .top) {
            if let message = store.lastMessage {
                Button { store.dismissMessage() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(NativeTheme.gold)
                        Text(message).font(.subheadline.weight(.semibold)).multilineTextAlignment(.leading)
                        Spacer(minLength: 4)
                        Image(systemName: "xmark").font(.caption).foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.primary).padding(13)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 10, y: 4)
                }
                .buttonStyle(.plain).padding(.horizontal, 16).padding(.top, 52)
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityHint("Double-tap to dismiss")
            }
        }
        .animation(.snappy, value: store.lastMessage)
        .onChange(of: store.lastMessage) { _, message in
            guard let message else { return }
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if store.lastMessage == message { store.dismissMessage() }
            }
        }
    }
}

private struct ContinueBar: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        if let game = store.game {
            let decisions = GameEngine.decisions(in: game)
            HStack(spacing: 10) {
                Button { store.advance(.oneWeek) } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Continue").font(.headline)
                        Text("Week \(game.week) → \(game.week + 1)").font(.caption2).opacity(0.75)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).frame(minHeight: 44)
                }
                .buttonStyle(.plain).disabled(store.isAdvancing)
                Menu {
                    Button("Advance one week") { store.advance(.oneWeek) }
                    Button("Advance four weeks") { store.advance(.weeks(4)) }
                    Button("Advance to next event") { store.advance(.nextEvent) }
                    if !decisions.isEmpty {
                        Divider()
                        Text("\(decisions.count) decision\(decisions.count == 1 ? "" : "s") open")
                    }
                } label: {
                    Image(systemName: decisions.isEmpty ? "forward.fill" : "exclamationmark.circle.fill")
                        .font(.title3).frame(width: 46, height: 46)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Advance options")
            }
            .foregroundStyle(.white).padding(.horizontal, 16).padding(.vertical, 9)
            .background(NativeTheme.green.opacity(0.98))
            .overlay(alignment: .top) { Divider().overlay(NativeTheme.gold.opacity(0.45)) }
        }
    }
}

struct OfficeView: View {
    @EnvironmentObject private var store: GameStore
    @Binding var selection: Int

    var body: some View {
        NavigationStack {
            if let game = store.game {
                ScrollView {
                    LazyVStack(spacing: 18) {
                        HeroBanner(image: "agency-desk", eyebrow: "Season \(game.season) · Week \(game.week)",
                                   title: game.agency.name,
                                   detail: game.transferWindowOpen ? "The transfer window is open. Make the right call." : "Build patiently between decisive moments.")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                MetricTile(label: "Cash", value: money(game.agency.cash), systemImage: "sterlingsign.circle")
                                MetricTile(label: "Clients", value: "\(game.clients.count) / \(game.clientCapacity)", systemImage: "person.2")
                                MetricTile(label: "Reputation", value: "\(game.agency.reputation)", systemImage: "star.fill")
                                MetricTile(label: "Weekly net", value: money(game.recurringNet), systemImage: "chart.line.uptrend.xyaxis", tint: game.recurringNet >= 0 ? .green : .orange)
                            }
                        }
                        .contentMargins(.horizontal, 1)
                        nextMoveCard(game)
                        stageCard(game)
                        objectiveCard(game)
                        decisionsCard(game)
                        eventsCard(game)
                    }
                    .padding(16).padding(.bottom, 10)
                }
                .background(NativeTheme.deepGreen)
                .navigationTitle("Office").navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func nextMoveCard(_ game: GameState) -> some View {
        let move = GameEngine.nextMove(in: game)
        return GameCard {
            Label("YOUR NEXT MOVE", systemImage: "scope").font(.caption.bold()).foregroundStyle(NativeTheme.gold)
            Text(move.title).font(.title3.bold()).padding(.top, 4)
            Text(move.detail).font(.subheadline).foregroundStyle(.secondary).padding(.top, 1)
            Button("Go there") { selection = move.tab }.buttonStyle(.borderedProminent).padding(.top, 8)
        }
    }

    private func stageCard(_ game: GameState) -> some View {
        GameCard {
            SectionTitle(title: "\(game.stage.label) agency", detail: game.stage == .elite ? "You have reached the game’s highest standing." : "Next: \(game.nextStageText)")
            ProgressView(value: Double(game.agency.reputation), total: 100).tint(NativeTheme.gold).padding(.top, 10)
            HStack {
                Label("\(game.progression.milestones.count) milestones", systemImage: "flag.checkered")
                Spacer()
                Text(money(game.agency.totalCommission) + " commission")
            }
            .font(.caption).foregroundStyle(.secondary).padding(.top, 8)
        }
    }

    @ViewBuilder private func objectiveCard(_ game: GameState) -> some View {
        if let objective = game.progression.objective, let progress = GameEngine.objectiveProgress(game) {
            GameCard {
                SectionTitle(title: objective.kind.label, detail: objective.completed ? "Complete — reward claimed" : "Season objective")
                ProgressView(value: min(progress.value, progress.target), total: max(1, progress.target))
                    .tint(objective.completed ? .green : NativeTheme.gold).padding(.top, 10)
                Text("Reward: \(money(objective.rewardCash)) and \(objective.rewardReputation) reputation")
                    .font(.caption).foregroundStyle(.secondary).padding(.top, 8)
            }
        } else {
            GameCard {
                SectionTitle(title: "Choose a season objective", detail: "Set a clear target and earn an explicit reward.")
                Menu("Select objective") {
                    ForEach(ObjectiveKind.allCases) { kind in Button(kind.label) { _ = store.perform(.selectObjective(kind)) } }
                }
                .buttonStyle(.borderedProminent).padding(.top, 8)
            }
        }
    }

    @ViewBuilder private func decisionsCard(_ game: GameState) -> some View {
        let decisions = GameEngine.decisions(in: game)
        if !decisions.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(title: "Open decisions", detail: "Most urgent first")
                ForEach(decisions) { decision in
                    GameCard {
                        HStack(alignment: .top) {
                            Image(systemName: decision.severity == .urgent ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(decision.severity == .urgent ? .red : .orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(decision.title).font(.headline)
                                Text(decision.detail).font(.subheadline).foregroundStyle(.secondary)
                                if let deadline = decision.deadlineWeek { Text("Deadline: week \(deadline)").font(.caption.bold()) }
                            }
                        }
                    }
                }
            }
        }
    }

    private func eventsCard(_ game: GameState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Recent events")
            if game.events.isEmpty {
                EmptyState(icon: "newspaper", title: "No news yet", detail: "Advance time to begin the story.")
            } else {
                ForEach(game.events.suffix(8).reversed()) { event in
                    GameCard {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: event.tone.icon).foregroundStyle(event.tone.color)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.title).font(.headline)
                                Text(event.detail).font(.subheadline).foregroundStyle(.secondary)
                                Text("Week \(event.week)").font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct NegotiationSheet: View {
    @EnvironmentObject private var store: GameStore
    @State private var proposal = 8.0

    var body: some View {
        NavigationStack {
            if let game = store.game, let negotiation = game.negotiation {
                let player = game.player(negotiation.playerID)
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(negotiation.kind == .representation ? "Representation terms" : "Transfer package").font(.title2.bold())
                        Text(player?.name ?? "Negotiation").foregroundStyle(.secondary)
                    }
                    GameCard {
                        Text(negotiation.hint).font(.headline)
                        Text("\(negotiation.roundsRemaining) round\(negotiation.roundsRemaining == 1 ? "" : "s") remaining")
                            .font(.caption).foregroundStyle(.secondary).padding(.top, 5)
                        if negotiation.lastProposal != nil {
                            Text("Their counter: \(formatted(negotiation.counter, kind: negotiation.kind))")
                                .font(.subheadline.bold()).padding(.top, 8)
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(negotiation.kind == .representation ? "Your commission" : "Package strength")
                            Spacer()
                            Text(formatted(proposal, kind: negotiation.kind)).font(.title3.bold()).monospacedDigit()
                        }
                        Slider(value: $proposal, in: negotiation.kind == .representation ? 4...16 : 35...100,
                               step: negotiation.kind == .representation ? 0.5 : 1)
                        Text(negotiation.kind == .representation ? "Higher earns more on future transfers, but is harder for the player to accept." : "A stronger package improves wage, fee and term, but tests the club’s limit.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Make proposal") { _ = store.perform(.proposeNegotiation(proposal)) }
                        .buttonStyle(PrimaryGameButtonStyle())
                }
                .padding(20)
                .onAppear { proposal = negotiation.counter }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Walk away", role: .cancel) { _ = store.perform(.walkAway) } }
                }
            }
        }
    }

    private func formatted(_ value: Double, kind: NegotiationKind) -> String {
        kind == .representation ? value.formatted(.number.precision(.fractionLength(1))) + "%" : "\(Int(value))/100"
    }
}

private struct GameOverView: View {
    @EnvironmentObject private var store: GameStore
    let reason: String

    var body: some View {
        ZStack {
            Image("career-tunnel").resizable().scaledToFill().ignoresSafeArea()
            Color.black.opacity(0.72).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "whistle.fill").font(.system(size: 44)).foregroundStyle(NativeTheme.gold)
                Text("Full time").font(.largeTitle.bold())
                Text(reason).multilineTextAlignment(.center).foregroundStyle(.secondary)
                if let game = store.game {
                    Text("\(game.agency.name) · Season \(game.season) · \(game.progression.milestones.count) milestones")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button("Delete this career and start again") {
                    if let slot = store.selectedSlot { store.delete(slot: slot) }
                }
                .buttonStyle(PrimaryGameButtonStyle())
            }
            .padding(28)
        }
    }
}
