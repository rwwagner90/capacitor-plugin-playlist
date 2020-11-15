//  Converted to Swift 5.3 by Swiftify v5.3.19197 - https://swiftify.com/
//
//  AVBidirectionalQueuePlayer.swift
//  IntervalPlayer
//
//  Created by Daniel Giovannelli on 2/18/13.
//  This class subclasses AVQueuePlayer to create a class with the same functionality as AVQueuePlayer
//  but with the added ability to go backwards in the queue - a function that is impossible in a normal
//  AVQueuePlayer since items on the queue are destroyed when they are finished playing.
//
//  IMPORTANT NOTE: This version of AVQueuePlayer assumes that ARC IS ENABLED. If ARC is NOT enabled and you
//  use this library, you'll get memory leaks on the two fields that have been added to the class, int
//  nowPlayingIndex and NSArray itemsForPlayer.
//
//  Note also that this classrequires that the AVFoundation framework be included in your project.

//
//  AVBidirectionalQueuePlayer.swift
//  IntervalPlayer
//
//  Created by Daniel Giovannelli on 2/18/13.
//
//  2014/07/16  (JRTaal) Greatly simplified and cleaned up code, meanwhile fixed number of bugs.
//                       Renamed to more apt AVBidirectionalQueuePlayer
//  2018/03/29  (codinronan) expanded feature set, added accessors and additional convenience methods & events.
//

import AVFoundation

let AVBidirectionalQueueAddedItem = "AVBidirectionalQueuePlayer.AddedItem"
let AVBidirectionalQueueAddedAllItems = "AVBidirectionalQueuePlayer.AddedAllItems"
let AVBidirectionalQueueRemovedItem = "AVBidirectionalQueuePlayer.RemovedItem"
let AVBidirectionalQueueCleared = "AVBidirectionalQueuePlayer.Cleared"
var offset = CMTimeSubtract(time, marker)

class AVBidirectionalQueuePlayer: AVQueuePlayer {
    private var _itemsForPlayer: [AnyHashable]?
    var itemsForPlayer: [AnyHashable]? {
        get {
            if _itemsForPlayer == nil {
                _itemsForPlayer = []
            }
            return _itemsForPlayer
        }
        set(itemsForPlayer) {
            removeAllItems()
            insertAllItems((itemsForPlayer)!)
        }
    }
    var: currentIndex?

    // Two methods need to be added to the AVQueuePlayer: one which will play the last song in the queue, and one which will return if the queue is at the beginning (in case the user wishes to implement special behavior when a queue is at its first item, such as restarting a song). A getIndex method to return the current index is also provided.
    // NEW METHODS

    func playPreviousItem() {
        // This function is the meat of this library: it allows for going backwards in an AVQueuePlayer,
        // basically by clearing the player and repopulating it from the index of the last item played.
        // It should be noted that if the player is on its first item, this function will do nothing. It will
        // not restart the item or anything like that; if you want that functionality you can implement it
        // yourself fairly easily using the isAtBeginning method to test if the player is at its start.
        var tempNowPlayingIndex: Int? = nil
        if let currentItem = currentItem {
            tempNowPlayingIndex = itemsForPlayer?.firstIndex(of: currentItem) ?? NSNotFound
        }

        if (tempNowPlayingIndex ?? 0) > 0 && tempNowPlayingIndex != NSNotFound {
            let currentrate = rate
            if currentrate != 0.0 {
                pause()
            }

            // Note: it is necessary to have seekToTime called twice in this method, once before and once after re-making the array. If it is not present before, the player will resume from the same spot in the next item when the previous item finishes playing; if it is not present after, the previous item will be played from the same spot that the current item was on.
            seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)

            // The next two lines are necessary since RemoveAllItems resets both the nowPlayingIndex and _itemsForPlayer
            let tempPlaylist = itemsForPlayer
            super.removeAllItems()

            var offset = 1
            while true {
                let _it = tempPlaylist?[(tempNowPlayingIndex ?? 0) - offset] as? AVPlayerItem
                if _it?.error != nil {
                    offset += 1
                }
                break
            }

            for i in ((tempNowPlayingIndex ?? 0) - offset)..<(tempPlaylist?.count ?? 0) {
                let item = tempPlaylist?[i] as? AVPlayerItem
                item?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
                if let item = item {
                    super.insert(item, after: nil)
                }
            }

            // Not a typo; see above comment
            seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)

