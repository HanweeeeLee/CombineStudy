//
//  ViewController.swift
//  Combine2_Subject
//
//  Created by hanwe lee on 2020/06/10.
//  Copyright © 2020 hanwe lee. All rights reserved.
//

import UIKit
import Combine

enum HanweError:Error {
    case unknown
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        currentValueSubject()
        passthroughSubject()
    }
    
    func currentValueSubject() {
        let currentValueSubject = CurrentValueSubject<String,Never>("hanwe")
        let subscriber = currentValueSubject.sink { (receiveValue) in
            print(receiveValue)
        }
        currentValueSubject.value = "안녕"
        currentValueSubject.send("하이")
    }
    
    func passthroughSubject() {
        passthroughSubjectInput()
        passthroughSubjectCompletion()
    }
    
    func passthroughSubjectInput() {
        let passthroughSubject = PassthroughSubject<String,Never>()
        let subscriber = passthroughSubject.sink(receiveValue: {
            print($0)
        })
        passthroughSubject.send("안녕!")
        passthroughSubject.send("hanwe!")
    }
    
    func passthroughSubjectCompletion() {
        let passthroughSubject = PassthroughSubject<String,Error>()
        let subscriber = passthroughSubject.sink(receiveCompletion: { (result) in
            switch result {
            case .finished:
                print("finished")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }) { (value) in
            print("value:\(value)")
        }
        
        passthroughSubject.send("안뇽~")
        passthroughSubject.send("hanwe~")
        
        passthroughSubject.send(completion: .finished)
        
        passthroughSubject.send("끝나서 출력 안됨")
    }
    
}


