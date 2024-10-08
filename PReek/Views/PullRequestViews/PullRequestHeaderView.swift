import SwiftUI

private let statusToIcon: [PullRequest.Status: ImageResource] = [
    PullRequest.Status.draft: .prDraft,
    PullRequest.Status.open: .prOpen,
    PullRequest.Status.merged: .prMerged,
    PullRequest.Status.closed: .prClosed,
]

private func usersToString(_ users: [User]) -> String {
    return users.map {
        $0.displayName
    }.joined(separator: "\n")
}

struct PullRequestHeaderView: View {
    var pullRequest: PullRequest
    var toggleRead: () -> Void

    @Environment(\.colorScheme) var colorScheme

    init(_ pullRequest: PullRequest, toggleRead: @escaping () -> Void) {
        self.pullRequest = pullRequest
        self.toggleRead = toggleRead
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(statusToIcon[pullRequest.status] ?? .prOpen)
                .foregroundStyle(.primary)
                .imageScale(.large)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        HoverableLink(pullRequest.repository.name, destination: pullRequest.repository.url)
                            .foregroundStyle(.primary)
                        HoverableLink(pullRequest.numberFormatted, destination: pullRequest.url)
                            .foregroundColor(.secondary)
                    }
                    
                    HoverableLink(destination: pullRequest.url) {
                        Text(pullRequest.title)
                            .font(.headline)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(.primary)
                    
                    details
                }
                Spacer()
            }

            Button(action: toggleRead) {
                Image(systemName: pullRequest.unread ? "circle.fill" : "circle")
                    .imageScale(.medium)
                    .foregroundStyle(pullRequest.unread ? .accent : .gray)
            }
            .buttonStyle(.borderless)
        }
    }

    var details: some View {
        HStack(spacing: 5) {
            Group {
                if let authorUrl = pullRequest.author.url {
                    HoverableLink("by \(pullRequest.author.displayName)", destination: authorUrl)
                } else {
                    Text("by \(pullRequest.author.displayName)")
                }
            }
            .if(pullRequest.author.login != pullRequest.author.displayName) { view in
                view.help(pullRequest.author.login)
            }

            Text("·")

            Text("\(pullRequest.lastUpdatedFormatted)")

            Text("·")

            HoverableLink(destination: pullRequest.filesUrl) {
                HStack(spacing: 2) {
                    Text(pullRequest.additionsFormatted)
                        .foregroundStyle(.success)
                    Text(pullRequest.deletionsFormatted)
                        .foregroundStyle(.failure)
                }
            }

            if !pullRequest.approvalFrom.isEmpty || !pullRequest.changesRequestedFrom.isEmpty {
                Text("·")

                HStack(spacing: 5) {
                    if !pullRequest.approvalFrom.isEmpty {
                        HStack(spacing: 1) {
                            Text("\(pullRequest.approvalFrom.count)")
                            ResourceIcon(image: .check)
                                .frame(width: 13)
                                .foregroundColor(.success)
                        }
                        .help(usersToString(pullRequest.approvalFrom))
                    }
                    if !pullRequest.changesRequestedFrom.isEmpty {
                        HStack(spacing: 2) {
                            Text("\(pullRequest.changesRequestedFrom.count)")
                            ResourceIcon(image: .fileDiff)
                                .frame(width: 12)
                                .foregroundColor(.failure)
                                .padding(.top, 1)
                        }
                        .help(usersToString(pullRequest.changesRequestedFrom))
                    }
                }
            }
        }
        .foregroundStyle(.secondary)
        .textScale(.secondary)
        .padding(.top, -3)
    }
}

#Preview {
    PullRequestHeaderView(PullRequest.preview(title: "long long long long long long long long long long long long long long long long long"), toggleRead: {})
        .padding()
}
