//
//  ExtensionVision.swift
//  FaceVision
//
//  Created by Rodolphe DUPUY on 15/04/2020.
//  Copyright © 2018 Rodolphe DUPUY. All rights reserved.
//

import UIKit
import Vision

extension ViewController {
    
    func supprimerAnciennesFrames(moustache: Bool) {
        for s in shapeLayers {
            s.removeFromSuperlayer()
        }
        if !moustache {
            for m in moustaches {
                m.removeFromSuperlayer()
            }
             moustaches.removeAll()
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
        supprimerAnciennesFrames(moustache: true)
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
                    self.supprimerAnciennesFrames(moustache: false)
                    if self.moustaches.count > 0 {
                        for x in (0...self.moustaches.count - 1) {
                            if x > resultatsTries.count, self.moustaches.count > x {
                                let moustache = self.moustaches[x]
                                moustache.removeFromSuperlayer()
                                self.moustaches.remove(at: x)
                            }
                        }
                    }
                } else {
                    self.supprimerAnciennesFrames(moustache: true)
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
                        
                    } else {
                        if let nez = observation.landmarks?.nose, let index = resultatsTries.firstIndex(of: observation) {
                            let points = self.convertirPoints(points: nez.normalizedPoints, rectAjuste)
                            var minX = points[0].x
                            var maxX = points[0].x
                            var minY = points[0].y
                            var maxY = points[0].y
                            for point in points {
                                if point.x > maxX {
                                    maxX = point.x
                                }
                                if point.x < minX {
                                    minX = point.x
                                }
                                
                                if point.y > maxY {
                                    maxY = point.y
                                }
                                if point.y < minY {
                                    minY = point.y
                                }
                                
                                let largeur = (maxX - minX) * 3
                                let milieu = (maxX + minX) / 2
                                let hauteur = largeur / 2
                                
                                if self.moustaches.count <= index {
                                    let moustache = CALayer()
                                    moustache.backgroundColor = UIColor.clear.cgColor
                                    moustache.frame = CGRect(x: 0, y: 0, width: largeur, height: hauteur)
                                    moustache.position = CGPoint(x: milieu, y: minY - (hauteur / 8))
                                    moustache.contents = #imageLiteral(resourceName: "moustache").cgImage
                                    self.moustaches.append(moustache)
                                    self.shapeLayer.addSublayer(moustache)
                                } else {
                                    let moustache = self.moustaches[index]
                                    moustache.frame = CGRect(x: 0, y: 0, width: largeur, height: hauteur)
                                    moustache.position = CGPoint(x: milieu, y: minY - (largeur / 8))
                                }
                            }
                        }
                        
                    }
                }
                
            }
        } else {
            DispatchQueue.main.async {
                self.supprimerAnciennesFrames(moustache: true)
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







