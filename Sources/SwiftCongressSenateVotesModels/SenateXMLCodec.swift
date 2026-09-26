#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import class Foundation.NSObject

// FoundationXML is a system codec dependency, never an HTTP transport.
#if canImport(FoundationXML)
import FoundationXML
#else
import class Foundation.XMLParser
import protocol Foundation.XMLParserDelegate
#endif

/// A bounded system XML reader for Senate documents.
/// It never opens URLs or loads external entities. Original bytes remain in SDK receipts.
public enum SenateXMLCodec {
  /// Reads at most 16 MiB, 64 nested elements, and 100,000 elements by default.
  /// - Throws: `SenateDecodingError` for malformed data, limits, or cancellation.
  public static func decode(
    _ data: Data, maximumBytes: Int = 16_777_216,
    maximumDepth: Int = 64, maximumElements: Int = 100_000
  ) throws(SenateDecodingError) -> SenateXMLNode {
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
    #if canImport(Darwin)
    // Apple's Foundation imports `delegate` as `unowned(unsafe)`, so any reference to it from
    // Swift, a `#keyPath` included, is an unsafe use under strict memory safety. Key-value coding
    // reaches the setter dynamically by name, so the property is never referenced here. The parser
    // keeps no strong reference to `reader`, so `parse()` runs inside `withExtendedLifetime(reader)`
    // below, which guarantees that no callback can reach a freed delegate.
    parser.setValue(reader, forKey: "delegate")
    #else
    parser.delegate = reader
    #endif
    parser.shouldProcessNamespaces = false
    parser.shouldResolveExternalEntities = false
    #if canImport(Darwin)
    parser.externalEntityResolvingPolicy = .never
    #endif
    let success = withExtendedLifetime(reader) { parser.parse() }
    if Task.isCancelled { throw .cancelled }
    if let failure = reader.failure { throw failure }
    guard success, reader.stack.isEmpty, let root = reader.root else { throw .invalidDocument }
    return root
  }
}

private final class XMLReader: NSObject, XMLParserDelegate {
  var failure: SenateDecodingError?
  private var elementCount = 0
  private let maximumDepth: Int
  private let maximumElements: Int
  var root: SenateXMLNode?
  var stack: [Builder] = []

  struct Builder {
    let attributes: [String: String]
    var content: [SenateXMLContent]
    let name: String
  }

  init(maximumDepth: Int, maximumElements: Int) {
    self.maximumDepth = maximumDepth; self.maximumElements = maximumElements
  }

  private func append(_ value: SenateXMLContent) {
    guard !stack.isEmpty else { return }
    stack[stack.count - 1].content.append(value)
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
    let node = SenateXMLNode(
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

}
