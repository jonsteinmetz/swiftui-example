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
		self.authorizationStatusPublisher()
			.removeDuplicates()
			.map { status -> AnyPublisher<PHFetchResult<PHAsset>, Never> in
				switch status {
					case .authorized:
						let fetchResult = PHAsset.fetchAssets(with: type, options: options)
						return self.changesPublisher()
							.compactMap {
								if $0.changeDetails(for: fetchResult) != nil {
									return fetchResult
								}
								return nil
							}
							.prepend(fetchResult)
							.eraseToAnyPublisher()
					case .denied, .notDetermined, .restricted:
						break
					@unknown default:
						break
				}
				return Empty().eraseToAnyPublisher()
			}
			.switchToLatest()
			.eraseToAnyPublisher()
	}
	
	func requestAuthorization() -> AnyPublisher<PHAuthorizationStatus, Never> {
		let subject = PassthroughSubject<PHAuthorizationStatus, Never>()
		PHPhotoLibrary.requestAuthorization { status in
			DispatchQueue.main.async {
				subject.send(status)
			}
		}
		return subject.eraseToAnyPublisher()
	}
	
	func changesPublisher() -> AnyPublisher<PHChange, Never> {
		let observer = PhotoLibraryChangeObserver(library: self)
		return observer.changes
			.handleEvents(receiveCompletion: { _ in
				// This ties the lifetime of the observer to the subscription.
				_ = observer
			})
			.receive(on: RunLoop.main)
			.eraseToAnyPublisher()
	}
	
	func authorizationStatusPublisher() -> AnyPublisher<PHAuthorizationStatus, Never> {
		let observer = PhotoLibraryChangeObserver(library: self)
		return observer.changes
			.map { _ in PHPhotoLibrary.authorizationStatus() }
			.prepend(PHPhotoLibrary.authorizationStatus())
			.handleEvents(receiveCompletion: { _ in
				// This ties the lifetime of the observer to the subscription.
				_ = observer
			})
			.receive(on: RunLoop.main)
			.eraseToAnyPublisher()
	}
}

extension PHImageManager {
	func requestImage( forAsset asset: PHAsset, targetSize: CGSize,
			contentMode: PHImageContentMode, options: PHImageRequestOptions?)
			-> AnyPublisher<UIImage, NSError> {
		let subject = PassthroughSubject<UIImage, NSError>()
		var requestID: PHImageRequestID?
		return subject
			.handleEvents(
				receiveSubscription: { subscription in
					// Note that the requestImage() call needs to be made after
					// the receiveSubscription is handled because it may return
					// synchronously and that confuses Combine.
					DispatchQueue.main.async {
						guard requestID == nil else { return }
						requestID = self.requestImage(for: asset, targetSize: targetSize,
								contentMode: contentMode, options: options) { (image, info) in
							DispatchQueue.main.async {
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
						}
					}
				},
				receiveCompletion: { [weak self] completion in
					if let requestID = requestID {
						self?.cancelImageRequest(requestID)
					}
				}
			)
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
		DispatchQueue.main.async {
			self.changes.send(changeInstance)
		}
	}
}
