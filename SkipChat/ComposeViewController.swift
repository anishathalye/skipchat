//
//  MessagesViewController.swift
//  treat
//
//  Created by Nick O'Neill on 8/2/14.
//  Copyright (c) 2014 Launch Apps. All rights reserved.
//

import UIKit
import CoreLocation

// this should be part of the JSQMessagesCollectionViewDataSource protocol as well, but swift says it doesn't conform
class ComposeViewController: JSQMessagesViewController {
    var messages: [JSQMessage] = []
    var treats: [Message] = []
    var contact: Contact?
    var avatarImages = Dictionary<String, UIImage>()
    
    var incomingBubbleImage: UIImageView?
    var outgoingBubbleImage: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showLoadEarlierMessagesHeader = false
        self.sender = PFUser.currentUser().username
        self.inputToolbar.hidden = true
        
        let fontSize = CGFloat(14)
        let width = UInt(self.collectionView.collectionViewLayout.outgoingAvatarViewSize.width)
        
        let backButton = UIButton.buttonWithType(.Custom) as UIButton
        backButton.setBackgroundImage(UIImage(named: "back"), forState: .Normal)
        backButton.addTarget(self, action: Selector("goBack"), forControlEvents: .TouchUpInside)
        backButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        self.view.addSubview(backButton)
        let bindings = ["backButton": backButton]
        let backHConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|-10-[backButton(==30)]", options: nil, metrics: nil, views: bindings)
        let backVConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-25-[backButton(==30)]", options: nil, metrics: nil, views: bindings)
        self.view.addConstraints(backHConstraints)
        self.view.addConstraints(backVConstraints)
        
        let newButton = UIButton.buttonWithType(.Custom) as UIButton
        newButton.setBackgroundImage(UIImage(named: "new"), forState: .Normal)
        newButton.addTarget(self, action: Selector("newTreat"), forControlEvents: .TouchUpInside)
        newButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        self.view.addSubview(newButton)
        let newbindings = ["newButton": newButton]
        let newHConstraints = NSLayoutConstraint.constraintsWithVisualFormat("[newButton(==45)]-10-|", options: nil, metrics: nil, views: newbindings)
        let newVConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[newButton(==45)]-10-|", options: nil, metrics: nil, views: newbindings)
        self.view.addConstraints(newHConstraints)
        self.view.addConstraints(newVConstraints)
        
        // prep backgrounds
        JSQMessagesBubbleImageFactory.outgoingTreatImageViewForLocation(CLLocation(latitude: 37.7514351, longitude: -122.4318659)) {
            (imageView) -> Void in
            self.outgoingBubbleImage = imageView
            self.finishReceivingMessage()
        }
        
        JSQMessagesBubbleImageFactory.incomingTreatImageViewForLocation(CLLocation(latitude: 37.7514351, longitude: -122.4318659)) {
            (imageView) -> Void in
            self.incomingBubbleImage = imageView
            self.finishReceivingMessage()
        }
        
        // prep all the avatars
        let selfImage = JSQMessagesAvatarFactory.avatarWithUserInitials("NO", backgroundColor: UIColor.lightGrayColor(), textColor: UIColor.darkGrayColor(), font: UIFont.systemFontOfSize(fontSize), diameter: width)
        self.avatarImages[PFUser.currentUser().username] = selfImage
        let otherImage = JSQMessagesAvatarFactory.avatarWithUserInitials("RK", backgroundColor: UIColor.lightGrayColor(), textColor: UIColor.darkGrayColor(), font: UIFont.systemFontOfSize(fontSize), diameter: width)
        var othername = "otheruser"
        if let othercontact = self.contact? {
            othername = othercontact.name
        }
        self.avatarImages[othername] = otherImage
    }
    
    func newTreat() {
        self.performSegueWithIdentifier("newTreat", sender: nil)
    }
    
    func goBack() {
        self.navigationController.popViewControllerAnimated(true)
    }
    
    func reloadMessages() {
        if let thisContact = self.contact? {
            let otherUser = PFUser(withoutDataWithObjectId: thisContact.objectId)
            
            let sentQuery = PFQuery(className: "Treat")
            sentQuery.whereKey("fromUser", equalTo: PFUser.currentUser())
            sentQuery.whereKey("toUser", equalTo: otherUser)
            let receivedQuery = PFQuery(className: "Treat")
            receivedQuery.whereKey("fromUser", equalTo: otherUser)
            receivedQuery.whereKey("toUser", equalTo: PFUser.currentUser())
            let allQuery = PFQuery.orQueryWithSubqueries([sentQuery,receivedQuery])
            allQuery.orderByDescending("createdAt")
            allQuery.includeKey("fromUser")
            allQuery.limit = 10
            
            allQuery.findObjectsInBackgroundWithBlock {
                (objects: [AnyObject]!, error: NSError!) in
                if error != nil {
                    println("error getting messages: \(error)")
                } else {
                    self.messages = []
                    self.treats = []
                    
                    for object in objects {
                        //                        println("treat: \(object)")
                        let treat = object as Treat
                        self.treats.append(treat)
                        
                        let amount = treat.stringAmount()
                        let fromUser = treat["fromUser"] as PFUser
                        
                        let sender = fromUser.username
                        
                        let string = "treat for \(amount)"
                        let message = JSQMessage(text: string, sender: sender, date: treat.createdAt)
                        self.messages.append(message)
                    }
                    
                    self.finishReceivingMessage()
                }
            }
        }
    }
    
    //MARK: JSQMessage data source
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        let messageData = self.messages[indexPath.row]
        
        return messageData
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, bubbleImageViewForItemAtIndexPath indexPath: NSIndexPath!) -> UIImageView! {
        
        let message = self.messages[indexPath.item]
        
        if message.sender == self.sender {
            return UIImageView(image: self.outgoingBubbleImage?.image, highlightedImage: self.outgoingBubbleImage?.highlightedImage)
        }
        
        return UIImageView(image: self.incomingBubbleImage?.image, highlightedImage: self.incomingBubbleImage?.highlightedImage)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageViewForItemAtIndexPath indexPath: NSIndexPath!) -> UIImageView! {
        
        let message = self.messages[indexPath.item]
        let username = message.sender
        
        return UIImageView(image: self.avatarImages[username])
    }
    
    //    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
    //        return nil
    //    }
    //
    //    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
    //        return nil
    //    }
    //
    //    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
    //        return nil
    //    }
    
    override func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell! {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as JSQMessagesCollectionViewCell
        
        let message = self.messages[indexPath.item]
        let treat = self.treats[indexPath.item]
        
        cell.amountLabel.text = treat.stringAmount()
        
        if treat.isExpired() {
            cell.timeLabel.hidden = true
            
            if treat.isRedeemed() {
                // replace countdown with check
            } else {
                // replace countdown with x
            }
        }
        
        return cell
    }
}