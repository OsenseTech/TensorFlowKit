import XCTest
@testable import TensorFlowKit
import Foundation

class TestClassificationPerformance: XCTestCase {
    
    private var modelDataHandler: ModelDataHandler?
    private let scaledSize: CGSize = CGSize(width: 320, height: 576)
    private let confidenceThreshold: Float = 0.5
    private var pixelBuffer: CVPixelBuffer?
    
    override func setUp() {
        super.setUp()
        
        let bundle = Bundle(for: TestClassificationPerformance.self)
        guard let path = bundle.path(forResource: "IMG_0870", ofType: "JPG") else {
            XCTAssert(false)
            return
        }
        let uiImage = UIImage(contentsOfFile: path)
        guard let buffer = uiImage?.convertToPixelBuffer() else {
            XCTAssertNotNil(uiImage)
            return
        }
        pixelBuffer = buffer
        
        modelDataHandler = ModelDataHandler(model: FileInfo(name: "tiny_ep499_576_320", type: "lite"),
                                            label: FileInfo(name: "labels", type: "txt"),
                                            scaledSize: CGSize(width: 320, height: 576))
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testRotatePerformance() {
        self.measure() {
            guard pixelBuffer?.rotate(size: scaledSize) != nil else {
                XCTAssert(false)
                return
            }
            
        }
    }

    func testTransFormatPerformance() {
        guard let rotatedBuffer = pixelBuffer?.rotate(size: scaledSize) else {
            XCTAssert(false)
            return
        }
        self.measure() {
            guard rotatedBuffer.convertTo32BGRAFormat() != nil else {
                XCTAssert(false)
                return
            }
        }
    }

    func testRunModelPerformance() {
        guard let rotatedBuffer = pixelBuffer?.rotate(size: scaledSize) else {
            XCTAssert(false)
            return
        }
        
        guard let rgbBuffer = rotatedBuffer.convertTo32BGRAFormat() else {
            XCTAssert(false)
            return
        }
        
        self.measure() {
            let result = modelDataHandler?.runModel(buffer: rgbBuffer, scaledSize: scaledSize)
            guard let label = result?.inferences.first?.label else {
                XCTAssert(false)
                return
            }
            
            XCTAssertEqual(label, "salute")
        }
    }
    
    func testRecognizePerformance() {
        self.measure() {
            guard let rotatedBuffer = pixelBuffer?.rotate(size: scaledSize) else {
                XCTAssert(false)
                return
            }
            
            guard let rgbBuffer = rotatedBuffer.convertTo32BGRAFormat() else {
                XCTAssert(false)
                return
            }
            let result = modelDataHandler?.runModel(buffer: rgbBuffer, scaledSize: scaledSize)
            guard let label = result?.inferences.first?.label else {
                XCTAssert(false)
                return
            }
            
            XCTAssertEqual(label, "salute")
        }
    }
    
}
