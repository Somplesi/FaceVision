//
//  ViewController.swift
//  FaceVision
//
//  Created by Rodolphe DUPUY on 15/04/2020.
//  Copyright © 2018 Rodolphe DUPUY. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var cameraVue: UIView!
    @IBOutlet weak var rotationBouton: UIButton!
    @IBOutlet weak var segment: UISegmentedControl!
    
    let mediaType = AVMediaType.video
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var position = AVCaptureDevice.Position.back
    var shapeLayers = [CAShapeLayer]()
    var shapeLayer = CAShapeLayer()
    var moustaches = [CALayer]()
    var isMoustache = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Vérifier authorisation
        verifierAutorisationEtLancerCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        shapeLayer.frame = cameraVue.bounds
        shapeLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: -1))
        view.layer.addSublayer(shapeLayer)
    }
    
    func verifierAutorisationEtLancerCamera() {
        // Ajouter dans plist: Privacy - Camera Usage Description
        let autorisation = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch autorisation {
        case .authorized: miseEnPlaceCamera()
        case .denied: print("L'utilisateur a refusé l'accès à la caméra")
        case .restricted: print("L'utilisation de la camera est restreint")
        //case .notDetermined:
        default:
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
        guard let copie = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate) else { return }
        let ciImage = CIImage(cvImageBuffer: pixel, options: convertToOptionalCIImageOptionDictionary(copie as? [String: Any]))
        if position == .front {
            self.choisirActionAEffectuer(ciImage: ciImage.oriented(forExifOrientation: Int32(UIImage.Orientation.leftMirrored.rawValue)))
            // Image a utiliser avec Vision
        } else {
            self.choisirActionAEffectuer(ciImage: ciImage.oriented(forExifOrientation: Int32(UIImage.Orientation.downMirrored.rawValue)))
        }
    }
    
    func choisirActionAEffectuer(ciImage: CIImage) {
        DispatchQueue.main.sync {
            switch self.segment.selectedSegmentIndex {
            case 0: self.detectionDeVisages(ciImage)
            case 1:
                self.isMoustache = false
                self.detectionElementsDuVisage(ciImage)
            case 2:
                self.isMoustache = true
                self.detectionElementsDuVisage(ciImage)
            default: break
            }
        }
    }
    
    @IBAction func rotationAction(_ sender: Any) {
        session?.stopRunning()
        switch position {
        case .back: position = .front
        case .front: position = .back
        //case .unspecified: position = .back
        default: position = .back
        }
        verifierAutorisationEtLancerCamera()
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalCIImageOptionDictionary(_ input: [String: Any]?) -> [CIImageOption: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (CIImageOption(rawValue: key), value)})
}
