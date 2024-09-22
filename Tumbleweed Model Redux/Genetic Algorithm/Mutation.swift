//
//  Mutation.swift
//  Experiment 6
//
//  Created by Ananta Shahane on 05/06/2023.
//

import Foundation

extension GeneticAlgorithm {
    
    func MutatePopulation() {
        var newOffspringPopulation = [Routine]()
        for individual in parentPopulation {
            let randomNumber = Int.random(in: 1...4)
            switch randomNumber {
            case 1: newOffspringPopulation.append(TSPMutation(individual: individual))
            case 2: newOffspringPopulation.append(FuelOptimiser(individual: individual))
            case 3: newOffspringPopulation.append(RotateOperator(individual: individual))
            default: newOffspringPopulation.append(LNS(individual: individual))
            }
        }
        offspringPopulation = newOffspringPopulation
    }

    private func RotateOperator(individual: Routine) -> Routine {
        var returnIndividual = individual
        if let mutationTruck = returnIndividual.trucks.enumerated().filter({$0.element.sequence.count >= 3}).randomElement() {
            let count = mutationTruck.element.sequence.count
            let strictness = CalculateStrictness(routine: individual)
            let sequence = mutationTruck.element.sequence.enumerated().sorted(by: {
                Customers[$0.element]!.demand > Customers[$1.element]!.demand
            })
            if let randomElement = SpinRouletteWheel(strictness: strictness, onCandidates: sequence) {
                let randomPoint = randomElement.offset
                let sequence = Array(mutationTruck.element.sequence[randomPoint..<count] + mutationTruck.element.sequence[0..<randomPoint])
                returnIndividual.trucks[mutationTruck.offset].sequence = sequence
            }
        }
        return returnIndividual
    }
    
    private func TSPMutation(individual : Routine) -> Routine {
        //Does the Alpha * current distance 2-opt search, an modification of 2-opt mutator, to optimise for searching for more fuel-distance pareto-front.
        var returnIndividual = individual
        if let mutationTruck = returnIndividual.trucks.enumerated().filter({$0.element.sequence.count > 2}).randomElement() {
            var sequence = mutationTruck.element.sequence
            let alpha = pow(2.71, Double.NormalRandom(mu: 0, sigma: 1)) * mutationTruck.element.GetAlpha()
            returnIndividual.trucks[mutationTruck.offset].SetAlpha(to: alpha)
            if let randomCustomer = sequence[0..<sequence.count - 2].randomElement() {
                let randomCustomerIndex = sequence.enumerated().filter({$0.element == randomCustomer}).first!.offset
                let distanceToBeat = distanceMatrix[randomCustomer][sequence[randomCustomerIndex + 1]] * alpha
                var candidateCustomers = Array(sequence.enumerated())[randomCustomerIndex + 1..<sequence.count].filter({distanceMatrix[randomCustomer][$0.element] < distanceToBeat})
                if Double.random(in: 0...1) < 0.5 {
                    candidateCustomers = candidateCustomers.sorted(by: {Customers[$0.element]!.demand > Customers[$1.element]!.demand})
                } else {
                    candidateCustomers = candidateCustomers.sorted(by: {distanceMatrix[randomCustomer][$0.element] < distanceMatrix[randomCustomer][$1.element]})
                }
                let strictness = CalculateStrictness(routine: individual)
                if let mutationPoint = SpinRouletteWheel(strictness: strictness, onCandidates: candidateCustomers) {
                    sequence = Array(sequence[0...randomCustomerIndex] + sequence[randomCustomerIndex + 1...mutationPoint.offset].reversed() + sequence[mutationPoint.offset + 1..<sequence.count])
                    returnIndividual.trucks[mutationTruck.offset].sequence = sequence
                } else {
                    let count = mutationTruck.element.sequence.count
                    let randomPoint = Int.random(in: 0..<count)
                    let sequence = Array(mutationTruck.element.sequence[randomPoint..<count] + mutationTruck.element.sequence[0..<randomPoint])
                    returnIndividual.trucks[mutationTruck.offset].sequence = sequence
                }
            } else {
                returnIndividual = RotateOperator(individual: returnIndividual)
            }
        }
        return returnIndividual
    }
    
