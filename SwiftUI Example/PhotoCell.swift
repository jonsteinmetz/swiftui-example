//
//  PhotoCell.swift
//  SwiftUI Example
//
//  Created by Jon Steinmetz on 3/8/20.
//  Copyright © 2020 CocoaHeads MN. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
	let imageView: UIImageView
	
	override init(frame: CGRect) {
    	self.imageView = UIImageView()
    	
    	super.init(frame: frame)
    	
    	self.addSubview(imageView)
    	imageView.translatesAutoresizingMaskIntoConstraints = false
    	imageView.contentMode = .scaleAspectFill
    	imageView.clipsToBounds = true
    	imageView.backgroundColor = .systemGray
    	NSLayoutConstraint.activate([
    		imageView.leftAnchor.constraint(equalTo: self.leftAnchor),
    		imageView.topAnchor.constraint(equalTo: self.topAnchor),
    		imageView.rightAnchor.constraint(equalTo: self.rightAnchor),
    		imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
    	])
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
