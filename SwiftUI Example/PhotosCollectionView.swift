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

struct PhotosCollectionView: UIViewControllerRepresentable {
	@ObservedObject var store: PhotosCollectionViewStore
	
	init(store: PhotosCollectionViewStore) {
    	self.store = store
	}
	
	func makeUIViewController(context: UIViewControllerRepresentableContext<PhotosCollectionView>)
			-> UICollectionViewController {
		let coordinator = context.coordinator
		let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
		let result = SpecialViewController(collectionViewLayout: layout)
		let store = self.store
		result.viewDidAppearCallback = { store.send(.viewDidAppear) }
		guard let collectionView = result.collectionView else { return result }
		collectionView.allowsSelection = false
		collectionView.alwaysBounceVertical = true
		collectionView.backgroundColor = .systemBackground
		collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: photoCellReuseIdentifier)
		
		let dataSource = UICollectionViewDiffableDataSource<Section, PHAsset>(
			collectionView: collectionView,
			cellProvider: cellProvider
		)
		coordinator.dataSource = dataSource
		return result
	}
	
    func updateUIViewController(_ uiViewController: UICollectionViewController, context: Self.Context) {
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
	guard let cell = collectionView.dequeueReusableCell(
		withReuseIdentifier: photoCellReuseIdentifier,
		for: indexPath
	) as? PhotoCell else { return nil }
	
	cell.cancelSet = []
	let store = makePhotoCellStore(
		photoLibrary: PHPhotoLibrary.shared(),
		imageManager: PHImageManager.default(),
		photo: item
	)
	store.$value
		.sink { [weak cell] state in
			cell?.imageView.image = state.image
		}
		.store(in: &cell.cancelSet)
	cell.publisher(for: \.bounds)
		.sink { [weak cell] bounds in
			// Note that the strong ref to store ties the lifetime to cancelSet
			let scale = cell?.contentScaleFactor ?? 1.0
			let size = CGSize(width: bounds.size.width * scale, height: bounds.size.height * scale)
			store.send(.sizeChanged(size))
		}
		.store(in: &cell.cancelSet)
	
	return cell
}

private func sectionProvider(section: Int, environment: NSCollectionLayoutEnvironment)
		-> NSCollectionLayoutSection? {
	let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
	let item = NSCollectionLayoutItem(layoutSize: itemSize)
	let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(0.5))
	let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
	return NSCollectionLayoutSection(group: group)
}

private class SpecialViewController: UICollectionViewController {
	var viewDidAppearCallback: (() -> Void)?
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		viewDidAppearCallback?()
	}
}
