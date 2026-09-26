import Foundation

enum GameEngine {
    static func newGame(name: String, seed: UInt64) -> GameState {
        let clubs = GameContent.clubs()
        let players = GameContent.players(seed: seed, clubs: clubs)
        let starter = players[0]
        let agencyName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Touchline Agency" : name
        return GameState(
            seed: seed,
            agency: Agency(name: agencyName, cash: 75_000, reputation: 12, hqLevel: 1,
                           totalCommission: 0, totalCosts: 0, specialization: .balanced,
                           identity: "Independent. Patient. Player first.", insolventWeeks: 0),
            players: players,
            clients: [Client(playerID: starter.id, trust: 68, commissionPercent: 8,
                             representationWeeks: 104, signedWeek: 1, playingTime: .regular,
                             seekingMove: false, wantsLoan: false, dealsDone: 0,
                             careerGoal: "Become a trusted first-team regular", promiseDeadline: nil,
                             promiseText: nil, lastConversationWeek: -10)],
            regions: GameContent.regions,
            clubs: clubs,
            scouts: [Scout(id: "scout-1", name: "Mara Bell", quality: 45, salary: 360,
                           regionID: nil, focus: nil, progress: 0)],
            rivals: GameContent.rivalNames.enumerated().map {
                RivalAgency(id: "rival-\($0.offset + 1)", name: $0.element,
                            reputation: 18 + $0.offset * 7, clientCount: 3 + $0.offset * 2)
            },
            departments: DepartmentKind.allCases.map { AgencyDepartment(kind: $0, level: 0) },
            careers: [CareerEntry(id: "career-1", playerID: starter.id, week: 1,
                                  title: "Representation begins",
                                  detail: "\(starter.name) trusted \(agencyName) with the next chapter.")],
            events: [GameEvent(id: "event-1-1", week: 1, title: "The doors are open",
                               detail: "Assign Mara to a region and begin building your agency.", tone: .good)],
            stocks: GameContent.stocks()
        )
    }

    static func perform(_ action: GameAction, on state: inout GameState) -> ActionOutcome {
        guard state.gameOverReason == nil else { return .failure("This agency career has ended.") }
        var candidate = state
        let outcome = apply(action, to: &candidate)
        if outcome.ok { state = candidate }
        return outcome
    }

    static func advance(_ mode: AdvanceMode, state: inout GameState) -> [GameEvent] {
        guard state.gameOverReason == nil else { return [] }
        let startingEventCount = state.events.count
        switch mode {
        case .oneWeek:
            advanceOneWeek(&state)
        case .weeks(let count):
            for _ in 0..<min(max(count, 1), 52) where state.gameOverReason == nil { advanceOneWeek(&state) }
        case .nextEvent:
            let initialDecisionIDs = Set(decisions(in: state).map(\.id))
            for _ in 0..<12 where state.gameOverReason == nil {
                let wasWindowOpen = state.transferWindowOpen
                advanceOneWeek(&state)
                let hasNewDecision = decisions(in: state).contains { !initialDecisionIDs.contains($0.id) }
                let majorEvent = state.events.suffix(max(0, state.events.count - startingEventCount)).contains { $0.tone != .neutral }
                if hasNewDecision || wasWindowOpen != state.transferWindowOpen || majorEvent { break }
            }
        }
        return Array(state.events.dropFirst(startingEventCount))
    }

    static func decisions(in state: GameState) -> [GameDecision] {
        var result: [GameDecision] = []
        if let negotiation = state.negotiation {
            result.append(.init(id: "negotiation-\(negotiation.id)", title: "Negotiation in progress",
                                detail: "Finish the conversation or walk away.", deadlineWeek: state.week,
                                severity: .urgent))
        }
        for offer in state.offers where offer.status == .open {
            let name = state.player(offer.playerID)?.name ?? "A client"
            result.append(.init(id: "offer-\(offer.id)", title: "\(offer.kind.label) offer for \(name)",
                                detail: "Review the terms before the offer expires.", deadlineWeek: offer.expiresWeek,
                                severity: offer.expiresWeek <= state.week + 1 ? .urgent : .warning))
        }
        for client in state.clients {
            let name = state.player(client.playerID)?.name ?? "A client"
            if client.representationWeeks <= 8 {
                result.append(.init(id: "renew-\(client.playerID)", title: "Renew \(name)",
                                    detail: "Representation expires in \(client.representationWeeks) weeks.",
                                    deadlineWeek: state.week + client.representationWeeks,
                                    severity: client.representationWeeks <= 3 ? .urgent : .warning))
            }
            if let deadline = client.promiseDeadline, deadline <= state.week + 3 {
                result.append(.init(id: "promise-\(client.playerID)", title: "Promise due for \(name)",
                                    detail: client.promiseText ?? "Deliver the promised career progress.",
                                    deadlineWeek: deadline, severity: deadline <= state.week ? .urgent : .warning))
            }
            if client.trust < 35 {
                result.append(.init(id: "trust-\(client.playerID)", title: "\(name) is losing faith",
                                    detail: "Talk now or deliver meaningful career progress.", deadlineWeek: nil,
                                    severity: client.trust < 20 ? .urgent : .warning))
            }
        }
        if state.agency.cash < 0 {
            result.append(.init(id: "insolvency", title: "Agency cash is below zero",
                                detail: "Cut recurring costs or close a deal before the agency fails.",
                                deadlineWeek: state.week + max(0, 12 - state.agency.insolventWeeks), severity: .urgent))
        }
        return result.sorted {
            if $0.severity != $1.severity { return $0.severity > $1.severity }
            return ($0.deadlineWeek ?? .max) < ($1.deadlineWeek ?? .max)
        }
    }

