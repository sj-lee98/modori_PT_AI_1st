//
//  Predictor.swift
//  modori_PT
//
//  Created by 이성주 on 2022/03/06.
//

import Foundation
import Vision // humanBodyPose 인식관련

typealias ModoriActionClassifier = modoriAction

// 뷰컨트롤로 데이터 넘겨주기 위한 프로토콜 채택
protocol PredictorDelegate: AnyObject {
    func predictor(_ predictor: Predictor, didFindNewRecognizedPoints points: [CGPoint])
    func predictor(_ predictor: Predictor, didLabelAction action: String, with confidence: Double)
}

class Predictor {
    
    weak var delegate: PredictorDelegate?
    
    // 30frame 2sec로 학습시킴
    let predictionWindowSize = 60
    // 각각의 pose 프레임을 합쳐서 연관성 찾는 배열
    var posesWindow: [VNHumanBodyPoseObservation] = []
    
    init() {
        posesWindow.reserveCapacity(predictionWindowSize) // 60
    }
    
    
    func estimation(sampleBuffer: CMSampleBuffer) {
        // visionImageRequestHandler
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer,
                                                   orientation: .up)
        let request = VNDetectHumanBodyPoseRequest(completionHandler: bodyPoseHandler)
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the request, with error: \(error)")
        }
    }
    
    
    func bodyPoseHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNHumanBodyPoseObservation] else { return }
        
        // preview 위에 인식 포인트 띄우기
        observations.forEach {
            processObservation($0)
        }
        
        if let result = observations.first {
            storeObservation(result)
            
            labelActionType()
        }
    }
    
    func labelActionType() {
        // 모델을 사용하여 동작인식 진행
        guard let modoriActionClassifier = try? ModoriActionClassifier(configuration: MLModelConfiguration()),
              let poseMultiArray = prepareInputWithObservations(posesWindow),
              let predictions = try? modoriActionClassifier.prediction(poses: poseMultiArray)
        else { return }
        
        // 앞서 넣은 ml모델에서 알려주는 데이터 받아옴 -> 운동종류 및 confidence
        let label = predictions.label
        let confidence = predictions.labelProbabilities[label] ?? 0
        
        delegate?.predictor(self, didLabelAction: label, with: confidence)
    }
    
    func prepareInputWithObservations(_ observations: [VNHumanBodyPoseObservation]) -> MLMultiArray? {
        // 인식한 포즈 인식 프레임을 ml모듈에 넣음
        let numAvailableFrames = observations.count
        let observationsNeeded = 60
        var multiArrayBuffer = [MLMultiArray]()
        
        
        // 아래 코드는 애플 developer 문서 복붙 ~ 105line 까지
        for frameIndex in 0 ..< min(numAvailableFrames, observationsNeeded) {
            let pose = observations[frameIndex]
            do {
                let oneFrameMultiArray = try pose.keypointsMultiArray()
                multiArrayBuffer.append(oneFrameMultiArray)
            } catch {
                continue
            }
        }
        
        if numAvailableFrames < observationsNeeded {
            for _ in 0 ..< (observationsNeeded - numAvailableFrames) {
                do {
                    let oneFrameMultiArray = try MLMultiArray(shape: [1,3,18], dataType: .double)
                    try resetMultiArray(oneFrameMultiArray)
                    multiArrayBuffer.append(oneFrameMultiArray)
                } catch {
                    continue
                }
            }
        }
        return MLMultiArray(concatenating: [MLMultiArray](multiArrayBuffer), axis: 0, dataType: .float)
    }
    
    func resetMultiArray(_ predictionWindow: MLMultiArray, with value: Double = 0.0) throws {
        let pointer = try UnsafeMutableBufferPointer<Double>(predictionWindow)
        pointer.initialize(repeating: value)
    }
    
    func storeObservation(_ observation: VNHumanBodyPoseObservation) {
        // 60프레임 가득차면 가장 앞 프레임 지움
        if posesWindow.count >= predictionWindowSize {
            posesWindow.removeFirst()
        }
        
        // 배열에 추가
        posesWindow.append(observation)
    }
    
    func processObservation(_ observation: VNHumanBodyPoseObservation) {
        do {
            let recognizedPoints = try observation.recognizedPoints(forGroupKey: .all)
            
            // 인식 포인트 좌표
            let displayPoints = recognizedPoints.map {
                CGPoint(x: $0.value.x, y: 1 - $0.value.y)
            }
            
            delegate?.predictor(self, didFindNewRecognizedPoints: displayPoints)
        } catch {
            print("recognizedPoints에 오류가 있음.")
        }
    }
}
