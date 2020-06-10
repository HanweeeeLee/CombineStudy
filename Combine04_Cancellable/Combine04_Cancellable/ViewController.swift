//
//  ViewController.swift
//  Combine04_Cancellable
//
//  Created by hanwe lee on 2020/06/10.
//  Copyright © 2020 hanwe lee. All rights reserved.
//

import UIKit
import Combine

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        example3()
        example4()
        
    }
    
    func example1() {
        let subject = PassthroughSubject<Int,Never>()
        let subscriber = subject.sink(receiveValue: { value in
            print(value)
        })
        subscriber.cancel()
        subject.send(1)
    }
    
    func example2() {
        var bag = Set<AnyCancellable>()
        
        let subject = PassthroughSubject<Int, Never>()
        
        subject.sink(receiveValue: { value in
            print(value)
        })
        .store(in: &bag)
    }
    
    func example3() {
        let subject = PassthroughSubject<String,Never>()
        let subscriber = HanweSubscriber()
        subject.print("Combine Test").subscribe(subscriber)
        
        subscriber.subscription = HanweSubscription({
            print("cancel!")
        })
        subject.send("Hanwe")
        subject.send("hanwe2")
        
        subscriber.subscription?.cancel()
        
    }
    
    func example4() {
        let subject = PassthroughSubject<String, Error>()
        
        let subscriber = subject.handleEvents(receiveSubscription: { (subscription) in
            print("Receive Subscription") //2
        }, receiveOutput: { (output) in
            print("Receive Output : \(output)") //3
        }, receiveCompletion: { (completion) in
            print("Receive Completion")
            switch completion {
            case .finished:
                print("finished")
            case .failure(let err):
                print("error :\(err.localizedDescription)")
            }
        }, receiveCancel: {
            print("Receive Cancel")
        }, receiveRequest: { (demand) in
            print("Receive Request:\(demand)") //1
        }).sink(receiveCompletion: { (completion) in
            switch completion {
            case .finished:
                print("finished")
            case .failure(let error):
                print("error :\(error.localizedDescription)")
            }
        }, receiveValue: { (value) in
                print("Receive Value in sink: \(value)")
        })
        subject.send("hanwe")
        subscriber.cancel()
        
    }


}

class HanweSubscriber:Subscriber {
    
    typealias Input = String
    typealias Failure = Never
    
    var subscription: Subscription?
    
    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
        self.subscription = subscription
    }
    
    func receive(_ input: String) -> Subscribers.Demand {
        return .unlimited
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        
    }
    
}

final class HanweSubscription:Subscription {
    
    private let cancellable: Cancellable
    
    init( _ cancel: @escaping () -> Void ) {
        self.cancellable = AnyCancellable(cancel)
    }
    
    func request(_ demand: Subscribers.Demand) {
        
    }
    
    func cancel() {
        self.cancellable.cancel()
    }
    
    
    
    
}