    private func FuelOptimiser(individual : Routine) -> Routine {
        var returnIndividual = individual
        let strictness = CalculateStrictness(routine : individual)
        if let truck = returnIndividual.trucks.enumerated().filter({$0.element.sequence.count > 2}).randomElement() {
            var sequence = truck.element.sequence
            let randomIndex = Int.random(in: 0..<sequence.count - 1)
            let alpha = pow(2.71, Double.NormalRandom(mu: 0, sigma: 1)) * truck.element.GetAlpha()
            returnIndividual.trucks[truck.offset].SetAlpha(to: alpha)
            let distanceToBeat = distanceMatrix[sequence[randomIndex]][sequence[randomIndex + 1]] * truck.element.GetAlpha()
            let candidateCustomers = sequence.enumerated().filter({distanceMatrix[sequence[randomIndex]][$0.element] <= distanceToBeat}).sorted(by: {
                Customers[$0.element]!.demand >= Customers[$1.element]!.demand
            })
            if let NextCustomer = SpinRouletteWheel(strictness: strictness, onCandidates: candidateCustomers) {
                sequence.swapAt(randomIndex, NextCustomer.offset)
                returnIndividual.trucks[truck.offset].sequence = sequence
            }
            return returnIndividual
        }
        return returnIndividual
    }
    
    private func LNS(individual : Routine) -> Routine {
        var freeCustomerIDs = [Int]()
        var returnIndividual = individual
        let strictness1 = CalculateStrictness(routine: individual)
        let strictness0 = sqrt(strictness1)
        for (id, truck) in returnIndividual.trucks.enumerated() {
            let size = max(1, (individual.frontNumber * truck.sequence.count) / (max(paretoFronts.count, 1)))
            // print("\(size) = \(individual.frontNumber) * \(truck.sequence.count) / \(paretoFronts.count)")
            let emitterCount = Int.random(in: 0...(size))
            if emitterCount != 0 {
                var customers = truck.GetDistanceSequence(customers: Customers.values)
                for _ in 1...emitterCount {
                    if let emittedCustomer = SpinRouletteWheel(strictness: strictness0, onCandidates: customers) {
                        freeCustomerIDs.append(emittedCustomer)
                        customers = customers.filter({$0 != emittedCustomer})
                        _ = returnIndividual.trucks[id].RemoveCustomer(customer: Customers[emittedCustomer]!, allCustomers: Customers.values)
                    }
                }
            }
        }
        let freeCustomers = freeCustomerIDs.map({Customers[$0]!})
        for customer in freeCustomers {
            let candidateTrucks = returnIndividual.trucks.enumerated().filter({$0.element.CanAccept(customer: customer, capacity: vehicleCapacity)}).sorted(by:{
                GetDotProduct(truck: $0.element, toCustomer: customer, fromCustomer: Depot, maxDistance: maxDistance) > GetDotProduct(truck: $1.element, toCustomer: customer, fromCustomer: Depot, maxDistance: maxDistance)
            })
            if let truck = SpinRouletteWheel(strictness: strictness1, onCandidates: candidateTrucks) {
                let targetCustomerIDs = truck.element.sequence.enumerated()
                let customers = targetCustomerIDs.map({($0.offset, Customers[$0.element]!)}).sorted(by: {
                    GetDotProduct(shadow: $0.1, onCustomer: customer, fromCustomer: Depot, maxDistance: maxDistance) > GetDotProduct(shadow: $1.1, onCustomer: customer, fromCustomer: Depot, maxDistance: maxDistance)
                })
                if customers.isEmpty {
                    returnIndividual.trucks[truck.offset].AddCustomer(customer: customer, allCustomers: Customers.values)
                } else {
                    returnIndividual.trucks[truck.offset].AddCustomer(customer: customer, atIndex: customers[0].0, allCustomers: Customers.values)
                }
                freeCustomerIDs = freeCustomerIDs.filter({$0 != customer.id})
            }
        }
        if !freeCustomerIDs.isEmpty {
            return individual
        }
        return returnIndividual
    }

    private func CalculateStrictness(routine : Routine) -> Double {
        let strictness = Double(routine.frontNumber * Customers.count * remainingIterations) / Double(paretoFronts.count * iterationCount)
        let delta = Double.NormalRandom(mu: 0, sigma: 2)
        return strictness * pow(2.71, delta)
    }
}

