//
//  HealthService.swift
//  Bikemeter
//
//  Created by Andrius Shiaulis on 19.06.2022.
//

import Foundation
import HealthKit

final class HealthService {

    struct CyclingDateStatisticsItem {
        let date: Date
        let kilometers: Double
    }

    private let store: HKHealthStore

    enum Error: Swift.Error {
        case dataNotAvailable
        case unableToMakeCyclingQuantityIdentifier
        case unableToMakeCyclingDystanceSampleType
        case dateCannotBeConstructed
    }

    init() throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw Error.dataNotAvailable
        }

        self.store = .init()
    }

    func start() async throws {
        guard let cyclingQuantityType: HKQuantityType = .quantityType(forIdentifier: .distanceCycling) else { throw Error.unableToMakeCyclingQuantityIdentifier }
        try await self.store.requestAuthorization(toShare: [], read: [cyclingQuantityType])
    }

//    func calculateDailyCyclingDistanceForPastWeek() throws {
//        guard let cyclingDistanceType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceCycling) else { throw Error.unableToMakeCyclingDystanceSampleType }
//        let anchorDate = try getMonday()
//        let daily = DateComponents(day: 1)
//        let exactlySevenDaysAgo = try exactlySevenDaysAgo()
//        let oneWeekAgo = HKQuery.predicateForSamples(withStart: exactlySevenDaysAgo, end: nil, options: .strictStartDate)
//
//        let query = HKStatisticsCollectionQuery(quantityType: cyclingDistanceType, quantitySamplePredicate: oneWeekAgo, anchorDate: anchorDate, intervalComponents: daily)
//
//        query.initialResultsHandler = { query, statisticsCollection, error in
//            if let statisticsCollection = statisticsCollection {
//                try! self.updateUI(with: statisticsCollection)
//            }
//        }
//
//        self.store.execute(query)
//    }

    func calculateDailyCyclingDistanceForPastWeek() async throws -> [CyclingDateStatisticsItem] {
        let cyclingDistanceType = HKQuantityType(.distanceCycling)
        let exactlySevenDaysAgo = try exactlySevenDaysAgo()
        let oneWeekAgo = HKQuery.predicateForSamples(withStart: exactlySevenDaysAgo, end: nil, options: .strictStartDate)
        let predicate = HKSamplePredicate.quantitySample(type: cyclingDistanceType, predicate: oneWeekAgo)
        let anchorDate = try getMonday()
        let daily = DateComponents(day: 1)

        let descriptor = HKStatisticsCollectionQueryDescriptor(predicate: predicate, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: daily)

        let collection = try await descriptor.result(for: self.store)
        return try items(from: collection)
    }

    func items(from statisticsCollection: HKStatisticsCollection) throws -> [CyclingDateStatisticsItem] {
        guard let startDate = Calendar.current.date(byAdding: .day, value: -6, to: .now) else { throw Error.dateCannotBeConstructed }
        let endDate: Date = .now

        var items: [CyclingDateStatisticsItem] = []
        statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
            let kilometers = statistics.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
            items.append(.init(date: statistics.startDate, kilometers: kilometers))
        }

        return items
    }

    private func exactlySevenDaysAgo() throws -> Date {
        guard let date = Calendar.current.date(byAdding: .day, value: -7, to: .now) else { throw Error.dateCannotBeConstructed }
        return date
    }

    func getMonday(myDate: Date = .now) throws -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear, .hour], from: myDate)
        components.weekday = 1 // Monday
        components.hour = 3
        guard let mondayInWeek = calendar.date(from: components) else { throw Error.dateCannotBeConstructed }
        return mondayInWeek
    }
}
