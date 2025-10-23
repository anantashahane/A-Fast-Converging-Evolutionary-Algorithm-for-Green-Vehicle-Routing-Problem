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
            var flag = false
            var individual = Routine(trucks: [])
            while !flag {
                (flag, individual) = GetSeed(balanced: Bool.random())
                // (flag, individual) = GetRandomSeed()
            }
            parentPopulation.append(individual)
        }
    }

    private func GetRandomSeed() -> (Bool, Routine) {
        var trucks = [Truck]()
        var remainingCustomers = Array(Customers.values)
        for _ in 0..<numberOfTrucks {
            var truck = Truck(sequenceOfCustomers: [])
            var flag = true
            while flag {
                if remainingCustomers.isEmpty
                    || remainingCustomers.filter({
                        truck.CanAccept(customer: $0, capacity: vehicleCapacity)
                    }).isEmpty
                {
                    flag = false
                }
                if let candidateCustomer = remainingCustomers.filter({
                    truck.CanAccept(customer: $0, capacity: vehicleCapacity)
                }).randomElement() {
                    truck.AddCustomer(customer: candidateCustomer, allCustomers: Customers.values)
                    remainingCustomers = remainingCustomers.filter({ $0.id != candidateCustomer.id }
                    )
                }
            }
            trucks.append(truck)
        }
        return (remainingCustomers.isEmpty, Routine(trucks: trucks))
    }

    private func GetSeed(balanced: Bool) -> (Bool, Routine) {
        var trucks = [Truck]()
        var remainingCustomers = Array(Customers.values)
        let totalDemand = remainingCustomers.map({ $0.demand }).reduce(0, +)
        for _ in 0..<numberOfTrucks {
            var truck = Truck(sequenceOfCustomers: [])
            var flag = true
            var lastCustomer = self.Depot
            var lastLastCustomer = self.Depot
            while flag {
                if remainingCustomers.isEmpty {
                    flag = false
                }
                if truck.sequence.isEmpty {
                    if let candidateCustomer = remainingCustomers.filter({
                        truck.CanAccept(customer: $0, capacity: vehicleCapacity)
                    }).randomElement() {
                        truck.AddCustomer(
                            customer: candidateCustomer, allCustomers: Customers.values)
                        remainingCustomers = remainingCustomers.filter({
                            $0.id != candidateCustomer.id
                        })
                        lastCustomer = candidateCustomer
                    }
                } else {
                    if let candidateCustomer = remainingCustomers.filter({
                        truck.CanAccept(customer: $0, capacity: vehicleCapacity)
                    }).sorted(by: {
                        GetDotProduct(
                            shadow: $0, onCustomer: lastCustomer, fromCustomer: lastLastCustomer,
                            maxDistance: maxDistance)
                            > GetDotProduct(
                                shadow: $1, onCustomer: lastCustomer,
                                fromCustomer: lastLastCustomer, maxDistance: maxDistance)
                    }).first {
                        truck.AddCustomer(
                            customer: candidateCustomer, allCustomers: Customers.values)
                        remainingCustomers = remainingCustomers.filter({
                            $0.id != candidateCustomer.id
                        })
                        lastLastCustomer = lastCustomer
                        lastCustomer = candidateCustomer
                    } else {
                        flag = false
                    }
                    if truck.GetDemand() > totalDemand / numberOfTrucks || balanced {
                        flag = false
                    }
                }
            }
            trucks.append(truck)
        }
        return (remainingCustomers.isEmpty, Routine(trucks: trucks))
    }
}
