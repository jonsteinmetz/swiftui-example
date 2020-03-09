//
//  MainView.swift
//  SwiftUI Example
//
//  Created by Jon Steinmetz on 3/7/20.
//  Copyright © 2020 CocoaHeads MN. All rights reserved.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
        	Form {
        		Section(header: Text("Photos")) {
        			NavigationLink(
        				"Photos in UICollectionView",
        				destination: PhotosCollectionView(store: makePhotosCollectionViewStore())
        					.navigationBarTitle("Photos")
					)
        			NavigationLink("Photos in SwiftUI", destination: ContentView())
				}
			}.navigationBarTitle("SwiftUI")
		}
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
