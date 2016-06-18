//
//  SimpleChatController.swift
//  SimpleChat
//
//  Created by Logan Wright on 10/16/14. Modified for use in this project.
//  Copyright (c) 2014 Logan Wright. All rights reserved.
//

/*
Mozilla Public License
Version 2.0
https://tldrlegal.com/license/mozilla-public-license-2.0-(mpl-2)
*/

import UIKit
import CoreData
import AddressBook

// MARK: Message
class LGChatMessage : NSObject {
    
    enum SentBy : String {
        case User = "LGChatMessageSentByUser"
        case Opponent = "LGChatMessageSentByOpponent"
    }
    
    // MARK: ObjC Compatibility
    
    /*
    ObjC can't interact w/ enums properly, so this is used for converting compatible values.
    */
    
    class func SentByUserString() -> String {
        return LGChatMessage.SentBy.User.rawValue
    }
    
    class func SentByOpponentString() -> String {
        return LGChatMessage.SentBy.Opponent.rawValue
    }
    
    var sentByString: String {
        get {
            return sentBy.rawValue
        }
        set {
            if let sentBy = SentBy(rawValue: newValue) {
                self.sentBy = sentBy
            } else {
                println("LGChatMessage.FatalError : Property Set : Incompatible string set to SentByString!")
            }
        }
    }
    
    // MARK: Public Properties
    
    var sentBy: SentBy
    var content: String
    var timeStamp: NSTimeInterval?
    
    required init (content: String, sentBy: SentBy, timeStamp: NSTimeInterval? = nil){
        self.sentBy = sentBy
        self.timeStamp = timeStamp
        self.content = content
    }
    
    // MARK: ObjC Compatibility
    
    convenience init (content: String, sentByString: String) {
        if let sentBy = SentBy(rawValue: sentByString) {
            self.init(content: content, sentBy: sentBy, timeStamp: nil)
        } else {
            fatalError("LGChatMessage.FatalError : Initialization : Incompatible string set to SentByString!")
        }
    }
    
    convenience init (content: String, sentByString: String, timeStamp: NSTimeInterval) {
        if let sentBy = SentBy(rawValue: sentByString) {
            self.init(content: content, sentBy: sentBy, timeStamp: timeStamp)
        } else {
            fatalError("LGChatMessage.FatalError : Initialization : Incompatible string set to SentByString!")
        }
    }
}

// MARK: Message Cell
class LGChatMessageCell : UITableViewCell {
    
    // MARK: Global MessageCell Appearance Modifier
    
    struct Appearance {
        static var opponentColor = UIColor(red: 0.142954, green: 0.60323, blue: 0.862548, alpha: 0.88)
        static var userColor = UIColor(red: 0.258824, green: 1, blue: 0.137255, alpha: 1) // #42ff23
        static var font: UIFont = UIFont.systemFontOfSize(17.0)
    }
    
    /*
    These methods are included for ObjC compatibility.  If using Swift, you can set the Appearance variables directly.
    */
    
    class func setAppearanceOpponentColor(opponentColor: UIColor) {
        Appearance.opponentColor = opponentColor
    }
    
    class func setAppearanceUserColor(userColor: UIColor) {
        Appearance.userColor = userColor
    }
    
    class  func setAppearanceFont(font: UIFont) {
        Appearance.font = font
    }
    
    // MARK: Message Bubble TextView
    
    private lazy var textView: MessageBubbleTextView = {
        let textView = MessageBubbleTextView()
        self.contentView.addSubview(textView)
        return textView
        }()
    
    private class MessageBubbleTextView : UITextView {
        
        override init(frame: CGRect = CGRectZero, textContainer: NSTextContainer? = nil) {
            super.init(frame: frame, textContainer: textContainer)
            self.font = Appearance.font
            self.scrollEnabled = false
            self.editable = false
            self.textContainerInset = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
            self.layer.cornerRadius = 15
            self.layer.borderWidth = 2.0
        }
        
        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    // MARK: ImageView
    
