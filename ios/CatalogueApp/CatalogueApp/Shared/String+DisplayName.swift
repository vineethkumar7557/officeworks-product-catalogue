import Foundation

extension String {
    // "men's clothing" becomes "Men's Clothing". Used for screen titles.
    var displayName: String {
        return split(separator: " ")
            .map { word in String(word.prefix(1)).uppercased() + String(word.dropFirst()) }
            .joined(separator: " ")
    }
}
