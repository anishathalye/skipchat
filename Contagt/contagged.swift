//
//  contagged.swift
//  SkipChat
//
//  Created by Ankush Gupta on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//
import AddressBook
import AddressBookUI
import UIKit



class ContaggedManager: NSObject, ABPeoplePickerNavigationControllerDelegate {
    
    var delegate : ContaggedPickerDelegate?
    
    func getAuthorizationStatus() -> ABAuthorizationStatus {
        return SwiftAddressBook.authorizationStatus()
    }
    
    func requestAuthorizationWithCompletion(completion: (Bool, CFError?) -> Void ) {
        swiftAddressBook?.requestAccessWithCompletion(completion)
    }
    
    // MARK: Contact Picker Methods
    func pickContact(fieldName: String) -> Void {
        let picker = ABPeoplePickerNavigationController()
        picker.peoplePickerDelegate = self
        
        if picker.respondsToSelector(Selector("predicateForEnablingPerson")) {
            // urls.filter({$0.label == fieldName}).count > 0
            picker.predicateForEnablingPerson = NSPredicate(format: "ANY urls.fieldName = %@", fieldName)
        }
        
        //presentViewController(picker, animated: true, completion: nil)
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!,
        didSelectPerson person: ABRecordRef!) {
        delegate?.personSelected(swiftAddressBook?.personWithRecordId(ABRecordGetRecordID(person)))
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, shouldContinueAfterSelectingPerson person: ABRecordRef!) -> Bool {
        peoplePickerNavigationController(peoplePicker, didSelectPerson: person)
        peoplePicker.dismissViewControllerAnimated(true, completion: nil)
        return false;
    }
    
    func peoplePickerNavigationControllerDidCancel(peoplePicker: ABPeoplePickerNavigationController!) {
        peoplePicker.dismissViewControllerAnimated(true, completion: nil)
        delegate?.peoplePickerNavigationControllerDidCancel();
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
    Find all contacts who have a given field
    
    :param: field The name of our custom field
    
    :returns: An Array of SwiftAddressBookPersons
    */
    func findContactsWithField(field:String) -> [SwiftAddressBookPerson]? {
        // return all contacts who have at least one url with a matching label and value
        return swiftAddressBook?.allPeople?.filter( {
            $0.urls?.filter({
                $0.label == field
            }).count > 0
        })
    }
    
    /**
    Find all contacts who have a given value for a given field
    
    :param: field The name of our custom field
    :param: value The value for our custom field
    
    :returns: An Array of SwiftAddressBookPersons
    */
    func findContactsByFieldValue(field:String, fieldValue:String) -> [SwiftAddressBookPerson]? {
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
    func findValueForRecord(field:String, record:ABRecord) -> [MultivalueEntry<String>]? {
        let person = swiftAddressBook?.personWithRecordId(ABRecordGetRecordID(record))
        return person?.urls?.filter({$0.label == field})
    }
}

protocol ContaggedPickerDelegate  {
    func peoplePickerNavigationControllerDidCancel()
    func personSelected(person: SwiftAddressBookPerson!)
}