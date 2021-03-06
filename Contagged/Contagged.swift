//  Contagged.swift
//  SkipChat
//
//  Created by Ankush Gupta on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//
import AddressBook
import AddressBookUI
import UIKit

protocol ContaggedPickerDelegate {
    func peoplePickerNavigationControllerDidCancel()
    func personSelected(person: SwiftAddressBookPerson?)
}

protocol ContaggedUnknownPersonDelegate {
    func didResolveToPerson(person: SwiftAddressBookPerson?)
}

class ContaggedManager: NSObject, ABPeoplePickerNavigationControllerDelegate, ABUnknownPersonViewControllerDelegate {
    
    var pickerDelegate : ContaggedPickerDelegate?
    var unknownPersonDelegate : ContaggedUnknownPersonDelegate?
    var viewController : UIViewController?
    var pickerField : String?
    

    // MARK: Authorization Methods
    class func getAuthorizationStatus() -> ABAuthorizationStatus {
        return SwiftAddressBook.authorizationStatus()
    }
    
    func requestAuthorizationWithCompletion(completion: (Bool, CFError?) -> Void ) {
        swiftAddressBook?.requestAccessWithCompletion(completion)
    }

    // MARK: People Picker Methods
    func pickContact(fieldName: String) -> Void {
        pickerField = fieldName;
        let picker = ABPeoplePickerNavigationController()
        picker.peoplePickerDelegate = self
        
        if picker.respondsToSelector(Selector("predicateForEnablingPerson")) {
            picker.predicateForEnablingPerson = NSPredicate(format: "%K.length>0", ABPersonNoteProperty)
        }
        
        viewController?.presentViewController(picker, animated: true, completion: nil)
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!,
        didSelectPerson person: ABRecordRef!) {
            pickerDelegate?.personSelected(swiftAddressBook?.personWithRecordId(ABRecordGetRecordID(person)))
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, shouldContinueAfterSelectingPerson person: ABRecordRef!) -> Bool {
        peoplePickerNavigationController(peoplePicker, didSelectPerson: person)
        peoplePicker.dismissViewControllerAnimated(true, completion: nil)
        return false;
    }
    
    func peoplePickerNavigationControllerDidCancel(peoplePicker: ABPeoplePickerNavigationController!) {
        peoplePicker.dismissViewControllerAnimated(true, completion: nil)
        pickerDelegate?.peoplePickerNavigationControllerDidCancel();
    }
    
    // MARK: Unknown Person Methods
    func addUnknownContact(fieldName: String, value: String) -> Void {
        if(ContaggedManager.getAuthorizationStatus() == ABAuthorizationStatus.NotDetermined){
            swiftAddressBook?.requestAccessWithCompletion({ (success, error) -> Void in
                if success {
                    let unknownPersonViewController = ABUnknownPersonViewController()
                    unknownPersonViewController.unknownPersonViewDelegate = self
                    unknownPersonViewController.allowsAddingToAddressBook = true
                    unknownPersonViewController.allowsActions = false // user can tap an email address to switch to mail, for example
                    
                    let person : SwiftAddressBookPerson = SwiftAddressBookPerson.create()
                    self.addFieldToContact(fieldName, value: value, person: person)
                    unknownPersonViewController.displayedPerson = person
                    
                    self.viewController!.showViewController(unknownPersonViewController, sender:self.viewController!) // push onto navigation controller
                }
                else {
                    println("Access to contacts denied!")
                }
            })
        }
    }
    
    func unknownPersonViewController(
        unknownCardViewController: ABUnknownPersonViewController!,
        didResolveToPerson person: ABRecord!) {
            unknownPersonDelegate?.didResolveToPerson(swiftAddressBook?.personWithRecordId( ABRecordGetRecordID(person)))
    }
    
    // MARK: General access methods
    /**
    Add a field to a contact
    
    :param: field The name of our custom field
    :param: value The value for our custom field
    :param: record The ABRecord pointing to the specific contact to which we want to add the field
    
    :returns: A reference to a CFError object.
    */
    func addFieldToContact(field:String, value:String, person:SwiftAddressBookPerson) -> CFError? {
        person.note = value
        
        return swiftAddressBook?.save()
    }
    
    /**
    Find all contacts who have a given field
    
    :param: field The name of our custom field
    
    :returns: An Array of SwiftAddressBookPersons
    */
//    func findContactsWithField(field:String) -> [SwiftAddressBookPerson]? {
//        // return all contacts who have at least one url with a matching label and value
//        return swiftAddressBook?.allPeople?.filter( {
//            $0.note != nil
//        })
//    }

    func noteEquals(person: SwiftAddressBookPerson?, fieldValue:String) -> Bool {
        return person?.note? == fieldValue;
    }
    
    /**
    Find all contacts who have a given value for a given field
    
    :param: field The name of our custom field
    :param: value The value for our custom field
    
    :returns: An Array of SwiftAddressBookPersons
    */
    func findContactsByFieldValue(field:String, fieldValue:String) -> SwiftAddressBookPerson? {
        // return all contacts who have at least one url with a matching label and value
        if let people = swiftAddressBook?.allPeople {
            for person in people {
                if let note = person.note{
                    if note == fieldValue{
                        return person;
                    }
                }
            }
        }
        return nil;
    }
    
    /**
    Find the values of contacts who have a given value for the desired field
    
    :param: field The name of our custom field
    :param: record The value for our custom field
    
    :returns: An Array of SwiftAddressBookPersons
    */
    func findValueForPerson(field:String, person:SwiftAddressBookPerson?) -> String? {
        return person?.note;
    }

    func getPeerName(field: String, value:String) -> String{
        return findContactsByFieldValue(field, fieldValue: value)?.firstName ?? "Unknown User";
    }
}

