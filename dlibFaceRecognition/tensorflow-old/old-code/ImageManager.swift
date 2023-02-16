//
//  ImageManager.swift
//  faceRecognition
//
//  Created by 현수빈 on 2023/02/15.
//

import Foundation
import UIKit

class ImageFileManager {
  static let shared: ImageFileManager = ImageFileManager()
// Save Image
// name: ImageName
  func saveImage(image: UIImage?, name: String,
                 onSuccess: @escaping ((String) -> Void)) {
  guard let data: Data
            = image?.jpegData(compressionQuality: 1)
            ?? image?.pngData() else { return }
  if let directory: NSURL =
    try? FileManager.default.url(for: .documentDirectory,
                                 in: .userDomainMask,
                                 appropriateFor: nil,
                                 create: false) as NSURL {
      do {
          if let url = directory.appendingPathComponent(name) {
              try data.write(to: url)
              onSuccess(url.absoluteString)
          }
          
          
      } catch let error as NSError {
        print("Could not saveImage🥺: \(error), \(error.userInfo)")
        onSuccess("")
      }
    }
  }
}