    static func nextMove(in state: GameState) -> NextMove {
        if let decision = decisions(in: state).first {
            return NextMove(title: decision.title, detail: decision.detail,
                            tab: decision.id.hasPrefix("offer") ? 3 : decision.id.hasPrefix("trust") || decision.id.hasPrefix("renew") ? 1 : 0)
        }
        if state.scouts.allSatisfy({ $0.regionID == nil }) {
            return NextMove(title: "Send your scout out", detail: "Choose a region to start finding your second client.", tab: 2)
        }
        if state.reports.isEmpty {
            return NextMove(title: "Wait for the first report", detail: "Advance time. A useful lead should arrive within four weeks.", tab: 0)
        }
        if state.reports.contains(where: { !$0.shortlisted }) {
            return NextMove(title: "Build a shortlist", detail: "Mark a promising report so your recruitment plan stays focused.", tab: 2)
        }
        if state.clients.count == 1, state.negotiation == nil,
           state.reports.contains(where: { $0.shortlisted && !$0.approached }) {
            return NextMove(title: "Approach a prospect", detail: "Agree a fair commission and grow beyond your first client.", tab: 2)
        }
        if state.clients.contains(where: { !$0.seekingMove }) && state.transferWindowOpen {
            return NextMove(title: "Shape a client’s next move", detail: "Make a thoughtful club pitch or declare availability.", tab: 3)
        }
        return NextMove(title: "Build patiently", detail: "Develop trust, watch costs and advance to the next opportunity.", tab: 0)
    }

    static func featureAccess(in state: GameState) -> [GameFeature: FeatureAccess] {
        let grewRoster = state.clients.count >= 2 || state.alumni.count > 0
        let earnedCommission = state.agency.totalCommission > 0
        let canInvest = state.recurringNet > 0 && state.agency.cash >= 100_000
        return [
            .market: .init(unlocked: grewRoster, requirement: "Sign one additional client"),
            .staff: .init(unlocked: earnedCommission, requirement: "Earn your first commission"),
            .departments: .init(unlocked: earnedCommission, requirement: "Earn your first commission"),
            .specialization: .init(unlocked: earnedCommission, requirement: "Earn your first commission"),
            .loans: .init(unlocked: earnedCommission, requirement: "Earn your first commission"),
            .stocks: .init(unlocked: canInvest, requirement: "Reach £100k cash with a positive weekly budget"),
        ]
    }

    // MARK: - Actions

