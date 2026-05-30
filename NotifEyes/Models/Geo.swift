import Foundation

struct LatLng: Codable, Hashable, Sendable {
    var lat: Double
    var lng: Double
}

enum GeometryMeta: Codable, Hashable, Sendable {
    case circle(centerLat: Double, centerLng: Double, radiusMeters: Double)
    case polygon(points: [LatLng])

    private enum CodingKeys: String, CodingKey {
        case kind
        case centerLat
        case centerLng
        case radiusMeters
        case points
    }

    private enum Kind: String, Codable {
        case circle
        case polygon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)

        switch kind {
        case .circle:
            self = .circle(
                centerLat: try container.decode(Double.self, forKey: .centerLat),
                centerLng: try container.decode(Double.self, forKey: .centerLng),
                radiusMeters: try container.decode(Double.self, forKey: .radiusMeters)
            )
        case .polygon:
            self = .polygon(points: try container.decode([LatLng].self, forKey: .points))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .circle(centerLat, centerLng, radiusMeters):
            try container.encode(Kind.circle, forKey: .kind)
            try container.encode(centerLat, forKey: .centerLat)
            try container.encode(centerLng, forKey: .centerLng)
            try container.encode(radiusMeters, forKey: .radiusMeters)
        case let .polygon(points):
            try container.encode(Kind.polygon, forKey: .kind)
            try container.encode(points, forKey: .points)
        }
    }
}
