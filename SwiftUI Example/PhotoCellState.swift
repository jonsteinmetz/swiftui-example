//
//  PhotoCellState.swift
//  SwiftUI Example
//
//  Created by Jon Steinmetz on 3/9/20.
//  Copyright © 2020 CocoaHeads MN. All rights reserved.
//

import Combine
import UIKit
import Photos

struct PhotoCellState {
	var photo: PHAsset
	var image: UIImage?
	
	enum Action {
		case sizeChanged(CGSize)
		case imageRequestResponse(UIImage)
	}
	enum Effect {
		case requestImage(PHAsset, CGSize)
	}
}

typealias PhotoCellStore = Store<
	PhotoCellState,
	PhotoCellState.Action,
	PhotoCellState.Effect
>

func photoCellReducer(state: inout PhotoCellState,
		action: PhotoCellState.Action) -> [PhotoCellState.Effect] {
	var effects = [PhotoCellState.Effect]()
	switch action {
		case .sizeChanged(let newSize):
			effects.append(.requestImage(state.photo, newSize))
		case .imageRequestResponse(let image):
			state.image = image
	}
	return effects
}

func makePhotoCellStore(photoLibrary: PHPhotoLibrary,
		imageManager: PHImageManager, photo: PHAsset)
		-> PhotoCellStore {
	let initialState = PhotoCellState(photo: photo, image: nil)

	let requestSubject = PassthroughSubject<(PHAsset, CGSize), Never>()

	let store = PhotoCellStore(
		initialValue: initialState,
		reducer: photoCellReducer,
		effectHandler: { effect in
			switch effect {
				case .requestImage(let photo, let size):
					requestSubject.send((photo, size))
					return Empty().eraseToAnyPublisher()
			}
		}
	)

	requestSubject
		.map { (photo, size) -> AnyPublisher<UIImage, Never> in
			return imageManager.requestImage(
				forAsset: photo,
				targetSize: size,
				contentMode: .aspectFill,
				options: nil
			)
				.catch { _ in Empty() }
				.eraseToAnyPublisher()
		}
		.switchToLatest()
		.sink(receiveValue: { [weak store] image in
			store?.send(.imageRequestResponse(image))
		})
		.store(in: &store.cancelSet)

	return store
}