    private static func apply(_ action: GameAction, to state: inout GameState) -> ActionOutcome {
        switch action {
        case .assignScout(let scoutID, let regionID):
            guard let scoutIndex = state.scouts.firstIndex(where: { $0.id == scoutID }),
                  state.regions.contains(where: { $0.id == regionID }) else { return .failure("That assignment is unavailable.") }
            state.scouts[scoutIndex].regionID = regionID
            state.scouts[scoutIndex].progress = 0
            let region = state.region(regionID)?.name ?? "the region"
            addEvent("Scouting assignment", "\(state.scouts[scoutIndex].name) is now covering \(region).", .neutral, to: &state)
            return .success("Scout assigned to \(region).")

        case .setScoutFocus(let scoutID, let focus):
            guard let index = state.scouts.firstIndex(where: { $0.id == scoutID }) else { return .failure("Scout not found.") }
            state.scouts[index].focus = focus
            state.scouts[index].progress = max(0, state.scouts[index].progress - 1)
            return .success(focus.map { "The brief now prioritises \($0.label.lowercased())s." } ?? "The scout is searching every position.")

        case .hireScout:
            guard state.scouts.count < state.scoutCapacity else { return .failure("Upgrade headquarters for another scout slot.") }
            let hiringCost = 8_000.0 + Double(state.scouts.count) * 4_000
            guard state.agency.cash >= hiringCost else { return .failure("You need \(currency(hiringCost)) to hire another scout.") }
            var random = SeededRandom(seed: state.seed, week: state.week, stream: "hire-scout-\(state.scouts.count)")
            let names = ["Ellis Ward", "Priya North", "Owen March", "Nia Vale", "Theo Carrick"]
            let name = names[state.scouts.count % names.count]
            let quality = random.int(38...62) + state.departments.first(where: { $0.kind == .analytics })!.level * 2
            state.agency.cash -= hiringCost
            state.scouts.append(.init(id: "scout-\(state.week)-\(state.scouts.count + 1)", name: name,
                                      quality: quality, salary: Double(quality * 8), regionID: nil,
                                      focus: nil, progress: 0))
            return .success("\(name) joined the scouting team.")

        case .fireScout(let scoutID):
            guard state.scouts.count > 1 else { return .failure("The agency must retain at least one scout.") }
            guard let index = state.scouts.firstIndex(where: { $0.id == scoutID }) else { return .failure("Scout not found.") }
            let name = state.scouts.remove(at: index).name
            return .success("\(name) left the scouting team.")

        case .shortlist(let reportID):
            guard let index = state.reports.firstIndex(where: { $0.id == reportID }) else { return .failure("Report not found.") }
            state.reports[index].shortlisted.toggle()
            return .success(state.reports[index].shortlisted ? "Added to your shortlist." : "Removed from your shortlist.")

        case .openRepresentation(let reportID):
            guard state.negotiation == nil else { return .failure("Finish the current negotiation first.") }
            guard state.clients.count < state.clientCapacity else { return .failure("Your headquarters has no free client capacity.") }
            guard let reportIndex = state.reports.firstIndex(where: { $0.id == reportID && !$0.approached }) else {
                return .failure("This prospect is no longer available to approach.")
            }
            let report = state.reports[reportIndex]
            guard !state.clients.contains(where: { $0.playerID == report.playerID }) else { return .failure("They are already a client.") }
            guard let player = state.player(report.playerID) else { return .failure("Player not found.") }
            if player.rivalAgencyID != nil && state.agency.reputation < 24 { return .failure("Build more reputation before challenging their current agency.") }
            state.reports[reportIndex].approached = true
            var random = SeededRandom(seed: state.seed, week: state.week, stream: "representation-\(player.id)")
            let ceiling = Double(random.int(7...12)) + Double(state.agency.reputation) / 35
            state.negotiation = Negotiation(id: "representation-\(player.id)-\(state.week)", kind: .representation,
                                             playerID: player.id, offerID: nil, roundsRemaining: 3,
                                             target: min(14, ceiling), counter: max(5, ceiling - 1),
                                             lastProposal: nil, hint: "They want a fair long-term partnership.")
            return .success("Representation talks opened with \(player.name).")

        case .openTransfer(let offerID):
            guard state.negotiation == nil else { return .failure("Finish the current negotiation first.") }
            guard let offer = state.offers.first(where: { $0.id == offerID && $0.status == .open }) else { return .failure("That offer is no longer open.") }
            guard offer.kind == .renewal || state.transferWindowOpen else { return .failure("The transfer window is closed.") }
            state.negotiation = Negotiation(id: "transfer-\(offer.id)", kind: .transfer, playerID: offer.playerID,
                                             offerID: offer.id, roundsRemaining: 3, target: min(92, offer.packageScore + 18),
                                             counter: offer.packageScore + 7, lastProposal: nil,
                                             hint: "The club has room to improve, but not without limit.")
            return .success("Package talks opened.")

        case .proposeNegotiation(let rawProposal):
            guard var negotiation = state.negotiation else { return .failure("There is no active negotiation.") }
            let range = negotiation.kind == .representation ? 4.0...16.0 : 35.0...100.0
            let proposal = min(max(rawProposal, range.lowerBound), range.upperBound)
            negotiation.lastProposal = proposal
            let accepted = proposal <= negotiation.target
            if accepted {
                if negotiation.kind == .representation {
                    guard let playerIndex = state.players.firstIndex(where: { $0.id == negotiation.playerID }) else { return .failure("Player not found.") }
                    let player = state.players[playerIndex]
                    state.players[playerIndex].rivalAgencyID = nil
                    state.clients.append(Client(playerID: player.id, trust: 62, commissionPercent: proposal,
                                                representationWeeks: 104, signedWeek: state.week,
                                                playingTime: .rotation, seekingMove: false, wantsLoan: false,
                                                dealsDone: 0, careerGoal: careerGoal(for: player),
                                                promiseDeadline: nil, promiseText: nil,
                                                lastConversationWeek: state.week - 8))
                    state.careers.append(.init(id: "career-\(state.careers.count + 1)", playerID: player.id, week: state.week,
                                               title: "Joined the agency", detail: "Signed at \(proposal.formatted(.number.precision(.fractionLength(1))))% commission."))
                    state.agency.reputation += 2
                    state.negotiation = nil
                    addEvent("New client", "\(player.name) has joined the agency.", .good, to: &state)
                    return .success("\(player.name) signed at \(proposal.formatted(.number.precision(.fractionLength(1))))% commission.")
                }
                guard let offerID = negotiation.offerID else { return .failure("Offer not found.") }
                state.negotiation = nil
                return completeOffer(offerID, packageScore: proposal, state: &state)
            }
            negotiation.roundsRemaining -= 1
            if negotiation.roundsRemaining <= 0 {
                state.negotiation = nil
                addEvent("Talks collapse", "The other side walked away after the final proposal.", .warning, to: &state)
                return .success("The final proposal was too ambitious. Talks ended.")
            }
            var random = SeededRandom(seed: state.seed, week: state.week,
                                      stream: "haggle-\(negotiation.id)-\(negotiation.roundsRemaining)")
            if random.chance(min(0.45, max(0, (proposal - negotiation.target) / 30))) {
                state.negotiation = nil
                addEvent("Talks collapse", "The other side withdrew from the negotiation.", .warning, to: &state)
                return .success("The proposal pushed too far and they walked away.")
            }
            negotiation.counter = min(proposal - 0.5, negotiation.target + random.double(0...2))
            negotiation.hint = proposal > negotiation.target + 3 ? "You are well beyond their limit." : "You are close. A small concession may close it."
            state.negotiation = negotiation
            return .success("Not accepted. \(negotiation.hint)")

        case .walkAway:
            guard state.negotiation != nil else { return .failure("There is no negotiation to leave.") }
            state.negotiation = nil
            return .success("You ended the talks.")

        case .seekMove(let playerID, let value):
            guard let index = state.clients.firstIndex(where: { $0.playerID == playerID }) else { return .failure("Client not found.") }
            state.clients[index].seekingMove = value
            if !value { state.clients[index].wantsLoan = false }
            return .success(value ? "Clubs will be told the player is available." : "The player is no longer seeking a move.")

        case .requestLoan(let playerID, let value):
            guard featureAccess(in: state)[.loans]?.unlocked == true else { return .failure("Earn your first commission to unlock the loan desk.") }
            guard let index = state.clients.firstIndex(where: { $0.playerID == playerID }) else { return .failure("Client not found.") }
            state.clients[index].wantsLoan = value
            if value { state.clients[index].seekingMove = true }
            return .success(value ? "The market will prioritise a development loan." : "Loan interest is no longer requested.")

        case .acceptOffer(let offerID):
            return completeOffer(offerID, packageScore: nil, state: &state)

        case .declineOffer(let offerID):
            guard let index = state.offers.firstIndex(where: { $0.id == offerID && $0.status == .open }) else { return .failure("Offer not found.") }
            state.offers[index].status = .declined
            return .success("Offer declined.")

        case .conversation(let playerID, let type):
            guard let index = state.clients.firstIndex(where: { $0.playerID == playerID }) else { return .failure("Client not found.") }
            guard state.week - state.clients[index].lastConversationWeek >= 4 else { return .failure("Give this conversation time to land before speaking again.") }
            let change: Int
            switch type {
            case .reassure: change = state.clients[index].trust < 55 ? 8 : 3
            case .challenge: change = state.clients[index].playingTime == .fringe ? -3 : 5
            case .praise: change = state.clients[index].playingTime == .key ? 7 : 2
            }
            state.clients[index].trust = min(100, max(0, state.clients[index].trust + change))
            state.clients[index].lastConversationWeek = state.week
            return .success(change >= 0 ? "The conversation strengthened trust." : "The message did not land well.")

        case .makePromise(let playerID, let text):
            guard let index = state.clients.firstIndex(where: { $0.playerID == playerID }) else { return .failure("Client not found.") }
            guard state.clients[index].promiseDeadline == nil else { return .failure("There is already an active promise.") }
            let promise = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !promise.isEmpty else { return .failure("Write a clear promise first.") }
            state.clients[index].promiseText = promise
            state.clients[index].promiseDeadline = state.week + 12
            state.clients[index].trust = min(100, state.clients[index].trust + 4)
            return .success("Promise recorded. Deliver within 12 weeks.")

        case .renewRepresentation(let playerID):
            guard let index = state.clients.firstIndex(where: { $0.playerID == playerID }) else { return .failure("Client not found.") }
            guard state.clients[index].representationWeeks <= 26 else { return .failure("Renewal talks are not due yet.") }
            guard state.clients[index].trust >= 45 else { return .failure("Trust is too low for a renewal. Repair the relationship first.") }
            state.clients[index].representationWeeks += 104
            state.clients[index].trust -= 3
            addCareer(playerID, "Representation renewed", "Committed to another two years.", to: &state)
            return .success("Representation renewed for two years.")

        case .releaseClient(let playerID):
            guard let index = state.clients.firstIndex(where: { $0.playerID == playerID }) else { return .failure("Client not found.") }
            guard state.clients.count > 1 else { return .failure("You cannot release the agency’s only client.") }
            let client = state.clients.remove(at: index)
            state.alumni.append(.init(playerID: playerID, leftWeek: state.week, reason: "Released by the agency",
                                      careerCommission: estimatedClientCommission(client, state: state)))
            addCareer(playerID, "Representation ended", "The agency chose to part ways.", to: &state)
            return .success("Client released.")

        case .pitch(let playerID, let clubID):
            guard featureAccess(in: state)[.market]?.unlocked == true else { return .failure("Sign one additional client to unlock club pitches.") }
            guard state.transferWindowOpen else { return .failure("The transfer window is closed.") }
            guard let client = state.clients.first(where: { $0.playerID == playerID }),
                  let player = state.player(playerID),
                  let club = state.club(clubID) else { return .failure("That pitch is unavailable.") }
            guard player.clubID != clubID else { return .failure("The player already belongs to that club.") }
            guard !state.offers.contains(where: { $0.playerID == playerID && $0.clubID == clubID && $0.status == .open }) else { return .failure("That club already has an open offer.") }
            var random = SeededRandom(seed: state.seed, week: state.week, stream: "pitch-\(playerID)-\(clubID)")
            let fit = 0.30 + Double(state.agency.reputation + club.relationship + client.trust) / 300
            guard random.chance(min(0.88, fit)) else {
                if let clubIndex = state.clubs.firstIndex(where: { $0.id == clubID }) { state.clubs[clubIndex].relationship -= 1 }
                return .success("The club listened, but the fit is not right today.")
            }
            state.offers.append(makeOffer(player: player, club: club, kind: client.wantsLoan ? .loan : .transfer,
                                          state: state, random: &random))
            return .success("\(club.name) responded with an offer.")

        case .hireStaff(let role):
            guard featureAccess(in: state)[.staff]?.unlocked == true else { return .failure("Earn your first commission to hire support staff.") }
            guard state.staff.count < state.staffCapacity else { return .failure("Upgrade headquarters for another support staff slot.") }
            let hiringCost = role.weeklyCost * 8
            guard state.agency.cash >= hiringCost else { return .failure("The agency cannot afford the hiring fee.") }
            state.agency.cash -= hiringCost
            let name = ["Rhea Cole", "Tomas Vale", "Amira Hart", "Jon Bell"][state.staff.count % 4]
            state.staff.append(.init(id: "staff-\(state.week)-\(state.staff.count + 1)", name: name, role: role,
                                     quality: 55 + state.staff.count * 4, weeklyCost: role.weeklyCost, clientIDs: []))
            return .success("\(name) joined as \(role.label.lowercased()).")

        case .fireStaff(let staffID):
            guard let index = state.staff.firstIndex(where: { $0.id == staffID }) else { return .failure("Staff member not found.") }
            let name = state.staff.remove(at: index).name
            return .success("\(name) left the agency.")

        case .togglePortfolio(let staffID, let clientID):
            guard let index = state.staff.firstIndex(where: { $0.id == staffID }),
                  state.clients.contains(where: { $0.playerID == clientID }) else { return .failure("Portfolio assignment not found.") }
            if let assigned = state.staff[index].clientIDs.firstIndex(of: clientID) {
                state.staff[index].clientIDs.remove(at: assigned)
                return .success("Client removed from the portfolio.")
            }
            guard state.staff[index].clientIDs.count < 4 else { return .failure("This portfolio is full.") }
            state.staff[index].clientIDs.append(clientID)
            return .success("Client added to the portfolio.")

        case .upgradeDepartment(let kind):
            guard featureAccess(in: state)[.departments]?.unlocked == true else { return .failure("Earn your first commission to build departments.") }
            guard let index = state.departments.firstIndex(where: { $0.kind == kind }) else { return .failure("Department not found.") }
            let next = state.departments[index].level + 1
            guard next <= state.agency.hqLevel else { return .failure("Upgrade headquarters to develop this department further.") }
            let cost = Double(next * next) * 12_000
            guard state.agency.cash >= cost else { return .failure("The agency cannot afford this department upgrade.") }
            state.agency.cash -= cost
            state.departments[index].level = next
            return .success("\(kind.label) reached level \(next).")

        case .downgradeDepartment(let kind):
            guard let index = state.departments.firstIndex(where: { $0.kind == kind && $0.level > 0 }) else { return .failure("That department is already at level zero.") }
            state.departments[index].level -= 1
            return .success("\(kind.label) reduced to level \(state.departments[index].level).")

        case .setIdentity(let identity):
            let value = identity.trimmingCharacters(in: .whitespacesAndNewlines)
            guard (8...100).contains(value.count) else { return .failure("Agency identity must be between 8 and 100 characters.") }
            state.agency.identity = value
            return .success("Agency identity updated.")

        case .setSpecialization(let specialization):
            guard featureAccess(in: state)[.specialization]?.unlocked == true else { return .failure("Earn your first commission to choose a specialization.") }
            guard state.agency.specialization != specialization else { return .failure("That specialization is already active.") }
            let cost = 15_000.0
            guard state.agency.cash >= cost else { return .failure("Changing specialization costs £15,000.") }
            state.agency.cash -= cost
            state.agency.specialization = specialization
            return .success("The agency now specialises in \(specialization.label.lowercased()).")

        case .selectObjective(let kind):
            guard state.progression.objective == nil else { return .failure("A seasonal objective is already active.") }
            let start = objectiveValue(kind, state: state)
            let target: Double
            switch kind {
            case .clients: target = start + 3
            case .commission: target = start + max(40_000, Double(state.season) * 25_000)
            case .reputation: target = min(100, start + 10)
            case .stability: target = max(100_000, start + 50_000)
            }
            state.progression.objective = .init(kind: kind, startValue: start, target: target,
                                                rewardCash: 18_000 + Double(state.season) * 2_000,
                                                rewardReputation: 4, completed: false)
            return .success("Season objective selected: \(kind.label).")

        case .upgradeHeadquarters:
            guard state.agency.hqLevel < 5 else { return .failure("Your headquarters is already at the highest tier.") }
            let next = state.agency.hqLevel + 1
            let cost = GameContent.hqUpgradeCosts[next]
            guard state.agency.cash >= cost else { return .failure("You need \(currency(cost)) to upgrade headquarters.") }
            state.agency.cash -= cost
            state.agency.hqLevel = next
            addEvent("Headquarters upgraded", "The agency moved into \(GameContent.hqNames[next]).", .good, to: &state)
            return .success("Welcome to \(GameContent.hqNames[next]).")

        case .downsizeHeadquarters:
            guard state.agency.hqLevel > 1 else { return .failure("The agency is already in the smallest office.") }
            let next = state.agency.hqLevel - 1
            let clientCap = [0, 5, 9, 14, 20, 28][next]
            let scoutCap = [0, 1, 2, 4, 6, 9][next]
            guard state.clients.count <= clientCap, state.scouts.count <= scoutCap,
                  state.staff.count <= next, state.departments.allSatisfy({ $0.level <= next }) else {
                return .failure("Reduce clients, scouts, staff or departments before moving down.")
            }
            state.agency.hqLevel = next
            return .success("The agency moved to smaller, cheaper premises.")

        case .buyStock(let stockID, let shares):
            guard featureAccess(in: state)[.stocks]?.unlocked == true else { return .failure("Reach £100k cash and a positive weekly budget to unlock stocks.") }
            guard shares > 0, let stock = state.stocks.first(where: { $0.id == stockID }) else { return .failure("Choose a valid number of shares.") }
            let subtotal = stock.price * Double(shares)
            let fee = max(2, subtotal * 0.01)
            guard state.agency.cash >= subtotal + fee else { return .failure("The agency does not have enough spendable cash.") }
            state.agency.cash -= subtotal + fee
            state.investments.feesPaid += fee
            if let index = state.investments.holdings.firstIndex(where: { $0.stockID == stockID }) {
                let old = state.investments.holdings[index]
                let totalShares = old.shares + shares
                state.investments.holdings[index].averageCost = (old.averageCost * Double(old.shares) + subtotal) / Double(totalShares)
                state.investments.holdings[index].shares = totalShares
            } else {
                state.investments.holdings.append(.init(stockID: stockID, shares: shares, averageCost: stock.price))
            }
            return .success("Bought \(shares) \(stock.symbol) shares including \(currency(fee)) fee.")

        case .sellStock(let stockID, let shares):
            guard shares > 0, let holdingIndex = state.investments.holdings.firstIndex(where: { $0.stockID == stockID }),
                  let stock = state.stocks.first(where: { $0.id == stockID }),
                  state.investments.holdings[holdingIndex].shares >= shares else { return .failure("You do not hold that many shares.") }
            let holding = state.investments.holdings[holdingIndex]
            let subtotal = stock.price * Double(shares)
            let fee = max(2, subtotal * 0.01)
            state.agency.cash += subtotal - fee
            state.investments.feesPaid += fee
            state.investments.realisedGain += (stock.price - holding.averageCost) * Double(shares) - fee
            state.investments.holdings[holdingIndex].shares -= shares
            if state.investments.holdings[holdingIndex].shares == 0 { state.investments.holdings.remove(at: holdingIndex) }
            return .success("Sold \(shares) \(stock.symbol) shares after \(currency(fee)) fee.")
        }
    }

