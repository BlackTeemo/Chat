//
//  ContentView.swift
//  Chat
//
//  Created by mac on 2026/5/30.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store : Store
    
    var body: some View {
        if store.islogin{
            MainView()
        }else{
            LoginView()
        }
        

    }
}

//#Preview {
//    ContentView()
//}