            // [self play];
            rate = currentrate
        } else if tempNowPlayingIndex == 0 {
            let currentrate = rate
            if currentrate != 0.0 {
                pause()
            }
            seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            // [self play];
            rate = currentrate
        }
    }

    func isAtBeginning() -> Bool {
        // This function simply returns whether or not the AVBidirectionalQueuePlayer is at the first item. This is
        // useful for implementing custom behavior if the user tries to play a previous item at the start of
        // the queue (such as restarting the item).
        return currentIndex() == 0
    }

    func isAtEnd() -> Bool {
        if currentIndex() >= (itemsForPlayer?.count ?? 0) - 1 || currentItem == nil {
            return true
        }
        return false
    }

    var isPlaying: Bool {
        return rate != 0.0
    }

    func currentTimeOffsetInQueue() -> CMTime {
        var timeOffset: CMTime = .zero
        let currentIndex = self.currentIndex()
        if currentIndex == NSNotFound {
            return .invalid
        }
        var item: AVPlayerItem? = nil
        let idx: Int
        for idx in 0..<currentIndex {
            item = itemsForPlayer?[idx] as? AVPlayerItem
            if let duration = item?.duration {
                timeOffset = CMTimeAdd(timeOffset, duration)
            }
        }
        if (itemsForPlayer?.count ?? 0) > idx {
            item = itemsForPlayer?[idx] as? AVPlayerItem
            if let currentTime = item?.currentTime() {
                timeOffset = CMTimeAdd(timeOffset, currentTime)
            }
        }
        return timeOffset
    }

    func setCurrentIndex(_ newCurrentIndex: Int, completionHandler: @escaping (Bool) -> Void) {
        // NSUInteger tempNowPlayingIndex = [_itemsForPlayer indexOfObject: self.currentItem];

        // if (tempNowPlayingIndex != NSNotFound){
        let currentrate = rate
        if currentrate > 0 {
            pause()
        }

        // Note: it is necessary to have seekToTime called twice in this method, once before and once after re-making the area. If it is not present before, the player will resume from the same spot in the next item when the previous item finishes playing; if it is not present after, the previous item will be played from the same spot that the current item was on.
        seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        // The next two lines are necessary since RemoveAllItems resets both the nowPlayingIndex and _itemsForPlayer
        let tempPlaylist = itemsForPlayer
        super.removeAllItems()
        for i in newCurrentIndex..<(tempPlaylist?.count ?? 0) {
            let item = tempPlaylist?[i] as? AVPlayerItem
            item?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
            if let item = item {
                super.insert(item, after: nil)
            }
        }
        // Not a typo; see above comment
        seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: completionHandler)
        // }
    }

    func insertAllItems(_ itemsForPlayer: inout [AnyHashable]) {
        for item in itemsForPlayer {
            guard let item = item as? AVPlayerItem else {
                continue
            }
            insert(item, after: nil)
        }
        let center = NotificationCenter.default
        center.post(name: NSNotification.Name(AVBidirectionalQueueAddedAllItems), object: self, userInfo: [
            "items": itemsForPlayer
        ])
    }
