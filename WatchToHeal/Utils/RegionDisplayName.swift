import Foundation

func regionDisplayName(for code: String) -> String {
    let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return code }
    let name = Locale.current.localizedString(forRegionCode: trimmed) ?? trimmed
    return name.uppercased()
}
