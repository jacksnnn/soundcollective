//
//  MainTabView.swift
//  SoundCollective
//
//  Created by Jackson Myers on 11/16/24.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Text("Search for Sounds")
                .tabItem{
                    VStack {
                        Image(systemName: selectedTab == 0 ? "map.fill" : "map")
                            .environment(\.symbolVariants, selectedTab == 0 ? .fill: .none)
                        Text("Search")
                    }
                }
                .onAppear {selectedTab = 0}
                .tag(0)
                
            Text("Implement Record Page")
                .tabItem{
                    VStack {
                        Image(systemName: "waveform")
                            .environment(\.symbolVariants, selectedTab == 1 ? .fill: .none)
                        Text("Record")
                    }
                }
                .onAppear {selectedTab = 1}
                .tag(1)
            
            Text("Implement Profile Page")
                .tabItem{
                    VStack {
                        Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                            .environment(\.symbolVariants, selectedTab == 2 ? .fill: .none)
                        Text("Profile")
                    }
                }
                .onAppear {selectedTab = 2}
                .tag(2)
        }
        .tint(.black)
        
    }
}

#Preview {
    MainTabView()
}
