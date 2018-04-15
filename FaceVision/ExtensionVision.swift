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
    
    func supprimerAnciennesFrames() {
        for s in shapeLayers {
            s.removeFromSuperlayer()
        }
        shapeLayers.removeAll()
    }
    
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
        guard let resultats = requete.results as? [VNFaceObservation], resultats.count > 0 else { return }
        // Supprime les anciennes détections de visage
        supprimerAnciennesFrames()
        for resultat in resultats {
            //Ajouter les nouvelles frames
            DispatchQueue.main.async {
                let monRect = resultat.boundingBox.miseAEchelle(from: self.cameraVue.bounds)
                let path = UIBezierPath(rect: monRect)
                let layer = CAShapeLayer()
                layer.strokeColor = UIColor.red.cgColor
                layer.lineWidth = 1
                layer.fillColor = UIColor.clear.cgColor
                layer.path = path.cgPath
                self.shapeLayers.append(layer)
                self.cameraVue.layer.addSublayer(layer)
            }
        }
    }
}


extension CGRect {
    
    func miseAEchelle(from: CGRect) -> CGRect {
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: from.width, y: -from.height)
        let translate = CGAffineTransform.identity.scaledBy(x: -from.width, y: from.height)
        return self.applying(translate).applying(transform)
    }
}







