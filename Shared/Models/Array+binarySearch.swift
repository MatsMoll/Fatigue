//
//  Array+binarySearch.swift
//  Fatigue
//
//  Created by Mats Mollestad on 10/06/2021.
//

import Foundation

extension Array {
    
    func binarySearch<T>(_ value: T, map: KeyPath<Element, T>) -> Index? where T: Comparable {
        if self.isEmpty { return nil }
        
        var searchBound = self.indices
        
        while searchBound.startIndex != searchBound.endIndex {
            let currentIndex = searchBound.count / 2 + searchBound.startIndex
            if self[currentIndex][keyPath: map] == value {
                return currentIndex
            } else if self[currentIndex][keyPath: map] > value {
                searchBound = (currentIndex + 1)..<searchBound.endIndex
            } else {
                searchBound = searchBound.startIndex..<currentIndex
            }
        }
        
        if self[searchBound.startIndex][keyPath: map] == value {
            return searchBound.startIndex
        } else {
            return nil
        }
    }
}
