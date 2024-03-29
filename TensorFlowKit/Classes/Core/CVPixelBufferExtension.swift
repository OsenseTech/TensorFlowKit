// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// =============================================================================

import Accelerate

extension CVPixelBuffer {
    
    /**
     Returns thumbnail by cropping pixel buffer to biggest square and scaling the cropped image to
     model dimensions.
     */
    func centerThumbnail(ofSize size: CGSize) -> CVPixelBuffer? {
        
        let imageWidth = CVPixelBufferGetWidth(self)
        let imageHeight = CVPixelBufferGetHeight(self)
        let pixelBufferType = CVPixelBufferGetPixelFormatType(self)
        
        assert(pixelBufferType == kCVPixelFormatType_32BGRA)
        
        let inputImageRowBytes = CVPixelBufferGetBytesPerRow(self)
        let imageChannels = 4
        
        let thumbnailSize = min(imageWidth, imageHeight)
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        
        var originX = 0
        var originY = 0
        
        if imageWidth > imageHeight {
            originX = (imageWidth - imageHeight) / 2
        } else {
            originY = (imageHeight - imageWidth) / 2
        }
        
        // Finds the biggest square in the pixel buffer and advances rows based on it.
        guard let inputBaseAddress = CVPixelBufferGetBaseAddress(self)?.advanced(
                by: originY * inputImageRowBytes + originX * imageChannels) else {
            return nil
        }
        
        // Gets vImage Buffer from input image
        var inputVImageBuffer = vImage_Buffer(
            data: inputBaseAddress, height: UInt(thumbnailSize), width: UInt(thumbnailSize),
            rowBytes: inputImageRowBytes)
        
        let thumbnailRowBytes = Int(size.width) * imageChannels
        guard let thumbnailBytes = malloc(Int(size.height) * thumbnailRowBytes) else {
            return nil
        }
        
        // Allocates a vImage buffer for thumbnail image.
        var thumbnailVImageBuffer = vImage_Buffer(data: thumbnailBytes, height: UInt(size.height), width: UInt(size.width), rowBytes: thumbnailRowBytes)
        
        // Performs the scale operation on input image buffer and stores it in thumbnail image buffer.
        let scaleError = vImageScale_ARGB8888(&inputVImageBuffer, &thumbnailVImageBuffer, nil, vImage_Flags(0))
        
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        
        guard scaleError == kvImageNoError else {
            return nil
        }
        
        let releaseCallBack: CVPixelBufferReleaseBytesCallback = {mutablePointer, pointer in
            if let pointer = pointer {
                free(UnsafeMutableRawPointer(mutating: pointer))
            }
        }
        
        var thumbnailPixelBuffer: CVPixelBuffer?
        
        // Converts the thumbnail vImage buffer to CVPixelBuffer
        let conversionStatus = CVPixelBufferCreateWithBytes(
            nil, Int(size.width), Int(size.height), pixelBufferType, thumbnailBytes,
            thumbnailRowBytes, releaseCallBack, nil, nil, &thumbnailPixelBuffer)
        
        guard conversionStatus == kCVReturnSuccess else {
            
            free(thumbnailBytes)
            return nil
        }
        
        return thumbnailPixelBuffer
    }
    
    func convertTo32BGRAFormat() -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: self)
        var buffer: CVPixelBuffer?
        let attributes = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                          kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        let width = Int(CVPixelBufferGetWidth(self))
        let height = Int(CVPixelBufferGetHeight(self))
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attributes, &buffer)
        guard let rgbBuffer = buffer else { return nil }
        CIContext().render(ciImage, to: rgbBuffer)
        
        return rgbBuffer
    }
    
    func rotate(size: CGSize) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: self)
        let ciContext = CIContext(options: nil)
        let cgImage = ciContext.createCGImage(ciImage, from: CGRect(origin: CGPoint.zero,
                                                                    size: CGSize(width: ciImage.extent.size.width,
                                                                                 height: ciImage.extent.size.height)))
        let outputSize = CGSize(width: size.height, height: size.width)
        guard let resizedCGImage = cgImage?.rotateImage(size: outputSize) else { return nil }
        let uiImage = UIImage(cgImage: resizedCGImage)
        guard let buffer = uiImage.convertToPixelBuffer() else { return nil }
        
        return buffer
    }
    
}

extension CGImage {
    
    fileprivate func rotateImage(size: CGSize) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel: CGFloat = 4
        let bytesPerRow = bytesPerPixel * size.width
        let bitsPerComponent = 8
        
        let context = CGContext(data: nil,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: Int(bytesPerRow),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        context?.rotate(by: -(CGFloat(Double.pi / 2)))
        context?.translateBy(x: -size.height, y: 0)
        context?.draw(self, in: CGRect(origin: CGPoint.zero, size: CGSize(width: size.height, height: size.width)))
        
        return context?.makeImage()
    }
    
}

extension UIImage {
    
    @objc
    public func convertToPixelBuffer() -> CVPixelBuffer? {
        let attributes = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                          kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(self.size.width),
                                         Int(self.size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attributes,
                                         &pixelBuffer)
        guard status == kCVReturnSuccess else { return nil }
        
        guard let buffer = pixelBuffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: Int(self.size.width),
                                      height: Int(self.size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
    
}
