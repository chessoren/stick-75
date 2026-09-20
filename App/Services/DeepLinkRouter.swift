import Foundation

/// stick://call/wake · stick://call/debrief · stick://intercept · stick://r/CODE · https://stick.app/r/CODE
enum DeepLink: Equatable {
  case call(CallKind)
  case intercept
  case referral(String)
  case tab(String)

  init?(url: URL) {
    let host = url.host()?.lowercased() ?? ""
    let parts = url.pathComponents.filter { $0 != "/" }
    if url.scheme == "stick" {
      switch host {
      case "call":
        guard let raw = parts.first, let kind = CallKind(rawValue: raw) else { return nil }
        self = .call(kind)
      case "intercept":
        self = .intercept
      case "r":
        guard let code = parts.first else { return nil }
        self = .referral(code)
      case "tab":
        guard let name = parts.first else { return nil }
        self = .tab(name)
      default:
        return nil
      }
      return
    }
    if host.contains("stick.app"), parts.first == "r", parts.count >= 2 {
      self = .referral(parts[1])
      return
    }
    return nil
  }
}
