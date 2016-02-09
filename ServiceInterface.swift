/*
Copyright (c) 2016, Srinivas Padidala
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

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
                }
            })
        }else {
            let response = task.response as! NSHTTPURLResponse
            NSLog("Response Header Fields:%@\n\nerror: %d\nError:%@\nURL:%@",response.allHeaderFields, response.statusCode, NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode), response.URL!);
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(self.theDelegate .respondsToSelector(self.successMethod)){
                    self.theDelegate .performSelector(self.successMethod, withObject: self.theResponseData)
                }
            })
        }
    }
}