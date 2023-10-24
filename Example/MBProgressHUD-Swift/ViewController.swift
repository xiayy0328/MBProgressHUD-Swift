//
//  ViewController.swift
//  MBProgressHUD-Swift
//
//  Created by Loveying on 04/29/2021.
//  Copyright (c) 2021 Loveying. All rights reserved.
//

import UIKit
import MBProgressHUD_Swift

class ViewController: UITableViewController {

    let examples = [
        ("Indeterminate mode", #selector(indeterminateExample)),
        ("With label", #selector(labelExample)),
        ("With details label", #selector(detailsLabelExample)),
        ("On window", #selector(windowExample)),
        ("Bar determinate mode", #selector(barDeterminateExample)),
        ("Determinate mode", #selector(determinateExample)),
        ("Annular determinate mode", #selector(annularDeterminateExample)),
        ("Custom view", #selector(customViewExample)),
        ("Text Only", #selector(textExample)),
        ("With action button", #selector(cancelationExample)),
        ("Determinate with Progress", #selector(determinateProgressExample)),
        ("Mode swithing", #selector(modeSwitchExample)),
        ("Dim background", #selector(dimBackgroundExample)),
        ("Colored", #selector(colorExample)),
        ("URLSession", #selector(networkingExample))
                    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "MBProgressHUDDemo"
    }

    // MARK: Examples
    @objc func indeterminateExample() {
        // Show the hud on the root view (self.view is a scrollable table view and thus not suitable,
        // as the hud would move with the content as we scroll).
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        
        // Fire off an asynchronous task, giving UIKit the opportunity to redraw wit the hud added to the
        // view hierarchy.
        DispatchQueue.global(qos: .userInitiated).async {
            self.doSomeWork()
            
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    @objc func labelExample() {
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        
        // Set label text
        hud.label?.text = NSLocalizedString("Loading...", comment: "hud loading title")
        // You can set other lable properties
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.doSomeWork()
            
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    @objc func detailsLabelExample() {
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        
        // Set label text
        hud.label?.text = NSLocalizedString("Loading...", comment: "hud loading title")
        // Set details label text.
        hud.detailsLabel?.text = NSLocalizedString("Pasing data\n(1/1)", comment: "hud title")
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.doSomeWork()
            
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    @objc func windowExample() {
        // Cover the entire screen.
        let hud = MBProgressHUD.show(addedToView: self.view.window!, animated: true)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.doSomeWork()
            
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    @objc func barDeterminateExample() {
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        hud.mode = .determinateHorizontalBar
        hud.label?.text = "Loading..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Do something useful in the background and update the hud periodically.
            self.doSomeWorkWithProgess()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    @objc func determinateExample() {
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        
        // Set determinate mode
        hud.mode = .determinate
        hud.label?.text = NSLocalizedString("Loading...", comment: "hud loading title")
        DispatchQueue.global(qos: .userInitiated).async {
            // Do something useful in the background and update the hud periodically.
            self.doSomeWorkWithProgess()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    @objc func annularDeterminateExample() {
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        
        // Set annular determinate mode
        hud.mode = .annularDeterminate
        hud.label?.text = NSLocalizedString("Loading...", comment: "hud loading title")
        DispatchQueue.global(qos: .userInitiated).async {
            // Do something useful in the background and update the hud periodically.
            self.doSomeWorkWithProgess()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    @objc func customViewExample() {
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        // Set the custom view mode
        hud.mode = .customView
        // Set a checkmark
        hud.customView = UIImageView(image: #imageLiteral(resourceName: "Checkmark1"))
        hud.isSquare = true
        hud.label?.text = NSLocalizedString("Done", comment: "hud done title")
        hud.hide(animated: true, afterDelay: 3.0)
    }
    
    @objc func textExample() {
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        
        // Set the Text mode
        hud.mode = .text
        hud.margin = 15
        hud.label?.text = NSLocalizedString("Message here!", comment: "hud message title")
        // Move to bottom center.
        //hud.offset = CGPoint(x: 0, y: SYProgressHUD.maxOffset)
        hud.hide(animated: true, afterDelay: 3.0)
    }
    
    @objc func cancelationExample() {
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        
        // Set the determinate mode
        hud.mode = .determinate
        hud.label?.text = NSLocalizedString("Loading...", comment: "hud loading title")
        
        // Configure the button
        hud.button?.setTitle(NSLocalizedString("cancel", comment: "hud cancel button title"), for: .normal)
        hud.button?.addTarget(self, action: #selector(cancelWork(sender:)), for: .touchUpInside)
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Do something useful in the background and update the hud periodically.
            self.doSomeWorkWithProgess()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    @objc func determinateProgressExample() {
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        
        // Set the determinate mode
        hud.mode = .determinate
        hud.label?.text = NSLocalizedString("Loading...", comment: "hud loading title")
        
        // Set up Progress
        hud.progressObject = Progress(totalUnitCount: 100)
        
        // Configure the button
        hud.button?.setTitle(NSLocalizedString("cancel", comment: "hud cancel button title"), for: .normal)
        hud.button?.addTarget(hud.progressObject, action: #selector(Progress.cancel), for: .touchUpInside)
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Do something useful in the background and update the hud periodically.
            self.doSomeWork(forProgressObject: hud.progressObject!)
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    @objc func modeSwitchExample() {
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        
        // Set some text to show the initial status.
        hud.label?.text = NSLocalizedString("Preparing", comment: "hud preparing title")
        // Set min size
        hud.minSize = CGSize(width: 150, height: 100)
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Do something useful in the background and update the hud periodically.
            self.doSomeWorkWithMixedProgress()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    @objc func dimBackgroundExample() {
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        
        // Change the background view style and color
        hud.backgroundView?.style = .solidColor
        hud.backgroundView?.color = UIColor(white: 0, alpha: 0.1)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.doSomeWork()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    @objc func colorExample() {
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        hud.contentColor = UIColor.white
        hud.bezelView?.layer.cornerRadius = 10
        hud.bezelView?.backgroundColor = UIColor(red: 0, green: 0.6, blue: 0.7, alpha: 1)
        // Set the label text.
        hud.label?.text = NSLocalizedString("Loading...", comment: "hud loading title")
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.doSomeWork()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    @objc func networkingExample() {
        let hud = MBProgressHUD.show(addedToView: (self.navigationController?.view)!, animated: true)
        
        // Set some text to show the initial status.
        hud.label?.text = NSLocalizedString("Preparing", comment: "hud preparing title")
        // Set min size
        hud.minSize = CGSize(width: 150, height: 100)
        
        doSomeNetworkWorkWithProgress()
    }
    
    
    // MARK - Tasks
    func doSomeWork() {
        sleep(3)
    }
    
    var canceled = false
    
    @objc func cancelWork(sender: AnyObject) {
        self.canceled = true
    }
    
    func doSomeWorkWithProgess() {
        var progress: Float = 0.0
        canceled = false
        while (progress < 1.0) {
            if (self.canceled) {
                break
            }
            progress += 0.01
            DispatchQueue.main.async {
                MBProgressHUD.hudForView((self.navigationController?.view)!)?.progress = progress
            }
            usleep(50000)
        }
    }
    
    func doSomeWork(forProgressObject progress: Progress) {
        // just increases the progress indicator
        while progress.fractionCompleted < 1.0 {
            if progress.isCancelled {
                break
            }
            progress.becomeCurrent(withPendingUnitCount: 1)
            progress.resignCurrent()
            usleep(50000)
        }
    }
    
    func doSomeWorkWithMixedProgress() {
        // Indetermimate mode
        sleep(2)
        // Switch to deteminate mode
        DispatchQueue.main.async {
            let hud = MBProgressHUD.hudForView((self.navigationController?.view)!)
            hud?.mode = .determinate
            hud?.label?.text = NSLocalizedString("Loading", comment: "hud loading title")
        }
        doSomeWorkWithProgess()
        
        // Back to indeter mode
        DispatchQueue.main.async {
            let hud = MBProgressHUD.hudForView((self.navigationController?.view)!)
            hud?.mode = .indeterminate
            hud?.label?.text = NSLocalizedString("Cleaning up...", comment: "hud cleaning up title")
        }
        sleep(2)
        DispatchQueue.main.sync {
            let hud = MBProgressHUD.hudForView((self.navigationController?.view)!)
            let image = #imageLiteral(resourceName: "Checkmark").withRenderingMode(.alwaysTemplate)
            let imageView = UIImageView(image: image)
            hud?.customView = imageView
            hud?.mode = .customView
            hud?.label?.text = NSLocalizedString("Completed", comment: "hud completed title")
        }
        sleep(2)
    }
    
    func doSomeNetworkWorkWithProgress() {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let url = URL(string: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/HT1425/sample_iPod.m4v.zip")
        let task = session.downloadTask(with: url!)
        task.resume()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return examples.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "exampleCell"
        let exapmle = examples[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = exapmle.0
        cell.textLabel?.textColor = self.view.tintColor
        cell.textLabel?.textAlignment = .center
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = cell.textLabel?.textColor.withAlphaComponent(0.1)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let example = examples[indexPath.row]
        perform(example.1)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: {
            tableView.deselectRow(at: indexPath, animated: true)
        })
    }
    
}

// MARK: - URLSessionDelegate
extension ViewController: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Do something with the data at location...
        
        // Update UI on the main thread
        DispatchQueue.main.async {
            let hud = MBProgressHUD.hudForView((self.navigationController?.view)!)
            let imageView = UIImageView(image:#imageLiteral(resourceName: "Checkmark").withRenderingMode(.alwaysTemplate))
            hud?.customView = imageView
            hud?.mode = .customView
            hud?.label?.text = NSLocalizedString("Completed", comment: "HUD completed title")
            hud?.hide(animated: true, afterDelay: 3.0)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        // Update UI on the main thread
        DispatchQueue.main.async {
            let hud = MBProgressHUD.hudForView((self.navigationController?.view)!)
            hud?.mode = .determinate
            hud?.progress = progress
        }
    }
}


//MARK: - 封装方便实用
extension MBProgressHUD {
    
    class func creatCustomHUD(_ view: UIView? = nil) -> MBProgressHUD {
        let window = UIApplication.shared.keyWindow
        let showView = view ?? window
        let hud = MBProgressHUD.show(addedToView: showView!, animated: true)
        hud.contentColor = UIColor.white
        hud.bezelView?.layer.cornerRadius = 8
        hud.bezelView?.backgroundColor = UIColor.black
        return hud
    }
    
    class func showToast(_ message: String, _ view: UIView? = nil) {
        let hud = MBProgressHUD.creatCustomHUD(view)
        hud.mode = .text
        hud.margin = 12
        hud.label?.text = message
        hud.bezelView?.layer.cornerRadius = 4
        hud.hide(animated: true, afterDelay: 2.0)
    }
    
    class func showLoading(_ message: String? = nil, _ view: UIView? = nil) {
        let hud = MBProgressHUD.creatCustomHUD(view)
        hud.label?.text = message
    }
    
    class func showImageToast(_ image: UIImage, _ message: String? = nil, _ view: UIView? = nil) {
        let hud = MBProgressHUD.creatCustomHUD(view)
        hud.mode = .customView
        hud.customView = UIImageView(image: image)
        hud.isSquare = true
        hud.label?.text = message
        hud.hide(animated: true, afterDelay: 2.5)
    }
    
    class func hideHud(_ view: UIView? = nil) {
        let window = UIApplication.shared.keyWindow
        let showView = view ?? window
        MBProgressHUD.hide(addedToView: showView!, animated: true)
    }
    
}
