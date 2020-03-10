//
//  CombineUtilities.swift
//  tallycounter
//
//  Created by Jon Steinmetz on 11/11/19.
//

import Combine
import Foundation

private var cancelSetKey: UInt8 = 0

typealias CancelSet = Set<AnyCancellable>

extension NSObject {
	var cancelSet: CancelSet {
		get {
			objc_sync_enter(self); defer { objc_sync_exit(self) }
			return wrappedCancelSet.wrappedSet
		}
		set {
			objc_sync_enter(self); defer { objc_sync_exit(self) }
			wrappedCancelSet.wrappedSet = newValue
		}
	}
	
	private var wrappedCancelSet: CancelSetWrapper {
		if let result = objc_getAssociatedObject(self, &cancelSetKey) as? CancelSetWrapper {
			return result
		} else {
			let result = CancelSetWrapper()
			objc_setAssociatedObject(self, &cancelSetKey, result, .OBJC_ASSOCIATION_RETAIN)
			return result
		}
	}
}

private class CancelSetWrapper: NSObject {
	var wrappedSet: CancelSet
	
	override init() {
    	wrappedSet = CancelSet()
    	super.init()
	}
}

infix operator <<- : MultiplicationPrecedence

func <<- <L, R, T: Equatable, PR: Publisher>(
		lhs: (L, ReferenceWritableKeyPath<L, T>),
		rhs: (PR, KeyPath<R, T>))
		-> AnyCancellable where PR.Output == R, PR.Failure == Never {
	rhs.0.bind(from: rhs.1, to: lhs.1, on: lhs.0)
}

func <<- <L, R, T: Equatable, PR: Publisher>(
		lhs: (L, ReferenceWritableKeyPath<L, T>),
		rhs: (PR, KeyPath<R, T?>))
		-> AnyCancellable where PR.Output == R, PR.Failure == Never {
	rhs.0.bind(from: rhs.1, to: lhs.1, on: lhs.0)
}

func <<- <L, R, T: Equatable, PR: Publisher>(
		lhs: (L, ReferenceWritableKeyPath<L, Any?>),
		rhs: (PR, KeyPath<R, T>))
		-> AnyCancellable where PR.Output == R, PR.Failure == Never {
	rhs.0.bind(from: rhs.1, to: lhs.1, on: lhs.0)
}

extension Publisher where Failure == Never {
	func bind<D, T: Equatable>(from: KeyPath<Output, T>,
			to: ReferenceWritableKeyPath<D, T>, on: D)
			-> AnyCancellable {
		self
			.map { $0[keyPath: from] }
			.removeDuplicates()
			.assign(to: to, on: on)
	}

	func bind<D, T: Equatable>(from: KeyPath<Output, T?>,
			to: ReferenceWritableKeyPath<D, T>, on: D)
			-> AnyCancellable {
		self
			.compactMap { $0[keyPath: from] }
			.removeDuplicates()
			.assign(to: to, on: on)
	}

	func bind<D, T: Equatable>(from: KeyPath<Output, T>,
			to: ReferenceWritableKeyPath<D, Any?>, on: D)
			-> AnyCancellable {
		self
			.map { $0[keyPath: from] }
			.removeDuplicates()
			.sink { on[keyPath: to] = $0 }
	}
}

public protocol OptionalType {
	associatedtype Wrapped
	var value: Wrapped? { get }
}

extension Optional: OptionalType {
	/// Cast `Optional<Wrapped>` to `Wrapped?`
	public var value: Wrapped? {
		return self
	}
}

public extension Publisher where Self.Output: OptionalType {
	func filterNil() -> AnyPublisher<Self.Output.Wrapped, Self.Failure> {
		return self.flatMap { element -> AnyPublisher<Self.Output.Wrapped, Self.Failure> in
			guard let value = element.value else {
				return Empty(completeImmediately: false)
					.setFailureType(to: Self.Failure.self)
					.eraseToAnyPublisher()
			}
			return Just(value)
				.setFailureType(to: Self.Failure.self)
				.eraseToAnyPublisher()
		}
			.eraseToAnyPublisher()
	}
}
