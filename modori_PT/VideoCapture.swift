//
//  VideoCapture.swift
//  modori_PT
//
//  Created by 이성주 on 2022/03/06.
//

import Foundation
import AVFoundation


// AVCaptureVideoDataOutputSampleBufferDelegate 델리게이트 채택 위해 nsobject추가
class VideoCapture: NSObject {
    let captureSession = AVCaptureSession() // video IO
    let videoOutput = AVCaptureVideoDataOutput()
    
    // frame 단위로 predict 및 각 frame 연계
    let predictor = Predictor()
    
    override init() {
        super.init()
        
        // default video mode
        guard let captureDevice = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: captureDevice) else {
                  return
              }
        // video capture quality high
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        captureSession.addInput(input)
        
        captureSession.addOutput(videoOutput)
        // 메모리에서 저장된 이전 프레임 즉시 삭제
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
    }
    
    func startCaptureSession() {
        captureSession.startRunning()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoDispatchQueue"))
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // load predictor
        predictor.estimation(sampleBuffer: sampleBuffer)
    }
}
