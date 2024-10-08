import SwiftUI

struct PullRequestView: View {
    var pullRequest: PullRequest
    var toggleRead: () -> Void

    @State var sectionExpanded: Bool
    let scrollId: String?

    init(_ pullRequest: PullRequest, toggleRead: @escaping () -> Void, sectionExpanded: Bool = false, scrollId: String? = nil) {
        self.pullRequest = pullRequest
        self.toggleRead = toggleRead
        self.sectionExpanded = sectionExpanded
        self.scrollId = scrollId
    }

    var body: some View {
        VStack {
            DisclosureGroup(isExpanded: $sectionExpanded) {
                PullRequestContentView(pullRequest)
            } label: {
                PullRequestHeaderView(pullRequest, toggleRead: toggleRead)
                    .padding(.leading, 10)
            }
        }
        .padding(.leading, 2)
        .contentShape(Rectangle())
        .focusable()
        .onKeyPress(.space) {
            sectionExpanded = !sectionExpanded
            return .handled
        }
        .onDisappear {
            sectionExpanded = false
        }
        .if(scrollId != nil) { view in
            view.id(scrollId)
        }
    }
}

#Preview {
    ScrollView {
        PullRequestView(
            PullRequest.preview(title: "long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long lon"),
            toggleRead: {},
            sectionExpanded: true
        )
    }
    .padding()
}
