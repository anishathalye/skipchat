//
//  ViewController.swift
//  SkipChat
//
//  Created by Katie Siegel on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PtoPProtocolDelegate {
    let IOS_BAR_HEIGHT : Float = 20.0
    let ROWS_PER_SCREEN : Float = 8.0
    var networkingLayer : PtoPProtocol!
    var messageTable = UITableView(frame: CGRectZero, style: .Plain)
    var messages : [Message]!

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    lazy var managedObjectContext : NSManagedObjectContext? = {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        }
        else {
            return nil
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.networkingLayer = PtoPProtocol(prKey: "asdf".dataUsingEncoding(NSUTF8StringEncoding)!, pubKey: "asdf".dataUsingEncoding(NSUTF8StringEncoding)!)
        self.networkingLayer?.send("asdf".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, recipient: "asdf".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        println(managedObjectContext!)
        
//        self.messageTable = UITableView(frame: self.view.bounds, style: UITableViewStyle.Plain)
//        self.messageTable.dataSource = self;
//        self.messageTable.delegate = self;
//        self.view.addSubview(self.messageTable)
        
        // dummy data
        if let moc = self.managedObjectContext {
            Message.createInManagedObjectContext(moc,
                peer: "Anish",
                text: "hello world",
                outgoing: true)
        }
        
        fetchMessages()
        
        // Store the full frame in a temporary variable
        var viewFrame = self.view.frame
        
        // Adjust it down by 20 points
        viewFrame.origin.y += CGFloat(IOS_BAR_HEIGHT)
        
        // Reduce the total height by 20 points
        viewFrame.size.height -= CGFloat(IOS_BAR_HEIGHT)
        
        // Set the logTableview's frame to equal our temporary variable with the full size of the view
        // adjusted to account for the status bar height
        self.messageTable.frame = viewFrame
        
        // Add the table view to this view controller's view
        self.view.addSubview(messageTable)
        
        // Here, we tell the table view that we intend to use a cell we're going to call "LogCell"
        // This will be associated with the standard UITableViewCell class for now
        self.messageTable.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "MessageCell")
        
        // This tells the table view that it should get it's data from this class, ViewController
        self.messageTable.dataSource = self
        self.messageTable.delegate = self
        
        presentItemInfo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchMessages() {
        let fetchRequest = NSFetchRequest(entityName: "Message")
        
        // Create a sort descriptor object that sorts on the "title"
        // property of the Core Data object
//        let sortDescriptor = NSSortDescriptor(key: "lastDate", ascending: true) TODO
        
        // Set the list of sort descriptors in the fetch request,
        // so it includes the sort descriptor
//        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Message] {
            messages = fetchResults
        }
    }
    
    func presentItemInfo() {
        let fetchRequest = NSFetchRequest(entityName: "Message")
        let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Message]
    }

    // UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell") as UITableViewCell
        
        // Get the LogItem for this index
        let messageItem = messages[indexPath.row]
        
        // Set the title of the cell to be the title of the logItem
        cell.textLabel?.text = messageItem.text
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count;
    }
    
    // UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat((Float(self.view.frame.size.height) - IOS_BAR_HEIGHT) / ROWS_PER_SCREEN)
    }
    
    // PtPProtocolDelegate
    func receive(message : NSData, pubKey : NSData, time : NSDate) {
        println("received message on frontend")
    }
}

