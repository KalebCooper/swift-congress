#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import class Foundation.NSObject

// FoundationXML is a system codec dependency, never an HTTP transport.
#if canImport(FoundationXML)
import FoundationXML
#endif

/// Failure while reading one bounded House source document.
public enum HouseDecodingError: Error, Hashable, Sendable {
  /// The reading task was cancelled.
  case cancelled
  /// The document is malformed or lacks required source structure.
  case invalidDocument
  /// The document exceeds byte, depth, or element bounds.
  case limitExceeded
}

/// Ordered XML content, preserving mixed text and nested elements.
public indirect enum HouseXMLContent: Codable, Hashable, Sendable {
  /// A nested element at its original position.
  case element(HouseXMLNode)
  /// Character content, including source whitespace.
  case text(String)
}

/// One source element with unknown attributes, children, and text retained.
public struct HouseXMLNode: Codable, Hashable, Sendable {
  /// Attributes using original qualified names.
  public let attributes: [String: String]
  /// Ordered character and element content.
  public let content: [HouseXMLContent]
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
  public init(attributes: [String: String], content: [HouseXMLContent], name: String) {
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

/// A source-specific response decodable without an SDK or transport.
public protocol HouseResponse: Sendable {
  /// Decodes the downloaded bytes using the request URL as explicit source context.
  static func decode(_ data: Data, sourceURL: URL) throws(HouseDecodingError) -> Self
}

/// A bounded system XML reader for House documents.
/// It never opens URLs or loads external entities. Original bytes remain in SDK receipts.
public enum HouseXMLCodec {
  /// Reads at most 16 MiB, 64 nested elements, and 100,000 elements by default.
  /// - Throws: `HouseDecodingError` for malformed data, limits, or cancellation.
  public static func decode(
    _ data: Data, maximumBytes: Int = 16_777_216,
    maximumDepth: Int = 64, maximumElements: Int = 100_000
  ) throws(HouseDecodingError) -> HouseXMLNode {
    guard !Task.isCancelled else { throw .cancelled }
    guard maximumBytes > 0, maximumDepth > 0, maximumElements > 0, data.count <= maximumBytes
    else { throw .limitExceeded }
    // libxml may silently skip declarations when entity resolution is disabled.
    // Reject their ASCII marker before parsing, including UTF-16/32 zero padding.
    // This deliberately also rejects a literal declaration marker inside a comment or CDATA.
    guard Data(data.filter { $0 != 0 }).range(of: Data("<!ENTITY".utf8)) == nil else {
      throw .invalidDocument
    }
    let reader = XMLReader(maximumDepth: maximumDepth, maximumElements: maximumElements)
    let parser = XMLParser(data: data)
    parser.delegate = reader
    parser.shouldProcessNamespaces = false
    parser.shouldResolveExternalEntities = false
    #if canImport(Darwin)
    parser.externalEntityResolvingPolicy = .never
    #endif
    let success = parser.parse()
    if Task.isCancelled { throw .cancelled }
    if let failure = reader.failure { throw failure }
    guard success, reader.stack.isEmpty, let root = reader.root else { throw .invalidDocument }
    return root
  }
}

private final class XMLReader: NSObject, XMLParserDelegate {
  var failure: HouseDecodingError?
  private var elementCount = 0
  private let maximumDepth: Int
  private let maximumElements: Int
  var root: HouseXMLNode?
  var stack: [Builder] = []

  struct Builder {
    let attributes: [String: String]
    var content: [HouseXMLContent]
    let name: String
  }

  init(maximumDepth: Int, maximumElements: Int) {
    self.maximumDepth = maximumDepth; self.maximumElements = maximumElements
  }

  func parser(
    _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?, attributes attributeDict: [String: String]
  ) {
    guard !Task.isCancelled else { failure = .cancelled; parser.abortParsing(); return }
    guard stack.count < maximumDepth, elementCount < maximumElements else {
      failure = .limitExceeded; parser.abortParsing(); return
    }
    elementCount += 1
    stack.append(Builder(attributes: attributeDict, content: [], name: elementName))
  }

  func parser(
    _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    guard let builder = stack.popLast() else {
      failure = .invalidDocument; parser.abortParsing(); return
    }
    let node = HouseXMLNode(
      attributes: builder.attributes, content: builder.content, name: builder.name)
    if stack.isEmpty {
      guard root == nil else { failure = .invalidDocument; parser.abortParsing(); return }
      root = node
    } else {
      append(.element(node))
    }
  }

  func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
    guard let value = String(data: CDATABlock, encoding: .utf8) else {
      failure = .invalidDocument; parser.abortParsing(); return
    }
    append(.text(value))
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    guard !Task.isCancelled else { failure = .cancelled; parser.abortParsing(); return }
    append(.text(string))
  }

  func parser(
    _ parser: XMLParser, foundExternalEntityDeclarationWithName name: String, publicID: String?,
    systemID: String?
  ) {
    failure = .invalidDocument; parser.abortParsing()
  }

  func parser(
    _ parser: XMLParser, foundInternalEntityDeclarationWithName name: String, value: String?
  ) {
    failure = .invalidDocument; parser.abortParsing()
  }

  func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?)
    -> Data?
  {
    failure = .invalidDocument; parser.abortParsing(); return nil
  }

  private func append(_ value: HouseXMLContent) {
    guard !stack.isEmpty else { return }
    stack[stack.count - 1].content.append(value)
  }
}
