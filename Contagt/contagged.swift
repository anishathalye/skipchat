//
//  contagt.swift
//  SkipChat
//
//  Created by Ankush Gupta on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

import Foundation
import AddressBook

class ContaggedManager {
    
    init() {
        let status : ABAuthorizationStatus = SwiftAddressBook.authorizationStatus()
        if (status != ABAuthorizationStatus.Authorized){
            swiftAddressBook?.requestAccessWithCompletion({ (success, error) -> Void in
                if success {
                    //do something with swiftAddressBook
                } else {
                    //no success, access denied. Optionally evaluate error
                }
            })
        }
    }
    
    
    /**
    Add a field to a contact
    
    :param: field The name of our custom field
    :param: value The value for our custom field
    :param: record The ABRecord pointing to the specific contact to which we want to add the field
    
    :returns: A reference to a CFError object.
    */
    func addFieldToContact(field:String, value:String, record:ABRecord) -> CFError? {
        var person = swiftAddressBook?.personWithRecordId(ABRecordGetRecordID(record))!
        let newField = MultivalueEntry<String>(value:value, label:field, id:0)
        
        person!.urls = [newField] + (person!.urls ?? [])
        
        return swiftAddressBook?.save()
    }
    
    
    /**
    Find all contacts who have a given value for a given field
    
    :param: field The name of our custom field
    :param: value The value for our custom field
    
    :returns: An Array of SwiftAddressBookPersons
    */
    func findContactsByField(field:String, fieldValue:String) -> [SwiftAddressBookPerson]? {
        // return all contacts who have at least one url with a matching label and value
        return swiftAddressBook?.allPeople?.filter( {
            $0.urls?.filter({
                $0.label == field && $0.value == fieldValue
            }).count > 0
        })
    }
    
    /**
    Find the value of  contacts who have a given value for the desired field
    
    :param: field The name of our custom field
    :param: record The value for our custom field
    
    :returns: An Array of SwiftAddressBookPersons
    */
    func findMultivalueEntriesForPerson(field:String, record:ABRecord) -> [MultivalueEntry<String>]? {
        let person = swiftAddressBook?.personWithRecordId(ABRecordGetRecordID(record))
        return person?.urls?.filter({$0.label == field})
    }

}