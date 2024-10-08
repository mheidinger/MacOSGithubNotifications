import Foundation

struct PullRequest: Identifiable {
    enum Status {
        case open
        case closed
        case merged
        case draft
    }

    let id: String
    let repository: Repository
    let author: User
    let title: String
    let number: Int
    let status: Status
    let lastUpdated: Date
    let lastNonViewerUpdated: Date
    let events: [Event]
    let url: URL
    let additions: Int
    let deletions: Int
    var approvalFrom: [User]
    var changesRequestedFrom: [User]

    var lastMarkedAsRead: Date? = nil
    var unread: Bool {
        guard let lastMarkedAsRead = lastMarkedAsRead else {
            return true
        }
        return lastMarkedAsRead < lastNonViewerUpdated
    }

    var oldestUnreadEvent: Event? {
        lastMarkedAsRead.map { lastMarkedAsRead in
            events.reversed().first { event in
                event.time > lastMarkedAsRead
            }
        } ?? nil
    }

    var isClosed: Bool {
        return status == .closed || status == .merged
    }

    var numberFormatted: String {
        "#\(number.formatted(.number.grouping(.never)))"
    }

    var lastUpdatedFormatted: String {
        let formattedTime = lastUpdated.formatted(date: .omitted, time: .shortened)
        if Calendar.current.isDateInToday(lastUpdated) {
            return String(localized: "updated at \(formattedTime)")
        }
        if Calendar.current.isDateInYesterday(lastUpdated) {
            return String(localized: "updated yesterday at \(formattedTime)")
        }
        let formattedDate = lastUpdated.formatted(
            Date.FormatStyle()
                .month(.abbreviated)
                .day(.defaultDigits)
        )
        return String(localized: "updated \(formattedDate) at \(formattedTime)")
    }

    var additionsFormatted: String {
        "+\(additions.formatted(.number))"
    }

    var deletionsFormatted: String {
        "-\(deletions.formatted(.number))"
    }

    var filesUrl: URL {
        url.appendingPathComponent("files")
    }

    static func preview(id: String? = nil, title: String? = nil, status: Status? = nil, events: [Event]? = nil, lastUpdated: Date? = nil) -> PullRequest {
        PullRequest(
            id: id ?? UUID().uuidString,
            repository: Repository(name: "max-heidinger/PReek", url: URL(string: "https://example.com")!),
            author: User(login: "max-heidinger", displayName: "Max Heidinger", url: URL(string: "https://example.com")!),
            title: title ?? "[TICKET-23251] Fix some things but the title is pretty long",
            number: 5312,
            status: status ?? .open,
            lastUpdated: lastUpdated ?? Date(),
            lastNonViewerUpdated: Date(),
            events: events ?? [
                Event.previewClosed,
                Event.previewForcePushed,
                Event.previewMerged,
                Event.previewCommit(),
                Event.previewReview(),
                Event.previewComment,
                Event.previewReviewRequested,
            ],
            url: URL(string: "https://example.com")!,
            additions: 123_456,
            deletions: 654_321,
            approvalFrom: [User(login: "user-1"), User(login: "user-2")],
            changesRequestedFrom: [User(login: "user-3")],
            lastMarkedAsRead: Date().addingTimeInterval(-35)
        )
    }
}
