//
//  SkipChat.swift
//  SkipChat
//
//  Created by Katie Siegel on 1/18/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

import Foundation
import CoreData

class Message: NSManagedObject {

    @NSManaged var outgoing: NSNumber
    @NSManaged var peer: String
    @NSManaged var text: String
    @NSManaged var publicKey: String
    @NSManaged var contactDate: NSDate
    
    class func createInManagedObjectContext(moc: NSManagedObjectContext, peer: String, publicKey: String, text: String, outgoing: Bool, contactDate: NSDate) -> Message {
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: moc) as Message
        newItem.peer = peer
        newItem.publicKey = publicKey
        newItem.text = text
        newItem.outgoing = outgoing
        newItem.contactDate = contactDate
        
        return newItem
    }

}
