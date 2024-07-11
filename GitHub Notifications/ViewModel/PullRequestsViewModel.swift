//
//  PullRequestsViewModel.swift
//  GitHub Notifications
//
//  Created by Max Heidinger on 24.05.24.
//

import Foundation

class PullRequestsViewModel: ObservableObject {
    @Published var lastUpdated: Date? = nil
    @Published var isRefreshing = false
    @Published var hasError = false
    
    @Published private var pullRequestMap: [String: PullRequest] = [:]
    var pullRequests: [PullRequest] {
        return pullRequestMap.map { entry in
            return entry.value
        }.filter { pullRequest in
            return pullRequest.events.allSatisfy { event in
                return !ConfigService.excludedUsers.contains(event.user.login)
            }
        }
    }
    
    private var timer: Timer?
    
    func triggerFetchPullRequests() {
        Task {
            await fetchPullRequests()
        }
    }
    
    func fetchPullRequests() async {
        do {
            print("Fetch notifications")
            
            DispatchQueue.main.async {
                self.isRefreshing = true
                self.hasError = false
            }
            
            // Add callback to `fetchUserNotifications` that triggers for each page
            // Let it sleep between pages => rate limiting
            // In the callback get the actual PRs (+ maybe dedupe if needed)
            // After getting PRs update them directly => shown in UI
            // Wait for all to be done and finish up refreshing => notifications call returned and in there last callback is awaited(?)
            
            let notifications = try await GitHubService.fetchUserNotifications(since: lastUpdated)
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
                    self.lastUpdated = Date()
                    pullRequests.forEach { pullRequest in
                        self.pullRequestMap[pullRequest.id] = pullRequest
                    }
                    self.isRefreshing = false
                }
            } else {
                print("No new PRs to fetch")
                
                DispatchQueue.main.async {
                    self.lastUpdated = Date()
                    self.isRefreshing = false
                }
            }
            
            
        } catch {
            print("Failed to get pull requests: \(error)")
            DispatchQueue.main.async {
                self.hasError = true
            }
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
}
