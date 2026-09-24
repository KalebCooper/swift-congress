#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A JSON value retaining unknown provider fields and explicit nulls.
public enum JSONValue: Codable, Hashable, Sendable {
  /// An ordered array.
  case array([JSONValue])
  /// A Boolean value.
  case boolean(Bool)
  /// An explicit null.
  case null
  /// A decimal JSON number.
  case number(Decimal)
  /// An object with source field names.
  case object([String: JSONValue])
  /// A source string.
  case string(String)

  /// The array value, if present.
  public var array: [JSONValue]? { if case .array(let value) = self { value } else { nil } }
  /// The integer value when exactly representable.
  public var integer: Int? {
    guard case .number(let value) = self else { return nil }
    return Int(value.description)
  }
  /// The object value, if present.
  public var object: [String: JSONValue]? {
    if case .object(let value) = self { value } else { nil }
  }
  /// The string value, if present.
  public var string: String? { if case .string(let value) = self { value } else { nil } }

  /// Decodes a JSON value without discarding unrecognized fields.
  public init(from decoder: any Decoder) throws {
    let c = try decoder.singleValueContainer()
    if c.decodeNil() {
      self = .null
    } else if let v = try? c.decode(Bool.self) {
      self = .boolean(v)
    } else if let v = try? c.decode(String.self) {
      self = .string(v)
    } else if let v = try? c.decode(Decimal.self) {
      self = .number(v)
    } else if let v = try? c.decode([JSONValue].self) {
      self = .array(v)
    } else {
      self = .object(try c.decode([String: JSONValue].self))
    }
  }

  /// Encodes the retained JSON value.
  public func encode(to encoder: any Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .array(let v): try c.encode(v)
    case .boolean(let v): try c.encode(v)
    case .null: try c.encodeNil()
    case .number(let v): try c.encode(v)
    case .object(let v): try c.encode(v)
    case .string(let v): try c.encode(v)
    }
  }
}
