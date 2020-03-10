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
	
	enum Action {
		case photosUpdated([PHAsset])
	}
	enum Effect {
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
	}
	return effects
}

func makePhotosCollectionViewEffectHandler()
		-> (PhotosCollectionViewState.Effect) -> AnyPublisher<PhotosCollectionViewState.Action, Never> {
	return { effect in
		Empty().eraseToAnyPublisher()
	}
}

func makePhotosCollectionViewStore() -> PhotosCollectionViewStore {
	let initialState = PhotosCollectionViewState(photos: [])
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
	return store
}
