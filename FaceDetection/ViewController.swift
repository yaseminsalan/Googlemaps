//
//  ViewController.swift
//  FaceDetection
//
//  Created by Yasemin salan on 30.03.2020.
//  Copyright © 2020 Yasemin salan. All rights reserved.
//

import UIKit
import Vision
import ImageIO

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    var imagePicker: UIImagePickerController!
       var userPickedImage: UIImage?
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate

        // Do any additional setup after loading the view.
    }

    @IBOutlet weak var lblResult: UILabel!
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
            
            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                imageView.contentMode = .scaleAspectFit
                imageView.image = pickedImage
                self.userPickedImage = pickedImage
            }
            
            dismiss(animated: true, completion: nil)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss(animated: true, completion: nil)
        }
        
        @IBAction func btnResimSec(_ sender: Any) {
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true, completion: nil)
        }

        @IBAction func btnAnalizEt(_ sender: Any) {
            self.lblResult.text = "işleniyor..."
            guard let ciImage = CIImage(image: self.userPickedImage!) else {
                return
            }
            //performRequestForFaceRectangle(ciImage: ciImage)
            performRequestForFaceLandmarks(ciImage: ciImage)
        }
        
        func performRequestForFaceRectangle(ciImage: CIImage ){
           
            let request = VNDetectFaceRectanglesRequest { [unowned self] request, error in
                
                self.handleFaceDetection(with: request)
                
            }
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            }
            catch {
                print(error.localizedDescription)
            }
        }
        
        func handleFaceDetection(with request: VNRequest) {
            guard let observations = request.results as? [VNFaceObservation] else {
                fatalError("hata")
            }
            self.lblResult.text = "Bulunan yüz sayısı: \(observations.count)"
        }
        
        func performRequestForFaceLandmarks(ciImage: CIImage){
            let request = VNDetectFaceLandmarksRequest { [unowned self] request, error in
                
                self.handleFaceLandmarksDetection(with: request)
                
            }
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            }
            catch {
                print(error.localizedDescription)
            }
        }

         func handleFaceLandmarksDetection(with request: VNRequest) {
            guard let observations = request.results as? [VNFaceObservation] else {
                fatalError("hata")
            }
            self.lblResult.text = "Bulunan yüz sayısı: \(observations.count)"
            
            for vw in self.imageView.subviews where vw.tag == 10 {
                vw.removeFromSuperview()
            }
            
            var landmarkRegions : [VNFaceLandmarkRegion2D] = []
            for faceObservation in observations {
             //   self.addFaceContour(forObservation: faceObservation, toView: self.imageView )
                 landmarkRegions =  self.addFaceFeatures(forObservation: faceObservation, toView: self.imageView )
                userPickedImage = self.drawOnImage(source: self.userPickedImage!, boundingRect: faceObservation.boundingBox, faceLandmarkRegions: landmarkRegions )
            }
              self.imageView.image = userPickedImage
        }
        
        
        func addFaceContour(forObservation face: VNFaceObservation, toView view :UIView) {
            let box1 = face.boundingBox // !!! the values are from 0 to 1 (unscaled)
            let box2 = view.bounds
            
            let w = box1.size.width * box2.width
            let h = box1.size.height * box2.height
            
            let x = box1.origin.x * box2.width
            let y =  abs((box1.origin.y * box2.height) - box2.height) - h
            
            let subview = UIView(frame: CGRect(x: x, y: y, width: w, height: h))
            subview.layer.borderColor = UIColor.green.cgColor
            subview.layer.borderWidth = 3.0
            subview.layer.cornerRadius = 5.0
            subview.tag = 10
            view.addSubview(subview)
        }
        func addFaceFeatures(forObservation face: VNFaceObservation, toView view :UIView) -> [VNFaceLandmarkRegion2D] {
            
            // get all the regions to draw to the images (eyes, lips, nose, etc...)
            // we draw these areas onto the image
            
            guard let landmarks = face.landmarks else {
                return []
            }
            
            var landmarkRegions: [VNFaceLandmarkRegion2D] = []
            
            if let faceContour = landmarks.faceContour {
                landmarkRegions.append(faceContour)
            }
            
            if let leftEye = landmarks.leftEye {
                landmarkRegions.append(leftEye)
            }
            if let rightEye = landmarks.rightEye {
                landmarkRegions.append(rightEye)
            }
            if let nose = landmarks.nose {
                landmarkRegions.append(nose)
            }
            if let noseCrest = landmarks.noseCrest {
                landmarkRegions.append(noseCrest)
            }
            if let medianLine = landmarks.medianLine {
                landmarkRegions.append(medianLine)
            }
            if let outerLips = landmarks.outerLips {
                landmarkRegions.append(outerLips)
            }
            if let leftEyebrow = landmarks.leftEyebrow {
                landmarkRegions.append(leftEyebrow)
            }
            if let rightEyebrow = landmarks.rightEyebrow {
                landmarkRegions.append(rightEyebrow)
            }
            
            if let innerLips = landmarks.innerLips {
                landmarkRegions.append(innerLips)
            }
            if let leftPupil = landmarks.leftPupil {
                landmarkRegions.append(leftPupil)
            }
            if let rightPupil = landmarks.rightPupil {
                landmarkRegions.append(rightPupil)
            }
            
            // we need to draw on the image (all the features)
            return landmarkRegions
            
            
            
        }
        
        
        func drawOnImage(source: UIImage,
                         boundingRect: CGRect,
                         faceLandmarkRegions: [VNFaceLandmarkRegion2D]) -> UIImage {
            UIGraphicsBeginImageContextWithOptions(source.size, false, 1)
            let context = UIGraphicsGetCurrentContext()!
            context.translateBy(x: 0, y: source.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            //context.setBlendMode(CGBlendMode.colorBurn)
            context.setBlendMode(CGBlendMode.colorDodge)
            context.setLineJoin(.round)
            context.setLineCap(.round)
            context.setShouldAntialias(true)
            context.setAllowsAntialiasing(true)
            
            let rectWidth = source.size.width * boundingRect.size.width
            let rectHeight = source.size.height * boundingRect.size.height
            
            //draw original image
            let rect = CGRect(x: 0, y:0, width: source.size.width, height: source.size.height)
            context.draw(source.cgImage!, in: rect)
            
            
            //draw bound rect
            var fillColor = UIColor.blue
           // var fillColor = UIColor.green
            fillColor.setFill()
            context.addRect(CGRect(x: boundingRect.origin.x * source.size.width, y:boundingRect.origin.y * source.size.height, width: rectWidth, height: rectHeight))
            context.drawPath(using: CGPathDrawingMode.stroke)
            
            
            
            //draw overlay
          //  fillColor = UIColor.red
              fillColor = UIColor.blue
            fillColor.setStroke()
            context.setLineWidth(8.0)
          //   context.setLineWidth(3.0)
            for faceLandmarkRegion in faceLandmarkRegions {
                var points: [CGPoint] = []
                for i in 0..<faceLandmarkRegion.pointCount {
                    let point = faceLandmarkRegion.normalizedPoints[i]
                    let p = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
                    points.append(p)
                }
                let mappedPoints = points.map { CGPoint(x: boundingRect.origin.x * source.size.width + $0.x * rectWidth, y: boundingRect.origin.y * source.size.height + $0.y * rectHeight) }
                context.addLines(between: mappedPoints)
                context.drawPath(using: CGPathDrawingMode.stroke)
            }
            
            let coloredImg : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return coloredImg
        }
        
        
        
    }


