import SwiftUI

struct PullRequestsView: View {
    var pullRequests: [PullRequest]
    var toggleRead: (PullRequest) -> Void

    init(_ pullRequests: [PullRequest], toggleRead: @escaping (PullRequest) -> Void) {
        self.pullRequests = pullRequests
        self.toggleRead = toggleRead
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    DividedView {
                        ForEach(pullRequests) { pullRequest in
                            PullRequestView(pullRequest, toggleRead: { toggleRead(pullRequest) })
                        }
                    }
                    .frame(width: geometry.size.width - 40) // full width - horizontal padding (explicit leading, implicit trailing)
                }
                .padding(.leading, 20)
                .padding(.top, 5)
            }
        }
    }
}

#Preview {
    PullRequestsView([
        PullRequest.preview(title: "short"),
        PullRequest.preview(title: "long long long long long long long long long long long long long long long long long long long"),
        PullRequest.preview(lastUpdated: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
        PullRequest.preview(lastUpdated: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
        PullRequest.preview(),
        PullRequest.preview(),
        PullRequest.preview(),
        PullRequest.preview(),
        PullRequest.preview(),
        PullRequest.preview(),
        PullRequest.preview(),
        PullRequest.preview(),
        PullRequest.preview(),
        PullRequest.preview(),
        PullRequest.preview(),
        PullRequest.preview(),
        PullRequest.preview(),
        PullRequest.preview(),
    ], toggleRead: { _ in })
}
