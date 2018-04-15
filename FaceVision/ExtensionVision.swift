//
//  ExtensionVision.swift
//  FaceVision
//
//  Created by Matthieu PASSEREL on 15/04/2018.
//  Copyright © 2018 Matthieu PASSEREL. All rights reserved.
//

import UIKit
import Vision

extension ViewController {
    
    func detectionDeVisages(_ ciImage: CIImage) {
        let requete = VNDetectFaceRectanglesRequest(completionHandler: completionDetection)
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([requete])
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    func completionDetection(_ requete: VNRequest, _ error: Error?) {
        
    }
}