    // MARK: - Weekly simulation

    private static func advanceOneWeek(_ state: inout GameState) {
        state.week += 1
        let newSeason = ((state.week - 1) / 52) + 1
        if newSeason != state.season {
            finishSeason(&state)
            state.season = newSeason
            for index in state.clubs.indices {
                state.clubs[index].points = 0; state.clubs[index].played = 0
                state.clubs[index].wins = 0; state.clubs[index].draws = 0; state.clubs[index].losses = 0
            }
        }
        settleFinances(&state)
        moveStocks(&state)
        developPlayers(&state)
        updateClients(&state)
        processScouting(&state)
        processMarket(&state)
        processRivals(&state)
        simulateLeagues(&state)
        evaluateProgression(&state)
        evaluateSolvency(&state)
        trimHistory(&state)
    }

    private static func settleFinances(_ state: inout GameState) {
        let retainers = state.weeklyRetainers
        let costs = state.weeklyOperatingCost
        let commission = state.pendingCommission
        let cashBeforeInvestments = state.agency.cash
        state.agency.cash += retainers + commission - costs
        state.agency.totalCosts += costs
        state.pendingCommission = 0
        state.financeHistory.append(.init(week: state.week, retainers: retainers, commission: commission,
                                          operatingCosts: costs, investmentChange: state.agency.cash - cashBeforeInvestments - retainers - commission + costs,
                                          closingCash: state.agency.cash))
    }

