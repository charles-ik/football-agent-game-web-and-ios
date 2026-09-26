import Foundation

struct SeededRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64, week: Int = 0, stream: String = "world") {
        state = seed ^ Self.fnv1a("\(week):\(stream)")
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }

    mutating func int(_ range: ClosedRange<Int>) -> Int {
        range.lowerBound + Int(next() % UInt64(range.count))
    }

    mutating func double(_ range: ClosedRange<Double> = 0...1) -> Double {
        let unit = Double(next() >> 11) / Double(1 << 53)
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }

    mutating func chance(_ probability: Double) -> Bool { double() < probability }

    mutating func pick<T>(_ values: [T]) -> T {
        values[Int(next() % UInt64(values.count))]
    }

    static func fnv1a(_ text: String) -> UInt64 {
        text.utf8.reduce(0xcbf29ce484222325) { ($0 ^ UInt64($1)) &* 0x100000001b3 }
    }
}
