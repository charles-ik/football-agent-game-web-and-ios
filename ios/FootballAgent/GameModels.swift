import Foundation

typealias GameID = String

enum Position: String, Codable, CaseIterable, Sendable {
    case goalkeeper, defender, midfielder, winger, striker

    var label: String { rawValue.capitalized }
    var shortLabel: String {
        switch self {
        case .goalkeeper: "GK"
        case .defender: "DEF"
        case .midfielder: "MID"
        case .winger: "WNG"
        case .striker: "ST"
        }
    }
}

enum PlayerTrait: String, Codable, CaseIterable, Sendable {
    case ambitious, driven, loyal, mercurial, professional
    var label: String { rawValue.capitalized }
}

enum PlayingTime: String, Codable, CaseIterable, Sendable {
    case key, regular, rotation, fringe
    var label: String { rawValue.capitalized }
}

enum GameFeature: String, Codable, CaseIterable, Identifiable, Sendable {
    case market, staff, departments, specialization, loans, stocks
    var id: String { rawValue }
    var label: String {
        switch self {
        case .market: "Market & relationships"
        case .staff: "Support staff"
        case .departments: "Departments"
        case .specialization: "Specialization"
        case .loans: "Loan desk"
        case .stocks: "Stocks"
        }
    }
}

enum AgencySpecialization: String, Codable, CaseIterable, Identifiable, Sendable {
    case balanced, youth, negotiation, relationships
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var detail: String {
        switch self {
        case .balanced: "Steady benefits across the agency."
        case .youth: "Faster scouting and player development."
        case .negotiation: "Stronger counters and better commission."
        case .relationships: "Club trust grows faster after good deals."
        }
    }
}

enum ObjectiveKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case clients, commission, reputation, stability
    var id: String { rawValue }
    var label: String {
        switch self {
        case .clients: "Grow the roster"
        case .commission: "Close meaningful deals"
        case .reputation: "Raise your standing"
        case .stability: "Build a cash reserve"
        }
    }
}

enum StaffRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case analyst, welfare, negotiator
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var weeklyCost: Double {
        switch self {
        case .analyst: 420
        case .welfare: 360
        case .negotiator: 520
        }
    }
}

enum DepartmentKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case analytics, playerCare, commercial
    var id: String { rawValue }
    var label: String {
        switch self {
        case .analytics: "Analytics"
        case .playerCare: "Player care"
        case .commercial: "Commercial"
        }
    }
}

enum OfferKind: String, Codable, Sendable {
    case transfer, loan, renewal
    var label: String { rawValue.capitalized }
}

