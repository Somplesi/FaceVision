//
//  ViewController.swift
//  FaceVision
//
//  Created by Matthieu PASSEREL on 15/04/2018.
//  Copyright © 2018 Matthieu PASSEREL. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var cameraVue: UIView!
    @IBOutlet weak var rotationBouton: UIButton!
    
    let mediaType = AVMediaType.video
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var position = AVCaptureDevice.Position.back
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Vérifier authorisation
        verifierAutorisationEtLancerCamera()
    }
    
    func verifierAutorisationEtLancerCamera() {
        let autorisation = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch autorisation {
        case .authorized: miseEnPlaceCamera()
        case .denied: print("L'utilisateur a refusé l'accès à la caméra")
        case .restricted: print("L'utilisation de la camera est restreint")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: mediaType) { (success) in
                DispatchQueue.main.async {
                    self.verifierAutorisationEtLancerCamera()
                }
            }
        }
    }
    
    func miseEnPlaceCamera() {
        previewLayer?.removeFromSuperlayer()
        
        session = AVCaptureSession()
        guard session != nil else { return }
        guard let appareilPhoto = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: mediaType, position: position) else { return }
        do {
            let input =  try AVCaptureDeviceInput(device: appareilPhoto)
            if session!.canAddInput(input) {
                session!.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            output.alwaysDiscardsLateVideoFrames = true
            if session!.canAddOutput(output) {
                session!.addOutput(output)
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: session!)
            previewLayer?.frame = cameraVue.bounds
            previewLayer?.connection?.videoOrientation = .portrait
            previewLayer?.videoGravity = .resizeAspect
            
            guard previewLayer != nil else { return }
            cameraVue.layer.addSublayer(previewLayer!)
            
            let queue = DispatchQueue(label: "videoqueue")
            output.setSampleBufferDelegate(self, queue: queue)
            session!.startRunning()
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixel = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let copie = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate) else { return }
        let ciImage = CIImage(cvImageBuffer: pixel, options: copie as? [String: Any])
        if position == .front {
            self.choisirActionAEffectuer(ciImage: ciImage.oriented(forExifOrientation: Int32(UIImageOrientation.leftMirrored.rawValue)))
            // Image a utiliser avec Vision
        } else {
            self.choisirActionAEffectuer(ciImage: ciImage.oriented(forExifOrientation: Int32(UIImageOrientation.downMirrored.rawValue)))
        }
    }
    
    func choisirActionAEffectuer(ciImage: CIImage) {
        
    }
    
    @IBAction func rotationAction(_ sender: Any) {
        session?.stopRunning()
        switch position {
        case .back: position = .front
        case .front: position = .back
        case .unspecified: position = .back
        }
        verifierAutorisationEtLancerCamera()
    }
}

