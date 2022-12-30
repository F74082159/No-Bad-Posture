

import Foundation
import Combine

extension Publisher {

    func bind<Output, Failure: Error>(to subscriber: AnySubscriber<Output, Failure>) -> AnyCancellable where Output == Self.Output, Failure == Self.Failure  {
        return sink(receiveCompletion: { completion in
            subscriber.receive(completion: completion)
        }, receiveValue: { value in
            _ = subscriber.receive(value)
        })
    }
}

extension Subject {
    func eraseToAnySubscriber() -> AnySubscriber<Output, Failure> {
       
        return AnySubscriber<Output, Failure>(
            receiveSubscription: { [weak self] subscription in
                guard let self = self else { return }
                self.send(subscription: subscription)
            },
            receiveValue: { [weak self] value -> Subscribers.Demand in
                guard let self = self else { return .none }
                self.send(value)
                return .unlimited
            },
            receiveCompletion: { [weak self] completion in
                self?.send(completion: completion)
            }
        )
    }
}
