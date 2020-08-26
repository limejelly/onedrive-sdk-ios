//  Copyright 2015 Microsoft Corporation
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


#import "ODAuthenticationViewController.h"
#import "ODAuthHelper.h"
#import "ODAuthConstants.h"

#define kRequestTimeoutDefault  60

@interface ODAuthenticationViewController() <WKNavigationDelegate>  // Ernie Ern2 UIWebVie_wDelegate

@property WKWebView *webView;   // Ern2

@property NSURLRequest *initialRequest;
@property (strong, nonatomic) ODEndURLCompletion successCompletion;
@property (strong, nonatomic) NSURL *endURL;

@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) BOOL isComplete;

@end

@implementation ODAuthenticationViewController

- (instancetype)initWithStartURL:(NSURL *)startURL
                          endURL:(NSURL *)endURL
                         success:(ODEndURLCompletion)sucessCompletion
{
    self = [super init];
    if (self){
        _endURL = endURL;
        _initialRequest = [NSURLRequest requestWithURL:startURL];
        _successCompletion = sucessCompletion;
        _requestTimeout = kRequestTimeoutDefault;
        _isComplete = NO;
    }
    return self;
}

- (void)cancel
{
    if (!self.isComplete)
    {
        [self.timer invalidate];
        self.timer = nil;
        self.isComplete = YES;
        
        NSError *cancelError = [NSError errorWithDomain:OD_AUTH_ERROR_DOMAIN code:ODAuthCanceled userInfo:@{}];
        if (self.successCompletion){
            self.successCompletion(nil, cancelError);
        }
    }
}

- (void)loadInitialRequest
{
    [self.webView loadRequest:self.initialRequest];
}

- (void)redirectWithStartURL:(NSURL *)startURL
                      endURL:(NSURL *)endURL
                      success:(ODEndURLCompletion)successCompletion
{
    self.endURL = endURL;
    self.successCompletion = successCompletion;
    self.initialRequest = [NSURLRequest requestWithURL:startURL];
    self.isComplete = NO;
    [self.webView loadRequest:self.initialRequest];
}

- (void)loadView
{
    self.webView = [[WKWebView alloc] init];
    // Ern2 [self.webView setScalesPageToFit:YES];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.navigationDelegate = self; // Ern2
    self.view = self.webView;
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(cancel)];
    self.navigationController.topViewController.navigationItem.leftBarButtonItem = cancel;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.webView loadRequest:self.initialRequest];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.webView stopLoading];
    self.webView.navigationDelegate = nil;
    [super viewWillDisappear:animated];
}

#pragma mark - UI_WebViewDelegate

// Ern2

- (void) webView: (WKWebView *) webView didStartProvisionalNavigation: (null_unspecified WKNavigation *) navigation {
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.requestTimeout target:self selector:@selector(failWithTimeout) userInfo:nil repeats:NO];
}
/*
- (void)webViewDidStartLoad:(UIWebVie_w *)webView
{
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.requestTimeout target:self selector:@selector(failWithTimeout) userInfo:nil repeats:NO];
} */

- (void) webView: (WKWebView *) webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self.timer invalidate];
    self.timer = nil;
}
/*
- (void)webViewDidFinishLoad:(UIWebVie_w *)webView
{
    [self.timer invalidate];
    self.timer = nil;
} */

- (void) webView: (WKWebView *) webView decidePolicyForNavigationAction: (WKNavigationAction *) navigationAction decisionHandler: (void (^)(WKNavigationActionPolicy)) decisionHandler {
    
    //NSLog(@"[ept] %@   %@", [navigationAction.request.URL absoluteString], [self.endURL absoluteString]);
    if ([[[navigationAction.request.URL absoluteString] lowercaseString] hasPrefix:[[self.endURL absoluteString] lowercaseString]]){
        self.isComplete = YES;
        [self.timer invalidate];
        self.timer = nil;
        
        self.successCompletion(navigationAction.request.URL, nil);
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    else decisionHandler(WKNavigationActionPolicyAllow);
}

/*
- (BOOL)webView:(UIWebVie_w *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebVie_wNavigationType)navigationType
{
    if ([[[request.URL absoluteString] lowercaseString] hasPrefix:[[self.endURL absoluteString] lowercaseString]]){
        self.isComplete = YES;
        [self.timer invalidate];
        self.timer = nil;
        
        self.successCompletion(request.URL, nil);
        return NO;
    }
    return YES;
} */

- (void) webView: (WKWebView *) webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error {
    
    [self.timer invalidate];
    self.timer = nil;
    
    if (NSURLErrorCancelled == error.code)
    {
        //This is a common error that webview generates and could be ignored.
        //See this thread for details: https://discussions.apple.com/thread/1727260
        return;
    }
    
    if([error.domain isEqual:@"WebKitErrorDomain"]){
        return;
    }
    
    // Ignore failures that are triggered after we have found the end URL
    if (self.isComplete)
    {
        //We expect to get an error here, as we intentionally fail to navigate to the final redirect URL.
        return;
    }
    
    if (self.successCompletion) {
        self.successCompletion(nil, error);
    }
}
/*
- (void)webView:(UIWebVie_w *)webView didFailLoadWithError:(NSError *)error
{
    [self.timer invalidate];
    self.timer = nil;
    
    if (NSURLErrorCancelled == error.code)
    {
        //This is a common error that webview generates and could be ignored.
        //See this thread for details: https://discussions.apple.com/thread/1727260
        return;
    }
    
    if([error.domain isEqual:@"WebKitErrorDomain"]){
        return;
    }
    
    // Ignore failures that are triggered after we have found the end URL
    if (self.isComplete)
    {
        //We expect to get an error here, as we intentionally fail to navigate to the final redirect URL.
        return;
    }
    
    if (self.successCompletion) {
        self.successCompletion(nil, error);
    }
}
*/

- (void)failWithTimeout
{
    [self webView: self.webView didFailNavigation: nil withError: [NSError errorWithDomain: NSURLErrorDomain code: NSURLErrorTimedOut userInfo:nil]];
    //[self webView:self.webView didFailLoadWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil]];
}

@end
