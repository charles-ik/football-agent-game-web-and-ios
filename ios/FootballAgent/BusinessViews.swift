import Charts
import SwiftUI

struct MarketView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        NavigationStack {
            if let game = store.game {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        HeroBanner(image: "agency-desk",
                                   eyebrow: game.transferWindowOpen ? "Window open" : "Window closed",
                                   title: "The market desk",
                                   detail: "Match ambition with opportunity and turn the right move into lasting trust.")
                        let openOffers = game.offers.filter { $0.status == .open }
                        if !openOffers.isEmpty {
                            SectionTitle(title: "Open offers", detail: "Accept the opening terms or negotiate up to three rounds.")
                            ForEach(openOffers) { offer in OfferCard(offer: offer, game: game) }
                        }
                        let access = GameEngine.featureAccess(in: game)[.market]!
                        if access.unlocked {
                            marketContent(game)
                        } else {
                            LockedFeatureView(title: "Market desk", requirement: access.requirement)
                        }
                    }
                    .padding(16)
                }
                .background(NativeTheme.deepGreen)
                .navigationTitle("Market").navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    @ViewBuilder private func marketContent(_ game: GameState) -> some View {
        GameCard {
            HStack {
                Label(game.transferWindowOpen ? "Transfer window open" : "Transfer window closed",
                      systemImage: game.transferWindowOpen ? "door.left.hand.open" : "door.left.hand.closed")
                    .font(.headline)
                Spacer()
                Text("Week \(game.weekOfSeason) / 52").font(.caption).foregroundStyle(.secondary)
            }
            Text(game.transferWindowOpen ? "Deals can be completed now." : "Prepare pitches now; permanent business resumes in weeks 1–10 or 28–31.")
                .font(.subheadline).foregroundStyle(.secondary).padding(.top, 5)
        }
        if game.offers.allSatisfy({ $0.status != .open }) {
            EmptyState(icon: "tray", title: "No offers", detail: "Mark clients available or pitch them to suitable clubs.")
        }
        SectionTitle(title: "Client availability")
        ForEach(game.clients) { client in
            if let player = game.player(client.playerID) {
                GameCard {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(player.name).font(.headline)
                            Text(game.club(player.clubID)?.name ?? "Free agent").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("Available", isOn: Binding(
                            get: { client.seekingMove },
                            set: { _ = store.perform(.seekMove(player.id, $0)) }
                        ))
                        .labelsHidden().accessibilityLabel("Make \(player.name) available")
                    }
                }
            }
        }
        NavigationLink { ClubDirectoryView(pitching: true) } label: {
            Label("Browse clubs and make a pitch", systemImage: "sportscourt.fill")
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
    }
}

private struct OfferCard: View {
    @EnvironmentObject private var store: GameStore
    let offer: TransferOffer
    let game: GameState

    var body: some View {
        GameCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.player(offer.playerID)?.name ?? "Player").font(.headline)
                    Text("\(offer.kind.label) · \(game.club(offer.clubID)?.name ?? "Club")")
                        .font(.subheadline).foregroundStyle(.secondary)
                    if offer.kind == .loan {
                        Text("\(offer.loanWeeks)-week development loan")
                    } else if offer.kind == .renewal {
                        Text("New wage \(money(offer.wage))/wk · \(offer.years)y")
                    } else {
                        Text("Fee \(money(offer.fee)) · Wage \(money(offer.wage))/wk · \(offer.years)y")
                    }
                    Text("Expires week \(offer.expiresWeek)").font(.caption).foregroundStyle(.orange)
                }
                Spacer()
                Text("\(Int(offer.packageScore))/100").font(.title3.bold()).foregroundStyle(NativeTheme.gold)
            }
            HStack {
                Button("Decline", role: .destructive) { _ = store.perform(.declineOffer(offer.id)) }.buttonStyle(.bordered)
                Spacer()
                if offer.kind != .loan {
                    Button("Negotiate") { _ = store.perform(.openTransfer(offer.id)) }.buttonStyle(.bordered)
                }
                Button("Accept") { _ = store.perform(.acceptOffer(offer.id)) }.buttonStyle(.borderedProminent)
            }
            .padding(.top, 12)
        }
    }
}

