//
//  ViewController.swift
//  SkipChat
//
//  Created by Katie Siegel on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var networkingLayer : PtoPProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.networkingLayer = PtoPProtocol(prKey: "asdf".dataUsingEncoding(NSUTF8StringEncoding)!, pubKey: "asdf".dataUsingEncoding(NSUTF8StringEncoding)!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