    private static func moveStocks(_ state: inout GameState) {
        var random = SeededRandom(seed: state.seed, week: state.week, stream: "stocks")
        for index in state.stocks.indices {
            state.stocks[index].previousPrice = state.stocks[index].price
            let marketDrift = 0.0015 + Double(state.season) * 0.0001
            let shock = random.double(-state.stocks[index].volatility...state.stocks[index].volatility)
            state.stocks[index].price = max(2, (state.stocks[index].price * (1 + marketDrift + shock) * 100).rounded() / 100)
        }
    }

    private static func developPlayers(_ state: inout GameState) {
        var random = SeededRandom(seed: state.seed, week: state.week, stream: "development")
        for index in state.players.indices where !state.players[index].retired {
            state.players[index].contractWeeks = max(0, state.players[index].contractWeeks - 1)
            if state.players[index].injuryWeeks > 0 { state.players[index].injuryWeeks -= 1 }
            if state.players[index].age <= 24, state.players[index].ability < state.players[index].potential,
               random.chance(0.018 + (state.agency.specialization == .youth ? 0.008 : 0)) {
                state.players[index].ability += 1
            }
            if state.players[index].age >= 31, random.chance(0.009) { state.players[index].ability = max(30, state.players[index].ability - 1) }
            if state.players[index].injuryWeeks == 0, random.chance(0.007) { state.players[index].injuryWeeks = random.int(1...7) }
            if state.weekOfSeason == 1 { state.players[index].age += 1 }
            if state.players[index].age >= 36, random.chance(0.18) { state.players[index].retired = true }
        }
    }

