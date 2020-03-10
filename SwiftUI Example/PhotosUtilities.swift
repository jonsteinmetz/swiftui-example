//
//  PhotosUtilities.swift
//  SwiftUI Example
//
//  Created by Jon Steinmetz on 3/8/20.
//  Copyright © 2020 CocoaHeads MN. All rights reserved.
//

import Combine
import Photos
import UIKit

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

extension PHImageManager {
	func requestImage( forAsset asset: PHAsset, targetSize: CGSize,
			contentMode: PHImageContentMode, options: PHImageRequestOptions?)
			-> AnyPublisher<UIImage, NSError> {
		let subject = CurrentValueSubject<UIImage?, NSError>(nil)
		let requestID = self.requestImage(for: asset, targetSize: targetSize,
				contentMode: contentMode, options: options) { (image, info) in
			if let image = image {
				subject.send(image)
			}
			if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool,
					isDegraded == false {
				subject.send(completion: .finished)
				return
			}
			if let error = info?[PHImageErrorKey] as? NSError {
				subject.send(completion: .failure(error))
				return
			}
			if let cancelled = info?[PHImageCancelledKey] as? NSNumber,
					cancelled.boolValue {
				subject.send(completion: .finished)
				return
			}
		}
		return subject
			.compactMap { $0 }
			.handleEvents(receiveCompletion: { [weak self] completion in
				self?.cancelImageRequest(requestID)
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
