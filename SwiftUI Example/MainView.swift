//
//  MainView.swift
//  SwiftUI Example
//
//  Created by Jon Steinmetz on 3/7/20.
//  Copyright © 2020 CocoaHeads MN. All rights reserved.
//

import SwiftUI

struct MainView: View {
	@State var showNotes: Bool = false
	@State var showDialog: Bool = false
	@State var showActionSheet: Bool = false
	
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
				Section(header: Text("Dynamic Contents")) {
					Toggle(isOn: $showNotes) {
						Text("Show Notes")
					}
					if showNotes {
						Text("This is an example of some kind of really long text that you might want to show in specific situations.")
							.font(.footnote)
							.foregroundColor(.gray)
					}
				}
				Section(header: Text("Dialog")) {
					Button(action: { self.showDialog = true }, label: { Text("Show Alert") })
					Button(action: { self.showActionSheet = true }, label: { Text("Show Action Sheet") })
				}
			}
				.navigationBarTitle("SwiftUI")
				.alert(isPresented: $showDialog) {
					Alert(title: Text("Boo!"))
				}
				.actionSheet(isPresented: $showActionSheet) {
					ActionSheet(
						title: Text("Action Sheet"),
						message: Text("This is an example action sheet"),
						buttons: [
							.default(Text("Hi there")),
							.destructive(Text("Boom")),
							.cancel()
						]
					)
				}
		}
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