    private static func updateClients(_ state: inout GameState) {
        var random = SeededRandom(seed: state.seed, week: state.week, stream: "clients")
        var departures: [(GameID, String)] = []
        for index in state.clients.indices {
            state.clients[index].representationWeeks = max(0, state.clients[index].representationWeeks - 1)
            guard let player = state.player(state.clients[index].playerID) else { continue }
            if player.retired { departures.append((player.id, "Retired from football")); continue }
            if player.injuryWeeks > 0 {
                state.clients[index].playingTime = .fringe
                state.clients[index].trust = max(0, state.clients[index].trust - 1)
            } else {
                let roll = random.int(1...100) + player.ability
                state.clients[index].playingTime = roll >= 145 ? .key : roll >= 120 ? .regular : roll >= 96 ? .rotation : .fringe
                let staffBoost = state.staff.filter { $0.role == .welfare && $0.clientIDs.contains(player.id) }.count
                let trustChange = state.clients[index].playingTime == .fringe ? -2 : state.clients[index].playingTime == .key ? 2 : 0
                state.clients[index].trust = min(100, max(0, state.clients[index].trust + trustChange + staffBoost))
            }
            if let deadline = state.clients[index].promiseDeadline, deadline <= state.week {
                let fulfilled = state.clients[index].dealsDone > 0 || state.clients[index].playingTime == .key
                state.clients[index].trust = min(100, max(0, state.clients[index].trust + (fulfilled ? 9 : -16)))
                addCareer(player.id, fulfilled ? "Promise delivered" : "Promise missed",
                          fulfilled ? "Career progress matched the agency’s word." : "The promised progress did not arrive in time.", to: &state)
                state.clients[index].promiseDeadline = nil
                state.clients[index].promiseText = nil
            }
            if state.clients[index].representationWeeks == 0 { departures.append((player.id, "Representation contract expired")) }
            else if state.clients[index].trust <= 8 { departures.append((player.id, "Lost faith in the agency")) }
        }
        for (playerID, reason) in departures { removeClient(playerID, reason: reason, state: &state) }
    }

    private static func processScouting(_ state: inout GameState) {
        var random = SeededRandom(seed: state.seed, week: state.week, stream: "scouting")
        for scoutIndex in state.scouts.indices {
            guard let regionID = state.scouts[scoutIndex].regionID else { continue }
            state.scouts[scoutIndex].progress += 1
            let scout = state.scouts[scoutIndex]
            for reportIndex in state.reports.indices where state.reports[reportIndex].scoutID == scout.id {
                let player = state.player(state.reports[reportIndex].playerID)
                guard let player else { continue }
                state.reports[reportIndex].observedWeeks += 1
                state.reports[reportIndex].updatedWeek = state.week
                let precision = max(1, scout.quality / 24 + (state.agency.specialization == .youth ? 1 : 0))
                state.reports[reportIndex].abilityLow = min(player.ability, state.reports[reportIndex].abilityLow + precision)
                state.reports[reportIndex].abilityHigh = max(player.ability, state.reports[reportIndex].abilityHigh - precision)
                state.reports[reportIndex].potentialLow = min(player.potential, state.reports[reportIndex].potentialLow + precision)
                state.reports[reportIndex].potentialHigh = max(player.potential, state.reports[reportIndex].potentialHigh - precision)
            }
            let discoveryEvery = max(2, 5 - scout.quality / 22)
            if scout.progress >= discoveryEvery {
                let known = Set(state.reports.map(\.playerID) + state.clients.map(\.playerID))
                let candidates = state.players.filter {
                    $0.regionID == regionID && !$0.retired && !known.contains($0.id) &&
                    (scout.focus == nil || $0.position == scout.focus)
                }
                if let player = candidates.isEmpty ? nil : random.pick(candidates) {
                    let width = max(6, 22 - scout.quality / 4)
                    state.reports.append(.init(id: "report-\(player.id)", playerID: player.id, scoutID: scout.id,
                                               abilityLow: max(1, player.ability - random.int(2...width)),
                                               abilityHigh: min(99, player.ability + random.int(2...width)),
                                               potentialLow: max(1, player.potential - random.int(2...width)),
                                               potentialHigh: min(99, player.potential + random.int(2...width)),
                                               observedWeeks: 1, shortlisted: false, approached: false,
                                               updatedWeek: state.week))
                    addEvent("Scouting report", "\(scout.name) has filed a first report on \(player.name).", .good, to: &state)
                }
                state.scouts[scoutIndex].progress = 0
            }
        }
    }

    private static func processMarket(_ state: inout GameState) {
        let returning = state.loans.filter { $0.endWeek <= state.week }
        for loan in returning {
            if let playerIndex = state.players.firstIndex(where: { $0.id == loan.playerID }) {
                state.players[playerIndex].clubID = loan.fromClubID
                addCareer(loan.playerID, "Loan completed", "Returned after a development spell.", to: &state)
                addEvent("Loan return", "\(state.players[playerIndex].name) returned to their parent club.", .neutral, to: &state)
            }
        }
        state.loans.removeAll { $0.endWeek <= state.week }
        for index in state.offers.indices where state.offers[index].status == .open && state.offers[index].expiresWeek < state.week {
            state.offers[index].status = .expired
            if let name = state.player(state.offers[index].playerID)?.name {
                addEvent("Offer expired", "The offer for \(name) was withdrawn.", .warning, to: &state)
            }
        }
        var renewalRandom = SeededRandom(seed: state.seed, week: state.week, stream: "renewals")
        for client in state.clients {
            guard let player = state.player(client.playerID), player.contractWeeks <= 20,
                  player.contractWeeks > 0, let club = state.club(player.clubID),
                  !state.offers.contains(where: { $0.playerID == player.id && $0.kind == .renewal && $0.status == .open }),
                  renewalRandom.chance(0.28) else { continue }
            state.offers.append(makeOffer(player: player, club: club, kind: .renewal,
                                          state: state, random: &renewalRandom))
            addEvent("Renewal offer", "\(club.name) offered \(player.name) a new contract.", .good, to: &state)
        }
        for playerIndex in state.players.indices where state.players[playerIndex].contractWeeks == 0 && state.players[playerIndex].clubID != nil {
            let playerID = state.players[playerIndex].id
            state.players[playerIndex].clubID = nil
            if let clientIndex = state.clients.firstIndex(where: { $0.playerID == playerID }) {
                state.clients[clientIndex].seekingMove = true
                state.clients[clientIndex].trust = max(0, state.clients[clientIndex].trust - 8)
            }
            addCareer(playerID, "Contract expired", "Became a free agent after no renewal was agreed.", to: &state)
        }
        guard state.transferWindowOpen else { return }
        var random = SeededRandom(seed: state.seed, week: state.week, stream: "market")
        for client in state.clients where client.seekingMove {
            guard let player = state.player(client.playerID),
                  !state.offers.contains(where: { $0.playerID == player.id && $0.status == .open }),
                  random.chance(0.18 + Double(state.agency.reputation) / 500) else { continue }
            let candidates = state.clubs.filter { $0.id != player.clubID && abs($0.strength - player.ability) <= 22 }
            guard !candidates.isEmpty else { continue }
            let club = random.pick(candidates)
            state.offers.append(makeOffer(player: player, club: club, kind: client.wantsLoan ? .loan : .transfer,
                                          state: state, random: &random))
            addEvent("Offer received", "\(club.name) wants to discuss \(player.name).", .good, to: &state)
        }
    }

