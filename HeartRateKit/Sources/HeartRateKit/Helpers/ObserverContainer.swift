//
//  ObserverContainer.swift
//  HeartRateKit
//
//  Created by Sergii Kostanian on 2/8/18.
//  Copyright © 2018 MadAppGang. All rights reserved.
//

import Foundation

public struct ObserverContainer<Observer> {

    private struct Container: Hashable {

        weak var observer: AnyObject?

        private(set) var hashValue = 0

        init(_ observer: AnyObject) {
            self.observer = observer
            self.hashValue = ObjectIdentifier(observer).hashValue
        }

        static func ==(lhs: ObserverContainer<Observer>.Container, rhs: ObserverContainer<Observer>.Container) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(hashValue)
        }
    }

    private var containers: Set<Container> = []

    public init() {

    }

    private mutating func purgeEmptyContainers() {
        containers = containers.filter { $0.observer is Observer }
    }

}

public extension ObserverContainer {

    var count: Int {
        return containers.count
    }

    mutating func add(_ observer: Observer) {
        let anyObserver = observer as AnyObject
        let container = Container(anyObserver)
        containers.update(with: container)

        purgeEmptyContainers()
    }

    mutating func remove(_ observer: Observer) {
        let anyObserver = observer as AnyObject

        let used = containers.filter { container in
            if let observer = container.observer as? Observer {
                let shouldRemove = ObjectIdentifier(anyObserver) != ObjectIdentifier(observer as AnyObject)
                return shouldRemove
            } else {
                return false
            }
        }

        containers = used

        purgeEmptyContainers()
    }

    func enumerateObservers(_ body: (_ observer: Observer) -> Void) {
        containers.forEach { container in
            if let observer = container.observer as? Observer {
                body(observer)
            }
        }
    }

}
