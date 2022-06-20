//
//  RootController.swift
//  Bikemeter
//
//  Created by Andrius Shiaulis on 19.06.2022.
//

import Foundation

final class RootController {

    init() {
        start()
    }

    private func start() {
        let service = try! HealthService()

        Task {
            try! await service.start()
            let items = try! await service.calculateDailyCyclingDistanceForPastWeek()
            print(items)
        }
    }
    
}
