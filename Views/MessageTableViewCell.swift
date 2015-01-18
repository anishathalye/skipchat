//
//  MessageTableViewCell.swift
//  SkipChat
//
//  Created by Katie Siegel on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

import Foundation
import UIKit

class MessageTableViewCell: UITableViewCell {
    var messagePeerLabel = UILabel();
    var messageTextLabel = UILabel();
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        messagePeerLabel = UILabel(frame: CGRectMake(30, 10, self.bounds.size.width - 40, 20))
        messagePeerLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        messageTextLabel = UILabel(frame: CGRectMake(30, 20, self.bounds.size.width - 40, 40))
        messageTextLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        
        self.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        self.contentView.addSubview(messagePeerLabel)
        self.contentView.addSubview(messageTextLabel)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}