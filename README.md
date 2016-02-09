# ServiceInterface
This swift class will be used for web service integration into our projects
<pre><code>let url = NSURL(string: "your service url string")
let request = NSMutableURLRequest(URL: url!)
request.HTTPMethod = "POST"
request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
request.setValue("application/json", forHTTPHeaderField: "Accept")

let service = ServiceInterface()
service.theDelegate = self
service.successMethod = Selector("SuccessResponse:")
service.failureMethod = Selector("failureResponse:")
service.startWithRequest(request)
</code></pre>