struct ClubDirectoryView: View {
    @EnvironmentObject private var store: GameStore
    var pitching = false
    @State private var search = ""

    var body: some View {
        if let game = store.game {
            List {
                ForEach([1, 2], id: \.self) { tier in
                    Section(tier == 1 ? "Albion Premier Division" : "Albion Championship") {
                        ForEach(filtered(game, tier: tier)) { club in
                            NavigationLink { ClubDetailView(clubID: club.id, pitching: pitching) } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(club.name).font(.headline)
                                    Text("Strength \(club.strength) · Prestige \(club.prestige) · Relationship \(club.relationship)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Club name")
            .navigationTitle("Clubs")
        }
    }

    private func filtered(_ game: GameState, tier: Int) -> [Club] {
        game.clubs.filter { $0.tier == tier && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) }
    }
}

private struct ClubDetailView: View {
    @EnvironmentObject private var store: GameStore
    let clubID: GameID
    let pitching: Bool

    var body: some View {
        if let game = store.game, let club = game.club(clubID) {
            ScrollView {
                VStack(spacing: 16) {
                    GameCard {
                        Text(club.name).font(.title2.bold())
                        Text("Tier \(club.tier) · \(game.region(club.regionID)?.name ?? "Albion")").foregroundStyle(.secondary)
                        HStack(spacing: 22) {
                            stat("Strength", "\(club.strength)")
                            stat("Prestige", "\(club.prestige)")
                            stat("Relationship", "\(club.relationship)")
                        }
                        .padding(.top, 14)
                    }
                    GameCard {
                        SectionTitle(title: "Season record")
                        HStack { stat("Played", "\(club.played)"); stat("W", "\(club.wins)"); stat("D", "\(club.draws)"); stat("L", "\(club.losses)"); stat("Pts", "\(club.points)") }
                            .padding(.top, 12)
                    }
                    if pitching {
                        GameCard {
                            SectionTitle(title: "Pitch a client", detail: game.transferWindowOpen ? "The club will judge fit, trust and your agency standing." : "Pitches reopen when the transfer window opens.")
                            ForEach(game.clients) { client in
                                if let player = game.player(client.playerID), player.clubID != club.id {
                                    Button("Pitch \(player.name)") { _ = store.perform(.pitch(player.id, clubID: club.id)) }
                                        .buttonStyle(.bordered).disabled(!game.transferWindowOpen).padding(.top, 6)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(NativeTheme.deepGreen).navigationTitle(club.name).navigationBarTitleDisplayMode(.inline)
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack { Text(value).font(.headline.monospacedDigit()); Text(label).font(.caption2).foregroundStyle(.secondary) }
            .frame(maxWidth: .infinity)
    }
}

struct MoreView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        NavigationStack {
            if let game = store.game {
                List {
                    Section {
                        NavigationLink { AgencyView() } label: { destination("Agency", "person.3.fill", "Staff, departments and identity") }
                        NavigationLink { FinanceView() } label: { destination("Finances", "chart.line.uptrend.xyaxis", "Cashflow, commission and runway") }
                        featureLink(game, feature: .stocks, title: "Stocks", icon: "chart.bar.fill") { StocksView() }
                    }
                    Section("Football world") {
                        NavigationLink { CareersView() } label: { destination("Careers & alumni", "figure.soccer", "Promises, history and former clients") }
                        NavigationLink { WorldView() } label: { destination("World", "globe.europe.africa.fill", "Leagues, clubs and rival agencies") }
                    }
                    Section("Progress") {
                        NavigationLink { HeadquartersView() } label: { destination("Headquarters", "building.2.crop.circle", GameContent.hqNames[game.agency.hqLevel]) }
                        NavigationLink { SeasonReviewView() } label: { destination("Season review", "trophy.fill", "Objectives and milestones") }
                    }
                    Section("Game") {
                        NavigationLink { SaveGamesView() } label: { destination("Save games", "externaldrive.fill", "Autosave and career slots") }
                    }
                }
                .scrollContentBackground(.hidden).background(NativeTheme.deepGreen)
                .navigationTitle("More")
            }
        }
    }

    private func destination(_ title: String, _ icon: String, _ detail: String) -> some View {
        Label {
            VStack(alignment: .leading) { Text(title); Text(detail).font(.caption).foregroundStyle(.secondary) }
        } icon: { Image(systemName: icon).foregroundStyle(NativeTheme.gold) }
        .padding(.vertical, 3)
    }

    @ViewBuilder private func featureLink<Destination: View>(_ game: GameState, feature: GameFeature,
                                                              title: String, icon: String,
                                                              @ViewBuilder destinationView: () -> Destination) -> some View {
        let access = GameEngine.featureAccess(in: game)[feature]!
        NavigationLink { destinationView() } label: {
            Label {
                VStack(alignment: .leading) {
                    HStack { Text(title); if !access.unlocked { Image(systemName: "lock.fill").font(.caption) } }
                    Text(access.unlocked ? "Portfolio and market prices" : access.requirement).font(.caption).foregroundStyle(.secondary)
                }
            } icon: { Image(systemName: icon).foregroundStyle(access.unlocked ? NativeTheme.gold : .secondary) }
            .padding(.vertical, 3)
        }
    }
}

private struct AgencyView: View {
    @EnvironmentObject private var store: GameStore
    @State private var identity = ""

    var body: some View {
        if let game = store.game {
            ScrollView {
                VStack(spacing: 16) {
                    HeroBanner(image: "agency-desk", eyebrow: game.stage.label,
                               title: "Build the agency", detail: "Create a team and identity strong enough to serve every client well.")
                    GameCard {
                        SectionTitle(title: "Identity")
                        TextField("Agency identity", text: $identity, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(2...4)
                        Button("Save identity") { _ = store.perform(.setIdentity(identity)) }.buttonStyle(.bordered).padding(.top, 8)
                    }
                    specialization(game)
                    staff(game)
                    departments(game)
                }
                .padding(16)
            }
            .background(NativeTheme.deepGreen).navigationTitle("Agency").navigationBarTitleDisplayMode(.inline)
            .onAppear { identity = game.agency.identity }
        }
    }

    @ViewBuilder private func specialization(_ game: GameState) -> some View {
        let access = GameEngine.featureAccess(in: game)[.specialization]!
        if access.unlocked {
            GameCard {
                SectionTitle(title: "Specialization", detail: "Current: \(game.agency.specialization.label). Changing costs £15,000.")
                ForEach(AgencySpecialization.allCases) { choice in
                    Button {
                        _ = store.perform(.setSpecialization(choice))
                    } label: {
                        HStack {
                            VStack(alignment: .leading) { Text(choice.label).font(.headline); Text(choice.detail).font(.caption).foregroundStyle(.secondary) }
                            Spacer()
                            if choice == game.agency.specialization { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                        }
                    }
                    .buttonStyle(.plain).padding(.vertical, 8).disabled(choice == game.agency.specialization)
                }
            }
        } else { LockedFeatureView(title: "Specialization", requirement: access.requirement) }
    }

    @ViewBuilder private func staff(_ game: GameState) -> some View {
        let access = GameEngine.featureAccess(in: game)[.staff]!
        if access.unlocked {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(title: "Support team", detail: "\(game.staff.count) / \(game.staffCapacity) staff slots")
                ForEach(game.staff) { member in
                    GameCard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(member.name).font(.headline)
                                Text("\(member.role.label) · Quality \(member.quality) · \(money(member.weeklyCost))/wk").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Menu {
                                ForEach(game.clients) { client in
                                    let assigned = member.clientIDs.contains(client.playerID)
                                    Button((assigned ? "Remove " : "Assign ") + (game.player(client.playerID)?.name ?? "Client")) {
                                        _ = store.perform(.togglePortfolio(staffID: member.id, clientID: client.playerID))
                                    }
                                }
                                Divider()
                                Button("Release staff", role: .destructive) { _ = store.perform(.fireStaff(member.id)) }
                            } label: { Image(systemName: "ellipsis.circle").frame(width: 44, height: 44) }
                        }
                        if !member.clientIDs.isEmpty {
                            Text("Portfolio: " + member.clientIDs.compactMap { game.player($0)?.name }.joined(separator: ", "))
                                .font(.caption).foregroundStyle(.secondary).padding(.top, 6)
                        }
                    }
                }
                Menu("Hire support staff") {
                    ForEach(StaffRole.allCases) { role in Button("\(role.label) · \(money(role.weeklyCost))/wk") { _ = store.perform(.hireStaff(role)) } }
                }
                .buttonStyle(.borderedProminent).disabled(game.staff.count >= game.staffCapacity)
            }
        } else { LockedFeatureView(title: "Support team", requirement: access.requirement) }
    }

    @ViewBuilder private func departments(_ game: GameState) -> some View {
        let access = GameEngine.featureAccess(in: game)[.departments]!
        if access.unlocked {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(title: "Departments", detail: "Each level adds capability and weekly overhead.")
                ForEach(game.departments) { department in
                    GameCard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(department.kind.label).font(.headline)
                                Text("Level \(department.level) / \(game.agency.hqLevel)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Reduce") { _ = store.perform(.downgradeDepartment(department.kind)) }
                                .buttonStyle(.bordered).disabled(department.level == 0)
                            Button("Upgrade") { _ = store.perform(.upgradeDepartment(department.kind)) }
                                .buttonStyle(.borderedProminent).disabled(department.level >= game.agency.hqLevel)
                        }
                    }
                }
            }
        } else { LockedFeatureView(title: "Departments", requirement: access.requirement) }
    }
}

private struct FinanceView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        if let game = store.game {
            ScrollView {
                VStack(spacing: 16) {
                    HeroBanner(image: "agency-desk", eyebrow: "The business behind the game",
                               title: "Finances", detail: "Protect the runway, create recurring stability and make every deal count.")
                    HStack(spacing: 10) {
                        MetricTile(label: "Spendable cash", value: money(game.agency.cash), systemImage: "banknote.fill")
                        MetricTile(label: "Weekly net", value: money(game.recurringNet), systemImage: "arrow.up.arrow.down", tint: game.recurringNet >= 0 ? .green : .orange)
                    }
                    GameCard {
                        SectionTitle(title: "Cash history", detail: "Last 24 recorded weeks")
                        if game.financeHistory.isEmpty {
                            Text("Advance one week to begin the ledger.").foregroundStyle(.secondary).frame(height: 150)
                        } else {
                            Chart(Array(game.financeHistory.suffix(24))) { week in
                                AreaMark(x: .value("Week", week.week), y: .value("Cash", week.closingCash))
                                    .foregroundStyle(LinearGradient(colors: [NativeTheme.gold.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                                LineMark(x: .value("Week", week.week), y: .value("Cash", week.closingCash))
                                    .foregroundStyle(NativeTheme.gold).lineStyle(.init(lineWidth: 2))
                            }
                            .frame(height: 190).chartYAxis { AxisMarks(position: .leading) }
                        }
                    }
                    GameCard {
                        SectionTitle(title: "Recurring budget")
                        financeRow("Client retainers", game.weeklyRetainers, good: true)
                        financeRow("Headquarters, scouting & team", -game.weeklyOperatingCost, good: false)
                        Divider().padding(.vertical, 7)
                        financeRow("Operating net", game.recurringNet, good: game.recurringNet >= 0)
                        financeRow("Career commission", game.agency.totalCommission, good: true)
                        financeRow("Investments", game.portfolioValue, good: true)
                    }
                    if game.agency.insolventWeeks > 0 {
                        GameCard {
                            Label("Insolvent for \(game.agency.insolventWeeks) weeks", systemImage: "exclamationmark.octagon.fill").foregroundStyle(.red).font(.headline)
                            Text("At four weeks the agency may be forced to downsize; at twelve weeks it closes.").font(.caption).foregroundStyle(.secondary).padding(.top, 4)
                        }
                    }
                }
                .padding(16)
            }
            .background(NativeTheme.deepGreen).navigationTitle("Finances").navigationBarTitleDisplayMode(.inline)
        }
    }

    private func financeRow(_ label: String, _ value: Double, good: Bool) -> some View {
        HStack { Text(label); Spacer(); Text(money(value)).monospacedDigit().foregroundStyle(good ? Color.primary : Color.orange) }
            .font(.subheadline).padding(.top, 9)
    }
}

private struct StocksView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        if let game = store.game {
            let access = GameEngine.featureAccess(in: game)[.stocks]!
            if access.unlocked {
                ScrollView {
                    VStack(spacing: 16) {
                        HeroBanner(image: "investment-city", eyebrow: "Beyond the touchline",
                                   title: "Stocks", detail: "Put surplus cash to work without risking the agency’s weekly commitments.")
                        HStack(spacing: 10) {
                            MetricTile(label: "Portfolio", value: money(game.portfolioValue), systemImage: "briefcase.fill")
                            MetricTile(label: "Realised gain", value: money(game.investments.realisedGain), systemImage: "chart.line.uptrend.xyaxis")
                        }
                        ForEach(game.stocks) { stock in
                            NavigationLink { StockDetailView(stockID: stock.id) } label: {
                                GameCard {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(stock.name).font(.headline)
                                            Text(stock.symbol).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            Text(money(stock.price)).font(.headline.monospacedDigit())
                                            let change = stock.previousPrice == 0 ? 0 : (stock.price / stock.previousPrice - 1) * 100
                                            Text(change.formatted(.number.precision(.fractionLength(1))) + "%")
                                                .font(.caption).foregroundStyle(change >= 0 ? .green : .red)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Text("Trades include a 1% fee with a £2 minimum. Prices move once per game week and are deterministic for this save.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(16)
                }
                .background(NativeTheme.deepGreen).navigationTitle("Stocks").navigationBarTitleDisplayMode(.inline)
            } else {
                LockedFeatureView(title: "Stocks", requirement: access.requirement).navigationTitle("Stocks")
            }
        }
    }
}

private struct StockDetailView: View {
    @EnvironmentObject private var store: GameStore
    let stockID: GameID
    @State private var shares = 1

    var body: some View {
        if let game = store.game, let stock = game.stocks.first(where: { $0.id == stockID }) {
            let holding = game.investments.holdings.first { $0.stockID == stockID }
            Form {
                Section {
                    Text(stock.name).font(.title2.bold())
                    LabeledContent("Price", value: money(stock.price))
                    LabeledContent("Held", value: "\(holding?.shares ?? 0) shares")
                    LabeledContent("Average cost", value: money(holding?.averageCost ?? 0))
                }
                Section("Order review") {
                    Stepper("\(shares) share\(shares == 1 ? "" : "s")", value: $shares, in: 1...10_000)
                    LabeledContent("Value", value: money(Double(shares) * stock.price))
                    LabeledContent("Estimated fee", value: money(max(2, Double(shares) * stock.price * 0.01)))
                    Button("Buy shares") { _ = store.perform(.buyStock(stockID, shares: shares)) }
                    Button("Sell shares") { _ = store.perform(.sellStock(stockID, shares: shares)) }
                        .disabled((holding?.shares ?? 0) < shares)
                }
            }
            .navigationTitle(stock.symbol)
        }
    }
}

private struct WorldView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        if let game = store.game {
            List {
                ForEach([1, 2], id: \.self) { tier in
                    Section(tier == 1 ? "Premier table" : "Championship table") {
                        ForEach(Array(game.clubs.filter { $0.tier == tier }.sorted {
                            $0.points == $1.points ? $0.strength > $1.strength : $0.points > $1.points
                        }.enumerated()), id: \.element.id) { position, club in
                            NavigationLink { ClubDetailView(clubID: club.id, pitching: false) } label: {
                                HStack {
                                    Text("\(position + 1)").font(.caption.monospacedDigit()).frame(width: 22)
                                    Text(club.name)
                                    Spacer()
                                    Text("\(club.points)").font(.headline.monospacedDigit())
                                }
                            }
                        }
                    }
                }
                Section("Rival agencies") {
                    ForEach(game.rivals.sorted { $0.reputation > $1.reputation }) { rival in
                        VStack(alignment: .leading) {
                            Text(rival.name).font(.headline)
                            Text("Reputation \(rival.reputation) · \(rival.clientCount) clients").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section { NavigationLink("Full club directory") { ClubDirectoryView() } }
            }
            .navigationTitle("World")
        }
    }
}

private struct CareersView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        if let game = store.game {
            List {
                Section("Active career stories") {
                    ForEach(game.clients) { client in
                        if let player = game.player(client.playerID) {
                            NavigationLink { ClientDetailView(playerID: player.id) } label: {
                                VStack(alignment: .leading) {
                                    Text(player.name).font(.headline)
                                    Text(client.careerGoal).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                Section("Alumni") {
                    if game.alumni.isEmpty { Text("Former clients will be remembered here.").foregroundStyle(.secondary) }
                    ForEach(game.alumni) { alumnus in
                        VStack(alignment: .leading) {
                            Text(game.player(alumnus.playerID)?.name ?? "Former client").font(.headline)
                            Text("Left week \(alumnus.leftWeek) · \(alumnus.reason)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Active loans") {
                    if game.loans.isEmpty { Text("No active loans.").foregroundStyle(.secondary) }
                    ForEach(game.loans) { loan in
                        VStack(alignment: .leading) {
                            Text(game.player(loan.playerID)?.name ?? "Player").font(.headline)
                            Text("\(game.club(loan.fromClubID)?.name ?? "Club") → \(game.club(loan.toClubID)?.name ?? "Club") · returns week \(loan.endWeek)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Careers")
        }
    }
}

private struct HeadquartersView: View {
    @EnvironmentObject private var store: GameStore
    @State private var confirmingDownsize = false

    var body: some View {
        if let game = store.game {
            ScrollView {
                VStack(spacing: 16) {
                    HeroBanner(image: "headquarters", eyebrow: "Room to grow",
                               title: GameContent.hqNames[game.agency.hqLevel],
                               detail: "Expand only when the next opportunity justifies the permanent overhead.")
                    GameCard {
                        SectionTitle(title: "Current capacity")
                        capacity("Clients", game.clients.count, game.clientCapacity)
                        capacity("Scouts", game.scouts.count, game.scoutCapacity)
                        capacity("Support staff", game.staff.count, game.staffCapacity)
                        LabeledContent("Total weekly operations", value: money(game.weeklyOperatingCost)).padding(.top, 10)
                    }
                    if game.agency.hqLevel < 5 {
                        let next = game.agency.hqLevel + 1
                        GameCard {
                            SectionTitle(title: "Next: \(GameContent.hqNames[next])", detail: "One-off upgrade: \(money(GameContent.hqUpgradeCosts[next]))")
                            Text("Client capacity rises to \([0, 5, 9, 14, 20, 28][next]); scout capacity rises to \([0, 1, 2, 4, 6, 9][next]).")
                                .font(.subheadline).foregroundStyle(.secondary).padding(.top, 8)
                            Button("Upgrade headquarters") { _ = store.perform(.upgradeHeadquarters) }
                                .buttonStyle(PrimaryGameButtonStyle()).padding(.top, 12)
                        }
                    }
                    Button("Move to smaller premises", role: .destructive) { confirmingDownsize = true }
                        .buttonStyle(.bordered).disabled(game.agency.hqLevel == 1)
                }
                .padding(16)
            }
            .background(NativeTheme.deepGreen).navigationTitle("Headquarters").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Downsize headquarters?", isPresented: $confirmingDownsize, titleVisibility: .visible) {
                Button("Downsize", role: .destructive) { _ = store.perform(.downsizeHeadquarters) }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Capacity and weekly costs fall. Upgrade fees are not refunded.") }
        }
    }

    private func capacity(_ label: String, _ value: Int, _ total: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack { Text(label); Spacer(); Text("\(value) / \(total)") }
            ProgressView(value: Double(value), total: Double(total)).tint(NativeTheme.gold)
        }
        .padding(.top, 11)
    }
}

private struct SeasonReviewView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        if let game = store.game {
            List {
                Section("Current season") {
                    LabeledContent("Season", value: "\(game.season)")
                    LabeledContent("Agency stage", value: game.stage.label)
                    if let objective = game.progression.objective {
                        VStack(alignment: .leading) {
                            Text(objective.kind.label).font(.headline)
                            Text(objective.completed ? "Completed" : "In progress").font(.caption).foregroundStyle(objective.completed ? .green : .secondary)
                        }
                    } else {
                        Text("Choose an objective from the Office.").foregroundStyle(.secondary)
                    }
                }
                Section("Milestones") {
                    if game.progression.milestones.isEmpty { Text("Your first milestone is still ahead.").foregroundStyle(.secondary) }
                    ForEach(game.progression.milestones, id: \.self) { Label($0, systemImage: "checkmark.seal.fill").foregroundStyle(.green) }
                }
                Section("Past reviews") {
                    if game.progression.seasonReviews.isEmpty { Text("The first review arrives after week 52.").foregroundStyle(.secondary) }
                    ForEach(game.progression.seasonReviews.reversed(), id: \.self) { Text($0) }
                }
            }
            .navigationTitle("Season review")
        }
    }
}

private struct SaveGamesView: View {
    @EnvironmentObject private var store: GameStore
    @State private var showingNew = false
    @State private var deleting: SaveSlot?

    var body: some View {
        List {
            Section {
                Button { showingNew = true } label: { Label("Start another career", systemImage: "plus.circle.fill") }
            }
            Section("Autosaves") {
                ForEach(store.slots) { slot in
                    HStack {
                        Button { store.load(slot: slot.id) } label: {
                            VStack(alignment: .leading) {
                                HStack { Text(slot.agencyName).font(.headline); if slot.id == store.selectedSlot { Text("CURRENT").font(.caption2.bold()).foregroundStyle(.green) } }
                                Text("Season \(slot.season) · Week \(slot.week)").font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        Button(role: .destructive) { deleting = slot } label: { Image(systemName: "trash").frame(width: 44, height: 44) }
                            .accessibilityLabel("Delete \(slot.agencyName)")
                    }
                }
            }
            Section { Text("Every successful action and time advance saves automatically. The previous file is retained as a backup.").font(.caption).foregroundStyle(.secondary) }
        }
        .navigationTitle("Save games")
        .sheet(isPresented: $showingNew) { NewCareerSheet() }
        .confirmationDialog("Delete \(deleting?.agencyName ?? "save")?", isPresented: Binding(
            get: { deleting != nil }, set: { if !$0 { deleting = nil } }
        ), titleVisibility: .visible) {
            Button("Delete save", role: .destructive) { if let deleting { store.delete(slot: deleting.id) }; deleting = nil }
            Button("Cancel", role: .cancel) { deleting = nil }
        } message: { Text("This removes the save and its local backup.") }
    }
}

private struct NewCareerSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = "New Agency"
    @State private var seed = String(UInt64(Date().timeIntervalSince1970))

    var body: some View {
        NavigationStack {
            Form {
                TextField("Agency name", text: $name)
                TextField("World seed", text: $seed).keyboardType(.numberPad)
                Button("Start career") {
                    store.newGame(name: name, seed: UInt64(seed) ?? UInt64(Date().timeIntervalSince1970))
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .navigationTitle("New career")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