enum OfferStatus: String, Codable, Sendable { case open, accepted, declined, expired }
enum EventTone: String, Codable, Sendable { case good, neutral, warning, urgent }
enum DecisionSeverity: Int, Codable, Comparable, Sendable {
    case info = 0, warning = 1, urgent = 2
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

enum ProgressStage: String, Codable, CaseIterable, Sendable {
    case startup, established, contender, elite
    var label: String { rawValue.capitalized }
}

enum ConversationType: String, Codable, CaseIterable, Identifiable, Sendable {
    case reassure, challenge, praise
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum NegotiationKind: String, Codable, Sendable { case representation, transfer }

struct Agency: Codable, Equatable, Sendable {
    var name: String
    var cash: Double
    var reputation: Int
    var hqLevel: Int
    var totalCommission: Double
    var totalCosts: Double
    var specialization: AgencySpecialization
    var identity: String
    var insolventWeeks: Int
}

struct Player: Codable, Equatable, Identifiable, Sendable {
    var id: GameID
    var name: String
    var age: Int
    var position: Position
    var ability: Int
    var potential: Int
    var trait: PlayerTrait
    var regionID: GameID
    var clubID: GameID?
    var wage: Double
    var contractWeeks: Int
    var injuryWeeks: Int
    var retired: Bool
    var rivalAgencyID: GameID?
}

struct Client: Codable, Equatable, Identifiable, Sendable {
    var id: GameID { playerID }
    var playerID: GameID
    var trust: Int
    var commissionPercent: Double
    var representationWeeks: Int
    var signedWeek: Int
    var playingTime: PlayingTime
    var seekingMove: Bool
    var wantsLoan: Bool
    var dealsDone: Int
    var careerGoal: String
    var promiseDeadline: Int?
    var promiseText: String?
    var lastConversationWeek: Int
}

struct Region: Codable, Equatable, Identifiable, Sendable {
    var id: GameID
    var name: String
    var starRating: Double
    var scoutingCost: Double
    var poolSize: Int
}

struct Scout: Codable, Equatable, Identifiable, Sendable {
    var id: GameID
    var name: String
    var quality: Int
    var salary: Double
    var regionID: GameID?
    var focus: Position?
    var progress: Int
}

struct ScoutingReport: Codable, Equatable, Identifiable, Sendable {
    var id: GameID
    var playerID: GameID
    var scoutID: GameID
    var abilityLow: Int
    var abilityHigh: Int
    var potentialLow: Int
    var potentialHigh: Int
    var observedWeeks: Int
    var shortlisted: Bool
    var approached: Bool
    var updatedWeek: Int
}

struct Club: Codable, Equatable, Identifiable, Sendable {
    var id: GameID
    var name: String
    var tier: Int
    var strength: Int
    var prestige: Int
    var regionID: GameID
    var relationship: Int
    var points: Int
    var played: Int
    var wins: Int
    var draws: Int
    var losses: Int
}

struct TransferOffer: Codable, Equatable, Identifiable, Sendable {
    var id: GameID
    var playerID: GameID
    var clubID: GameID
    var kind: OfferKind
    var wage: Double
    var fee: Double
    var years: Int
    var loanWeeks: Int
    var expiresWeek: Int
    var status: OfferStatus
    var packageScore: Double
}

struct Loan: Codable, Equatable, Identifiable, Sendable {
    var id: GameID
    var playerID: GameID
    var fromClubID: GameID
    var toClubID: GameID
    var startWeek: Int
    var endWeek: Int
}

struct RivalAgency: Codable, Equatable, Identifiable, Sendable {
    var id: GameID
    var name: String
    var reputation: Int
    var clientCount: Int
}

struct SupportStaff: Codable, Equatable, Identifiable, Sendable {
    var id: GameID
    var name: String
    var role: StaffRole
    var quality: Int
    var weeklyCost: Double
    var clientIDs: [GameID]
}

struct AgencyDepartment: Codable, Equatable, Identifiable, Sendable {
    var id: GameID { kind.rawValue }
    var kind: DepartmentKind
    var level: Int
}

struct CareerEntry: Codable, Equatable, Identifiable, Sendable {
    var id: GameID
    var playerID: GameID
    var week: Int
    var title: String
    var detail: String
}

struct AlumniRecord: Codable, Equatable, Identifiable, Sendable {
    var id: GameID { playerID }
    var playerID: GameID
    var leftWeek: Int
    var reason: String
    var careerCommission: Double
}

struct GameEvent: Codable, Equatable, Identifiable, Sendable {
    var id: GameID
    var week: Int
    var title: String
    var detail: String
    var tone: EventTone
}

struct FinanceWeek: Codable, Equatable, Identifiable, Sendable {
    var id: Int { week }
    var week: Int
    var retainers: Double
    var commission: Double
    var operatingCosts: Double
    var investmentChange: Double
    var closingCash: Double
    var net: Double { retainers + commission - operatingCosts }
}

struct StockListing: Codable, Equatable, Identifiable, Sendable {
    var id: GameID
    var name: String
    var symbol: String
    var price: Double
    var previousPrice: Double
    var volatility: Double
}

struct StockHolding: Codable, Equatable, Identifiable, Sendable {
    var id: GameID { stockID }
    var stockID: GameID
    var shares: Int
    var averageCost: Double
}

struct InvestmentPortfolio: Codable, Equatable, Sendable {
    var holdings: [StockHolding] = []
    var realisedGain: Double = 0
    var feesPaid: Double = 0
}

struct SeasonObjective: Codable, Equatable, Sendable {
    var kind: ObjectiveKind
    var startValue: Double
    var target: Double
    var rewardCash: Double
    var rewardReputation: Int
    var completed: Bool
}

struct Progression: Codable, Equatable, Sendable {
    var milestones: [String] = []
    var objective: SeasonObjective?
    var seasonReviews: [String] = []
}

struct Negotiation: Codable, Equatable, Identifiable, Sendable {
    var id: GameID
    var kind: NegotiationKind
    var playerID: GameID
    var offerID: GameID?
    var roundsRemaining: Int
    var target: Double
    var counter: Double
    var lastProposal: Double?
    var hint: String
}

struct GameState: Codable, Equatable, Sendable {
    var schemaVersion = 1
    var seed: UInt64
    var week = 1
    var season = 1
    var agency: Agency
    var players: [Player]
    var clients: [Client]
    var regions: [Region]
    var clubs: [Club]
    var scouts: [Scout]
    var reports: [ScoutingReport] = []
    var offers: [TransferOffer] = []
    var loans: [Loan] = []
    var rivals: [RivalAgency]
    var staff: [SupportStaff] = []
    var departments: [AgencyDepartment]
    var careers: [CareerEntry] = []
    var alumni: [AlumniRecord] = []
    var events: [GameEvent] = []
    var financeHistory: [FinanceWeek] = []
    var stocks: [StockListing]
    var investments = InvestmentPortfolio()
    var progression = Progression()
    var negotiation: Negotiation?
    var pendingCommission: Double = 0
    var gameOverReason: String?
}

enum AdvanceMode: Equatable, Sendable { case oneWeek, weeks(Int), nextEvent }

enum GameAction: Equatable, Sendable {
    case assignScout(GameID, regionID: GameID)
    case setScoutFocus(GameID, Position?)
    case hireScout
    case fireScout(GameID)
    case shortlist(GameID)
    case openRepresentation(GameID)
    case openTransfer(GameID)
    case proposeNegotiation(Double)
    case walkAway
    case seekMove(GameID, Bool)
    case requestLoan(GameID, Bool)
    case acceptOffer(GameID)
    case declineOffer(GameID)
    case conversation(GameID, ConversationType)
    case makePromise(GameID, String)
    case renewRepresentation(GameID)
    case releaseClient(GameID)
    case pitch(GameID, clubID: GameID)
    case hireStaff(StaffRole)
    case fireStaff(GameID)
    case togglePortfolio(staffID: GameID, clientID: GameID)
    case upgradeDepartment(DepartmentKind)
    case downgradeDepartment(DepartmentKind)
    case setIdentity(String)
    case setSpecialization(AgencySpecialization)
    case selectObjective(ObjectiveKind)
    case upgradeHeadquarters
    case downsizeHeadquarters
    case buyStock(GameID, shares: Int)
    case sellStock(GameID, shares: Int)
}

struct ActionOutcome: Equatable, Sendable {
    var ok: Bool
    var message: String
    static func success(_ message: String) -> Self { .init(ok: true, message: message) }
    static func failure(_ message: String) -> Self { .init(ok: false, message: message) }
}

struct GameDecision: Equatable, Identifiable, Sendable {
    var id: String
    var title: String
    var detail: String
    var deadlineWeek: Int?
    var severity: DecisionSeverity
}

struct NextMove: Equatable, Sendable {
    var title: String
    var detail: String
    var tab: Int
}

struct FeatureAccess: Equatable, Sendable {
    var unlocked: Bool
    var requirement: String
}

extension GameState {
    var weekOfSeason: Int { ((week - 1) % 52) + 1 }
    var transferWindowOpen: Bool { (1...10).contains(weekOfSeason) || (28...31).contains(weekOfSeason) }
    var stage: ProgressStage {
        if agency.reputation >= 75 && agency.totalCommission >= 1_500_000 { return .elite }
        if agency.reputation >= 48 && agency.totalCommission >= 400_000 { return .contender }
        if agency.reputation >= 25 && agency.totalCommission >= 50_000 { return .established }
        return .startup
    }
    var nextStageText: String {
        switch stage {
        case .startup: "25 reputation and £50k commission"
        case .established: "48 reputation and £400k commission"
        case .contender: "75 reputation and £1.5m commission"
        case .elite: "Top-tier agency"
        }
    }
    var weeklyOperatingCost: Double {
        let hq = [0, 180, 620, 1_900, 6_200, 15_000][min(max(agency.hqLevel, 1), 5)]
        let scoutCosts = scouts.reduce(0) { total, scout in
            total + scout.salary + (regions.first { $0.id == scout.regionID }?.scoutingCost ?? 0)
        }
        let staffCosts = staff.reduce(0) { $0 + $1.weeklyCost }
        let departmentCosts = departments.reduce(0) { $0 + Double($1.level * $1.level) * 180 }
        return Double(hq) + scoutCosts + staffCosts + departmentCosts
    }
    var weeklyRetainers: Double { Double(clients.count) * 160 }
    var recurringNet: Double { weeklyRetainers - weeklyOperatingCost }
    var portfolioValue: Double {
        investments.holdings.reduce(0) { total, holding in
            total + Double(holding.shares) * (stocks.first { $0.id == holding.stockID }?.price ?? 0)
        }
    }
    var clientCapacity: Int { [0, 5, 9, 14, 20, 28][min(max(agency.hqLevel, 1), 5)] }
    var scoutCapacity: Int { [0, 1, 2, 4, 6, 9][min(max(agency.hqLevel, 1), 5)] }
    var staffCapacity: Int { agency.hqLevel }

    func player(_ id: GameID) -> Player? { players.first { $0.id == id } }
    func club(_ id: GameID?) -> Club? { clubs.first { $0.id == id } }
    func region(_ id: GameID?) -> Region? { regions.first { $0.id == id } }
}