    private static func processRivals(_ state: inout GameState) {
        var random = SeededRandom(seed: state.seed, week: state.week, stream: "rivals")
        for index in state.clients.indices where state.clients[index].trust < 35 {
            guard random.chance(0.025) else { continue }
            let playerID = state.clients[index].playerID
            state.clients[index].trust = max(0, state.clients[index].trust - 8)
            if let name = state.player(playerID)?.name {
                addEvent("Rival approach", "Another agency has contacted \(name). Rebuild trust quickly.", .urgent, to: &state)
            }
        }
        if random.chance(0.06) {
            let available = state.players.indices.filter { playerIndex in
                state.players[playerIndex].rivalAgencyID == nil &&
                    !state.clients.contains(where: { $0.playerID == state.players[playerIndex].id })
            }
            if let playerIndex = available.isEmpty ? nil : random.pick(available) {
                let rivalIndex = random.int(0...(state.rivals.count - 1))
                state.players[playerIndex].rivalAgencyID = state.rivals[rivalIndex].id
                state.rivals[rivalIndex].clientCount += 1
            }
        }
    }

    private static func simulateLeagues(_ state: inout GameState) {
        var random = SeededRandom(seed: state.seed, week: state.week, stream: "leagues")
        for index in state.clubs.indices {
            let roll = random.int(1...100) + state.clubs[index].strength
            state.clubs[index].played += 1
            if roll >= 130 { state.clubs[index].wins += 1; state.clubs[index].points += 3 }
            else if roll >= 95 { state.clubs[index].draws += 1; state.clubs[index].points += 1 }
            else { state.clubs[index].losses += 1 }
        }
    }

    private static func evaluateProgression(_ state: inout GameState) {
        if var objective = state.progression.objective, !objective.completed,
           objectiveValue(objective.kind, state: state) >= objective.target {
            objective.completed = true
            state.progression.objective = objective
            state.agency.cash += objective.rewardCash
            state.agency.reputation += objective.rewardReputation
            addEvent("Objective complete", "\(objective.kind.label): \(currency(objective.rewardCash)) and \(objective.rewardReputation) reputation awarded.", .good, to: &state)
        }
        let milestones: [(String, Bool, Double, Int)] = [
            ("First new client", state.clients.count >= 2 || state.alumni.count > 0, 5_000, 2),
            ("First commission", state.agency.totalCommission > 0, 10_000, 3),
            ("Five-client agency", state.clients.count >= 5, 25_000, 5),
            ("Six-figure business", state.agency.totalCommission >= 100_000, 35_000, 5),
            ("National contender", state.stage == .contender || state.stage == .elite, 75_000, 7),
            ("Elite agency", state.stage == .elite, 200_000, 10),
        ]
        for (name, achieved, cash, reputation) in milestones where achieved && !state.progression.milestones.contains(name) {
            state.progression.milestones.append(name)
            state.agency.cash += cash
            state.agency.reputation = min(100, state.agency.reputation + reputation)
            addEvent("Milestone: \(name)", "Awarded \(currency(cash)) and \(reputation) reputation.", .good, to: &state)
        }
    }

    private static func evaluateSolvency(_ state: inout GameState) {
        if state.agency.cash < 0 { state.agency.insolventWeeks += 1 } else { state.agency.insolventWeeks = 0 }
        if state.agency.insolventWeeks == 4, state.agency.hqLevel > 1 {
            state.agency.hqLevel -= 1
            addEvent("Forced downsizing", "Creditors forced the agency into cheaper premises.", .urgent, to: &state)
        }
        if state.agency.insolventWeeks >= 12 {
            state.gameOverReason = "The agency remained insolvent for twelve weeks and closed its doors."
            addEvent("Agency closed", state.gameOverReason ?? "The agency closed.", .urgent, to: &state)
        }
        if state.clients.isEmpty {
            state.gameOverReason = "With no represented players left, the agency closed."
            addEvent("Agency closed", state.gameOverReason ?? "The agency closed.", .urgent, to: &state)
        }
    }

    private static func finishSeason(_ state: inout GameState) {
        let leader = state.clubs.max { $0.points < $1.points }?.name ?? "Unknown"
        let objective = state.progression.objective
        let review = "Season \(state.season): \(leader) led the league. Objective \(objective?.completed == true ? "completed" : "missed")."
        state.progression.seasonReviews.append(review)
        state.progression.objective = nil
        addEvent("Season review", review, objective?.completed == true ? .good : .neutral, to: &state)
    }

    // MARK: - Helpers

