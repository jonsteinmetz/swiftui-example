//
//  PhotosCollectionViewState.swift
//  SwiftUI Example
//
//  Created by Jon Steinmetz on 3/8/20.
//  Copyright © 2020 CocoaHeads MN. All rights reserved.
//

import Combine
import UIKit
import Photos

struct PhotosCollectionViewState {
	var photos: [PHAsset]
	var authStatus: PHAuthorizationStatus
	
	enum Action {
		case photosUpdated([PHAsset])
		case photosAccessUpdated(PHAuthorizationStatus)
		case viewDidAppear
	}
	enum Effect {
		case requestPhotosAuthorization
	}
}

typealias PhotosCollectionViewStore = Store<
	PhotosCollectionViewState,
	PhotosCollectionViewState.Action,
	PhotosCollectionViewState.Effect
>

func photosCollectionViewReducer(state: inout PhotosCollectionViewState,
		action: PhotosCollectionViewState.Action)
		-> [PhotosCollectionViewState.Effect] {
	var effects = [PhotosCollectionViewState.Effect]()
	switch action {
		case .photosUpdated(let photos):
			state.photos = photos
		case .photosAccessUpdated(let status):
			state.authStatus = status
		case .viewDidAppear:
			if state.authStatus == .notDetermined {
				effects.append(.requestPhotosAuthorization)
			}
	}
	return effects
}

func makePhotosCollectionViewEffectHandler()
		-> (PhotosCollectionViewState.Effect) -> AnyPublisher<PhotosCollectionViewState.Action, Never> {
	let photosLibrary = PHPhotoLibrary.shared()
	return { effect in
		switch effect {
    		case .requestPhotosAuthorization:
    			return photosLibrary.requestAuthorization()
    				.map { .photosAccessUpdated($0) }
    				.eraseToAnyPublisher()
		}
	}
}

func makePhotosCollectionViewStore() -> PhotosCollectionViewStore {
	let initialState = PhotosCollectionViewState(
		photos: [],
		authStatus: PHPhotoLibrary.authorizationStatus()
	)
	let store = PhotosCollectionViewStore(
		initialValue: initialState,
		reducer: photosCollectionViewReducer,
		effectHandler: makePhotosCollectionViewEffectHandler()
	)
	let library = PHPhotoLibrary.shared()
	library.fetchAssets(withType: .image)
		.map { $0.objects(at: IndexSet(integersIn: 0..<$0.count)) }
		.receive(on: RunLoop.main)
		.sink { [weak store] assets in store?.send(.photosUpdated(assets)) }
		.store(in: &store.cancelSet)
	library.authorizationStatusPublisher()
		.receive(on: RunLoop.main)
		.sink { [weak store] status in store?.send(.photosAccessUpdated(status)) }
		.store(in: &store.cancelSet)
	return store
}
