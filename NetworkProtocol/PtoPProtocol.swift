//
//  PtoPProtocol.swift
//  SkipChat
//
//  Created by Katie Siegel on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

import Foundation
import MultipeerConnectivity
//import CommonCrypto

protocol NetworkProtocolDelegate {
    func receive(message : NSData, pubKey : NSData, time : NSDate)
}

private class BufferItem{
    var blob : NSData
    var timeToLive : UInt
    var receiveTime : NSDate
    var hash : NSData?
    
    public init(msgBlob:NSData, ttl:UInt, rTime:NSDate) {
        self.blob = msgBlob
        self.timeToLive = ttl
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
    let serviceType = "pf-connector"
//    var assistant : MCAdvertiserAssistant!
    var advertiser : MCNearbyServiceAdvertiser!
    var session : MCSession!
    var peerID: MCPeerID!
    var browser : MCNearbyServiceBrowser!
    
    var buffer : [NSData]
    var privateKey : NSData
    var publicKey : NSData
    var delegate : NetworkProtocolDelegate?
    
    public init(prKey : NSData, pubKey : NSData) {
        self.buffer = []
        self.privateKey = prKey
        self.publicKey = pubKey
        
        self.peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        
        super.init()
        
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
//        self.assistant = MCAdvertiserAssistant(serviceType:serviceType,
//            discoveryInfo:nil, session:self.session)
//        self.assistant.start() // start advertising
        
        self.advertiser = MCNearbyServiceAdvertiser(peer: self.peerID, discoveryInfo: nil, serviceType: serviceType)
        self.advertiser.delegate = self
        self.advertiser.startAdvertisingPeer()
        
        self.browser = MCNearbyServiceBrowser(peer: self.peerID, serviceType: serviceType)
        self.browser.delegate = self;
        self.browser.startBrowsingForPeers()
        
        println("initialized p2p")
    }
    
    // class methods
    public func send(message: NSData, recipient: NSData){
        var error : NSError?
        
//        self.session.sendData(msg, toPeers: self.session.connectedPeers,
//            withMode: MCSessionSendDataMode.Unreliable, error: &error)
        
        if error != nil {
            print("Error sending data: \(error?.localizedDescription)")
        }

    }
    
    public func logPeers() {
        var peers = self.session.connectedPeers
        for peer in peers {
            println("peer %@", peer)
        }
        
    }
    
    // MCSessionDelegate
    public func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        // Called when a peer sends an NSData to us
        
        // This needs to run on the main queue
        dispatch_async(dispatch_get_main_queue()) {
            
            var msg = NSString(data: data, encoding: NSUTF8StringEncoding)
            
//            self.updateChat(msg, fromPeer: peerID)
        }
    }
    
    public func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        // Called when a peer starts sending a file to us
    }
    
    public func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        // Called when a file has finished transferring from another peer
    }
    
    
    public func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        // Called when a peer establishes a stream with us

    }
    
    public func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        // Called when a connected peer changes state (for example, goes offline)
//        if state == MCSessionStateConnecting {
//            println("received MCSessionStateConnecting for " + peerID.displayName)
//        } else if state == MCSessionStateConnected {
//            println("received MCSessionStateConnected for " + peerID.displayName)
//        } else if state == MCSessionStateNotConnected {
//            println("received MCSessionStateNotConnected for " + peerID.displayName)
//        }
        println("started session with state %@", state)
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
        self.browser.invitePeer(peerID, toSession: self.session, withContext: nil, timeout: 30) // what is this constant TODO]
        println("found peer %@", peerID)
    }
    
    public func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        self.logPeers()
        println("lost peer %@", peerID)
    }
    
}