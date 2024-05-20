//
//  Initialise.swift
//  Experiment 6
//
//  Created by Ananta Shahane on 24/05/2023.
//

import Foundation

extension GeneticAlgorithm {
    
    func Initialise() {
        archive.ClearArchive()
        for _ in 1...populationSize {
//            if i % 10 == 0 {print("Generating individual \(i)")}
            var flag = false
            var individual = Routine(trucks: [])
            while !flag {
                (flag, individual) = GetSeed()
            }
            parentPopulation.append(individual)
        }
    }
    
    private func GetSeed() -> (Bool, Routine) {
        var trucks = [Truck]()
        var remainingCustomers = Array(Customers.values)
        for _ in 0..<numberOfTrucks {
            var truck = Truck(sequenceOfCustomers: [])
            var flag = true
            while flag {
                if remainingCustomers.isEmpty || remainingCustomers.filter({truck.CanAccept(customer: $0, capacity: vehicleCapacity)}).isEmpty {
                    flag = false
                }
                if let candidateCustomer = remainingCustomers.filter({truck.CanAccept(customer: $0, capacity: vehicleCapacity)}).randomElement() {
                    truck.AddCustomer(customer: candidateCustomer, allCustomers: Customers.values)
                    remainingCustomers = remainingCustomers.filter({$0.id != candidateCustomer.id})
                }
            }
            trucks.append(truck)
        }
        return (remainingCustomers.isEmpty, Routine(trucks: trucks))
    }
}
