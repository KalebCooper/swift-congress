/// One source element with unknown attributes, children, and text retained.
public struct SenateXMLNode: Codable, Hashable, Sendable {
  /// Attributes using original qualified names.
  public let attributes: [String: String]
  /// Ordered character and element content.
  public let content: [SenateXMLContent]
  /// The original qualified element name.
  public let name: String

  /// The local name used to interpret namespaced source variants.
  public var localName: String { String(name.split(separator: ":").last ?? Substring(name)) }
  /// All descendant character content in document order, without trimming.
  public var text: String {
    content.map { item in
      switch item {
      case .element(let node): node.text;
      case .text(let value): value
      }
    }.joined()
  }

  /// Creates a portable element value without parsing or I/O.
  public init(attributes: [String: String], content: [SenateXMLContent], name: String) {
    self.attributes = attributes; self.content = content; self.name = name
  }

  /// Returns the first direct child with a matching local name.
  public func child(_ name: String) -> Self? { children(named: name).first }

  /// Returns every direct child with a matching local name, without deduplication.
  public func children(named name: String) -> [Self] {
    content.compactMap { item in
      if case .element(let node) = item, node.localName == name { node } else { nil }
    }
  }
}
