//
//  ReducerArchitecture.swift
//  PRLUtilities
//
//  Created by Jon Steinmetz on 10/15/19.
//
//	Almost entirely derived from https://www.pointfree.co/episodes/ep81-the-combine-framework-and-effects-part-2

import Combine
import Foundation

public typealias Reducer<Value, Action, Effect> = (inout Value, Action) -> [Effect]
public typealias EffectHandler<Effect, Action> = (Effect) -> AnyPublisher<Action, Never>

@available(iOS 13.0, *)
public final class Store<Value, Action, Effect>: NSObject, ObservableObject {
	private let reducer: Reducer<Value, Action, Effect>
	private let effectHandler: EffectHandler<Effect, Action>
	@Published public private(set) var value: Value

	public init(initialValue: Value,
			reducer: @escaping Reducer<Value, Action, Effect>,
			effectHandler: @escaping EffectHandler<Effect, Action>) {
		self.reducer = reducer
		self.effectHandler = effectHandler
		self.value = initialValue
	}

	public func send(_ action: Action) {
		let effects = self.reducer(&self.value, action)
		var cancelSet = self.cancelSet
		effects.forEach { effect in
			var effectCancellable: AnyCancellable?
			var didComplete = false
			effectCancellable = effectHandler(effect)
				.sink(
					receiveCompletion: { _ in
						didComplete = true
						guard let effectCancellable = effectCancellable else { return }
						cancelSet.remove(effectCancellable)
					},
					receiveValue: self.send
				)
			if !didComplete, let effectCancellable = effectCancellable {
				cancelSet.insert(effectCancellable)
			}
		}
	}

	public func view<LocalValue, LocalAction, LocalEffect>(
		value toLocalValue: @escaping (Value) -> LocalValue,
		action toGlobalAction: @escaping (LocalAction) -> Action
	) -> Store<LocalValue, LocalAction, LocalEffect> {
		let localStore = Store<LocalValue, LocalAction, LocalEffect>(
			initialValue: toLocalValue(self.value),
			reducer: { localValue, localAction in
				self.send(toGlobalAction(localAction))
				localValue = toLocalValue(self.value)
				return []
			},
			effectHandler: { _ in
				return Empty<LocalAction, Never>()
					.eraseToAnyPublisher()
			}
		)
		self.$value
			.sink { [weak localStore] newValue in
				localStore?.value = toLocalValue(newValue)
			}
			.store(in: &localStore.cancelSet)
		return localStore
	}
}
