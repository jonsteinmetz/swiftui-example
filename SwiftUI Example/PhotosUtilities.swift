//
//  PhotosUtilities.swift
//  SwiftUI Example
//
//  Created by Jon Steinmetz on 3/8/20.
//  Copyright © 2020 CocoaHeads MN. All rights reserved.
//

import Combine
import Photos

extension PHPhotoLibrary {
	func fetchAssets(withType type: PHAssetMediaType, options: PHFetchOptions? = nil)
			-> AnyPublisher<PHFetchResult<PHAsset>, Never> {
		let fetchResult = PHAsset.fetchAssets(with: type, options: options)
		return self.changes()
			.compactMap {
				if $0.changeDetails(for: fetchResult) != nil {
					return fetchResult
				}
				return nil
			}
			.prepend(fetchResult)
			.eraseToAnyPublisher()
	}
	
	func changes() -> AnyPublisher<PHChange, Never> {
		let observer = PhotoLibraryChangeObserver(library: self)
		return observer.changes
			.handleEvents(receiveCompletion: { _ in
				// This ties the lifetime of the observer to the subscription.
				_ = observer
			})
			.eraseToAnyPublisher()
	}
}

private class PhotoLibraryChangeObserver: NSObject, PHPhotoLibraryChangeObserver {
	let changes = PassthroughSubject<PHChange, Never>()
	private let library: PHPhotoLibrary
	
	init(library: PHPhotoLibrary) {
		self.library = library
		
		super.init()
		
		library.register(self)
	}
	
	deinit {
    	library.unregisterChangeObserver(self)
	}
	
	func photoLibraryDidChange(_ changeInstance: PHChange) {
		changes.send(changeInstance)
	}
}
