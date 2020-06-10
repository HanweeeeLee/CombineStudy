//
//  ViewController.swift
//  Combine3_Scheduler
//
//  Created by hanwe lee on 2020/06/10.
//  Copyright © 2020 hanwe lee. All rights reserved.
//

import UIKit
import Combine

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        threadTest()
        testFunc()
    }
    
    func threadTest() {
//        let subject = PassthroughSubject<Int, Never>()
//        //1
//        let token = subject.sink(receiveValue: { value in
//            print(Thread.isMainThread)
//        })
//        //2
//        subject.send(1)
//        DispatchQueue.global().async {
//            subject.send(2)
//        } //Scheduler는 element가 생성된 스레드와 동일한 스레드를 사용합니다.
    }
    
    func testFunc() {
        let publisher = ["Hanwe"].publisher
        
        publisher
            .map {_ in print(Thread.isMainThread)} //true
            .receive(on: DispatchQueue.global())
            .map { print(Thread.isMainThread) } //false
            .sink { print(Thread.isMainThread) } //false
    }


}

