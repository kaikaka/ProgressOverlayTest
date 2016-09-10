//
//  ViewController.swift
//  ProgressOverlayTest
//
//  Created by xiangkai yin on 16/9/7.
//  Copyright © 2016年 kuailao_2. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,NSURLConnectionDataDelegate {
  
  @IBOutlet weak var tableView: UITableView!
  
  typealias demoMethod = ViewController -> () -> Void
  
  var progressOverlay:ProgressOverlay!
  
  var canceled = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  
  let demos:[(String, demoMethod)] =
    [
      ("Simple indeterminate progress", simpleIndeterminateProgress),
      ("With label", withLabel),
      ("With details label", withDetailsLabel),
      ("Determinate mode", determinateMode),
      ("Annular determinate mode", annularDeterminateMode),
      ("Bar determinate mode", barDeterminateMode),
      ("Custom view", customView),
      ("Mode switching", modeSwitching),
      ("With action button", cancelationExample),
      ("On Window", onWindow),
      ("NSURLConnection", nsURLConnection),
      ("Dim background", dimBackground),
      ("Text only", textOnly),
      ("Colored", colored)
  ]
  
  // Used in the NSURLConnection demo.
  var expectedLength:Int64 = 0
  var currentLength:Int64 = 0
  
  // MARK: - Data source: supply the table view with the demo button cells.
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return demos.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell:TableViewCell = tableView.dequeueReusableCellWithIdentifier("mainCell", forIndexPath: indexPath) as! TableViewCell
    cell.demoButton.setTitle(demos[indexPath.row].0, forState: .Normal)
    cell.demoButton.tag = indexPath.row
    cell.demoButton.addTarget(self, action: #selector(demoButtonTapped(_:)), forControlEvents: .TouchUpInside)
    return cell
  }
  
  // MARK: - NSURLConnection Delegate methods
  
  func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
    expectedLength = max(response.expectedContentLength, 1)
    currentLength = 0
    progressOverlay?.mode = .Determinate
  }
  
  func connection(connection: NSURLConnection, didReceiveData data: NSData) {
    currentLength += data.length
    progressOverlay.forProgress(Double(currentLength) / Double(expectedLength))
  }
  
  func connectionDidFinishLoading(connection: NSURLConnection) {
    progressOverlay?.customView = UIImageView(image: UIImage(named: "Checkmark"))
    progressOverlay?.mode = .CustomView
    progressOverlay?.hideAnimated(true, delay: 2.0)
  }
  
  func connection(connection: NSURLConnection, didFailWithError error: NSError) {
    progressOverlay?.hideAnimated(true)
  }
  
  // MARK: - Actions
  
  func doSomeWork() {
    sleep(3)
  }
  
  func doSomeWorkWithProgress() {
    self.canceled = false
    var progress:Double = 0.0
    while progress < 1.0 {
      if self.canceled {
        break
      }
      progress += 0.01
      progressOverlay.forProgress(progress) 
      usleep(50000)
    }
  }
  
  func doSomeWorkWithMixedProgress() {
    // Indeterminate mode
    sleep(2)
    
    // Switch to determinate mode
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.progressOverlay?.mode = .Determinate
      self.progressOverlay?.label.text = "Progress"
    })
    
    var progress:Double = 0.0
    while (progress < 1.0) {
      progress += 0.01
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.progressOverlay?.forProgress(progress)
      })
      usleep(50000)
    }
    
    // Back to indeterminate mode
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.progressOverlay?.mode = .Indeterminate
      self.progressOverlay?.label.text = "Cleaning up"
    })
    
    sleep(2)
    
    // UIImageView is a UIKit class, we have to initialise it on the main thread
    dispatch_sync(dispatch_get_main_queue()) {
      let image = UIImage(named: "Checkmark")
      let imageView = UIImageView(image: image)
      
      self.progressOverlay?.customView = imageView
      self.progressOverlay?.mode = .CustomView
      self.progressOverlay?.label.text = "Completed"
    }
    
    sleep(2)
  }

  func doSomeNetworkWorkWithProgress() {

    guard let url = NSURL(string: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/HT1425/sample_iPod.m4v.zip") else { return }
    let request = NSURLRequest(URL: url)
    
    // TODO: Add a demo that uses NSURLSession instead of the deprecated NSURLConnection.
    let connection = NSURLConnection(request: request, delegate: self)
    connection?.start()
    
    progressOverlay = ProgressOverlay.showOnView(self.navigationController?.view, animated: true)
    progressOverlay.removeFromSuperViewOnHide = true
  }
  
  func demoButtonTapped(button:UIButton) {
    // Run the requested demo.
    let demoIndex = button.tag
    (demos[demoIndex].1(self))()
  }
  
  func cancelWork() {
    self.canceled = true
  }
  
  // MARK: - Demos
  
  func simpleIndeterminateProgress() {
    // The overlay disables all input on the view (uses the highest view possible in the view hierarchy).
    progressOverlay = ProgressOverlay.showOnView(self.navigationController?.view, animated: true)
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      // Do something useful in the background
      self.doSomeWork()
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.progressOverlay?.hideAnimated(true)
      })
    })
  }
  
  func withLabel() {
    // The overlay disables all input on the view (uses the highest view possible in the view hierarchy).
    progressOverlay = ProgressOverlay.showOnView(self.navigationController?.view, animated: true)
    // set the label text (设置文本)
    progressOverlay.label.text = "Loading"
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      // Do something useful in the background
      self.doSomeWork()
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.progressOverlay.hideAnimated(true)
      })
    })
  }
  
  func withDetailsLabel() {
    // The overlay disables all input on the view (uses the highest view possible in the view hierarchy).
    let progressOverlay = ProgressOverlay.showOnView(self.navigationController?.view, animated: true)
    // set the label text (设置文本)
    progressOverlay.label.text = "Loading"
    
    // Set detail label text (设置详情文本)
    progressOverlay.detailsLabel.text = "Parsing data\n(1/1)"
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      // Do something useful in the background
      self.doSomeWork()
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        progressOverlay.hideAnimated(true)
      })
    })
  }
  
  func determinateMode() {
    // The overlay disables all input on the view (uses the highest view possible in the view hierarchy).
    progressOverlay = ProgressOverlay.showOnView(self.navigationController?.view, animated: true)
    
    progressOverlay.mode = ProgressOverlayMode.Determinate
    // set the label text (设置文本)
    progressOverlay.label.text = "Loading"
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      // Do something useful in the background
      self.doSomeWorkWithProgress()
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.progressOverlay.hideAnimated(true)
      })
    })
  }
  
  func annularDeterminateMode() {
    // The overlay disables all input on the view (uses the highest view possible in the view hierarchy).
    progressOverlay = ProgressOverlay.showOnView(self.navigationController?.view, animated: true)
    
    progressOverlay.mode = ProgressOverlayMode.AnnularDeterminate
    // set the label text (设置文本)
    progressOverlay.label.text = "Loading"
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      // Do something useful in the background
      self.doSomeWorkWithProgress()
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.progressOverlay.hideAnimated(true)
      })
    })
  }
  
  func barDeterminateMode() {
    // The overlay disables all input on the view (uses the highest view possible in the view hierarchy).
    progressOverlay = ProgressOverlay.showOnView(self.navigationController?.view, animated: true)
    
    progressOverlay.mode = ProgressOverlayMode.DeterminateHorizontalBar
    // set the label text (设置文本)
    progressOverlay.label.text = "Loading"
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      // Do something useful in the background
      self.doSomeWorkWithProgress()
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.progressOverlay.hideAnimated(true)
      })
    })
  }
  
  func customView() {
    // The overlay disables all input on the view (uses the highest view possible in the view hierarchy).
    let progressOverlay = ProgressOverlay.showOnView(self.navigationController?.view, animated: true)
    
    progressOverlay.mode = ProgressOverlayMode.CustomView
    // Set an image view with a checkmark.
    let image = UIImage.init(named: "Checkmark")?.imageWithRenderingMode(.AlwaysTemplate)
    progressOverlay.customView = UIImageView.init(image: image)
    progressOverlay.square = true
    
    // Optional label text.
    progressOverlay.label.text = "Done"
    
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      progressOverlay.hideAnimated(true, delay: 3.0)
    })
  }
  
  func modeSwitching() {
    // The overlay disables all input on the view (uses the highest view possible in the view hierarchy).
    progressOverlay = ProgressOverlay.showOnView(self.navigationController?.view, animated: true)
    
    //Set some text to show the initial status.
    progressOverlay.label.text = "Done"
    
    progressOverlay.minSize = CGSizeMake(150.0, 100.0)
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      // Do something useful in the background
      self.doSomeWorkWithMixedProgress()
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.progressOverlay.hideAnimated(true)
      })
    })
  }

  func textOnly() {
    
    // The overlay disables all input on the view (uses the highest view possible in the view hierarchy).
    let progressOverlay = ProgressOverlay.showOnView(self.navigationController?.view, animated: true)
    
    progressOverlay.mode = ProgressOverlayMode.Text
    progressOverlay.label.text = "Message here!"
    
    // Move to bottm center.
    progressOverlay.offset = CGPointMake(0.0, ProgressOverlayMaxOffset)
    
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      progressOverlay.hideAnimated(true, delay: 3.0)
    })
  }
  
  func cancelationExample() {
    
    // The overlay disables all input on the view (uses the highest view possible in the view hierarchy).
    progressOverlay = ProgressOverlay.showOnView(self.navigationController?.view, animated: true)
    
    progressOverlay.mode = ProgressOverlayMode.Determinate
    // set the label text (设置文本)
    progressOverlay.label.text = "Loading"
    
    progressOverlay.button.setTitle("Cancel", forState: .Normal)
    progressOverlay.button.addTarget(self, action: #selector(cancelWork), forControlEvents: .TouchUpInside)
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      // Do something useful in the background
      self.doSomeWorkWithProgress()
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.progressOverlay.hideAnimated(true)
      })
    })
  }
  
  func onWindow(){
    
    let progressOverlay = ProgressOverlay.showOnView(self.view.window, animated: true)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      // Do something useful in the background
      self.doSomeWork()
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        progressOverlay.hideAnimated(true)
      })
    })
  }
  
  func nsURLConnection() {
    self.doSomeNetworkWorkWithProgress()
  }
  
  func dimBackground() {
    // The overlay disables all input on the view (uses the highest view possible in the view hierarchy).
    let progressOverlay = ProgressOverlay.showOnView(self.navigationController?.view, animated: true)
    
    progressOverlay.backgroundView.style = OverlayBackgroundStyle.SolidColor
    progressOverlay.backgroundView.color = UIColor.init(white: 0.0, alpha: 0.1)
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      // Do something useful in the background
      self.doSomeWork()
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        progressOverlay.hideAnimated(true)
      })
    })
  }
  
  func colored() {
    // The overlay disables all input on the view (uses the highest view possible in the view hierarchy).
    let progressOverlay = ProgressOverlay.showOnView(self.navigationController?.view, animated: true)
    progressOverlay.contentColor = UIColor.init(red: 0.0, green: 0.6, blue: 0.7, alpha: 1.0)
    progressOverlay.label.text = "Loading..."
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
      // Do something useful in the background
      self.doSomeWork()
      
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        progressOverlay.hideAnimated(true)
      })
    })
  }
}

