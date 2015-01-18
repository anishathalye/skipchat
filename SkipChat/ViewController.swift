//
//  ViewController.swift
//  SkipChat
//
//  Created by Katie Siegel on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PtoPProtocolDelegate, UINavigationBarDelegate, LGChatControllerDelegate {
    let IOS_BAR_HEIGHT : Float = 20.0
    let ROWS_PER_SCREEN : Float = 8.0
    let NAV_BAR_HEIGHT : Float = 64.0
    var networkingLayer : PtoPProtocol!
    var messageTable = UITableView(frame: CGRectZero, style: .Plain)
    var navBar : UINavigationBar = UINavigationBar(frame: CGRectZero)
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
        viewFrame.origin.y += CGFloat(NAV_BAR_HEIGHT)
        
        // Reduce the total height by 20 points
        viewFrame.size.height -= CGFloat(NAV_BAR_HEIGHT)
        
        // Set the logTableview's frame to equal our temporary variable with the full size of the view
        // adjusted to account for the status bar height
        self.messageTable.frame = viewFrame
        
        // Add the table view to this view controller's view
        self.view.addSubview(messageTable)
        
        // Here, we tell the table view that we intend to use a cell we're going to call "LogCell"
        // This will be associated with the standard UITableViewCell class for now
        self.messageTable.registerClass(MessageTableViewCell.classForCoder(), forCellReuseIdentifier: "MessageCell")
        
        // This tells the table view that it should get it's data from this class, ViewController
        self.messageTable.dataSource = self
        self.messageTable.delegate = self
        
        
        navBar.frame = CGRectMake(0, 0, self.view.frame.width, CGFloat(NAV_BAR_HEIGHT))
        navBar.layer.masksToBounds = false
        navBar.delegate = self
        
        // Create a navigation item with a title
        let navigationItem = UINavigationItem()
        navigationItem.title = "SkipChat"
        
        // Create left and right button for navigation item
        //        let leftButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Plain, target: self, action: nil)
        let rightButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Compose, target: self, action: "composeNewMessage")
        
        // Create two buttons for the navigation item
        //        navigationItem.leftBarButtonItem = leftButton
        navigationItem.rightBarButtonItem = rightButton
        
        // Assign the navigation item to the navigation bar
        navBar.items = [navigationItem]
        
        
        self.view.addSubview(navBar)
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

    // UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell") as MessageTableViewCell
        
        // Get the LogItem for this index
        let messageItem = messages[indexPath.row]
        
        // Set the title of the cell to be the title of the logItem
        cell.messagePeerLabel.text = messageItem.peer
        cell.messageTextLabel.text = messageItem.text
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count;
    }
    
    // UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat((Float(self.view.frame.size.height) - IOS_BAR_HEIGHT) / ROWS_PER_SCREEN)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("pushing new controller")
//        self.presentViewController(ComposeViewController(), animated: true, completion: nil)
        let chatController = LGChatController()
        chatController.opponentImage = UIImage(named: "User")
        chatController.messages = getMessages()
        chatController.peer = self.messages[indexPath.row].peer
        chatController.delegate = self
        self.messageTable.deselectRowAtIndexPath(indexPath, animated: true)
        self.presentViewController(chatController, animated: true, completion: nil)
    }
    
    public func composeNewMessage() {
        let chatController = LGChatController()
        chatController.opponentImage = UIImage(named: "User")
        chatController.messages = getMessages()
        chatController.delegate = self
        chatController.isNewMessage = true 
        self.presentViewController(chatController, animated: true, completion: nil)
    }

    
    func getMessages() -> [LGChatMessage] {
        let helloWorld = LGChatMessage(content: "Hello World!", sentBy: .User)
        return [helloWorld]
    }
    
    // LGChatControllerDelegate
    func chatController(chatController: LGChatController, didAddNewMessage message: LGChatMessage) {
        println("Did Add Message: \(message.content)")
    }
    
    func shouldChatController(chatController: LGChatController, addMessage message: LGChatMessage) -> Bool {
        /*
        Use this space to prevent sending a message, or to alter a message.  For example, you might want to hold a message until its successfully uploaded to a server.
        */
        return true
    }
    
    // PtPProtocolDelegate
    func receive(message : NSData, pubKey : NSData, time : NSDate) {
        println("received message on frontend")
    }
}

