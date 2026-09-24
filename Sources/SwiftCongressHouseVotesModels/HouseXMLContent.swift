/// Ordered XML content, preserving mixed text and nested elements.
public indirect enum HouseXMLContent: Codable, Hashable, Sendable {
  /// A nested element at its original position.
  case element(HouseXMLNode)
  /// Character content, including source whitespace.
  case text(String)
}