    private lazy var opponentImageView: UIImageView = {
        let opponentImageView = UIImageView()
        opponentImageView.hidden = true
        opponentImageView.bounds.size = CGSize(width: self.minimumHeight, height: self.minimumHeight)
        let halfWidth = CGRectGetWidth(opponentImageView.bounds) / 2.0
        let halfHeight = CGRectGetHeight(opponentImageView.bounds) / 2.0
        
        // Center the imageview vertically to the textView when it is singleLine
        let textViewSingleLineCenter = self.textView.textContainerInset.top + (Appearance.font.lineHeight / 2.0)
        opponentImageView.center = CGPointMake(self.padding + halfWidth, textViewSingleLineCenter)
        opponentImageView.backgroundColor = UIColor.lightTextColor()
        opponentImageView.layer.rasterizationScale = UIScreen.mainScreen().scale
        opponentImageView.layer.shouldRasterize = true
        opponentImageView.layer.cornerRadius = halfHeight
        opponentImageView.layer.masksToBounds = true
        self.contentView.addSubview(opponentImageView)
        return opponentImageView
    }()
    
    // MARK: Sizing
    
    private let padding: CGFloat = 5.0
    
    private let minimumHeight: CGFloat = 30.0 // arbitrary minimum height
    
    private var size = CGSizeZero
    
    private var maxSize: CGSize {
        get {
            let maxWidth = CGRectGetWidth(self.bounds) * 0.75 // Cells can take up to 3/4 of screen
            let maxHeight = CGFloat.max
            return CGSize(width: maxWidth, height: maxHeight)
        }
    }
    
    // MARK: Setup Call
    
    /*!
    Use this in cellForRowAtIndexPath to setup the cell.
    */
    func setupWithMessage(message: LGChatMessage) -> CGSize {
        textView.text = message.content
        size = textView.sizeThatFits(maxSize)
        if size.height < minimumHeight {
            size.height = minimumHeight
        }
        textView.bounds.size = size
        self.styleTextViewForSentBy(message.sentBy)
        return size
    }
    
    // MARK: TextBubble Styling
    
    private func styleTextViewForSentBy(sentBy: LGChatMessage.SentBy) {
        let halfTextViewWidth = CGRectGetWidth(self.textView.bounds) / 2.0
        let targetX = halfTextViewWidth + padding
        let halfTextViewHeight = CGRectGetHeight(self.textView.bounds) / 2.0
        switch sentBy {
        case .Opponent:
            self.textView.center.x = targetX
            self.textView.center.y = halfTextViewHeight
            self.textView.layer.borderColor = Appearance.opponentColor.CGColor
            
            if self.opponentImageView.image != nil {
                self.opponentImageView.hidden = false
                self.textView.center.x += CGRectGetWidth(self.opponentImageView.bounds) + padding
            }
            
        case .User:
            self.opponentImageView.hidden = true
            self.textView.center.x = CGRectGetWidth(self.bounds) - targetX
            self.textView.center.y = halfTextViewHeight
            self.textView.layer.borderColor = Appearance.userColor.CGColor
        }
    }
}

// MARK: Chat Controller
@objc protocol LGChatControllerDelegate {
    optional func shouldChatController(chatController: LGChatController, addMessage message: LGChatMessage) -> Bool
    optional func chatController(chatController: LGChatController, didAddNewMessage message: LGChatMessage)
}

class LGChatController : UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, LGChatInputDelegate, UINavigationBarDelegate, ContaggedUnknownPersonDelegate, ContaggedPickerDelegate{
    
    // MARK: Constants
    private struct Constants {
        static let MessagesSection: Int = 0;
        static let MessageCellIdentifier: String = "LGChatController.Constants.MessageCellIdentifier"
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
    
    let kPubKeyField = "pubkey"

    /*!
    Use this to set the messages to be displayed
    */
    var messages: [LGChatMessage] = []
    var opponentImage: UIImage?
    var peerPublicKey : String?
    var peer : String?
    var isNewMessage : Bool = false
    weak var delegate: LGChatControllerDelegate?
    var rootView : ViewController!
    
    // MARK: Private Properties
    private let sizingCell = LGChatMessageCell()
    private let tableView: UITableView = UITableView()
    private let navBar: UINavigationBar = UINavigationBar()
    private let toField: UITextField = UITextField()
    private let chatInput = LGChatInput()
    private var bottomChatInputConstraint: NSLayoutConstraint!
    private let contaggedManager: ContaggedManager = ContaggedManager();


