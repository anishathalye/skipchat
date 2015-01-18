//
//  PtoPProtocol.swift
//  SkipChat
//
//  Created by Katie Siegel on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol PtoPProtocolDelegate {
    func receive(message : NSData, pubKey : NSData, time : NSDate)
}

public class DataPacket : NSObject, NSCoding {
    var blob : NSData
    var timeToLive : Int
    
    public init(blob : NSData, ttl : Int) {
        self.blob = blob
        self.timeToLive = ttl
    }
    
    class func deserialize(dataInfo : NSData) -> DataPacket {
        return NSKeyedUnarchiver.unarchiveObjectWithData(dataInfo) as DataPacket
    }
    
    public func serialize() -> NSData {
        return NSKeyedArchiver.archivedDataWithRootObject(self)
    }
    
    public required init(coder aDecoder: NSCoder) {
        self.blob = aDecoder.decodeObjectForKey("blob") as NSData
        self.timeToLive = aDecoder.decodeIntegerForKey("ttl")
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(self.timeToLive, forKey: "ttl")
        aCoder.encodeObject(self.blob, forKey: "blob")
    }
    
    // returns false if dead
    public func decrementTTL() -> Bool {
        return --self.timeToLive > 0
    }
    
    public func equalsPacket(other : DataPacket) -> Bool {
        return self.blob.isEqualToData(other.blob)
    }
}

public class BufferItem {
    var packetItem : DataPacket
    var receiveTime : NSDate
    
    public init(packet : DataPacket, rTime:NSDate) {
        self.packetItem = packet
        self.receiveTime = rTime
    }

    
//    private func md5: NSData {
//        let str = self.cStringUsingEncoding(NSUTF8StringEncoding)
//        let strLen = CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
//        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
//        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
//        
//        CC_MD5(str!, strLen, result)
//        
//        var hash = NSMutableString()
//        for i in 0..<digestLen {
//            hash.appendFormat("%02x", result[i])
//        }
//        
//        result.dealloc(digestLen)
//        
//        return String(format: hash)
//    }
}