    private static func completeOffer(_ offerID: GameID, packageScore: Double?, state: inout GameState) -> ActionOutcome {
        guard let offerIndex = state.offers.firstIndex(where: { $0.id == offerID && $0.status == .open }),
              let clientIndex = state.clients.firstIndex(where: { $0.playerID == state.offers[offerIndex].playerID }),
              let playerIndex = state.players.firstIndex(where: { $0.id == state.offers[offerIndex].playerID }),
              let clubIndex = state.clubs.firstIndex(where: { $0.id == state.offers[offerIndex].clubID }) else {
            return .failure("That offer is no longer available.")
        }
        let offer = state.offers[offerIndex]
        guard offer.kind == .renewal || state.transferWindowOpen else { return .failure("The transfer window is closed.") }
        let score = packageScore ?? offer.packageScore
        guard score <= offer.packageScore + 18 else { return .failure("The club will not accept that package.") }
        let factor = max(0.85, score / max(offer.packageScore, 1))
        state.offers[offerIndex].status = .accepted
        if offer.kind == .renewal {
            let finalWage = offer.wage * factor
            let commission = finalWage * 52 * Double(offer.years) * state.clients[clientIndex].commissionPercent / 100
            state.players[playerIndex].wage = finalWage
            state.players[playerIndex].contractWeeks = offer.years * 52
            state.clients[clientIndex].dealsDone += 1
            state.clients[clientIndex].trust = min(100, state.clients[clientIndex].trust + 7)
            state.pendingCommission += commission
            state.agency.totalCommission += commission
            addCareer(offer.playerID, "Club contract renewed", "Agreed \(offer.years) more years with \(state.clubs[clubIndex].name).", to: &state)
            addEvent("Renewal complete", "\(state.players[playerIndex].name) renewed. Commission: \(currency(commission)).", .good, to: &state)
            return .success("Renewal signed. The agency earned \(currency(commission)).")
        }
        if offer.kind == .loan {
            guard let oldClubID = state.players[playerIndex].clubID else { return .failure("The player has no parent club for a loan.") }
            let commission = offer.wage * Double(offer.loanWeeks) / 4 * state.clients[clientIndex].commissionPercent / 100
            state.loans.append(.init(id: "loan-\(offer.id)", playerID: offer.playerID, fromClubID: oldClubID,
                                     toClubID: offer.clubID, startWeek: state.week, endWeek: state.week + offer.loanWeeks))
            state.players[playerIndex].clubID = offer.clubID
            state.clients[clientIndex].wantsLoan = false
            state.clients[clientIndex].seekingMove = false
            state.clients[clientIndex].trust = min(100, state.clients[clientIndex].trust + 8)
            state.clients[clientIndex].dealsDone += 1
            state.pendingCommission += commission
            state.agency.totalCommission += commission
            addCareer(offer.playerID, "Loan move", "Joined \(state.clubs[clubIndex].name) for \(offer.loanWeeks) weeks.", to: &state)
            addEvent("Loan agreed", "\(state.players[playerIndex].name) joined \(state.clubs[clubIndex].name) on loan. Commission: \(currency(commission)).", .good, to: &state)
            return .success("Loan agreed with \(state.clubs[clubIndex].name). Commission: \(currency(commission)).")
        }
        let finalFee = offer.fee * factor
        let commission = finalFee * state.clients[clientIndex].commissionPercent / 100
        state.players[playerIndex].clubID = offer.clubID
        state.players[playerIndex].wage = offer.wage * factor
        state.players[playerIndex].contractWeeks = max(52, offer.years * 52)
        state.clients[clientIndex].dealsDone += 1
        state.clients[clientIndex].seekingMove = false
        state.clients[clientIndex].wantsLoan = false
        state.clients[clientIndex].trust = min(100, state.clients[clientIndex].trust + 12)
        state.pendingCommission += commission
        state.agency.totalCommission += commission
        state.agency.reputation = min(100, state.agency.reputation + max(1, state.clubs[clubIndex].prestige / 24))
        state.clubs[clubIndex].relationship = min(100, state.clubs[clubIndex].relationship + 8 + (state.agency.specialization == .relationships ? 4 : 0))
        addCareer(offer.playerID, "Transfer completed", "Moved to \(state.clubs[clubIndex].name) for \(currency(finalFee)).", to: &state)
        addEvent("Deal complete", "\(state.players[playerIndex].name) joined \(state.clubs[clubIndex].name). Commission: \(currency(commission)).", .good, to: &state)
        return .success("Transfer complete. The agency earned \(currency(commission)).")
    }

    private static func makeOffer(player: Player, club: Club, kind: OfferKind, state: GameState,
                                  random: inout SeededRandom) -> TransferOffer {
        let base = Double(player.ability * player.ability) * (club.tier == 1 ? 2_200 : 1_250)
        return TransferOffer(id: "offer-\(state.week)-\(state.offers.count + 1)", playerID: player.id,
                             clubID: club.id, kind: kind, wage: Double(player.ability * player.ability) * random.double(3.5...5.5),
                             fee: kind == .transfer ? base * random.double(0.82...1.25) : 0, years: random.int(2...5),
                             loanWeeks: kind == .loan ? random.int(16...38) : 0,
                             expiresWeek: state.week + random.int(2...4), status: .open,
                             packageScore: random.double(48...72))
    }

    private static func removeClient(_ playerID: GameID, reason: String, state: inout GameState) {
        guard let index = state.clients.firstIndex(where: { $0.playerID == playerID }) else { return }
        let client = state.clients.remove(at: index)
        state.alumni.append(.init(playerID: playerID, leftWeek: state.week, reason: reason,
                                  careerCommission: estimatedClientCommission(client, state: state)))
        addCareer(playerID, "Representation ended", reason, to: &state)
        if let name = state.player(playerID)?.name { addEvent("Client departure", "\(name): \(reason).", .urgent, to: &state) }
    }

    private static func addEvent(_ title: String, _ detail: String, _ tone: EventTone, to state: inout GameState) {
        state.events.append(.init(id: "event-\(state.week)-\(state.events.count + 1)", week: state.week,
                                  title: title, detail: detail, tone: tone))
    }

    private static func addCareer(_ playerID: GameID, _ title: String, _ detail: String, to state: inout GameState) {
        state.careers.append(.init(id: "career-\(state.careers.count + 1)", playerID: playerID,
                                   week: state.week, title: title, detail: detail))
    }

    private static func careerGoal(for player: Player) -> String {
        if player.age <= 20 { return "Reach regular first-team football" }
        if player.ability >= 70 { return "Compete for major honours" }
        if player.age >= 30 { return "Secure the right final contract" }
        return "Earn a move that advances the career"
    }

    private static func objectiveValue(_ kind: ObjectiveKind, state: GameState) -> Double {
        switch kind {
        case .clients: Double(state.clients.count)
        case .commission: state.agency.totalCommission
        case .reputation: Double(state.agency.reputation)
        case .stability: state.agency.cash
        }
    }

    static func objectiveProgress(_ state: GameState) -> (value: Double, target: Double)? {
        guard let objective = state.progression.objective else { return nil }
        return (objectiveValue(objective.kind, state: state), objective.target)
    }

    private static func estimatedClientCommission(_ client: Client, state: GameState) -> Double {
        Double(client.dealsDone) * 40_000 * client.commissionPercent / 100
    }

    private static func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "GBP").precision(.fractionLength(0)))
    }

    private static func trimHistory(_ state: inout GameState) {
        if state.events.count > 140 { state.events.removeFirst(state.events.count - 140) }
        if state.financeHistory.count > 104 { state.financeHistory.removeFirst(state.financeHistory.count - 104) }
    }
}
