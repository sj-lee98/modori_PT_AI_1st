//
//  ViewController.swift
//  modori_PT
//
//  Created by 이성주 on 2022/03/06.
//

import UIKit
import AVFoundation // audio visual 프레임워크
import AudioToolbox


class ViewController: UIViewController {
    
    let videoCapture = VideoCapture()
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var pointsLayer = CAShapeLayer()
    
    var isActionDetected = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupVideoPreview()
        
        videoCapture.predictor.delegate = self
        
    }

    private func setupVideoPreview() {
        videoCapture.startCaptureSession()
        previewLayer = AVCaptureVideoPreviewLayer(session: videoCapture.captureSession)
        
        guard let previewLayer = previewLayer else { return }
        
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        view.layer.addSublayer(pointsLayer)
        pointsLayer.frame = view.frame
        pointsLayer.strokeColor = UIColor.green.cgColor

    }

}

extension ViewController: PredictorDelegate {
    func predictor(_ predictor: Predictor, didLabelAction action: String, with confidence: Double) {
        if action == "Lunge" && confidence > 0.80  {
            print("Lunge detected")
            isActionDetected = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.isActionDetected = false
            }
            
            DispatchQueue.main.async {
                AudioServicesPlayAlertSound(SystemSoundID(1007))
            }
        }
        
        else if action == "Crunch" && confidence > 0.95 && isActionDetected == false {
            print("Crunch detected")
            isActionDetected = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.isActionDetected = false
            }
            
            DispatchQueue.main.async {
                AudioServicesPlayAlertSound(SystemSoundID(1007))
            }
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
        
        DispatchQueue.main.async {
            self.pointsLayer.didChangeValue(for: \.path)
        }
    }
}