    //MARK: UITextViewDelegate
    func textFieldDidBeginEditing(textField: UITextField!) {
        getContact()
    }

    // MARK: ContaggedUnknownPersonDelegate
    func didResolveToPerson(person: SwiftAddressBookPerson?){
        println(person?.firstName)
    }

    // MARK: ContaggedPickerDelegate
    func peoplePickerNavigationControllerDidCancel(){
        // do nothing?
    }
    
    func personSelected(person: SwiftAddressBookPerson?){
        peerPublicKey = contaggedManager.findValueForPerson(kPubKeyField, person: person)?
        peer = contaggedManager.getPeerName(kPubKeyField, value: peerPublicKey!);
        messages = self.rootView.getMessagesForPublicKey(peerPublicKey!)

        if let ppk = peerPublicKey{
            isNewMessage = false;
        } else {
            isNewMessage = true;
        }

        setup();
    }
    


    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        contaggedManager.pickerDelegate = self
        contaggedManager.unknownPersonDelegate = self
        contaggedManager.viewController = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.listenForKeyboardChanges()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollToBottom()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.unregisterKeyboardObservers()
    }
    
    deinit {
        /*
        Need to remove delegate and datasource or they will try to send scrollView messages.
        */
        self.tableView.delegate = nil
        self.tableView.dataSource = nil
    }
    
    // MARK: Setup
    
    private func setup() {
        self.view.backgroundColor = UIColor.whiteColor()
        self.setupTableView()
        self.setupNavView()
        if self.isNewMessage {
            self.setupToFieldView()
        }
        self.setupChatInput()
        self.setupLayoutConstraints()
    }
    
    private func setupNavView() {
        navBar.delegate = self
        navBar.frame = CGRectMake(0, 0, self.view.frame.width, 64)
        // Create a navigation item with a title
        let navigationItem = UINavigationItem()
        
        if !self.isNewMessage {
            navigationItem.title = peer
        } else {
            navigationItem.title = "New Message"
        }
        
        // Create left and right button for navigation item
        let rightButton = UIBarButtonItem(title: "New Contact", style:UIBarButtonItemStyle.Bordered, target: self, action: "addNewContact")
        let leftButton = UIBarButtonItem(title: "Back", style: .Plain, target: self, action:"dismissSelf")
        
        // Create two buttons for the navigation item
        if (isNewMessage) {
            navigationItem.rightBarButtonItem = rightButton
        }

        navigationItem.leftBarButtonItem = leftButton
        
        // Assign the navigation item to the navigation bar
        navBar.items = [navigationItem]
        
        self.view.addSubview(navBar)
    }
    
    func getContact() {
        contaggedManager.pickContact(kPubKeyField)
    }
    
    func addNewContact(){
        //TODO: something
    }

    private func setupToFieldView() {
        var paddingView = UILabel(frame: CGRectMake(0, 64, 40, 50)) // hacky formatting, sorry
        paddingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05)
        paddingView.text = "   To:"
        paddingView.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        self.view.addSubview(paddingView)
        toField.frame = CGRectMake(40, 64, self.view.frame.width, 50)
        toField.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05)
        toField.actionsForTarget("toggleToFieldExists", forControlEvent: UIControlEvents.AllEditingEvents)
        self.view.addSubview(toField)
        toField.delegate = self
    }
    
