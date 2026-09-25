import Foundation

/// stick://call/wake · stick://call/debrief · stick://intercept · stick://tab/today
enum DeepLink: Equatable {
  case call(CallKind)
  case intercept
  case tab(String)

  init?(url: URL) {
    guard url.scheme == "stick" else { return nil }
    let host = url.host()?.lowercased() ?? ""
    let parts = url.pathComponents.filter { $0 != "/" }
    switch host {
    case "call":
      guard let raw = parts.first, let kind = CallKind(rawValue: raw) else { return nil }
      self = .call(kind)
    case "intercept":
      self = .intercept
    case "tab":
      guard let name = parts.first else { return nil }
      self = .tab(name)
    default:
      return nil
    }
  }
}
