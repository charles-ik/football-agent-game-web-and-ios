import SwiftUI

struct ClientsView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        NavigationStack {
            if let game = store.game {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        HeroBanner(image: "career-tunnel", eyebrow: "People before deals",
                                   title: "Your clients", detail: "Understand ambition, protect trust and guide every next chapter.")
                        HStack(spacing: 10) {
                            MetricTile(label: "Roster", value: "\(game.clients.count) / \(game.clientCapacity)", systemImage: "person.2")
                            MetricTile(label: "Average trust", value: "\(averageTrust(game))", systemImage: "heart.fill", tint: .green)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(game.clients) { client in
                            if let player = game.player(client.playerID) {
                                NavigationLink { ClientDetailView(playerID: player.id) } label: {
                                    ClientRow(player: player, client: client, club: game.club(player.clubID))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16).padding(.bottom, 8)
                }
                .background(NativeTheme.deepGreen)
                .navigationTitle("Clients").navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func averageTrust(_ game: GameState) -> Int {
        guard !game.clients.isEmpty else { return 0 }
        return game.clients.reduce(0) { $0 + $1.trust } / game.clients.count
    }
}

private struct ClientRow: View {
    let player: Player
    let client: Client
    let club: Club?

    var body: some View {
        GameCard {
            HStack(spacing: 13) {
                Text(player.position.shortLabel)
                    .font(.caption.bold()).frame(width: 43, height: 43)
                    .background(NativeTheme.gold.opacity(0.15), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(player.name).font(.headline)
                    Text("\(club?.name ?? "Free agent") · \(client.playingTime.label)")
                        .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                    HStack(spacing: 10) {
                        Label("\(client.trust)", systemImage: "heart.fill")
                        if client.seekingMove { Label("Available", systemImage: "arrow.right.circle") }
                        if player.injuryWeeks > 0 { Label("\(player.injuryWeeks)w injury", systemImage: "cross.case.fill") }
                    }
                    .font(.caption).foregroundStyle(client.trust < 35 ? .orange : .secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
        }
    }
}

struct ClientDetailView: View {
    @EnvironmentObject private var store: GameStore
    let playerID: GameID
    @State private var promise = "Secure a better football opportunity"
    @State private var confirmingRelease = false

    var body: some View {
        if let game = store.game,
           let player = game.player(playerID),
           let client = game.clients.first(where: { $0.playerID == playerID }) {
            ScrollView {
                VStack(spacing: 16) {
                    GameCard {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(player.name).font(.title2.bold())
                                Text("\(player.age) · \(player.position.label) · \(player.trait.label)")
                                    .foregroundStyle(.secondary)
                                Text(game.club(player.clubID)?.name ?? "Free agent").font(.headline)
                            }
                            Spacer()
                            Text("\(client.trust)")
                                .font(.title.bold()).foregroundStyle(client.trust < 35 ? .orange : NativeTheme.gold)
                                .accessibilityLabel("Trust \(client.trust) out of 100")
                        }
                        ProgressView(value: Double(client.trust), total: 100).tint(client.trust < 35 ? .orange : .green).padding(.top, 12)
                    }
                    GameCard {
                        SectionTitle(title: "Career plan", detail: client.careerGoal)
                        detailRow("Playing time", client.playingTime.label)
                        detailRow("Contract", "\(player.contractWeeks) weeks")
                        detailRow("Representation", "\(client.representationWeeks) weeks · \(client.commissionPercent.formatted(.number.precision(.fractionLength(1))))%")
                        detailRow("Deals completed", "\(client.dealsDone)")
                        if player.injuryWeeks > 0 { detailRow("Injury", "\(player.injuryWeeks) weeks remaining") }
                    }
                    GameCard {
                        SectionTitle(title: "Career actions", detail: "Clear, consequential choices — no hidden cooldowns.")
                        Toggle("Seek a permanent move", isOn: Binding(
                            get: { client.seekingMove && !client.wantsLoan },
                            set: { _ = store.perform(.seekMove(playerID, $0)) }
                        ))
                        if GameEngine.featureAccess(in: game)[.loans]?.unlocked == true {
                            Toggle("Prioritise a loan", isOn: Binding(
                                get: { client.wantsLoan },
                                set: { _ = store.perform(.requestLoan(playerID, $0)) }
                            ))
                        } else {
                            Label("Loan desk unlocks after your first commission", systemImage: "lock.fill")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Menu("Have a conversation") {
                            ForEach(ConversationType.allCases) { type in
                                Button(type.label) { _ = store.perform(.conversation(playerID, type)) }
                            }
                        }
                        .buttonStyle(.bordered)
                        if client.promiseDeadline == nil {
                            TextField("Promise", text: $promise).textFieldStyle(.roundedBorder)
                            Button("Make 12-week promise") { _ = store.perform(.makePromise(playerID, promise)) }
                                .buttonStyle(.bordered)
                        } else {
                            Label("\(client.promiseText ?? "Promise") · due week \(client.promiseDeadline ?? 0)", systemImage: "calendar.badge.clock")
                                .font(.subheadline).foregroundStyle(.orange)
                        }
                        Button("Renew representation") { _ = store.perform(.renewRepresentation(playerID)) }
                            .buttonStyle(.bordered).disabled(client.representationWeeks > 26)
                    }
                    careerHistory(game)
                    Button("End representation", role: .destructive) { confirmingRelease = true }
                        .buttonStyle(.bordered).disabled(game.clients.count <= 1)
                }
                .padding(16)
            }
            .background(NativeTheme.deepGreen)
            .navigationTitle(player.name).navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("End representation?", isPresented: $confirmingRelease, titleVisibility: .visible) {
                Button("Release client", role: .destructive) { _ = store.perform(.releaseClient(playerID)) }
                Button("Cancel", role: .cancel) {}
            } message: { Text("The player moves to alumni. This cannot be undone.") }
        } else {
            EmptyState(icon: "person.slash", title: "No longer a client", detail: "This player has left the agency.")
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label).foregroundStyle(.secondary); Spacer(); Text(value).multilineTextAlignment(.trailing) }
            .font(.subheadline).padding(.top, 8)
    }

    private func careerHistory(_ game: GameState) -> some View {
        GameCard {
            SectionTitle(title: "Career story")
            let entries = game.careers.filter { $0.playerID == playerID }.sorted { $0.week > $1.week }
            if entries.isEmpty {
                Text("No recorded chapters yet.").foregroundStyle(.secondary).padding(.top, 8)
            } else {
                ForEach(entries) { entry in
                    HStack(alignment: .top, spacing: 10) {
                        Text("W\(entry.week)").font(.caption.bold()).foregroundStyle(NativeTheme.gold).frame(width: 34)
                        VStack(alignment: .leading) {
                            Text(entry.title).font(.subheadline.bold())
                            Text(entry.detail).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
    }
}

struct ScoutingView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        NavigationStack {
            if let game = store.game {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        HeroBanner(image: "scouting-ground", eyebrow: "Find the overlooked",
                                   title: "Scouting room", detail: "Set a brief, learn patiently and act when the picture is clear enough.")
                        ForEach(game.scouts) { scout in ScoutCard(scout: scout, game: game) }
                        Button("Hire another scout") { _ = store.perform(.hireScout) }
                            .buttonStyle(.borderedProminent)
                            .disabled(game.scouts.count >= game.scoutCapacity)
                        SectionTitle(title: "Reports", detail: "Ranges narrow with continued observation. True ratings stay hidden.")
                        if game.reports.isEmpty {
                            EmptyState(icon: "binoculars", title: "No reports yet", detail: "Assign your scout, then advance a few weeks.")
                        } else {
                            ForEach(game.reports.sorted { $0.updatedWeek > $1.updatedWeek }) { report in
                                if let player = game.player(report.playerID) {
                                    NavigationLink { ReportDetailView(reportID: report.id) } label: {
                                        ReportRow(report: report, player: player, club: game.club(player.clubID))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .background(NativeTheme.deepGreen)
                .navigationTitle("Scouting").navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

private struct ScoutCard: View {
    @EnvironmentObject private var store: GameStore
    let scout: Scout
    let game: GameState

    var body: some View {
        GameCard {
            HStack {
                VStack(alignment: .leading) {
                    Text(scout.name).font(.headline)
                    Text("Quality \(scout.quality) · \(money(scout.salary))/week").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "person.text.rectangle.fill").foregroundStyle(NativeTheme.gold)
            }
            Picker("Region", selection: Binding(
                get: { scout.regionID ?? "" },
                set: { if !$0.isEmpty { _ = store.perform(.assignScout(scout.id, regionID: $0)) } }
            )) {
                Text("Choose a region").tag("")
                ForEach(game.regions) { region in
                    Text("\(region.name) · \(money(region.scoutingCost))/wk").tag(region.id)
                }
            }
            .pickerStyle(.menu).padding(.top, 6)
            Picker("Position brief", selection: Binding(
                get: { scout.focus?.rawValue ?? "all" },
                set: { _ = store.perform(.setScoutFocus(scout.id, $0 == "all" ? nil : Position(rawValue: $0))) }
            )) {
                Text("All positions").tag("all")
                ForEach(Position.allCases, id: \.rawValue) { Text($0.label).tag($0.rawValue) }
            }
            .pickerStyle(.menu)
            if scout.regionID != nil {
                ProgressView(value: Double(scout.progress), total: Double(max(2, 5 - scout.quality / 22))).tint(NativeTheme.gold)
                    .accessibilityLabel("Progress toward next report")
            }
            if game.scouts.count > 1 {
                Button("Release scout", role: .destructive) { _ = store.perform(.fireScout(scout.id)) }
                    .buttonStyle(.bordered).padding(.top, 10)
            }
        }
    }
}

private struct ReportRow: View {
    let report: ScoutingReport
    let player: Player
    let club: Club?

    var body: some View {
        GameCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(player.name).font(.headline)
                        if report.shortlisted { Image(systemName: "star.fill").foregroundStyle(NativeTheme.gold) }
                    }
                    Text("\(player.age) · \(player.position.label) · \(club?.name ?? "Free agent")")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Ability \(report.abilityLow)–\(report.abilityHigh) · Potential \(report.potentialLow)–\(report.potentialHigh)")
                        .font(.subheadline.monospacedDigit())
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
        }
    }
}

private struct ReportDetailView: View {
    @EnvironmentObject private var store: GameStore
    let reportID: GameID

    var body: some View {
        if let game = store.game,
           let report = game.reports.first(where: { $0.id == reportID }),
           let player = game.player(report.playerID) {
            ScrollView {
                VStack(spacing: 16) {
                    GameCard {
                        Text(player.name).font(.title2.bold())
                        Text("\(player.age) · \(player.position.label) · \(player.trait.label)").foregroundStyle(.secondary)
                        Text(game.club(player.clubID)?.name ?? "Free agent").font(.headline).padding(.top, 6)
                    }
                    GameCard {
                        SectionTitle(title: "Observed profile", detail: "Updated week \(report.updatedWeek) after \(report.observedWeeks) week\(report.observedWeeks == 1 ? "" : "s")")
                        range("Current ability", low: report.abilityLow, high: report.abilityHigh)
                        range("Potential", low: report.potentialLow, high: report.potentialHigh)
                        Text("The scout’s uncertainty narrows over time; exact hidden ratings are never exposed.")
                            .font(.caption).foregroundStyle(.secondary).padding(.top, 10)
                    }
                    Button(report.shortlisted ? "Remove from shortlist" : "Add to shortlist") {
                        _ = store.perform(.shortlist(report.id))
                    }
                    .buttonStyle(.bordered)
                    Button(report.approached ? "Approach already used" : "Approach to represent") {
                        _ = store.perform(.openRepresentation(report.id))
                    }
                    .buttonStyle(PrimaryGameButtonStyle()).disabled(report.approached)
                }
                .padding(16)
            }
            .background(NativeTheme.deepGreen)
            .navigationTitle("Scout report").navigationBarTitleDisplayMode(.inline)
        } else {
            EmptyState(icon: "doc.questionmark", title: "Report unavailable", detail: "This scouting report no longer exists.")
        }
    }

    private func range(_ label: String, low: Int, high: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Text(label); Spacer(); Text("\(low)–\(high)").font(.headline.monospacedDigit()) }
            ProgressView(value: Double(low), total: 100).tint(NativeTheme.gold)
        }
        .padding(.top, 14)
    }
}