//    public func toggleToFieldExists() {
//        println("number of elements ")
//        if countElements(toField.text) > 0 {
//            chatInput.hasCustomDestination = true
//        } else {
//            chatInput.hasCustomDestination = false
//        }
//    }
    
    public func dismissSelf() {
        self.rootView?.fetchMessages()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func setupTableView() {
        tableView.allowsSelection = false
        tableView.separatorStyle = .None
        tableView.registerClass(LGChatMessageCell.classForCoder(), forCellReuseIdentifier: "identifier")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        
        self.view.addSubview(tableView)
    }
    
    private func setupChatInput() {
        chatInput.delegate = self
        if (self.isNewMessage) {
            chatInput.isNewMessage = true
        }
        self.view.addSubview(chatInput)
    }
    
    private func setupLayoutConstraints() {
        chatInput.setTranslatesAutoresizingMaskIntoConstraints(false)
        tableView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.view.addConstraints(self.chatInputConstraints())
        self.view.addConstraints(self.tableViewConstraints())
        
    }
    
    private func chatInputConstraints() -> [NSLayoutConstraint] {
        self.bottomChatInputConstraint = NSLayoutConstraint(item: chatInput, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        let leftConstraint = NSLayoutConstraint(item: chatInput, attribute: .Left, relatedBy: .Equal, toItem: self.view, attribute: .Left, multiplier: 1.0, constant: 0.0)
        let rightConstraint = NSLayoutConstraint(item: chatInput, attribute: .Right, relatedBy: .Equal, toItem: self.view, attribute: .Right, multiplier: 1.0, constant: 0.0)
        return [leftConstraint, self.bottomChatInputConstraint, rightConstraint]
    }
    
    private func tableViewConstraints() -> [NSLayoutConstraint] {
        let leftConstraint = NSLayoutConstraint(item: tableView, attribute: .Left, relatedBy: .Equal, toItem: self.view, attribute: .Left, multiplier: 1.0, constant: 0.0)
        let rightConstraint = NSLayoutConstraint(item: tableView, attribute: .Right, relatedBy: .Equal, toItem: self.view, attribute: .Right, multiplier: 1.0, constant: 0.0)
        var topConst = NSLayoutConstraint(item: tableView, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1.0, constant: 64)
        if isNewMessage {
            topConst = NSLayoutConstraint(item: tableView, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1.0, constant: 114)
        }
        let topConstraint = topConst
        let bottomConstraint = NSLayoutConstraint(item: tableView, attribute: .Bottom, relatedBy: .Equal, toItem: chatInput, attribute: .Top, multiplier: 1.0, constant: 0)
        return [rightConstraint, leftConstraint, topConstraint, bottomConstraint]
    }
    
    // MARK: Keyboard Notifications
    
    private func listenForKeyboardChanges() {
        let defaultCenter = NSNotificationCenter.defaultCenter()
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
            defaultCenter.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
            defaultCenter.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        } else {
            defaultCenter.addObserver(self, selector: "keyboardWillChangeFrame:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        }
    }
    
    private func unregisterKeyboardObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: iOS 8 Keyboard Animations
    
    func keyboardWillChangeFrame(note: NSNotification) {
        
        /*
        NOTE: For iOS 8 Only, will cause autolayout issues in iOS 7
        */
        
        let keyboardAnimationDetail = note.userInfo!
        let duration = keyboardAnimationDetail[UIKeyboardAnimationDurationUserInfoKey] as NSTimeInterval
        var keyboardFrame = (keyboardAnimationDetail[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        if let window = self.view.window {
            keyboardFrame = window.convertRect(keyboardFrame, toView: self.view)
        }
        let animationCurve = keyboardAnimationDetail[UIKeyboardAnimationCurveUserInfoKey] as UInt
        
        self.tableView.scrollEnabled = false
        self.tableView.decelerationRate = UIScrollViewDecelerationRateFast
        self.view.layoutIfNeeded()
        var chatInputOffset = -(CGRectGetHeight(self.view.bounds) - CGRectGetMinY(keyboardFrame))
        if chatInputOffset > 0 {
            chatInputOffset = 0
        }
        self.bottomChatInputConstraint.constant = chatInputOffset
        UIView.animateWithDuration(duration, delay: 0.0, options: UIViewAnimationOptions(animationCurve), animations: { () -> Void in
            self.view.layoutIfNeeded()
            self.scrollToBottom()
            }, completion: {(finished) -> () in
                self.tableView.scrollEnabled = true
                self.tableView.decelerationRate = UIScrollViewDecelerationRateNormal
        })
    }
    
    // MARK: iOS 7 Compatibility Keyboard Animations
    func keyboardWillShow(note: NSNotification) {
        let keyboardAnimationDetail = note.userInfo!
        let duration = keyboardAnimationDetail[UIKeyboardAnimationDurationUserInfoKey] as NSTimeInterval
        let keyboardFrame = (keyboardAnimationDetail[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        let animationCurve = keyboardAnimationDetail[UIKeyboardAnimationCurveUserInfoKey] as UInt
        let keyboardHeight = UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication().statusBarOrientation) ? CGRectGetHeight(keyboardFrame) : CGRectGetWidth(keyboardFrame)
        
        self.tableView.scrollEnabled = false
        self.tableView.decelerationRate = UIScrollViewDecelerationRateFast
        self.view.layoutIfNeeded()
        self.bottomChatInputConstraint.constant = -keyboardHeight
        UIView.animateWithDuration(duration, delay: 0.0, options: UIViewAnimationOptions(animationCurve), animations: { () -> Void in
            self.view.layoutIfNeeded()
            self.scrollToBottom()
            }, completion: {(finished) -> () in
                self.tableView.scrollEnabled = true
                self.tableView.decelerationRate = UIScrollViewDecelerationRateNormal
        })
    }
    
    func keyboardWillHide(note: NSNotification) {
        let keyboardAnimationDetail = note.userInfo!
        let duration = keyboardAnimationDetail[UIKeyboardAnimationDurationUserInfoKey] as NSTimeInterval
        let animationCurve = keyboardAnimationDetail[UIKeyboardAnimationCurveUserInfoKey] as UInt
        self.tableView.scrollEnabled = false
        self.tableView.decelerationRate = UIScrollViewDecelerationRateFast
        self.view.layoutIfNeeded()
        self.bottomChatInputConstraint.constant = 0.0
        UIView.animateWithDuration(duration, delay: 0.0, options: UIViewAnimationOptions(animationCurve), animations: { () -> Void in
            self.view.layoutIfNeeded()
            self.scrollToBottom()
            }, completion: {(finished) -> () in
                self.tableView.scrollEnabled = true
                self.tableView.decelerationRate = UIScrollViewDecelerationRateNormal
        })
    }
    
    // MARK: Scrolling
    private func scrollToBottom() {
        if messages.count > 0 {
            var lastItemIdx = self.tableView.numberOfRowsInSection(Constants.MessagesSection) - 1
            if lastItemIdx < 0 {
                lastItemIdx = 0
            }
            let lastIndexPath = NSIndexPath(forRow: lastItemIdx, inSection: Constants.MessagesSection)
            self.tableView.scrollToRowAtIndexPath(lastIndexPath, atScrollPosition: .Bottom, animated: false)
        }
    }
    
    // MARK: New messages
    func addNewMessage(message: LGChatMessage) {
        messages += [message]
        tableView.reloadData()
        self.scrollToBottom()
        self.delegate?.chatController?(self, didAddNewMessage: message)
    }
    
    // MARK: SwiftChatInputDelegate
    
    func chatInputDidResize(chatInput: LGChatInput) {
        self.scrollToBottom()
    }
    
    func chatInput(chatInput: LGChatInput, didSendMessage message: String) {
        let newMessage = LGChatMessage(content: message, sentBy: .User)
        var shouldSendMessage = true
        if let value = self.delegate?.shouldChatController?(self, addMessage: newMessage) {
            shouldSendMessage = value
        }
        
        if shouldSendMessage {
            
            var recipient : String = self.peer!
            var recipientPublicKey : String = self.peerPublicKey!
            var actualPubKey = NSData(base64EncodedString: recipientPublicKey, options: NSDataBase64DecodingOptions.allZeros)!
            PtoPProtocol.sharedInstance.send(message.dataUsingEncoding(NSUTF8StringEncoding)!, recipient: actualPubKey)
            
            if let moc = self.managedObjectContext {
                Message.createInManagedObjectContext(moc,
                    peer: recipient,
                    publicKey: NSString(data: actualPubKey, encoding: NSUTF8StringEncoding)!,
                    text: message,
                    outgoing: true,
                    contactDate: NSDate()
                )
            }
            var error : NSError? = nil
            if !self.managedObjectContext!.save(&error) {
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
            self.addNewMessage(newMessage)
        }
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let padding: CGFloat = 10.0
        sizingCell.bounds.size.width = CGRectGetWidth(self.view.bounds)
        let height = self.sizingCell.setupWithMessage(messages[indexPath.row]).height + padding;
        return height
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.dragging {
            self.chatInput.textView.resignFirstResponder()
        }
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("identifier", forIndexPath: indexPath) as LGChatMessageCell
        let message = self.messages[indexPath.row]
        cell.opponentImageView.image = message.sentBy == .Opponent ? self.opponentImage : nil
        cell.setupWithMessage(message)
        return cell;
    }
    
}

// MARK: Chat Input
protocol LGChatInputDelegate : class {
    func chatInputDidResize(chatInput: LGChatInput)
    func chatInput(chatInput: LGChatInput, didSendMessage message: String)
}

class LGChatInput : UIView, LGStretchyTextViewDelegate {
    
    // MARK: Styling
    
    struct Appearance {
        static var includeBlur = true
        static var tintColor = UIColor(red: 0.0, green: 120 / 255.0, blue: 255 / 255.0, alpha: 1.0)
        static var backgroundColor = UIColor.whiteColor()
        static var textViewFont = UIFont.systemFontOfSize(17.0)
        static var textViewTextColor = UIColor.darkTextColor()
        static var textViewBackgroundColor = UIColor.whiteColor()
    }
    
    /*
    These methods are included for ObjC compatibility.  If using Swift, you can set the Appearance variables directly.
    */
    
    class func setAppearanceIncludeBlur(includeBlur: Bool) {
        Appearance.includeBlur = includeBlur
    }
    
    class func setAppearanceTintColor(color: UIColor) {
        Appearance.tintColor = color
    }
    
    class func setAppearanceBackgroundColor(color: UIColor) {
        Appearance.backgroundColor = color
    }
    
    class func setAppearanceTextViewFont(textViewFont: UIFont) {
        Appearance.textViewFont = textViewFont
    }
    
    class func setAppearanceTextViewTextColor(textColor: UIColor) {
        Appearance.textViewTextColor = textColor
    }
    
    class func setAppearanceTextViewBackgroundColor(color: UIColor) {
        Appearance.textViewBackgroundColor = color
    }
    
    // MARK: Public Properties
    
    var textViewInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    var isNewMessage : Bool = false
    var hasCustomDestination : Bool = false
    weak var delegate: LGChatInputDelegate?
    
    // MARK: Private Properties
    
    private let textView = LGStretchyTextView()
    private let sendButton = UIButton.buttonWithType(.System) as UIButton
    private let blurredBackgroundView: UIToolbar = UIToolbar()
    private var heightConstraint: NSLayoutConstraint!
    private var sendButtonHeightConstraint: NSLayoutConstraint!
    
    // MARK: Initialization
    
    override init(frame: CGRect = CGRectZero) {
        super.init(frame: frame)
        self.setup()
        self.stylize()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    
    func setup() {
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.setupSendButton()
        self.setupSendButtonConstraints()
        self.setupTextView()
        self.setupTextViewConstraints()
        self.setupBlurredBackgroundView()
        self.setupBlurredBackgroundViewConstraints()
    }
    
    func setupTextView() {
        textView.bounds = UIEdgeInsetsInsetRect(self.bounds, self.textViewInsets)
        textView.stretchyTextViewDelegate = self
        textView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
        self.styleTextView()
        self.addSubview(textView)
    }
    
    func styleTextView() {
        textView.layer.rasterizationScale = UIScreen.mainScreen().scale
        textView.layer.shouldRasterize = true
        textView.layer.cornerRadius = 5.0
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor(white: 0.0, alpha: 0.2).CGColor
    }
    
    func setupSendButton() {
        self.sendButton.enabled = false
        self.sendButton.setTitle("Send", forState: .Normal)
        self.sendButton.addTarget(self, action: "sendButtonPressed:", forControlEvents: .TouchUpInside)
        self.sendButton.bounds = CGRect(x: 0, y: 0, width: 40, height: 1)
        self.addSubview(sendButton)
    }
    
    func setupSendButtonConstraints() {
        self.sendButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.sendButton.removeConstraints(self.sendButton.constraints())
        
        // TODO: Fix so that button height doesn't change on first newLine
        let rightConstraint = NSLayoutConstraint(item: self, attribute: .Right, relatedBy: .Equal, toItem: self.sendButton, attribute: .Right, multiplier: 1.0, constant: textViewInsets.right)
        let bottomConstraint = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: self.sendButton, attribute: .Bottom, multiplier: 1.0, constant: textViewInsets.bottom)
        let widthConstraint = NSLayoutConstraint(item: self.sendButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 40)
        sendButtonHeightConstraint = NSLayoutConstraint(item: self.sendButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 30)
        self.addConstraints([sendButtonHeightConstraint, widthConstraint, rightConstraint, bottomConstraint])
    }
    
    func setupTextViewConstraints() {
        self.textView.setTranslatesAutoresizingMaskIntoConstraints(false)
        let topConstraint = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: self.textView, attribute: .Top, multiplier: 1.0, constant: -textViewInsets.top)
        let leftConstraint = NSLayoutConstraint(item: self, attribute: .Left, relatedBy: .Equal, toItem: self.textView, attribute: .Left, multiplier: 1, constant: -textViewInsets.left)
        let bottomConstraint = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: self.textView, attribute: .Bottom, multiplier: 1, constant: textViewInsets.bottom)
        let rightConstraint = NSLayoutConstraint(item: self.textView, attribute: .Right, relatedBy: .Equal, toItem: self.sendButton, attribute: .Left, multiplier: 1, constant: -textViewInsets.right)
        heightConstraint = NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1.00, constant: 40)
        self.addConstraints([topConstraint, leftConstraint, bottomConstraint, rightConstraint, heightConstraint])
    }
    
    func setupBlurredBackgroundView() {
        self.addSubview(self.blurredBackgroundView)
        self.sendSubviewToBack(self.blurredBackgroundView)
    }
    
    func setupBlurredBackgroundViewConstraints() {
        self.blurredBackgroundView.setTranslatesAutoresizingMaskIntoConstraints(false)
        let topConstraint = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: self.blurredBackgroundView, attribute: .Top, multiplier: 1.0, constant: 0)
        let leftConstraint = NSLayoutConstraint(item: self, attribute: .Left, relatedBy: .Equal, toItem: self.blurredBackgroundView, attribute: .Left, multiplier: 1.0, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: self.blurredBackgroundView, attribute: .Bottom, multiplier: 1.0, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: self, attribute: .Right, relatedBy: .Equal, toItem: self.blurredBackgroundView, attribute: .Right, multiplier: 1.0, constant: 0)
        self.addConstraints([topConstraint, leftConstraint, bottomConstraint, rightConstraint])
    }
    
    // MARK: Styling
    
    func stylize() {
        self.textView.backgroundColor = Appearance.textViewBackgroundColor
        self.sendButton.tintColor = Appearance.tintColor
        self.textView.tintColor = Appearance.tintColor
        self.textView.font = Appearance.textViewFont
        self.textView.textColor = Appearance.textViewTextColor
        self.blurredBackgroundView.hidden = !Appearance.includeBlur
        self.backgroundColor = Appearance.backgroundColor
    }
    
    // MARK: StretchyTextViewDelegate
    
    func stretchyTextViewDidChangeSize(textView: LGStretchyTextView) {
        let textViewHeight = CGRectGetHeight(textView.bounds)
        if countElements(textView.text) == 0 {
            self.sendButtonHeightConstraint.constant = textViewHeight
        }
        let targetConstant = textViewHeight + textViewInsets.top + textViewInsets.bottom
        self.heightConstraint.constant = targetConstant
        self.delegate?.chatInputDidResize(self)
    }
    
    func stretchyTextView(textView: LGStretchyTextView, validityDidChange isValid: Bool) {
        self.sendButton.enabled = isValid
    }
    
    // MARK: Button Presses
    
    func sendButtonPressed(sender: UIButton) {
        if countElements(self.textView.text) > 0 { // && (!self.isNewMessage || self.hasCustomDestination) {
            self.delegate?.chatInput(self, didSendMessage: self.textView.text)
            self.textView.text = ""
        }
    }
}

// MARK: Text View

@objc protocol LGStretchyTextViewDelegate {
    func stretchyTextViewDidChangeSize(chatInput: LGStretchyTextView)
    optional func stretchyTextView(textView: LGStretchyTextView, validityDidChange isValid: Bool)
}

class LGStretchyTextView : UITextView, UITextViewDelegate {
    
    // MARK: Delegate
    
    weak var stretchyTextViewDelegate: LGStretchyTextViewDelegate?
    
    // MARK: Public Properties
    
    var maxHeightPortrait: CGFloat = 160
    var maxHeightLandScape: CGFloat = 60
    var maxHeight: CGFloat {
        get {
            return UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication().statusBarOrientation) ? maxHeightPortrait : maxHeightLandScape
        }
    }
    // MARK: Private Properties
    
    private var maxSize: CGSize {
        get {
            return CGSize(width: CGRectGetWidth(self.bounds), height: self.maxHeightPortrait)
        }
    }
    
    private var _isValid = false
    private var isValid: Bool {
        get {
            return _isValid
        }
        set {
            if _isValid != newValue {
                _isValid = newValue
                self.stretchyTextViewDelegate?.stretchyTextView?(self, validityDidChange: _isValid)
            }
        }
    }
    
    private let sizingTextView = UITextView()
    
    // MARK: Property Overrides
    
    override var contentSize: CGSize {
        didSet {
            self.resizeAndAlign()
        }
    }
    
    override var font: UIFont! {
        didSet {
            sizingTextView.font = font
        }
    }
    
    override var textContainerInset: UIEdgeInsets {
        didSet {
            sizingTextView.textContainerInset = textContainerInset
        }
    }
    
    // MARK: Initializers
    
    override init(frame: CGRect = CGRectZero, textContainer: NSTextContainer? = nil) {
        super.init(frame: frame, textContainer: textContainer);
        self.setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    
    func setup() {
        self.font = UIFont.systemFontOfSize(17.0)
        self.textContainerInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        self.delegate = self
    }
    
    // MARK: Resize & Align
    
    func resizeAndAlign() {
        self.resize()
        self.align()
    }
    
    // MARK: Sizing
    
    func resize() {
        self.bounds.size.height = self.targetHeight()
        self.stretchyTextViewDelegate?.stretchyTextViewDidChangeSize(self)
    }
    
    func targetHeight() -> CGFloat {
        
        /*
        There is an issue when calling `sizeThatFits` on self that results in really weird drawing issues with aligning line breaks ("\n").  For that reason, we have a textView whose job it is to size the textView. It's excess, but apparently necessary.  If there's been an update to the system and this is no longer necessary, or if you find a better solution. Please remove it and submit a pull request as I'd rather not have it.
        */
        
        sizingTextView.text = self.text
        let targetSize = sizingTextView.sizeThatFits(maxSize)
        var targetHeight = targetSize.height
        let maxHeight = self.maxHeight
        return targetHeight < maxHeight ? targetHeight : maxHeight
    }
    
    // MARK: Alignment
    
    func align() {
        
        let caretRect: CGRect = self.caretRectForPosition(self.selectedTextRange?.end)
        
        let topOfLine = CGRectGetMinY(caretRect)
        let bottomOfLine = CGRectGetMaxY(caretRect)
        
        let contentOffsetTop = self.contentOffset.y
        let bottomOfVisibleTextArea = contentOffsetTop + CGRectGetHeight(self.bounds)
        
        /*
        If the caretHeight and the inset padding is greater than the total bounds then we are on the first line and aligning will cause bouncing.
        */
        
        let caretHeightPlusInsets = CGRectGetHeight(caretRect) + self.textContainerInset.top + self.textContainerInset.bottom
        if caretHeightPlusInsets < CGRectGetHeight(self.bounds) {
            var overflow: CGFloat = 0.0
            if topOfLine < contentOffsetTop + self.textContainerInset.top {
                overflow = topOfLine - contentOffsetTop - self.textContainerInset.top
            } else if bottomOfLine > bottomOfVisibleTextArea - self.textContainerInset.bottom {
                overflow = (bottomOfLine - bottomOfVisibleTextArea) + self.textContainerInset.bottom
            }
            self.contentOffset.y += overflow
        }
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChangeSelection(textView: UITextView) {
        self.align()
    }
    
    func textViewDidChange(textView: UITextView) {
        
        // TODO: Possibly filter spaces and newlines
        
        self.isValid = countElements(textView.text) > 0
    }
}
