//
//  ViewController.swift
//  modori_PT
//
//  Created by 이성주 on 2022/03/06.
//

import UIKit
import AVFoundation // audio visual 프레임워크 -> call previewLayer
import AudioToolbox


class ViewController: UIViewController {
    
    @IBOutlet weak var poses: UILabel!
    @IBOutlet weak var confidence: UILabel!
    
    let videoCapture = VideoCapture()
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // 인식 포인트 그리는 레이어
    var pointsLayer = CAShapeLayer()
    
    var isActionDetected = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupVideoPreview() // video setup
        
        videoCapture.predictor.delegate = self
        
    }

    private func setupVideoPreview() {
        
        videoCapture.startCaptureSession()
        // 실제 영상 따와서 뷰에 띄움
        previewLayer = AVCaptureVideoPreviewLayer(session: videoCapture.captureSession)
        
        guard let previewLayer = previewLayer else { return } // initialize
        
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        view.layer.addSublayer(pointsLayer)
        pointsLayer.frame = view.frame
        // 초록색으로 인식포인트 점 그림
        pointsLayer.strokeColor = UIColor.green.cgColor

    }

}

extension ViewController: PredictorDelegate {
    // predictor로 부터 운동종류 및 confidence 받아옴
    func predictor(_ predictor: Predictor, didLabelAction action: String, with confidence: Double) {
        if action == "Lunge" && confidence > 0.55 && isActionDetected == false {
            print("Lunge detected")
            DispatchQueue.main.async {
                self.poses.text = action
                self.confidence.text = String(confidence)
            }
            isActionDetected = true
            delayAndSoundEffect()
        }
        
        else if action == "Crunch" && confidence > 0.55 && isActionDetected == false {
            print("Crunch detected")
            DispatchQueue.main.async {
                self.poses.text = action
                self.confidence.text = String(confidence)
            }
            isActionDetected = true
            delayAndSoundEffect()
        }
        else if action == "situp" && confidence > 0.55 && isActionDetected == false {
            print("SitUp detected")
            DispatchQueue.main.async {
                self.poses.text = action
                self.confidence.text = String(confidence)
            }
            isActionDetected = true
            delayAndSoundEffect()
        }
        else if action == "Squat_videos" && confidence > 0.55 && isActionDetected == false {
            print("Squat detected")
            DispatchQueue.main.async {
                self.poses.text = action
                self.confidence.text = String(confidence)
            }
            isActionDetected = true
            delayAndSoundEffect()
        }
        
    }
    
    func delayAndSoundEffect() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isActionDetected = false
        }
        
        DispatchQueue.main.async {
            AudioServicesPlayAlertSound(SystemSoundID(1007))
        }
    }
    
    func predictor(_ predictor: Predictor, didFindNewRecognizedPoints points: [CGPoint]) {
        guard let previewLayer = previewLayer else { return }
        
        let convertedPoints = points.map {
            previewLayer.layerPointConverted(fromCaptureDevicePoint: $0)
        }
        let combinedPath = CGMutablePath()
        
        for point in convertedPoints {
            let dotPath = UIBezierPath(ovalIn: CGRect(x: point.x, y: point.y, width: 10, height: 10))
            combinedPath.addPath(dotPath.cgPath)
        }
        
        pointsLayer.path = combinedPath
        
        // 프레임이 변경될때마다 포인트 계산 동기화 -> 메인스레드에서 진행
        DispatchQueue.main.async {
            self.pointsLayer.didChangeValue(for: \.path)
        }
    }
}

