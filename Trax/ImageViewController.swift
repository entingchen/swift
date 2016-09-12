//
//  ImageViewController.swift
//  Cassini
//
//  Created by enting chen on 2016/8/24.
//  Copyright © 2016年 enting chen. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    var imageURL: NSURL? {
        didSet {
            image = nil
            if view.window != nil {
                fetchImage()
            }
        }
    }
    
    private func fetchImage() {
        if let url = imageURL {
//            if let imageData = NSData(contentsOfURL: url) {
//                image = UIImage(data: imageData)
//            }
            spinner?.startAnimating()
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                let contentsOfURL = NSData(contentsOfURL: url)
                
                dispatch_async(dispatch_get_main_queue()){ [weak weakSelf = self] in
                    
                    if url ==  weakSelf?.imageURL {
                        if let imageData = contentsOfURL {
                            weakSelf?.image = UIImage(data: imageData)
                                                    }
                        else {
                            weakSelf?.spinner?.stopAnimating()

                        }
                    }
                    else {
                        print("ignore return fetch, url = \(url)")
                    }
                }
            }

        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView?.contentSize = imageView.frame.size
            scrollView.delegate = self
            scrollView.minimumZoomScale = 0.03
            scrollView.maximumZoomScale = 1.0
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    private var imageView = UIImageView()
    
    private var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
            
            scrollView?.contentSize = imageView.frame.size
            
            spinner?.stopAnimating()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if image == nil {
            fetchImage()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //view.addSubview(imageView)
        scrollView.addSubview(imageView)
        
        //imageURL = NSURL(string: DemoURL.Stanford)
        
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