/* The following methods of AVQueuePlayer are overridden by AVBidirectionalQueuePlayer:
 – initWithItems: to keep track of the array used to create the player
 + queuePlayerWithItems: to keep track of the array used to create the player
 – advanceToNextItem to update the now playing index
 – insertItem:afterItem: to update the now playing index
 – removeAllItems to update the now playing index
 – removeItem:  to update the now playing index
 */



    // CONSTRUCTORS
    override init() {
        super.init()
        itemsForPlayer = []
    }

    override init(items: [AVPlayerItem]) {
        // This function calls the constructor for AVQueuePlayer, then sets up the nowPlayingIndex to 0 and saves the array that the player was generated from as itemsForPlayer
        super.init(items: items)
        itemsForPlayer = items
    }

    convenience init(items: [AVPlayerItem]) {
        // This function just allocates space for, creates, and returns an AVBidirectionalQueuePlayer from an array.
        // Honestly I think having it is a bit silly, but since its present in AVQueuePlayer it needs to be
        // overridden here to ensure compatability.
        let playerToReturn = self.init(items: items)
    }

    func currentIndex() -> Int {
        // This method simply returns the now playing index
        if let currentItem = currentItem {
            return itemsForPlayer?.firstIndex(of: currentItem) ?? NSNotFound
        }
        return 0
    }

    func setCurrentIndex(_ currentIndex: Int) {
        setCurrentIndex(currentIndex, completionHandler: { _ in })
    }

    // OVERRIDDEN AVQUEUEPLAYER METHODS
    override func play() {
        if isAtEnd() {
            // we could add a flag here to indicate looping
            setCurrentIndex(0)
        }

        super.play()
    }

    override func removeAllItems() {
        // This does the same thing as the normal AVQueuePlayer removeAllItems, but clears our collection copy
        super.removeAllItems()
        itemsForPlayer?.removeAll()

        NotificationCenter.default.post(name: NSNotification.Name(AVBidirectionalQueueCleared), object: self, userInfo: nil)
    }

    override func remove(_ item: AVPlayerItem) {
        // This method calls the superclass to remove the items from the AVQueuePlayer itself, then removes
        // any instance of the item from the itemsForPlayer array. This mimics the behavior of removeItem on
        // AVQueuePlayer, which removes all instances of the item in question from the queue.
        // It also subtracts 1 from the nowPlayingIndex for every time the item shows up in the itemsForPlayer
        // array before the current value.
        super.remove(item)

        itemsForPlayer?.removeAll { $0 as AnyObject === item as AnyObject }
        NotificationCenter.default.post(name: NSNotification.Name(AVBidirectionalQueueRemovedItem), object: self, userInfo: [
            "item": item
        ])
    }

    override func insert(_ item: AVPlayerItem, after afterItem: AVPlayerItem?) {
        // This method calls the superclass to add the new item to the AVQueuePlayer, then adds that item to the
        // proper location in the itemsForPlayer array and increments the nowPlayingIndex if necessary.
        super.insert(item, after: afterItem)

        if let afterItem = afterItem {
            if itemsForPlayer?.contains(afterItem) ?? false {
                // AfterItem is non-nil
                if (itemsForPlayer?.firstIndex(of: afterItem) ?? NSNotFound) < (itemsForPlayer?.count ?? 0) - 1 {
                    itemsForPlayer?.insert(item, at: (itemsForPlayer?.firstIndex(of: afterItem) ?? NSNotFound) + 1)
                } else {
                    itemsForPlayer?.append(item)
                }
            } else {
                // afterItem is nil
                itemsForPlayer?.append(item)
            }
        }

        NotificationCenter.default.post(name: NSNotification.Name(AVBidirectionalQueueAddedItem), object: self, userInfo: [
            "item": item
        ])
    }
    /* The following methods of AVQueuePlayer are overridden by AVBidirectionalQueuePlayer:
     – initWithItems: to keep track of the array used to create the player
     + queuePlayerWithItems: to keep track of the array used to create the player
     – advanceToNextItem to update the now playing index
     – insertItem:afterItem: to update the now playing index
     – removeAllItems to update the now playing index
     – removeItem:  to update the now playing index
     */
}