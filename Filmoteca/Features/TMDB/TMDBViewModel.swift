import Observation

@Observable
final class TMDBViewModel {
    var selectedTab: TMDBTab

    let tabs: [TMDBTab]

    init(selectedTab: TMDBTab = .home, tabs: [TMDBTab] = TMDBTab.allCases) {
        self.selectedTab = selectedTab
        self.tabs = tabs
    }
}
