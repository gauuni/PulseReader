//
//  MonitorController.swift
//  Optical-Pulse-Reader
//
//  Created by Gabe Richman on 23/11/15.
//  Copyright © 2015 Baby Carrot Productions. All rights reserved.
//

import UIKit

enum State: Int
{
    case kIncreasing,kDecreasing
}

class MonitorController: NSObject {

   private var lastPeakDate: NSDate?
   private var lastPeakValue: Double?
   private var lastDate: NSDate?
   private var lastValue: CGFloat?
   private var maxDiff: Double?
   private var minDiff: Double?
   private var previousDiff: Double?
   private var data: [AnyObject]?
   private var state: State?
   private var diffState: State?
   private var estimatedRate: NSNumber?
   private var incrementCount: Int?
   private var decrementCount: Int?
   private var lastSample: NSMutableArray?
    
    class func getInstance() -> AnyObject {

        let shared: MonitorController? = nil
        if shared == nil {
            //shared = self.init()
            shared!.lastPeakDate = NSDate()
            shared!.maxDiff = -999
            shared!.minDiff = 999
            shared!.lastValue = 0
            shared!.lastSample = NSMutableArray(capacity: 0)
        }
        
        return shared!
    }
    
    func update(redComponent: CGFloat, greenComponent: CGFloat, blueComponent: CGFloat) -> Double{
        
        // Estimate heart rate from RGB components and previous values

        if greenComponent < 0.95 && greenComponent > 0.05
        {
            
            if lastValue == nil
            {
                lastValue = 0
            }
            
            let diff: CGFloat = fabs(greenComponent - lastValue!)
            
            print("Value: %f, lastvalue: %f, Diff: %f, Inc: %d, Dec: %d", greenComponent,lastValue,diff,incrementCount,decrementCount)
            
            if diff < 0.00005
            {
                
            }
            else
            {
                if state == State.kIncreasing
                {
                    if greenComponent < lastValue
                    {
                        state = State.kDecreasing
                        
                        if decrementCount > 2
                        {
                            let now: NSDate = NSDate()
                            let interval: Double = now.timeIntervalSinceDate(lastPeakDate!)
                            let calcRate: Double = 60 / interval
                            if calcRate < 150 && calcRate > 40
                            {
                                print("------> PEAKED @ %d, HR:%f", decrementCount, calcRate)
                                let rate: NSNumber = NSNumber(double: calcRate)
                                
                                // Calulate last sample average
                                
                                let sampleCount: Int = 6
                                if lastSample!.count < sampleCount
                                {
                                    lastSample!.addObject(rate)
                                }
                                else
                                {
                                    let range = NSMakeRange(1, sampleCount-1)
                                    
                                    lastSample = NSMutableArray(array: lastSample!.subarrayWithRange(range))
                                    lastSample!.addObject(rate)
                                    
                                    var sum: Float = Float(0)
                                    
                                    for number in lastSample! {
                                        sum = sum + (number as! NSNumber).floatValue
                                    }
                                    
                                    let averageRate :NSNumber = NSNumber(float: sum / Float(sampleCount))
                                    
                                    NSNotificationCenter .defaultCenter().postNotificationName("peaked", object:averageRate)
                                }
                            }
                            lastPeakDate = now
                        }
                        decrementCount = 0
                    }else{
                        decrementCount!++
                    }
                    
                    lastValue = greenComponent
                    
                }else{
                    
                    if state == State.kDecreasing{
                        
                        if greenComponent > lastValue{
                            
                            state = State.kIncreasing
                            
                            if incrementCount > 2{
                                
                            }
                            
                            incrementCount = 0
                        }else{
                            incrementCount!++
                        }
                        
                        lastValue = greenComponent
                    }
                }
            }
        }
        return 0
    }
}
