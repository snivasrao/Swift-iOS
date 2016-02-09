//
//  ServiceInterface.swift
//  SelfiePay
//
//  Created by Srinivas Padidala on 20/11/15.
//  Copyright © 2015 Personal. All rights reserved.
//

import Foundation

class ServiceError {
    var description:String = String()
    var debugDescription:String = String()
    var errorCode:Int = -1
}

typealias CompleteHandlerBlock = () -> ()

class ServiceInterface:NSObject, NSURLSessionDelegate{
    var theDelegate:NSObject!
    var successMethod:Selector!
    var failureMethod:Selector!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var theResponseData:NSMutableData!
    
    func startWithURL(url:NSURL) {
        let request:NSURLRequest!
        request = NSURLRequest(URL: url)
        self.startWithRequest(request)
    }
    
    func startWithRequest(request:NSURLRequest) {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfiguration.allowsCellularAccess = true

        let session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        
        let dataTask:NSURLSessionDataTask!
        dataTask = session.dataTaskWithRequest(request)
        dataTask.resume()
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        if(error != nil) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(self.theDelegate != nil) {
                    if(self.theDelegate .respondsToSelector(self.failureMethod)){
                        let errorObj:ServiceError! = ServiceError()
                        errorObj.description = (error?.description)!
                        errorObj.debugDescription = error.debugDescription
                        errorObj.errorCode = (error?.code)!
                        self.theDelegate .performSelector(self.failureMethod, withObject: errorObj)
                    }
                }
            })
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        let protectionSpace = challenge.protectionSpace
        
        let theSender = challenge.sender
        
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            
            if let theTrust = protectionSpace.serverTrust{
                
                let theCredential = NSURLCredential(trust: theTrust)
                
                theSender!.useCredential(theCredential, forAuthenticationChallenge: challenge)
                
                completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, theCredential)
                return
            }
        }
        
        theSender!.performDefaultHandlingForAuthenticationChallenge!(challenge)
        completionHandler(NSURLSessionAuthChallengeDisposition.PerformDefaultHandling, nil)
        
        return
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if theResponseData == nil {
            theResponseData = NSMutableData()
        }
        
        theResponseData.appendData(data)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {

        if error != nil {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(self.theDelegate .respondsToSelector(self.failureMethod)){
                    let errorObj:ServiceError! = ServiceError()
                    errorObj.description = (error?.description)!
                    errorObj.debugDescription = error.debugDescription
                    errorObj.errorCode = (error?.code)!
                    self.theDelegate .performSelector(self.failureMethod, withObject: errorObj)
                }else {
                    NSLog("\n\nResponse failed!!!!\(error)")
                    self.appDelegate.hideActivity()
                }
            })
        }else {
            let response = task.response as! NSHTTPURLResponse
            NSLog("Response Header Fields:%@\n\nerror: %d\nError:%@\nURL:%@",response.allHeaderFields, response.statusCode, NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode), response.URL!);
//            if (response.statusCode >= 200) && (response.statusCode < 300) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(self.theDelegate .respondsToSelector(self.successMethod)){
                    self.theDelegate .performSelector(self.successMethod, withObject: self.theResponseData)
                }else {
                    self.appDelegate.hideActivity()
                }
            })
            
//            }else {
//                if(theDelegate .respondsToSelector(failureMethod)){
//                    let errorObj:ServiceError! = ServiceError()
//                    errorObj.description = response.description
//                    errorObj.debugDescription = response.debugDescription
//                    errorObj.errorCode = response.statusCode
//                    theDelegate .performSelector(failureMethod, withObject: errorObj)
//                }else {
//                    appDelegate.hideActivity()
//                }
//            }
        }
    }
}