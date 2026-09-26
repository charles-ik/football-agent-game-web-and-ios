import Foundation

enum GameContent {
    static let regions: [Region] = [
        .init(id: "capital", name: "The Capital", starRating: 5, scoutingCost: 520, poolSize: 55),
        .init(id: "north", name: "The North", starRating: 4, scoutingCost: 380, poolSize: 48),
        .init(id: "midlands", name: "The Midlands", starRating: 3.5, scoutingCost: 300, poolSize: 44),
        .init(id: "northeast", name: "The Northeast", starRating: 3, scoutingCost: 230, poolSize: 38),
        .init(id: "east", name: "The East", starRating: 2.5, scoutingCost: 170, poolSize: 34),
    ]

    private static let clubRows: [(String, Int, Int, Int, String)] = [
        ("Kingsbridge United", 1, 88, 92, "capital"), ("Ashford Rovers", 1, 85, 88, "capital"),
        ("Northgate City", 1, 84, 86, "north"), ("Harrowfield Athletic", 1, 81, 82, "north"),
        ("Sterling Park FC", 1, 79, 80, "capital"), ("Draybury Town", 1, 76, 74, "midlands"),
        ("Eastmoor Wanderers", 1, 74, 72, "east"), ("Riverton City", 1, 73, 71, "northeast"),
        ("Blackwater FC", 1, 72, 69, "north"), ("Crownhill United", 1, 71, 70, "capital"),
        ("Falkmere Albion", 1, 70, 66, "northeast"), ("Thornbury Rovers", 1, 69, 65, "midlands"),
        ("Weybridge FC", 1, 68, 64, "capital"), ("Marlow Heath", 1, 67, 62, "east"),
        ("Caldon Athletic", 1, 66, 61, "north"), ("Pentland City", 1, 65, 60, "northeast"),
        ("Silverdale United", 1, 64, 58, "midlands"), ("Grangeford FC", 1, 63, 57, "north"),
        ("Oakhaven Town", 1, 62, 55, "east"), ("Brackenhill FC", 1, 61, 54, "midlands"),
        ("Millford Town", 2, 60, 50, "midlands"), ("Redstone Rovers", 2, 59, 49, "north"),
        ("Hollowfield United", 2, 58, 48, "northeast"), ("Alderbrook Athletic", 2, 57, 46, "capital"),
        ("Kestrel Bay FC", 2, 56, 45, "east"), ("Longmere City", 2, 55, 44, "midlands"),
        ("Duncastle United", 2, 54, 43, "north"), ("Whitmoor Town", 2, 53, 41, "northeast"),
        ("Barrowgate FC", 2, 52, 40, "north"), ("Elmhurst Rovers", 2, 51, 39, "capital"),
        ("Stanwick Athletic", 2, 50, 37, "east"), ("Fenwick City", 2, 49, 36, "midlands"),
        ("Portholme United", 2, 48, 35, "east"), ("Greyfriars FC", 2, 47, 33, "capital"),
        ("Netherton Town", 2, 46, 32, "northeast"), ("Ravenscourt FC", 2, 45, 31, "capital"),
        ("Sedgewell Rangers", 2, 44, 29, "midlands"), ("Highcliffe United", 2, 43, 28, "east"),
        ("Bramwell Town", 2, 42, 27, "north"), ("Coldharbour FC", 2, 41, 26, "northeast"),
    ]

    static let firstNames = [
        "Adam", "Alfie", "Archie", "Arlo", "Ben", "Billy", "Blake", "Brandon", "Callum", "Cameron",
        "Charlie", "Connor", "Corey", "Declan", "Dominic", "Dylan", "Elliot", "Ethan", "Finn", "George",
        "Harvey", "Isaac", "Jacob", "Jake", "Jamie", "Jay", "Joel", "Jonah", "Jordan", "Josh", "Kai",
        "Leon", "Lewis", "Liam", "Logan", "Louis", "Luca", "Mason", "Max", "Micah", "Nathan", "Noah",
        "Oliver", "Owen", "Reece", "Riley", "Rory", "Ryan", "Sam", "Seb", "Theo", "Toby", "Tyler", "Zach",
    ]

    static let surnames = [
        "Ainsworth", "Arkwright", "Barlowe", "Bexley", "Braddock", "Calloway", "Carrick", "Chadwick",
        "Corliss", "Denby", "Draycott", "Eastwick", "Fairbrass", "Fenner", "Garrick", "Halsey", "Hargrave",
        "Havelock", "Ingram", "Kellaway", "Larkin", "Loxley", "Maddox", "Marchant", "Merrick", "Norwood",
        "Oakley", "Palgrave", "Penrose", "Quill", "Ransome", "Redfern", "Rothwell", "Selby", "Sharrock",
        "Stannard", "Thackery", "Tolhurst", "Vance", "Wardle", "Weatherby", "Whitlock", "Winstanley", "Yardley",
    ]

    static let rivalNames = [
        "Meridian Sports Group", "Halcyon Player Management", "Vantage Football Partners",
        "Ironside Representation", "Clearwater Talent", "Sovereign Sports Agency",
        "Northstar Management", "Kestrel & Vane",
    ]

    static func clubs() -> [Club] {
        clubRows.enumerated().map { index, row in
            Club(id: "club-\(index + 1)", name: row.0, tier: row.1, strength: row.2,
                 prestige: row.3, regionID: row.4, relationship: 0, points: 0,
                 played: 0, wins: 0, draws: 0, losses: 0)
        }
    }

    static func players(seed: UInt64, clubs: [Club]) -> [Player] {
        var random = SeededRandom(seed: seed, stream: "players")
        var names = Set<String>()
        var result: [Player] = []
        for index in 0..<120 {
            var name = ""
            repeat { name = "\(random.pick(firstNames)) \(random.pick(surnames))" } while names.contains(name)
            names.insert(name)
            let age = random.int(16...31)
            let region = random.pick(regions).id
            let club = random.pick(clubs.filter { $0.regionID == region })
            let ability = index == 0 ? 56 : random.int(34...78)
            let potential = min(94, max(ability, ability + random.int(1...18) - max(0, age - 23)))
            let position = random.pick(Position.allCases)
            result.append(Player(
                id: "player-\(index + 1)", name: name, age: age, position: position,
                ability: ability, potential: potential, trait: random.pick(PlayerTrait.allCases),
                regionID: region, clubID: index == 0 ? "club-21" : club.id,
                wage: Double(max(500, ability * ability * (club.tier == 1 ? 4 : 2))),
                contractWeeks: random.int(30...156), injuryWeeks: 0, retired: false,
                rivalAgencyID: index > 0 && random.chance(0.28) ? "rival-\(random.int(1...8))" : nil
            ))
        }
        return result
    }

    static func stocks() -> [StockListing] {
        [
            ("stadia", "Albion Stadia", "AST", 42.0, 0.045),
            ("kits", "Heritage Kits", "HKT", 18.5, 0.07),
            ("media", "Touchline Media", "TLM", 63.0, 0.055),
            ("travel", "Northstar Travel", "NST", 27.0, 0.04),
            ("tech", "Matchday Systems", "MDS", 91.0, 0.085),
        ].map { StockListing(id: $0.0, name: $0.1, symbol: $0.2, price: $0.3, previousPrice: $0.3, volatility: $0.4) }
    }

    static let hqNames = ["", "Shared Office", "Townhouse", "City Studio", "National HQ", "Global House"]
    static let hqUpgradeCosts: [Double] = [0, 0, 45_000, 140_000, 420_000, 1_200_000]
}
