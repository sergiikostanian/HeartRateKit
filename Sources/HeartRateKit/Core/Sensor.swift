//
//  Sensor.swift
//  SmartRun
//
//  Created by Sergii Kostanian on 7/17/17.
//  Copyright © 2017 MadAppGang. All rights reserved.
//

import Foundation

public enum Source: String {
    case bluetooth
    case appleWatch
}

public enum State: String {
    case none
    case connected
    case notConnected
}

public struct Sensor: Hashable {

    public enum Kind: String {
        case smartRunChest
        case smartRunArm
        case appleWatch
        case polarH7
        case xiaomiMiBand2
        case healthApp
        case fake
        case unknown
    }

    public let id: UUID
 
    public var type: Kind = .unknown
    public var state: State = .none
    public var description = ""
    public var nameOfDevice: String?
    public var source: Source = .bluetooth

    public var hashValue: Int {
        return id.hashValue
    }
    
    init(id: UUID) {
        self.id = id
    }

    public static func ==(lhs: Sensor, rhs: Sensor) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id.hashValue)
    }

}

extension Sensor: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case state
        case description
        case nameOfDevice
        case source
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)

        let rawType = try values.decode(String.self, forKey: .type)
        type = Kind(rawValue: rawType) ?? .unknown

        let rawState = try values.decode(String.self, forKey: .state)
        state = State(rawValue: rawState) ?? .none

        description = try values.decode(String.self, forKey: .description)
        nameOfDevice = try values.decode(String.self, forKey: .nameOfDevice)

        let rawSource = try values.decode(String.self, forKey: .source)
        source = Source(rawValue: rawSource) ?? .bluetooth
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(state.rawValue, forKey: .state)
        try container.encode(description, forKey: .description)
        try container.encode(nameOfDevice, forKey: .nameOfDevice)
        try container.encode(source.rawValue, forKey: .source)
    }
}
