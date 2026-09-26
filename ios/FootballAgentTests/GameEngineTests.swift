import XCTest
@testable import FootballAgent

final class GameEngineTests: XCTestCase {
    func testNewGameAndAdvancementAreDeterministic() {
        var first = GameEngine.newGame(name: "Northbank", seed: 42)
        var second = GameEngine.newGame(name: "Northbank", seed: 42)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.agency.cash, 75_000)
        XCTAssertEqual(first.clients.count, 1)
        XCTAssertEqual(first.scouts.count, 1)
        _ = GameEngine.advance(.weeks(12), state: &first)
        _ = GameEngine.advance(.weeks(12), state: &second)
        XCTAssertEqual(first, second)
    }

    func testScoutingNarrowsRangesAndCanSignAClient() throws {
        var game = GameEngine.newGame(name: "Northbank", seed: 42)
        let scout = try XCTUnwrap(game.scouts.first)
        XCTAssertTrue(GameEngine.perform(.assignScout(scout.id, regionID: "east"), on: &game).ok)
        _ = GameEngine.advance(.weeks(4), state: &game)
        let firstReport = try XCTUnwrap(game.reports.first)
        let startingWidth = firstReport.abilityHigh - firstReport.abilityLow
        _ = GameEngine.advance(.weeks(2), state: &game)
        let updated = try XCTUnwrap(game.reports.first { $0.id == firstReport.id })
        XCTAssertLessThanOrEqual(updated.abilityHigh - updated.abilityLow, startingWidth)
        XCTAssertTrue(GameEngine.perform(.shortlist(updated.id), on: &game).ok)
        XCTAssertTrue(GameEngine.perform(.openRepresentation(updated.id), on: &game).ok)
        XCTAssertTrue(GameEngine.perform(.proposeNegotiation(4), on: &game).ok)
        XCTAssertEqual(game.clients.count, 2)
        XCTAssertTrue(GameEngine.featureAccess(in: game)[.market]?.unlocked == true)
    }

    func testFailedActionLeavesWholeStateUnchanged() {
        var game = GameEngine.newGame(name: "Northbank", seed: 7)
        game.agency.cash = 0
        let before = game
        XCTAssertFalse(GameEngine.perform(.upgradeHeadquarters, on: &game).ok)
        XCTAssertEqual(game, before)
    }

    func testTransferPaysCommissionAndRecordsCareer() throws {
        var game = GameEngine.newGame(name: "Northbank", seed: 9)
        let client = try XCTUnwrap(game.clients.first)
        let player = try XCTUnwrap(game.player(client.playerID))
        let destination = try XCTUnwrap(game.clubs.first { $0.id != player.clubID })
        game.offers.append(.init(id: "test-offer", playerID: player.id, clubID: destination.id,
                                 kind: .transfer, wage: 8_000, fee: 1_000_000, years: 3,
                                 loanWeeks: 0, expiresWeek: 4, status: .open, packageScore: 60))
        XCTAssertTrue(GameEngine.perform(.acceptOffer("test-offer"), on: &game).ok)
        XCTAssertEqual(game.player(player.id)?.clubID, destination.id)
        XCTAssertEqual(game.agency.totalCommission, 80_000)
        XCTAssertEqual(game.pendingCommission, 80_000)
        XCTAssertTrue(game.careers.contains { $0.playerID == player.id && $0.title == "Transfer completed" })
        XCTAssertTrue(GameEngine.featureAccess(in: game)[.staff]?.unlocked == true)
    }

    func testScoutCapacityAndClubRenewal() throws {
        var game = GameEngine.newGame(name: "Northbank", seed: 14)
        let before = game
        XCTAssertFalse(GameEngine.perform(.hireScout, on: &game).ok)
        XCTAssertEqual(game, before)
        XCTAssertTrue(GameEngine.perform(.upgradeHeadquarters, on: &game).ok)
        XCTAssertTrue(GameEngine.perform(.hireScout, on: &game).ok)
        XCTAssertEqual(game.scouts.count, 2)

        game.week = 20 // outside both transfer windows; club renewals still proceed
        let client = try XCTUnwrap(game.clients.first)
        let player = try XCTUnwrap(game.player(client.playerID))
        let clubID = try XCTUnwrap(player.clubID)
        game.offers.append(.init(id: "renewal", playerID: player.id, clubID: clubID,
                                 kind: .renewal, wage: 9_000, fee: 0, years: 3,
                                 loanWeeks: 0, expiresWeek: 24, status: .open, packageScore: 60))
        XCTAssertTrue(GameEngine.perform(.acceptOffer("renewal"), on: &game).ok)
        XCTAssertEqual(game.player(player.id)?.contractWeeks, 156)
        XCTAssertGreaterThan(game.agency.totalCommission, 0)
    }

    func testAdvanceToEventNeverSkipsMoreThanTwelveWeeks() {
        var game = GameEngine.newGame(name: "Northbank", seed: 5)
        let before = game.week
        _ = GameEngine.advance(.nextEvent, state: &game)
        XCTAssertGreaterThan(game.week, before)
        XCTAssertLessThanOrEqual(game.week - before, 12)
    }

    func testJSONRoundTripPreservesFutureSimulation() throws {
        var game = GameEngine.newGame(name: "Northbank", seed: 101)
        _ = GameEngine.advance(.weeks(10), state: &game)
        let data = try JSONEncoder().encode(game)
        var reopened = try JSONDecoder().decode(GameState.self, from: data)
        var original = game
        _ = GameEngine.advance(.weeks(8), state: &original)
        _ = GameEngine.advance(.weeks(8), state: &reopened)
        XCTAssertEqual(original, reopened)
    }
}

@MainActor
final class GameStoreTests: XCTestCase {
    func testAutosaveRoundTripAndCorruptSavePreservation() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = GameStore(directory: directory, autoLoad: false)
        store.newGame(name: "Northbank", seed: 42, slot: "one")
        store.advance(.oneWeek)
        let expected = try XCTUnwrap(store.game)
        let reopened = GameStore(directory: directory, autoLoad: false)
        reopened.load(slot: "one")
        XCTAssertEqual(reopened.game, expected)

        let save = directory.appendingPathComponent("one.json")
        try Data("not json".utf8).write(to: save)
        let corrupt = GameStore(directory: directory, autoLoad: false)
        corrupt.load(slot: "one")
        XCTAssertNil(corrupt.game)
        XCTAssertNotNil(corrupt.persistentError)
        XCTAssertEqual(try Data(contentsOf: save), Data("not json".utf8))

        var future = expected
        future.schemaVersion = 2
        let futureData = try JSONEncoder().encode(future)
        let futureURL = directory.appendingPathComponent("future.json")
        try futureData.write(to: futureURL)
        let newer = GameStore(directory: directory, autoLoad: false)
        newer.load(slot: "future")
        XCTAssertNil(newer.game)
        XCTAssertNotNil(newer.persistentError)
        XCTAssertEqual(try Data(contentsOf: futureURL), futureData)
    }
}
