/// The documented law route categories; response labels remain open source strings.
public enum LawType: String, Hashable, Sendable {
  /// A private law, addressed with the provider's `priv` route token.
  case `private` = "priv"
  /// A public law, addressed with the provider's `pub` route token.
  case `public` = "pub"
}
