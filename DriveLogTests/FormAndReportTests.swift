import XCTest
import SwiftData
@testable import DriveLog

final class FormAndReportTests: XCTestCase {
    func testLocationAuthorizationProducesVisibleAction() {
        XCTAssertEqual(LocationAuthorizationAction.resolve(.authorizedWhenInUse), .start)
        XCTAssertEqual(LocationAuthorizationAction.resolve(.authorizedAlways), .start)
        XCTAssertEqual(LocationAuthorizationAction.resolve(.notDetermined), .requestPermission)
        XCTAssertEqual(LocationAuthorizationAction.resolve(.denied), .openSettings)
        XCTAssertEqual(LocationAuthorizationAction.resolve(.restricted), .openSettings)
    }

    func testBackgroundLocationRequiresArrayCapability() {
        XCTAssertTrue(LocationConfiguration.supportsBackgroundLocation(
            infoDictionary: ["UIBackgroundModes": ["audio", "location"]]
        ))
        XCTAssertFalse(LocationConfiguration.supportsBackgroundLocation(
            infoDictionary: ["UIBackgroundModes": "location"]
        ))
        XCTAssertFalse(LocationConfiguration.supportsBackgroundLocation(infoDictionary: [:]))
    }

    func testRecordingSnapshotRoundTripPreservesRoute() throws {
        let point = TrackPoint(latitude: 52.534, longitude: 17.582, timestamp: .now)
        let original = RecordingSnapshot(
            startedAt: point.timestamp,
            endedAt: nil,
            vehicleID: UUID(),
            shiftID: UUID(),
            distanceMeters: 1234.5,
            points: [point]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RecordingSnapshot.self, from: data)
        XCTAssertEqual(decoded.startedAt, original.startedAt)
        XCTAssertEqual(decoded.vehicleID, original.vehicleID)
        XCTAssertEqual(decoded.shiftID, original.shiftID)
        XCTAssertEqual(decoded.distanceMeters, original.distanceMeters)
        XCTAssertEqual(decoded.points, original.points)
        XCTAssertNil(decoded.endedAt)
    }

    func testPolishAndDotDecimalInput() {
        XCTAssertEqual(EntryNumber.parse(" 12,50 "), 12.5)
        XCTAssertEqual(EntryNumber.parse("12.50"), 12.5)
        XCTAssertEqual(EntryNumber.parse("0"), 0)
        XCTAssertEqual(EntryNumber.text(2009), "2009")
    }

    func testInvalidInputIsNotSilentlySavedAsZero() {
        for input in ["", " ", "-1", "abc", "NaN", "inf", "1,2,3", "12 zł", "1e9"] {
            XCTAssertNil(EntryNumber.parse(input), input)
        }
    }

    func testMidnightBelongsOnlyToNextPeriod() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let end = start.addingTimeInterval(86_400)
        let incomes = [Income(date: start, amount: 10, platform: "Test"),
                       Income(date: end, amount: 20, platform: "Test")]
        let first = ProfitabilityCalculator.calculate(trips: [], fuel: [], expenses: [], incomes: incomes,
            interval: DateInterval(start: start, end: end))
        let second = ProfitabilityCalculator.calculate(trips: [], fuel: [], expenses: [], incomes: incomes,
            interval: DateInterval(start: end, duration: 86_400))
        XCTAssertEqual(first.income, 10)
        XCTAssertEqual(second.income, 20)
    }

    func testVehicleFilterDoesNotAssignLegacyIncome() {
        let now = Date(), car = UUID(), other = UUID()
        let assigned = Income(date: now, amount: 100, platform: "Test", tips: 10, commission: 20)
        assigned.vehicleID = car
        let legacy = Income(date: now, amount: 50, platform: "Test")
        let another = Income(date: now, amount: 80, platform: "Test")
        another.vehicleID = other
        let interval = DateInterval(start: now.addingTimeInterval(-1), duration: 2)
        let result = ProfitabilityCalculator.calculate(trips: [], fuel: [], expenses: [], incomes: [assigned, legacy, another], interval: interval, vehicleID: car)
        XCTAssertEqual(result.income, 90)
        let all = ProfitabilityCalculator.calculate(trips: [], fuel: [], expenses: [], incomes: [assigned, legacy, another], interval: interval)
        XCTAssertEqual(all.income, 220)
    }

    func testOnlyBusinessTripsCountInDrivingMetrics() {
        let now = Date(), car = UUID()
        let trips = TripCategory.allCases.map {
            Trip(startedAt: now, endedAt: now.addingTimeInterval(3600),
                 distanceMeters: 10_000, vehicleID: car, category: $0)
        }
        let result = ProfitabilityCalculator.calculate(trips: trips, fuel: [], expenses: [], incomes: [],
            interval: DateInterval(start: now, duration: 7200))
        XCTAssertEqual(result.distanceKM, 10)
        XCTAssertEqual(result.workSeconds, 3600)
    }

    func testEmptySummaryHasNoDivisionByZero() {
        let value = ProfitabilitySummary(income: 0, costs: 0, distanceKM: 0, workSeconds: 0)
        XCTAssertEqual(value.profitPerKM, 0)
        XCTAssertEqual(value.profitPerHour, 0)
    }

    @MainActor
    func testLinkedEntryCanBeSavedAndFetched() throws {
        let container = try ModelContainer(for: Income.self, WorkShift.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let shift = WorkShift(vehicleID: UUID())
        let income = Income(amount: 100, platform: "Test")
        income.shiftID = shift.id; income.vehicleID = shift.vehicleID
        context.insert(shift); context.insert(income)
        try context.save()
        let saved = try context.fetch(FetchDescriptor<Income>())
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.shiftID, shift.id)
        XCTAssertEqual(saved.first?.vehicleID, shift.vehicleID)
    }
}
