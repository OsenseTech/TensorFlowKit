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
    public init(modelFilename: String, labelFileName: String) {
        self.modelDataHandler = ModelDataHandler(model: FileInfo(name: modelFilename, type: "lite"),
                                                 label: FileInfo(name: labelFileName, type: "txt"))
    }
    
    @objc
    public func recognize(pixelBuffer: CVPixelBuffer, scaledSize size: CGSize, confidenceThreshold threshold: Float = 0.5) -> String? {
        modelDataHandler?.recognize(pixelBuffer: pixelBuffer, scaledSize: size, confidenceThreshold: threshold)
    }
    
}
