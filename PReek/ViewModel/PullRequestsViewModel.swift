import Foundation

protocol PullRequestsViewModelProtocol: ObservableObject {
    var lastUpdated: Date? { get set }
    var isRefreshing: Bool { get set }
    var hasError: Bool { get set }
    var hideClosed: Bool { get set }
    var hideRead: Bool { get set }
    var pullRequests: [PullRequest] { get }
    
    func triggerFetchPullRequests()
    func startFetchTimer()
    func toggleRead(_ pullRequest: PullRequest)
    func markAllAsRead()
}

class PullRequestsViewModel: PullRequestsViewModelProtocol {
    @Published var lastUpdated: Date? = nil
    @Published var isRefreshing = false
    @Published var hasError = false
    
    @Published var hideClosed = false {
        didSet {
            ConfigService.hideClosed = hideClosed
        }
    }
    @Published var hideRead = false {
        didSet {
            ConfigService.hideRead = hideRead
        }
    }
    
    @CodableAppStorage("pullRequestReadMap") private var storedPullRequestReadMap: [String: Date] = [:]
    @Published private var pullRequestReadMap: [String: Date] = [:] {
        didSet {
            storedPullRequestReadMap = pullRequestReadMap
        }
    }
    
    @Published private var pullRequestMap: [String: PullRequest] = [:]
    var pullRequests: [PullRequest] {
        return pullRequestMap.map { entry in
            var pullRequest = entry.value
            pullRequest.markedAsRead = isRead(pullRequest)
            return pullRequest
        }.filter { pullRequest in
            let containsNonExcludedUser = pullRequest.events.contains { event in
                return !ConfigService.excludedUsers.contains(event.user.login)
            }
            
            let passesClosedFilter = !hideClosed || !pullRequest.isClosed
            let passesReadFilter = !hideRead || !pullRequest.markedAsRead
            
            return containsNonExcludedUser && passesClosedFilter && passesReadFilter
        }.sorted {
            $0.lastUpdated > $1.lastUpdated
        }
    }
    
    init() {
        pullRequestReadMap = storedPullRequestReadMap
    }
    
    private var timer: Timer?
    
    func triggerFetchPullRequests() {
        Task {
            await fetchPullRequests()
        }
    }
        
    func startFetchTimer() {
        if timer != nil {
            return
        }
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.triggerFetchPullRequests()
        }
    }
    
    func toggleRead(_ pullRequest: PullRequest) {
        if isRead(pullRequest) {
            pullRequestReadMap.removeValue(forKey: pullRequest.id)
        } else {
            pullRequestReadMap[pullRequest.id] = Date()
        }
        objectWillChange.send()
    }
    
    func markAllAsRead() {
        let now = Date()
        pullRequests.forEach { pullRequest in
            pullRequestReadMap[pullRequest.id] = now
        }
        objectWillChange.send()
    }
    
    private func isRead(_ pullRequest: PullRequest) -> Bool {
        guard let markedRead = pullRequestReadMap[pullRequest.id] else {
            return false
        }
        return markedRead > pullRequest.lastNonViewerUpdated
    }
    
    private func handleReceivedNotifications(notifications: [Notification]) async throws {
        print("Got \(notifications.count) notifications")
        
        let repoMap = notifications.reduce([String: [Int]]()) { repoMap, notification in
            var repoMapClone = repoMap
            
            let existingPRs = repoMap[notification.repo]
            repoMapClone[notification.repo] = (existingPRs ?? []) + [notification.prNumber]
            
            return repoMapClone
        }
        
        if !repoMap.isEmpty {
            let pullRequests = try await GitHubService.fetchPullRequests(repoMap: repoMap)
            print("Got \(pullRequests.count) pull requests")
            
            DispatchQueue.main.async {
                pullRequests.forEach { pullRequest in
                    self.pullRequestMap[pullRequest.id] = pullRequest
                }
            }
        } else {
            print("No new PRs to fetch")
        }
    }
    
    private func fetchPullRequests() async {
        do {
            print("Fetch notifications")
            
            DispatchQueue.main.async {
                self.isRefreshing = true
                self.hasError = false
            }
            
            let since = lastUpdated ?? Calendar.current.date(byAdding: .day, value: ConfigService.onStartFetchWeeks * 7 * -1, to: Date())!
            try await GitHubService.fetchUserNotifications(since: since, onNotificationsReceived: handleReceivedNotifications)
            
            cleanupPullRequests()
            
            DispatchQueue.main.async {
                self.lastUpdated = Date()
                self.isRefreshing = false
            }
            print("Finished fetching notifications")
        } catch {
            print("Failed to get pull requests: \(error)")
            DispatchQueue.main.async {
                self.hasError = true
            }
        }
    }
    
    private func cleanupPullRequests() {
        let deleteFrom = Calendar.current.date(byAdding: .day, value: ConfigService.deleteAfterWeeks * 7 * -1, to: Date())!

        let filteredPullRequestMap = pullRequestMap.filter { _, pullRequest in
            pullRequest.lastUpdated > deleteFrom || (ConfigService.deleteOnlyClosed && !pullRequest.isClosed)
        }
        
        if filteredPullRequestMap.count != pullRequestMap.count {
            print("Removed \(pullRequestMap.count - filteredPullRequestMap.count) pull requests")
            DispatchQueue.main.async {
                self.pullRequestMap = filteredPullRequestMap
            }
        }
    }
}
