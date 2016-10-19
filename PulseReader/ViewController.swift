//
//  ViewController.swift
//  PulseReader
//
//  Created by Gabe Richman on 21/11/15.
//  Copyright © 2015 Vital. All rights reserved.
//

import UIKit
import AVFoundation
import GPUImage
//import MonitorController

class ViewController: UIViewController {
    
    @IBOutlet weak var heartRate: UILabel!
    
    @IBOutlet weak var heartView: GPUImageView!
    
    var videoCamera : GPUImageVideoCamera?
    
    var filter : GPUImageOutput?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "peaked:", name:"peaked", object: nil)
        
        // Setup controllers
        //var monitorController = MonitorController.getInstance()
        let monitor:MonitorController = MonitorController()

        // Turn flash light on
        self.turnTorchOn(true)
        
        // Setup video camera
       // var videoCamera : GPUImageVideoCamera?
        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset1280x720, cameraPosition: .Back)
        videoCamera!.outputImageOrientation = .Portrait;
        videoCamera?.horizontallyMirrorFrontFacingCamera = false
        videoCamera?.horizontallyMirrorRearFacingCamera = false
        
        // Setup average color filter
        
        let averageColor : GPUImageAverageColor = GPUImageAverageColor()
        averageColor.colorAverageProcessingFinishedBlock = {(redComponent:CGFloat , greenComponent:CGFloat, blueComponent:CGFloat, alphaComponent:CGFloat, frameTime:CMTime)->Void in
            
            monitor.update(redComponent, greenComponent: greenComponent, blueComponent: blueComponent)
        }
        
       //  Setup exposure filter, using max value to reduce noise
        let exposureFilter : GPUImageExposureFilter = GPUImageExposureFilter()
        exposureFilter.exposure = 8.0
        exposureFilter.addTarget(averageColor)
        
        filter = exposureFilter
        videoCamera?.addTarget((filter as! GPUImageInput))

        //videoCamera!.addTarget(filter)
        
        let filterView : GPUImageView = GPUImageView()
        filterView.frame = self.view.frame
        self.heartView.addSubview(filterView)
        filter?.addTarget(filterView)
        
        videoCamera?.startCameraCapture()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Turn flash light on
        self.turnTorchOn(false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func turnTorchOn(on: Bool){
    
        // check if flashlight available
        
        let captureDeviceClass : AnyClass? = NSClassFromString("AVCaptureDevice")!
        
            if(captureDeviceClass != nil){
                
                let device : AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
                
                if device.hasTorch && device.hasFlash{
                    
                    do {
                        try device.lockForConfiguration()
                        
                        if on == true {
                            device.torchMode = .On
                            device.flashMode = .On
                        } else {
                            device.torchMode = .Off
                            device.flashMode = .Off
                        }
                        
                        device.unlockForConfiguration()
                    } catch {
                        print("Torch could not be used")
                    }

//                   device.lockForConfiguration()
//                    
//                    if on{
//                        
//                       device.torchMode = .On
//                        device.flashMode = .On
//                    } else {
//                        
//                        device.torchMode = .Off
//                        device.flashMode = .Off
//                    }
//                    device.unlockForConfiguration()
                }
        }
//        )
    }
    
    //MARK
    //Notifications
    func peaked(notif: NSNotification){
    
        var rate : NSNumber!
        rate = notif.object as! NSNumber
        NSOperationQueue.mainQueue().addOperationWithBlock({
        
            self.heartRate.text = NSString(format: "%.2f", rate.doubleValue) as String
            
        })
    }
}