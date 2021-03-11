//
//  ViewController.swift
//  TensorFlowKit
//
//  Created by 蘇健豪 on 03/02/2021.
//  Copyright (c) 2021 蘇健豪. All rights reserved.
//

import UIKit
import TensorFlowKit
import ARKit

class ViewController: UIViewController {
    
    private lazy var sceneView: ARSCNView = {
        let frame = UIScreen.main.bounds
        let sceneView = ARSCNView(frame: frame)
        sceneView.delegate = self
        sceneView.session.delegate = self
        self.view.addSubview(sceneView)
        
        return sceneView
    }()
    
    private lazy var modelDataHandler: ModelDataHandler? = {
        ModelDataHandler(modelFileInfo: FileInfo(name: "tiny_ep499_576_320", extension: "lite"),
                         labelsFileInfo: FileInfo(name: "labels", extension: "txt"))
    }()
    
    private var pixelBuffer: CVPixelBuffer?
    private weak var timer: Timer?
    private lazy var recognizeQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        
        return queue
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = ARWorldTrackingConfiguration()
        if #available(iOS 12.0, *) {
            config.maximumNumberOfTrackedImages = 1
        }
        if #available(iOS 11.3, *) {
            config.detectionImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resource", bundle: nil)
        }
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
     
    private func fireTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(catchCurrentPixelBuffer), userInfo: nil, repeats: true)
        }
    }
    
    @objc private func catchCurrentPixelBuffer() {
        guard let buffer = pixelBuffer else { return }
        
        recognize(pixelBuffer: buffer)
    }
    
    private func recognize(pixelBuffer: CVPixelBuffer) {
        let type = CVPixelBufferGetPixelFormatType(pixelBuffer)
        guard type == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange else {
            return
        }
        
        guard let _ = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return
        }
        
        recognizeQueue.addOperation { [self] in
            let size = CGSize(width: 320, height: 576)
            guard let rotatedBuffer = pixelBuffer.rotate(size: size) else { return }
            
            if let label = modelDataHandler?.recognize(pixelBuffer: rotatedBuffer, scaledSize: size) {
                print(label)
            }
        }
    }
    
}

extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        pixelBuffer = frame.capturedImage
    }
    
}


extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        fireTimer()
        print("didAdd")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
    }

}
