import XCTest
@testable import DriveLog

final class ProfitabilityCalculatorTests: XCTestCase {
    func testProfitMetrics() {
        let vehicle = UUID(); let now = Date()
        let trips = [Trip(startedAt: now.addingTimeInterval(-7200), endedAt: now, distanceMeters: 100_000, vehicleID: vehicle, category: .business)]
        let income = [Income(date: now, amount: 500, platform: "Test")]
        let fuel = [FuelEntry(date: now, vehicleID: vehicle, odometer: 100, liters: 20, pricePerUnit: 5)]
        let result = ProfitabilityCalculator.calculate(trips: trips, fuel: fuel, expenses: [], incomes: income, interval: DateInterval(start: now.addingTimeInterval(-10_000), end: now.addingTimeInterval(1)))
        XCTAssertEqual(result.profit, 400, accuracy: 0.01)
        XCTAssertEqual(result.profitPerKM, 4, accuracy: 0.01)
        XCTAssertEqual(result.profitPerHour, 200, accuracy: 0.01)
    }
}

