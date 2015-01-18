//SwiftAddressBook - A strong-typed Swift Wrapper for ABAddressBook
//Copyright (C) 2014  Socialbit GmbH
//
//This program is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with this program.  If not, see http://www.gnu.org/licenses/ .
//If you would to like license this software for non-free commercial use,
//please write us at kontakt@socialbit.de .

import UIKit
import AddressBook

//MARK: global address book variable

var swiftAddressBook : SwiftAddressBook? {
get {
    if let instance = swiftAddressBookInstance {
        return instance
    }
    else {
        swiftAddressBookInstance = SwiftAddressBook(0)
        return swiftAddressBookInstance
    }
}
}


//MARK: private address book store

private var swiftAddressBookInstance : SwiftAddressBook?


//MARK: Address Book

class SwiftAddressBook {
    
    var internalAddressBook : ABAddressBook!
    
    private init?(_ dummy : Int) {
        var err : Unmanaged<CFError>? = nil
        let ab = ABAddressBookCreateWithOptions(nil, &err)
        if err == nil {
            internalAddressBook = ab.takeRetainedValue()
        }
        else {
            return nil
        }
    }
    
    class func authorizationStatus() -> ABAuthorizationStatus {
        return ABAddressBookGetAuthorizationStatus()
    }
    
    func requestAccessWithCompletion( completion : (Bool, CFError?) -> Void ) {
        ABAddressBookRequestAccessWithCompletion(internalAddressBook) {(let b : Bool, c : CFError!) -> Void in completion(b,c)}
    }
    
    func hasUnsavedChanges() -> Bool {
        return ABAddressBookHasUnsavedChanges(internalAddressBook)
    }
    
    func save() -> CFError? {
        return errorIfNoSuccess { ABAddressBookSave(self.internalAddressBook, $0)}
    }
    
    func revert() {
        ABAddressBookRevert(internalAddressBook)
    }
    
    func addRecord(record : SwiftAddressBookRecord) -> CFError? {
        return errorIfNoSuccess { ABAddressBookAddRecord(self.internalAddressBook, record.internalRecord, $0) }
    }
    
    func removeRecord(record : SwiftAddressBookRecord) -> CFError? {
        return errorIfNoSuccess { ABAddressBookRemoveRecord(self.internalAddressBook, record.internalRecord, $0) }
    }
    
    //MARK: person records
    
    var personCount : Int {
        get {
            return ABAddressBookGetPersonCount(internalAddressBook)
        }
    }
    
    func personWithRecordId(recordId : Int32) -> SwiftAddressBookPerson? {
        return SwiftAddressBookRecord(record: ABAddressBookGetPersonWithRecordID(internalAddressBook, recordId).takeUnretainedValue()).convertToPerson()
    }
    
    var allPeople : [SwiftAddressBookPerson]? {
        get {
            return convertRecordsToPersons(ABAddressBookCopyArrayOfAllPeople(internalAddressBook).takeRetainedValue())
        }
    }
    
    func allPeopleInSource(source : SwiftAddressBookSource) -> [SwiftAddressBookPerson]? {
        return convertRecordsToPersons(ABAddressBookCopyArrayOfAllPeopleInSource(internalAddressBook, source.internalRecord).takeRetainedValue())
    }
    
    func peopleWithName(name : String) -> [SwiftAddressBookPerson]? {
        let string : CFString = name as CFString
        return convertRecordsToPersons(ABAddressBookCopyPeopleWithName(internalAddressBook, string).takeRetainedValue())
    }
    
}


//MARK: Wrapper for ABAddressBookRecord

class SwiftAddressBookRecord {
    
    var internalRecord : ABRecord
    
    init(record : ABRecord) {
        internalRecord = record
    }
    
    func convertToSource() -> SwiftAddressBookSource? {
        if ABRecordGetRecordType(internalRecord) == UInt32(kABSourceType) {
            let source = SwiftAddressBookSource(record: internalRecord)
            return source
        }
        else {
            return nil
        }
    }
    
    func convertToGroup() -> SwiftAddressBookGroup? {
        if ABRecordGetRecordType(internalRecord) == UInt32(kABGroupType) {
            let group = SwiftAddressBookGroup(record: internalRecord)
            return group
        }
        else {
            return nil
        }
    }
    
