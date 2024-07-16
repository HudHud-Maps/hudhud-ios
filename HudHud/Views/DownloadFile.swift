//
//  DownloadFile.swift
//  KFSH_MOTAMARAT
//
//  Created by Aziz Dev on 08/03/2019.
//  Copyright © 2019 AzizDev. All rights reserved.
//

import UIKit

class FileDownloader: NSObject, URLSessionDownloadDelegate {
    var progressHandler: ((Float) -> Void)?
    var completionHandler: ((URL?, Error?) -> Void)?

    // MARK: - Internal

    func downloadFile(from url: URL) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let downloadTask = session.downloadTask(with: url)
        downloadTask.resume()
    }

    // URLSessionDownloadDelegate method called when a download task finishes successfully
    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        self.completionHandler?(location, nil)
    }

    // URLSessionDownloadDelegate method called periodically to track the progress of the download task
    func urlSession(_: URLSession,
                    downloadTask _: URLSessionDownloadTask,
                    didWriteData _: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        self.progressHandler?(progress)
    }

    // URLSessionTaskDelegate method called when a download task fails
    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
        self.completionHandler?(nil, error)
    }
}
