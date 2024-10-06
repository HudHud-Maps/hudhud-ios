//
//  DownloadManager.swift
//  HudHud
//
//  Created by Aziz Dev on 24/02/2024.
//  Copyright © 2024 HudHud. All rights reserved.
//

import CommonCrypto
import OSLog
import UIKit

// MARK: - DownloadManager

class DownloadManager {

    typealias CallBackBlock = (_ path: String?, _ error: String?) -> Void

    // MARK: Static Properties

    static let shared = DownloadManager()

    // MARK: Properties

    var inDownload = [String: [CallBackBlock]]()

    // MARK: Class Functions

    class func getLocalFilePath(_ link: String) -> String? {
        let ext = (link as NSString).pathExtension
        let newPath = NSTemporaryDirectory() + link.sha265 + ".\(ext)"

        if FileManager.default.fileExists(atPath: newPath) {
            return newPath
        }

        return nil
    }

    class func downloadFile(_ path: String,
                            fileName: String? = nil,
                            isThumb: Bool = false,
                            downloadProgress: ((_ progress: Float) -> Void)? = nil,
                            block: @escaping CallBackBlock) {
        let ext = ((fileName ?? path) as NSString).pathExtension
        let newPath = NSTemporaryDirectory() + path.sha265 + ".\(ext)"

        let thumb = "\(isThumb ? "_th" : "")"
        let newPathTh = NSTemporaryDirectory() + path.sha265 + thumb + ".\(ext)"
        let newURL = URL(filePath: newPath)
        let newURLTh = URL(filePath: newPathTh)

        let localPath = isThumb ? newPathTh : newPath
        guard FileManager.default.fileExists(atPath: localPath) == false else {
            block(localPath, nil)
            return
        }

        guard let fileURL = URL(string: path) else {
            block(nil, "URL is not valid")
            return
        }

        // check if in download already
        if DownloadManager.shared.inDownload[path.sha265] == nil {
            DownloadManager.shared.inDownload[path.sha265] = [block]
        } else {
            DownloadManager.shared.inDownload[path.sha265]?.append(block)
            return
        }

        let downloader = FileDownloader()

        downloader.progressHandler = { progress in
            downloadProgress?(progress)
        }

        downloader.completionHandler = { location, error in

            var errorMessage: String?
            var newSavedPath: String?

            if let error {
                errorMessage = error.localizedDescription
            } else if let location {
                do {
                    try FileManager.default.copyItem(at: location, to: newURL)
                    // create thumb image
                    if isThumb, path.isImageType() {
                        if let image = UIImage(contentsOfFile: newPath) {
                            let thumb = image.thumbnail(pixelSize: 200)
                            if newPath.isPNG() {
                                try? thumb.pngData()?.write(to: newURLTh)
                            } else if newPath.isJPEG() {
                                try? thumb.jpegData(compressionQuality: 1)?.write(to: newURLTh)
                            }
                        }
                    }
                    newSavedPath = newPath
                } catch {
                    errorMessage = error.localizedDescription
                }
            }

            AppQueue.main {
                // call all blocks
                let blockArr = DownloadManager.shared.inDownload[path.sha265] ?? []
                for tmpBlock in blockArr {
                    if newSavedPath != nil || errorMessage != nil {
                        tmpBlock(newSavedPath, errorMessage)
                    }
                }
            }
        }

        downloader.downloadFile(from: fileURL)
    }

    class func fileExistOrLoading(_ path: String,
                                  fileName: String? = nil,
                                  isThumb: Bool = false) -> Bool {
        let ext = ((fileName ?? path) as NSString).pathExtension
        let newPath = NSTemporaryDirectory() + path.sha265 + ".\(ext)"

        let thumb = "\(isThumb ? "_th" : "")"
        let newPathTh = NSTemporaryDirectory() + path.sha265 + thumb + ".\(ext)"

        let localPath = isThumb ? newPathTh : newPath
        if FileManager.default.fileExists(atPath: localPath) || DownloadManager.shared.inDownload[path.sha265] != nil {
            return true
        }
        return false
    }

}

public extension String {

    internal var sha265: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        let sha265String = hash.map { String(format: "%02x", $0) }.joined()
        return sha265String
    }

    func isImageType() -> Bool {
        let imageFormats = ["jpg", "jpeg", "png"] // , "gif"]
        let ext = (self as NSString).pathExtension.lowercased()
        return imageFormats.contains(ext)
    }

    func isVideoType() -> Bool {
        // video formats which you want to check
        let imageFormats = ["mp4", "mov", "m4a"]

        if URL(string: self) != nil {
            let extensi = (self as NSString).pathExtension

            return imageFormats.contains(extensi)
        }
        return false
    }

    func isPNG() -> Bool {
        let ext = (self as NSString).pathExtension.lowercased()
        return ext == "png"
    }

    func isJPEG() -> Bool {
        let imageFormats = ["jpg", "jpeg"]
        let ext = (self as NSString).pathExtension.lowercased()
        return imageFormats.contains(ext)
    }

}

extension UIImage {

    func thumbnail(pixelSize: Int = 200) -> UIImage {
        let image = self
        guard let imageData = image.pngData() else { return self }

        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: pixelSize
        ] as [CFString: Any] // as CFDictionary

        let imgCFData = CGImageSourceCreateWithData(imageData as CFData, nil)
        guard let source = imgCFData else { return self }
        let cfOpt = options as CFDictionary
        guard let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, cfOpt) else { return self }

        let img = UIImage(cgImage: imageReference)

        if !img.isValideImage() {
            return self
        }

        return img
    }

    func isValideImage() -> Bool {
        if self.size.width == 0 || self.size.height == 0 {
            return false
        }
        return true
    }

}

// MARK: - AppQueue

class AppQueue {
    class func delay(_ delay: Double, closure: @escaping () -> Void) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }

    // MARK: - Internal

    class func background(work: @escaping () -> Void) {
        DispatchQueue.global(qos: .default).async {
            work()
        }
    }

    class func main(work: @escaping () -> Void) {
        DispatchQueue.main.async {
            work()
        }
    }
}