    func convertToPerson() -> SwiftAddressBookPerson? {
        if ABRecordGetRecordType(internalRecord) == UInt32(kABPersonType) {
            let person = SwiftAddressBookPerson(record: internalRecord)
            return person
        }
        else {
            return nil
        }
    }
}


//MARK: Wrapper for ABAddressBookRecord of type ABSource

class SwiftAddressBookSource : SwiftAddressBookRecord {
    
    var searchable : Bool {
        get {
            let sourceType : CFNumber = ABRecordCopyValue(internalRecord, kABSourceTypeProperty).takeRetainedValue() as CFNumber
            var rawSourceType : Int32? = nil
            CFNumberGetValue(sourceType, CFNumberGetType(sourceType), &rawSourceType)
            let andResult = kABSourceTypeSearchableMask & rawSourceType!
            return andResult != 0
        }
    }
    
    var sourceName : String {
        return ABRecordCopyValue(internalRecord, kABSourceNameProperty).takeRetainedValue() as CFString
    }
}



//MARK: Wrapper for ABAddressBookRecord of type ABGroup

class SwiftAddressBookGroup : SwiftAddressBookRecord {
    
    var name : String {
        get {
            return ABRecordCopyValue(internalRecord, kABGroupNameProperty).takeRetainedValue() as CFString
        }
    }
    
    class func create() -> SwiftAddressBookGroup {
        return SwiftAddressBookGroup(record: ABGroupCreate().takeRetainedValue())
    }
    
    class func createInSource(source : SwiftAddressBookSource) -> SwiftAddressBookGroup {
        return SwiftAddressBookGroup(record: ABGroupCreateInSource(source.internalRecord).takeRetainedValue())
    }
    
    var allMembers : [SwiftAddressBookPerson]? {
        get {
            return convertRecordsToPersons(ABGroupCopyArrayOfAllMembers(internalRecord).takeRetainedValue())
        }
    }
    
    func addMember(person : SwiftAddressBookPerson) -> CFError? {
        return errorIfNoSuccess { ABGroupAddMember(self.internalRecord, person.internalRecord, $0) }
    }
    
    func removeMember(person : SwiftAddressBookPerson) -> CFError? {
        return errorIfNoSuccess { ABGroupRemoveMember(self.internalRecord, person.internalRecord, $0) }
    }
    
    var source : SwiftAddressBookSource {
        get {
            return SwiftAddressBookSource(record: ABGroupCopySource(internalRecord).takeRetainedValue())
        }
    }
}


//MARK: Wrapper for ABAddressBookRecord of type ABPerson

class SwiftAddressBookPerson : SwiftAddressBookRecord {
    
    class func create() -> SwiftAddressBookPerson {
        return SwiftAddressBookPerson(record: ABPersonCreate().takeRetainedValue())
    }
    
    class func createInSource(source : SwiftAddressBookSource) -> SwiftAddressBookPerson {
        return SwiftAddressBookPerson(record: ABPersonCreateInSource(source.internalRecord).takeRetainedValue())
    }
    
    class func createInSourceWithVCard(source : SwiftAddressBookSource, vCard : String) -> [SwiftAddressBookPerson]? {
        let data : NSData? = vCard.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        let abPersons : NSArray? = ABPersonCreatePeopleInSourceWithVCardRepresentation(source.internalRecord, data).takeRetainedValue()
        var swiftPersons = [SwiftAddressBookPerson]()
        if let persons = abPersons {
            for person : ABRecord in persons {
                let swiftPerson = SwiftAddressBookPerson(record: person)
                swiftPersons.append(swiftPerson)
            }
        }
        if swiftPersons.count != 0 {
            return swiftPersons
        }
        else {
            return nil
        }
    }
    
    class func createVCard(people : [SwiftAddressBookPerson]) -> String {
        let peopleArray : NSArray = people.map{$0.internalRecord}
        let data : NSData = ABPersonCreateVCardRepresentationWithPeople(peopleArray).takeRetainedValue()
        return NSString(data: data, encoding: NSUTF8StringEncoding)!
    }
    
    
    
