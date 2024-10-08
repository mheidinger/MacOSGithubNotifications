import SwiftUI

struct PullRequestsView: View {
    var pullRequests: [PullRequest]
    var toggleRead: (PullRequest) -> Void

    @State var scrollToPullRequestId: String?
    @FocusState var focusedPullRequestId: String?

    init(_ pullRequests: [PullRequest], toggleRead: @escaping (PullRequest) -> Void) {
        self.pullRequests = pullRequests
        self.toggleRead = toggleRead

        if focusedPullRequestId == nil {
            print("set focused pull request to first")
            focusedPullRequestId = pullRequests.first?.id
        }
    }

    private func toScrollId(_ id: String) -> String {
        "scroll-\(id)"
    }

    private func selectByOffset(by offset: Int) {
        // Calculate next PR by current focus
        let currentIndex = focusedPullRequestId.flatMap { focusedId in
            pullRequests.firstIndex { $0.id == focusedId }
        }
        let newIndex = ((currentIndex ?? (offset < 0 ? pullRequests.count : -1)) + offset + pullRequests.count) % pullRequests.count

        // Scroll to next PR to make sure it is in view, after scroll focus will be set
        scrollToPullRequestId = pullRequests[safe: newIndex].map { $0.id }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        DividedView {
                            ForEach(pullRequests) { pullRequest in
                                PullRequestView(
                                    pullRequest,
                                    toggleRead: { toggleRead(pullRequest) },
                                    scrollId: toScrollId(pullRequest.id)
                                )
                                .focused($focusedPullRequestId, equals: pullRequest.id)
                            }
                        }
                        // full width - horizontal padding (explicit leading, implicit trailing)
                        .frame(width: geometry.size.width - 40)
                    }
                    .padding(.leading, 20)
                    .padding(.vertical, 5)
                    .onChange(of: scrollToPullRequestId) { _, newValue in
                        if let id = newValue {
                            withAnimation {
                                proxy.scrollTo(toScrollId(id))
                                focusedPullRequestId = id
                            }
                        }
                    }
                }
                .onKeyPress("j") {
                    selectByOffset(by: 1)
                    return .handled
                }
                .onKeyPress("k") {
                    selectByOffset(by: -1)
                    return .handled
                }
            }
        }
    }
}

#Preview {
    PullRequestsView([
        PullRequest.preview(id: "1", title: "short"),
        PullRequest.preview(id: "2", title: "long long long long long long long long long long long long long long long long long long long"),
        PullRequest.preview(id: "3", lastUpdated: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
        PullRequest.preview(id: "4", lastUpdated: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
        PullRequest.preview(id: "5"),
        PullRequest.preview(id: "6"),
        PullRequest.preview(id: "7"),
        PullRequest.preview(id: "8"),
        PullRequest.preview(id: "9"),
        PullRequest.preview(id: "10"),
        PullRequest.preview(id: "11"),
        PullRequest.preview(id: "12"),
        PullRequest.preview(id: "13"),
        PullRequest.preview(id: "14"),
        PullRequest.preview(id: "15"),
        PullRequest.preview(id: "16"),
        PullRequest.preview(id: "17"),
        PullRequest.preview(id: "18"),
    ], toggleRead: { _ in })
}
