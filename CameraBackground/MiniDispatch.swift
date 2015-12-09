//
//  MiniDispatch.swift
//  Minimal GCD convenience layer. Dispatch succinctly.
//
//  Created by Yonat Sharon on 09.12.2015.
//  Copyright © 2015 Yonat Sharon. All rights reserved.
//

import Foundation

func async_main(block: dispatch_block_t) {
    dispatch_async(dispatch_get_main_queue(), block)
}

func sync_main(block: dispatch_block_t) {
    if NSThread.isMainThread() {
        block()
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), block)
    }
}

// thanks to http://stackoverflow.com/a/24318861/1176162
func delay(delay: NSTimeInterval, block: ()->Void) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), block)
}

