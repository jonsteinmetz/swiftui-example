//
//  LazyView.swift
//  SwiftUI Example
//
//  Created by Jon Steinmetz on 3/29/20.
//  Copyright © 2020 CocoaHeads MN. All rights reserved.
//

import SwiftUI

// source: https://www.objc.io/blog/2019/07/02/lazy-loading/

struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
