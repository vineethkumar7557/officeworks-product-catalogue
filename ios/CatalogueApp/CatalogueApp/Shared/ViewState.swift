import Foundation

// The four things a screen can be showing while it loads data.
enum ViewState<Content> {
    case loading
    case loaded(Content)
    case empty
    case failed(String)
}

extension ViewState: Equatable where Content: Equatable {}
