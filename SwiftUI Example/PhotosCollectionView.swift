//
//  PhotosCollectionView.swift
//  SwiftUI Example
//
//  Created by Jon Steinmetz on 3/8/20.
//  Copyright © 2020 CocoaHeads MN. All rights reserved.
//

import Photos
import SwiftUI
import UIKit

struct PhotosCollectionView: UIViewRepresentable {
	@ObservedObject var store: PhotosCollectionViewStore
	
	init(store: PhotosCollectionViewStore) {
    	self.store = store
	}
	
	func makeUIView(context: UIViewRepresentableContext<PhotosCollectionView>)
			-> UICollectionView {
		let coordinator = context.coordinator
		let layout = UICollectionViewFlowLayout()
		let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
		collectionView.allowsSelection = false
		collectionView.alwaysBounceVertical = true
		collectionView.backgroundColor = .systemBackground
		collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: photoCellReuseIdentifier)
		
		let dataSource = UICollectionViewDiffableDataSource<Section, PHAsset>(
			collectionView: collectionView,
			cellProvider: cellProvider
		)
		coordinator.dataSource = dataSource
		return collectionView
	}
	
	func updateUIView(_ uiView: UICollectionView, context: UIViewRepresentableContext<PhotosCollectionView>) {
		guard let dataSource = context.coordinator.dataSource else { return }
		var snapshot = NSDiffableDataSourceSnapshot<Section, PHAsset>()
		snapshot.appendSections([.main])
		snapshot.appendItems(store.value.photos)
		dataSource.apply(snapshot)
	}
	
	func makeCoordinator() -> Coordinator {
		return Coordinator()
	}
	
	fileprivate enum Section {
		case main
	}

	class Coordinator: NSObject {
		fileprivate var dataSource: UICollectionViewDiffableDataSource<Section, PHAsset>?
	}
}

private let photoCellReuseIdentifier = "PhotoCell"
private func cellProvider(collectionView: UICollectionView, indexPath: IndexPath,
		item: PHAsset) -> UICollectionViewCell? {
	let cell = collectionView.dequeueReusableCell(
		withReuseIdentifier: photoCellReuseIdentifier,
		for: indexPath
	)
	cell.cancelSet = []
	
	return cell
}
