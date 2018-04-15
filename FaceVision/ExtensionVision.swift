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
        shapeLayer.sublayers?.removeAll()
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
    
    func detectionElementsDuVisage(_ ciImage: CIImage) {
        let requete = VNDetectFaceLandmarksRequest(completionHandler: completionElement)
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([requete])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func completionElement( _ requete: VNRequest, _ error: Error?) {
        if let resultats = requete.results as? [VNFaceObservation], resultats.count > 0 {
            DispatchQueue.main.async {
                let resultatsTries = resultats.sorted(by: {$0.boundingBox.minX > $1.boundingBox.minX})
                if self.isMoustache {
                    // Verifier si on doit enlever les moustaches
                } else {
                    self.supprimerAnciennesFrames()
                }
                
                for observation in resultatsTries {
                    let rectAjuste = observation.boundingBox.miseAAchelleElements(from: self.view.bounds.size)
                    if !self.isMoustache {
                        self.convertirLandmarkEnshape(observation.landmarks?.faceContour, rectAjuste)
                        self.convertirLandmarkEnshape(observation.landmarks?.nose, rectAjuste)
                        self.convertirLandmarkEnshape(observation.landmarks?.innerLips, rectAjuste)
                        self.convertirLandmarkEnshape(observation.landmarks?.outerLips, rectAjuste)
                        self.convertirLandmarkEnshape(observation.landmarks?.leftEye, rectAjuste)
                        self.convertirLandmarkEnshape(observation.landmarks?.rightEye, rectAjuste)
                        self.convertirLandmarkEnshape(observation.landmarks?.leftEyebrow, rectAjuste)
                        self.convertirLandmarkEnshape(observation.landmarks?.rightEyebrow, rectAjuste)
                        
                    }
                }
                
            }
        } else {
            DispatchQueue.main.async {
                self.supprimerAnciennesFrames()
            }
        }
        
    }
    
    func convertirLandmarkEnshape(_ landmark: VNFaceLandmarkRegion2D?, _ boundingBox: CGRect) {
        guard let points = landmark?.normalizedPoints  else { return }
        let pointsConvertis = convertirPoints(points: points, boundingBox)
        guard pointsConvertis.count > 0 else { return }
        DispatchQueue.main.async {
            let nouveauLayer = CAShapeLayer()
            nouveauLayer.strokeColor = UIColor.blue.cgColor
            nouveauLayer.lineWidth = 1
            let path = UIBezierPath()
            path.move(to: pointsConvertis[0])
            for point in pointsConvertis {
                path.addLine(to: point)
                path.move(to: point)
            }
            path.addLine(to: pointsConvertis[0])
            nouveauLayer.path = path.cgPath
            self.shapeLayer.addSublayer(nouveauLayer)
        }
    }
    
    func convertirPoints(points: [CGPoint], _ boundingBox: CGRect) -> [CGPoint] {
        var nouveauxPoints = [CGPoint]()
        
        for point in points {
            let pointX = point.x * boundingBox.width + boundingBox.origin.x
            let pointY = point.y * boundingBox.height + boundingBox.origin.y
            let nouveau = CGPoint(x: pointX, y: pointY)
            nouveauxPoints.append(nouveau)
        }
        
        return nouveauxPoints
    }
    
}


extension CGRect {
    
    func miseAEchelle(from: CGRect) -> CGRect {
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: from.width, y: -from.height)
        let translate = CGAffineTransform.identity.scaledBy(x: -from.width, y: from.height)
        return self.applying(translate).applying(transform)
    }
    
    func miseAAchelleElements(from: CGSize) -> CGRect {
        let x = self.origin.x * from.width
        let y = self.origin.y * from.height
        let width = self.size.width * from.width
        let height = self.size.height * from.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}







