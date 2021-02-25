//
//  TensorFlowWorker.swift
//  
//
//  Created by 蘇健豪 on 2021/2/25.
//

import UIKit
import Accelerate

class TensorFlowWorker {
    
    private lazy var modelDataHandler: ModelDataHandler? = {
        ModelDataHandler(modelFileInfo: MobileNet.modelInfo, labelsFileInfo: MobileNet.labelsInfo)
    }()
    
    @objc func recognize(pixelBuffer: CVPixelBuffer) -> String {
        guard let rgbBuffer = convertTo32BGRAFormat(pixelBuffer: pixelBuffer) else { return "" }
        
        let result = modelDataHandler?.runModel(onFrame: rgbBuffer)
        if let inference = result?.inferences.first {
            if inference.confidence > 0.5 {
                return inference.label
            }
        }
        
        return ""
    }
    
    // MARK: - Private
    
    private func convertTo32BGRAFormat(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        var buffer: CVPixelBuffer?
        let attributes = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                          kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        let width = Int(CVPixelBufferGetWidth(pixelBuffer))
        let height = Int(CVPixelBufferGetHeight(pixelBuffer))
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attributes, &buffer)
        guard let rgbBuffer = buffer else { return nil }
        CIContext().render(ciImage, to: rgbBuffer)
        
        return rgbBuffer
    }
    
}
