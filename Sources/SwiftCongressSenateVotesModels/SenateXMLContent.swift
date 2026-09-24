/// Ordered XML content, preserving mixed text and nested elements.
public indirect enum SenateXMLContent: Codable, Hashable, Sendable {
  /// A nested element at its original position.
  case element(SenateXMLNode)
  /// Character content, including source whitespace.
  case text(String)
}