public class PtoPProtocol: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    let maxBufferLength = 20
    let defaultTTL = 10 // hops
    let serviceType = "pf-connector"
    var advertiser : MCNearbyServiceAdvertiser!
    var session : MCSession!
    var peerID: MCPeerID!
    var browser : MCNearbyServiceBrowser!
    
    var buffer : [BufferItem]
    var keyPair : KeyPair
    var delegate : PtoPProtocolDelegate?
    
    class var sharedInstance: PtoPProtocol {
        struct NetworkingLayer {
            static var instance: PtoPProtocol?
        }
        
        if NetworkingLayer.instance == nil {
            let defaults = NSUserDefaults.standardUserDefaults()
            var privateKey: NSData?
            var publicKey: NSData?
            privateKey = defaults.objectForKey("private_key") as? NSData
            publicKey = defaults.objectForKey("public_key") as? NSData
            if (privateKey == nil || publicKey == nil) {
                NSLog("Generating keypair...")
                let keyPair = Crypto.genKeyPair()
                privateKey = keyPair.privateKey
                publicKey = keyPair.publicKey
                defaults.setObject(privateKey, forKey: "private_key")
                defaults.setObject(publicKey, forKey: "public_key")
                NSLog("Done generating keypair")
            } else {
                NSLog("Using saved keypair")
            }
            NetworkingLayer.instance = PtoPProtocol(keyPair: KeyPair.fromPublicKey(publicKey!, andPrivateKey: privateKey!))
        }
        
        return NetworkingLayer.instance!
    }
    
    public init(keyPair: KeyPair) {
        self.buffer = []
        self.keyPair = keyPair;
        self.peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        
        super.init()
        
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
        
        self.advertiser = MCNearbyServiceAdvertiser(peer: self.peerID, discoveryInfo: nil, serviceType: serviceType)
        self.advertiser.delegate = self
        self.advertiser.startAdvertisingPeer()
        
        self.browser = MCNearbyServiceBrowser(peer: self.peerID, serviceType: serviceType)
        self.browser.delegate = self;
        self.browser.startBrowsingForPeers()
        
        println("initialized p2p")
    }
    
    // class methods
    public func send(message: NSData, recipient: NSData) {
        if let encrypted = Crypto.sign(message, with: self.keyPair, andEncryptFor: recipient) {
            let packet = DataPacket(blob: encrypted, ttl: defaultTTL)
            let item = BufferItem(packet: packet, rTime: NSDate())
            self.buffer.append(item)
            evict()
        }
    }
    
    public func logPeers() {
        var peers = self.session.connectedPeers
        for peer in peers {
            println("peer ", peer)
        }
        
    }
    
    // MCSessionDelegate
    public func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        // Called when a peer sends an NSData to us
        println("Received data")

        var packet = DataPacket.deserialize(data)
        var from: NSData? // public key of sender
        var time: NSDate?
        if let decrypted = Crypto.decrypt(packet.blob, with: self.keyPair, from: &from, at: &time) {
            println("Received message")
            if let delegate = self.delegate? {
                dispatch_async(dispatch_get_main_queue()) {
                    delegate.receive(decrypted, pubKey: from!, time: time!)
                }
            }
        } else {
            if packet.decrementTTL() {
                if !inBuffer(packet) {
                    println("Propogating message by adding to our buffer")
                    buffer.append(BufferItem(packet: packet, rTime: NSDate()))
                    evict()
                }
            }
        }
        
        println("buffer length: ", buffer.count)
        
    }
    
    public func inBuffer(packet : DataPacket) -> Bool {
        for item in self.buffer {
            if item.packetItem.equalsPacket(packet) {
                return true
            }
        }
        return false
    }
    
    // trim buffer to desired length
    public func evict() {
        let remove = buffer.count - maxBufferLength
        if (remove > 0) {
            buffer.removeRange(Range(start: 0, end: buffer.count - maxBufferLength))
        }
    }
    
    public func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        // Called when a peer starts sending a file to us
    }
    
    public func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        // Called when a file has finished transferring from another peer
        println("finished receiving ", resourceName)
    }
    
    
    public func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        // Called when a peer establishes a stream with us
        println("started receiving stream")
    }
    
    public func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        // Called when a connected peer changes state (for example, goes offline)
        switch (state) {
            case MCSessionState.NotConnected: println("Session changed state -> not connected")
            break;
            case MCSessionState.Connecting: println("Session changed state -> connecting")
            break;
            case MCSessionState.Connected: println("Session changed state -> connected")
            break;
        }
        
        if state == MCSessionState.Connected {
            var error : NSError?
            
            for item in self.buffer {
                self.session.sendData(item.packetItem.serialize(), toPeers: [peerID], withMode: MCSessionSendDataMode.Reliable, error: &error)
                
                if error != nil {
                    print("Error sending data: \(error?.localizedDescription)")
                }
                error = nil
            }
        }
        self.logPeers()
    }
    
    // MCNearbyServiceAdvertiserDelegate
    
    public func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        println("Advertiser " + self.peerID.displayName + " did not start advertising with error: " + error.localizedDescription);
    }
    
    public func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        println("Advertiser " + self.peerID.displayName + " received an invitation from " + peerID.displayName)
        invitationHandler(true, self.session);
        println("Advertiser " + self.peerID.displayName + " accepted invitation from " + peerID.displayName)
    }
    
    // MCNearbyServiceBrowser
    
    public func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        println("Browser " + self.peerID.displayName + " did not start browsing with error: " + error.localizedDescription)
    }
    
    public func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        self.browser.invitePeer(peerID, toSession: self.session, withContext: nil, timeout: 0)
        println("found peer %@", peerID)
        
    }
    
    public func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        self.logPeers()
        println("lost peer %@", peerID)
    }
    
}