    //MARK: Personal Information
    
    
    func setImage(image : UIImage) -> CFError? {
        let imageData : NSData = UIImagePNGRepresentation(image)
        return errorIfNoSuccess { ABPersonSetImageData(self.internalRecord,  CFDataCreate(nil, UnsafePointer(imageData.bytes), imageData.length), $0) }
    }
    
    var image : UIImage? {
        get {
            return UIImage(data: ABPersonCopyImageData(internalRecord).takeRetainedValue())
        }
    }
    
    func imageDataWithFormat(format : SwiftAddressBookPersonImageFormat) -> UIImage? {
        return UIImage(data: ABPersonCopyImageDataWithFormat(internalRecord, format.abPersonImageFormat).takeRetainedValue())
    }
    
    func hasImageData() -> Bool {
        return ABPersonHasImageData(internalRecord)
    }
    
    func removeImage() -> CFError? {
        return errorIfNoSuccess { ABPersonRemoveImageData(self.internalRecord, $0) }
    }
    
    var allLinkedPeople : [SwiftAddressBookPerson]? {
        get {
            return convertRecordsToPersons(ABPersonCopyArrayOfAllLinkedPeople(internalRecord).takeRetainedValue() as CFArray)
        }
    }
    
    var source : SwiftAddressBookSource {
        get {
            return SwiftAddressBookSource(record: ABPersonCopySource(internalRecord).takeRetainedValue())
        }
    }
    
    var compositeNameDelimiterForRecord : String {
        get {
            return ABPersonCopyCompositeNameDelimiterForRecord(internalRecord).takeRetainedValue()
        }
    }
    
    
    var firstName : String? {
        get {
            let value: AnyObject = ABRecordCopyValue(self.internalRecord, kABPersonFirstNameProperty).takeRetainedValue() ?? ""
            let typedval = value as? String
            return typedval
        }
        set {
            let value: AnyObject = newValue ?? ""
            setSingleValueProperty(kABPersonFirstNameProperty, value)
        }
    }
    
    var lastName : String? {
        get {
            let value: AnyObject = ABRecordCopyValue(self.internalRecord, kABPersonLastNameProperty).takeRetainedValue() ?? ""
            let typedval = value as? String
            return typedval        }
        set {
            let value: AnyObject = newValue ?? ""
            setSingleValueProperty(kABPersonLastNameProperty, value)
        }
    }
    
    var middleName : String? {
        get {
            return extractProperty(kABPersonMiddleNameProperty)
        }
        set {
            let value: AnyObject = newValue ?? ""
            setSingleValueProperty(kABPersonMiddleNameProperty, value)
        }
    }
    
    var prefix : String? {
        get {
            return extractProperty(kABPersonPrefixProperty)
        }
        set {
            let value: AnyObject = newValue ?? ""
            setSingleValueProperty(kABPersonPrefixProperty, value)
        }
    }
    
    var suffix : String? {
        get {
            return extractProperty(kABPersonSuffixProperty)
        }
        set {
            let value: AnyObject = newValue ?? ""
            setSingleValueProperty(kABPersonSuffixProperty, value)
        }
    }
    
    var nickname : String? {
        get {
            return extractProperty(kABPersonNicknameProperty)
        }
        set {
            let value: AnyObject = newValue ?? ""
            setSingleValueProperty(kABPersonNicknameProperty, value)
        }
    }
    
    var firstNamePhonetic : String? {
        get {
            return extractProperty(kABPersonFirstNamePhoneticProperty)
        }
        set {
            let value: AnyObject = newValue ?? ""
            setSingleValueProperty(kABPersonFirstNamePhoneticProperty, value)
        }
    }
    
    var lastNamePhonetic : String? {
        get {
            return extractProperty(kABPersonLastNamePhoneticProperty)
        }
        set {
            let value: AnyObject = newValue ?? ""
            setSingleValueProperty(kABPersonLastNamePhoneticProperty, value)
        }
    }
    
    var middleNamePhonetic : String? {
        get {
            return extractProperty(kABPersonMiddleNamePhoneticProperty)
        }
        set {
            let value: AnyObject = newValue ?? ""
            setSingleValueProperty(kABPersonMiddleNamePhoneticProperty, value)
        }
    }
    
