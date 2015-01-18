//
//  Message.swift
//  SkipChat
//
//  Created by Katie Siegel on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

import Foundation
import CoreData

class Message: NSManagedObject {

    @NSManaged var outgoing: NSNumber
    @NSManaged var text: String
    @NSManaged var peer: String
    
    class func createInManagedObjectContext(moc: NSManagedObjectContext, peer: String, text: String, outgoing: Bool) -> Message {
        let newItem = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: moc) as Message
        newItem.peer = peer
        newItem.text = text
        newItem.outgoing = outgoing
        
        return newItem
    }
}
