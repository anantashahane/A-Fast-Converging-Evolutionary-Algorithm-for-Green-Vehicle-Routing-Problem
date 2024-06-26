//
//  Miscellaneous.swift
//  Experiment 6
//
//  Created by Ananta Shahane on 24/05/2023.
//

import Foundation

func GetDistance(customer1 : Customer, customer2 : Customer) -> Double {
    //Returns Euclidian Distance between two Customers.
    return sqrt(pow(customer2.x - customer1.x, 2) + pow(customer2.y - customer1.y, 2))
}

func GetDistance(x : (Double, Double), y : (Double, Double)) -> Double {
    //Returns Euclidian Distance between two Customers.
    return sqrt(pow(x.0 - y.0, 2) + pow(x.1 - y.1, 2))
}


func GetDistanceMatrix(Customers : [Customer]) -> (Double, [[Double]]) {
    //Returns maximum Distance between 2 customers and Distance matrix of customer, where customerID == index.
    var distanceMatrix = [[Double]]()
    distanceMatrix.append([])
    var maxDistance = 0.0
    for customer1 in Customers {
        var distanceVector = [0.0]
        for customer2 in Customers {
            let distance = GetDistance(customer1: customer1, customer2: customer2)
            maxDistance = maxDistance < distance ? distance : maxDistance
            distanceVector.append(distance)
        }
        distanceMatrix.append(distanceVector)
    }
    return (maxDistance, distanceMatrix)
}

func GetDotProduct(shadow ofCustomer: Customer, onCustomer : Customer, fromCustomer: Customer, maxDistance: Double) -> Double {
    //Returns (Dmax/D) * (v1 . v2) / v1
    let nf = GetDistance(customer1: onCustomer, customer2: fromCustomer)
    let projectorVector = (ofCustomer.x - fromCustomer.x, ofCustomer.y - fromCustomer.y)
    let projecteeVector = ((onCustomer.x - fromCustomer.x) / nf, (onCustomer.y - fromCustomer.y) / nf)               //Get Unitary Vector of Projectee Vector
    var returnValue = maxDistance / GetDistance(customer1: ofCustomer, customer2: onCustomer)
    returnValue *= (projecteeVector.0 * projectorVector.0 + projecteeVector.1 * projectorVector.1)
    return returnValue
}

func GetDotProduct(truck : Truck, toCustomer: Customer, fromCustomer: Customer, maxDistance : Double) -> Double {
    //Returns (Dmax/D) * (v1 . v2) / v1 with truck projection on a customer.
    let distance = GetDistance(customer1: toCustomer, customer2: fromCustomer)
    let normalisedVector = ((toCustomer.x - fromCustomer.x) / distance, (toCustomer.y - toCustomer.y) / distance)
    let truckCom = truck.GetCentreOfMass()
    let truckVector = (truckCom.0 - fromCustomer.x, truckCom.1 - toCustomer.y)
    var returnValue = maxDistance / GetDistance(x: truckCom, y: (toCustomer.x, toCustomer.y))
    returnValue *= (normalisedVector.0 * truckVector.0 + normalisedVector.1 * truckVector.1)
    return returnValue
}

func GetDotProduct(projector : Truck, projectee: Truck, fromCustomer: Customer, maxDistance : Double) -> Double {
    //Returns (Dmax/D) * (v1 . v2) / v1 with truck projection on a customer.
    let projectorCom = projector.GetCentreOfMass()
    let projecteeCom = projectee.GetCentreOfMass()
    let distance = GetDistance(x: projectorCom, y: projecteeCom)
    let normalisedVector = ((projecteeCom.0 - fromCustomer.x) / distance, (projectorCom.1 - fromCustomer.y) / distance)
    let truckVector = (projectorCom.0 - fromCustomer.x, projectorCom.1 - fromCustomer.y)
    var returnValue = maxDistance / distance
    returnValue *= (normalisedVector.0 * truckVector.0 + normalisedVector.1 * truckVector.1)
    return returnValue
}

extension Double {
    enum RNGError : Error {
        case invalidUpperBound
        case centerOutOfRange
    }
    static func NormalRandom(mu: Double, sigma: Double) -> Double {
        let u1 = Double.random(in: 0...1)
        let u2 = Double.random(in: 0...1)
        
        let z0 = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
        let randomNumber = z0 * sigma + mu
        
        return randomNumber
    }

    static func RandomNumber(center : Double, upperBound : Double, seed : Double?) throws -> Double {
        if upperBound < 0 {
            print("RNG Error: Upperbound (\(upperBound)) set lower than 0.")
            throw RNGError.invalidUpperBound
        }
        if center >= upperBound || center <= 0 {
            print("RNG Error: Center (\(center)) out of range [0, \(upperBound)).")
        }
        var val = 0.0
        if let seed = seed {
            val = seed
        } else {
            val = Double.random(in: 0...1)
        }
        let frontRatio = center / upperBound
        if val < frontRatio {
            val = val / frontRatio - 1
            let unscaled = asin(val) + (Double.pi / 2)
            return 2 * unscaled * center / Double.pi
        } else {
            val = (val - frontRatio) / (1 - frontRatio)
            let unscaled = asin(val)
            return center + (2 * unscaled * (upperBound - center)) / Double.pi
        }
    }
}