    var organization : String? {
        get {
            return extractProperty(kABPersonOrganizationProperty)
        }
        set {
            let value: AnyObject = newValue ?? ""
            setSingleValueProperty(kABPersonOrganizationProperty, value)
        }
    }
    
    var jobTitle : String? {
        get {
            return extractProperty(kABPersonJobTitleProperty)
        }
        set {
            let value: AnyObject = newValue ?? ""
            setSingleValueProperty(kABPersonJobTitleProperty, value)
        }
    }
    
    var department : String? {
        get {
            return extractProperty(kABPersonDepartmentProperty)
        }
        set {
            let value: AnyObject = newValue ?? ""
            setSingleValueProperty(kABPersonDepartmentProperty, value)
        }
    }
    
    
    var birthday : NSDate? {
        get {
            return extractProperty(kABPersonBirthdayProperty)
        }
        set {
            setSingleValueProperty(kABPersonBirthdayProperty, newValue)
        }
    }
    
    var note : String? {
        get {
            let value: AnyObject = ABRecordCopyValue(self.internalRecord, kABPersonNoteProperty).takeRetainedValue() ?? ""
            let typedval = value as? String
            return typedval
        }
        set {
            let value: AnyObject = newValue ?? ""
            setSingleValueProperty(kABPersonNoteProperty, value)
        }
    }
    
    var creationDate : NSDate? {
        get {
            return extractProperty(kABPersonCreationDateProperty)
        }
        set {
            setSingleValueProperty(kABPersonCreationDateProperty, newValue)
        }
    }
    
    var modificationDate : NSDate? {
        get {
            return extractProperty(kABPersonModificationDateProperty)
        }
        set {
            setSingleValueProperty(kABPersonModificationDateProperty, newValue)
        }
    }
    
    
    
    var alternateBirthday : Dictionary<String, AnyObject>? {
        get {
            return extractProperty(kABPersonAlternateBirthdayProperty)
        }
        set {
            let dict : NSDictionary? = newValue
            setSingleValueProperty(kABPersonAlternateBirthdayProperty, dict)
        }
    }
    
    
    //MARK: generic methods to set and get person properties
    
    private func extractProperty<T>(propertyName : ABPropertyID) -> T? {
        let copyval = ABRecordCopyValue(self.internalRecord, propertyName)
        let retval = copyval.takeRetainedValue()
        let typedval = retval as? T
        return typedval
    }
    
    private func setSingleValueProperty<T : AnyObject>(key : ABPropertyID,_ value : T?) {
        ABRecordSetValue(self.internalRecord, key, value, nil)
    }
    
    
    private func convertDictionary<T,U, V : AnyObject, W : AnyObject where V : Hashable>(d : Dictionary<T,U>?, keyConverter : (T) -> V, valueConverter : (U) -> W ) -> NSDictionary? {
        if let d2 = d {
            var dict = Dictionary<V,W>()
            for key in d2.keys {
                dict[keyConverter(key)] = valueConverter(d2[key]!)
            }
            return dict
        }
        else {
            return nil
        }
    }
}


//MARK: methods to convert arrays of ABRecords
private func convertRecordsToPersons(records : [ABRecord]?) -> [SwiftAddressBookPerson]? {
    let swiftRecords = records?.map {(record : ABRecord) -> SwiftAddressBookPerson in return SwiftAddressBookRecord(record: record).convertToPerson()!}
    return swiftRecords
}


enum SwiftAddressBookPersonImageFormat {
    case thumbnail
    case originalSize
    
    var abPersonImageFormat : ABPersonImageFormat {
        switch self {
        case .thumbnail :
            return kABPersonImageFormatThumbnail
        case .originalSize :
            return kABPersonImageFormatOriginalSize
        }
    }
}


//MARK: some more handy methods
//extension NSString {
//    convenience init?(string : String?) {
//        if string == nil {
//            self.init()
//            return nil
//        }
//        self.init(string: string!)
//    }
//}

func errorIfNoSuccess(call : (UnsafeMutablePointer<Unmanaged<CFError>?>) -> Bool) -> CFError? {
    var err : Unmanaged<CFError>? = nil
    let success : Bool = call(&err)
    if success {
        return nil
    }
    else {
        return err?.takeRetainedValue()
    }
}