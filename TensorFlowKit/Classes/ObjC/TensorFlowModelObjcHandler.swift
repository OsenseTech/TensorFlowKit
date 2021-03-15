//
//  TensorFlowModelObjcHandler.swift
//  TensorFlowKit
//
//  Created by 蘇健豪 on 2021/3/15.
//

import Foundation

@objc
public class TensorFlowModelObjcHandler: NSObject {
    
    private var modelDataHandler: ModelDataHandler?
    
    @objc
    public init(modelFilename: String, labelFileName: String, scaledSize size: CGSize, confidenceThreshold threshold: Float = 0.5) {
        self.modelDataHandler = ModelDataHandler(model: FileInfo(name: modelFilename, type: "lite"),
                                                 label: FileInfo(name: labelFileName, type: "txt"),
                                                 scaledSize: size,
                                                 confidenceThreshold: threshold)
    }
    
    @objc
    public func recognize(pixelBuffer: CVPixelBuffer) -> String? {
        modelDataHandler?.recognize(pixelBuffer: pixelBuffer)
    }
    
}
