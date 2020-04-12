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
        		Section(header: Text("Photos in UICollectionView")) {
        			NavigationLink(
        				"Photos in UICollectionView",
        				destination: LazyView(
        					PhotosCollectionView(store: makePhotosCollectionViewStore())
						)
        					.navigationBarTitle("Photos")
        					.edgesIgnoringSafeArea(.all)
					)
        			NavigationLink(
        				"Photos in SwiftUI",
        				destination: LazyView(
        					PhotosSwiftUIView(store: makePhotosCollectionViewStore())
						)
        					.navigationBarTitle("Photos in SwiftUI")
					)
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
