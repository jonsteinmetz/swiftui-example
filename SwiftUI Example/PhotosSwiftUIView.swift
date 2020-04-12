//
//  PhotosSwiftUIView.swift
//  SwiftUI Example
//
//  Created by Jon Steinmetz on 4/11/20.
//  Copyright © 2020 CocoaHeads MN. All rights reserved.
//

import Photos
import SwiftUI

struct PhotosSwiftUIView: View {
	@ObservedObject var store: PhotosCollectionViewStore
	
	init(store: PhotosCollectionViewStore) {
    	self.store = store
	}
	
    var body: some View {
        let photoLibrary = PHPhotoLibrary.shared()
        let imageManager = PHImageManager.default()
        let columns = 2
        var data: [[PHAsset]] = []
        _ = store.value.photos.publisher
        	.collect(columns)
        	.collect()
        	.sink(receiveValue: { data = $0 })
		return List {
			ForEach(0..<data.count, id: \.self) { rowIndex in
				return HStack(spacing: 0) {
					ForEach(data[rowIndex], id: \.self) { asset in
						PhotoView(store: makePhotoCellStore(
							photoLibrary: photoLibrary,
							imageManager: imageManager,
							photo: asset
						))
					}
				}
					.listRowInsets(EdgeInsets())
					
			}
		}
    }
}

struct PhotoView: View {
	@ObservedObject var store: PhotoCellStore
	
	init(store: PhotoCellStore) {
		self.store = store
		// I don't know how to detect size changes so just request a specific
		// size.
		store.send(.sizeChanged(CGSize(width: 200, height: 200)))
	}
	
	var body: some View {
		Image(uiImage: store.value.image ?? UIImage(systemName: "questionmark.square")!)
			.resizable()
			.aspectRatio(1, contentMode: .fill)
			.clipped()
	}
}

struct PhotosSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
