//
//  ViewController.swift
//  TestARApp
//
//  Created by Alex 6.1 on 1/16/20.
//  Copyright © 2020 aglegaspi. All rights reserved.
//

import UIKit
import RealityKit
import AVKit
import Vision

class ViewController: UIViewController {
    
    lazy var captureSession:AVCaptureSession = {
        let captureSession = AVCaptureSession()
        return captureSession
    }()
    
    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCaptureSession()
        
        // Load the "Box" scene from the "Experience" Reality File
        let boxAnchor = try! Experience.loadBox()
        
        // Add the box anchor to the scene
        arView.scene.anchors.append(boxAnchor)
    }
    
    func setupCaptureSession(){
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.addInput(input)
        captureSession.stopRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        arView.layer.addSublayer(previewLayer)
        previewLayer.frame = arView.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoOutput"))
        captureSession.addOutput(dataOutput)
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer:CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {return}
        
        let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
            if let err = error{
                print("Cant figure out structure \(err)")
            }
            
            guard let results = finishedRequest.results as? [VNClassificationObservation] else {return}
            
            guard let firstObservation = results.first else {return}
            
            print(firstObservation.identifier, firstObservation.confidence)
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
