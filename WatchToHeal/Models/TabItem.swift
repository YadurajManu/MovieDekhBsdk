//
//  TabItem.swift
//  WatchToHeal
//
//  Created by Yaduraj Singh on 14/12/25.
//

import SwiftUI

enum TabItem: String, CaseIterable {
    case home = "Home"
    case calendar = "Calendar"
    case search = "Search"
    case community = "Community"
    case watchlist = "Watchlist"
    case profile = "Profile"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .calendar: return "calendar.badge.plus"
        case .search: return "magnifyingglass"
        case .community: return "person.2.fill"
        case .watchlist: return "bookmark.fill"
        case .profile: return "person.fill"
        }
    }
}
