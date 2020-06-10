//
//  ViewController.swift
//  CombineTest1
//
//  Created by hanwe lee on 2020/06/09.
//  Copyright © 2020 hanwe lee. All rights reserved.
//

//https://zeddios.tistory.com/925?category=842493 실습

import UIKit
import Combine

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        way1()
        way2()

    }
    
    func way1() { //sink이용
        let publisher = Just("hanwe")
        //        let subscriber = publisher.sink { (value) in
        //            print("value")
        //        }
        let subscriber = publisher.sink(receiveCompletion: { (result) in
            switch result {
            case .finished:
                print("finished")
            case .failure(let error):
                print("error:\(error.localizedDescription)")
            }
        }) { (value) in
            print("value:\(value)")
        }
    }
    
    func way2() { // subscribe메소드 이용
//       let publisher = Just("hanwe")
        let publisher = ["Pantera","Metallica","RadioHead"].publisher
        
        publisher.print().subscribe(HanweSubscriber())
    }
    
    func way3() {
        
    }
    
}

class HanweSubscriber:Subscriber {
    
    typealias Input = String
    typealias Failure = Never
    
    func receive(subscription: Subscription) {
        print("응~ 구독 시작이야 ~")
        subscription.request(.max(2))//item을 요청 2개까지
    }
    
    func receive(_ input: String) -> Subscribers.Demand {
//        print("\(input)")
        return .none
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("응~ 완료야~",completion)
    }
    
    
}

