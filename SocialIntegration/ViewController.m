//
//  ViewController.m
//  SocialIntegration
//
//  Created by Francesco Mattia on 25/06/2013.
//  Copyright (c) 2013 Francesco. All rights reserved.
//

#import "ViewController.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import <Twitter/Twitter.h>
#import <FacebookSDK/FacebookSDK.h>
#import "DEFacebookComposeViewController.h"

@interface ViewController ()

@end

const NSString* kFBAppId = @"133004096754741";
BOOL failPublishOnAccountNotAvailable = NO;

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - facebook sharing

- (IBAction)autoPublish:(id)sender {
    if (NSClassFromString(@"SLComposeViewController") != nil) {
        // iOS6
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        
        ACAccountType *facebookAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
        
        // Specify App ID and permissions
        NSDictionary *options = @{
                                  ACFacebookAppIdKey: kFBAppId,
                                  ACFacebookPermissionsKey: @[@"publish_stream", @"publish_actions"],
                                  ACFacebookAudienceKey: ACFacebookAudienceFriends
                                  };
        
        // TODO investigate iOS6 with no account
        [accountStore requestAccessToAccountsWithType:facebookAccountType
                                              options:options completion:^(BOOL granted, NSError *e) {
        if (granted) {
            NSArray *accounts = [accountStore accountsWithAccountType:facebookAccountType];
            ACAccount *facebookAccount = [accounts lastObject];
            NSDictionary *parameters = @{@"message": @"My first iOS 6 Facebook posting "};

            NSURL *feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/photos"]; // me/feed

            SLRequest *feedRequest = [SLRequest
                                    requestForServiceType:SLServiceTypeFacebook
                                    requestMethod:SLRequestMethodPOST
                                    URL:feedURL 
                                    parameters:parameters];

            UIImage *image = [UIImage imageNamed:@"Default"];
            NSData *bitmapData = UIImagePNGRepresentation(image);
            [feedRequest addMultipartData:bitmapData
                                 withName:@"source"
                                     type:@"multipart/form-data"
                                 filename:@"TestImage"];
              
            feedRequest.account = facebookAccount;
              
            [feedRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                NSLog(@"Res: %@ Err: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding], [e localizedDescription]);
                // Handle response
            }];
          }
          else
          {
              // Handle Failure
              NSLog(@"Failed! %@", [e localizedDescription]);
          }
        }];
    } else {
        // iOS5 use fb sdk
    }
}

- (IBAction)publish:(id)sender {
    if (NSClassFromString(@"SLComposeViewController") != nil) {
        // iOS6 use social framework
        SLComposeViewController *fbController=[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        
        if(![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook] && failPublishOnAccountNotAvailable)
            return; // Facebook account not available, return
        
        SLComposeViewControllerCompletionHandler __block completionHandler=^(SLComposeViewControllerResult result){
            
            [fbController dismissViewControllerAnimated:YES completion:nil];
            
            switch(result){
                case SLComposeViewControllerResultCancelled:
                default:
                {
                    NSLog(@"Cancelled.....");
                    
                }
                    break;
                case SLComposeViewControllerResultDone:
                {
                    NSLog(@"Posted....");
                }
                    break;
            }};
        
        [fbController addImage:[UIImage imageNamed:@"Default"]];
        [fbController setInitialText:@"Check out this article."];
        [fbController addURL:[NSURL URLWithString:@"http://soulwithmobiletechnology.blogspot.com/"]];
        [fbController setCompletionHandler:completionHandler];
        [self presentViewController:fbController animated:YES completion:nil];
    }
}

#pragma mark - twitter sharing

- (IBAction)twitterAutoPublish:(id)sender {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:twitterAccountType
                            withCompletionHandler:^(BOOL granted, NSError *error) {
                                if (granted) {
                                    // Get the list of Twitter accounts.
                                    NSArray *accountsArray = [accountStore accountsWithAccountType:twitterAccountType];
                                    
                                    if ([accountsArray count] > 0) {
                                        // Grab the initial Twitter account to tweet from.
                                        ACAccount *twitterAccount = accountsArray[0];
                                        //NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"];
                                        NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update_with_media.json"];
                                        

                                        NSDictionary *content = @{@"status":@"This is a test"};
                                        if (NSClassFromString(@"SLRequest"))
                                        {
                                            SLRequest *postRequest = nil;
                                            postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                                             requestMethod:SLRequestMethodPOST
                                                                                       URL:url
                                                                                parameters:content];
                                            
                                            NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"Default"]);
                                            [postRequest addMultipartData:imageData
                                                             withName:@"media[]"
                                                                 type:@"image/png"
                                                             filename:@"image.png"];
                                            
                                            // Set the account used to post the tweet.
                                            [postRequest setAccount:twitterAccount];
                                            [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                                                if ([urlResponse statusCode] == 200) {
                                                    NSLog(@"Tweet successful");
                                                }else {
                                                    NSLog(@"Tweet failed");
                                                }
                                            }];
                                        }
                                        else
                                        {
                                            TWRequest *postRequest = nil;
                                            postRequest = [[TWRequest alloc] initWithURL:url
                                                                              parameters:content
                                                                           requestMethod:TWRequestMethodPOST];
                                            
                                            NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"Default"]);
                                            [postRequest addMultiPartData:imageData withName:@"media" type:@"image/png"];
                                            
                                            // Set the account used to post the tweet.
                                            [postRequest setAccount:twitterAccount];
                                            [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                                                if ([urlResponse statusCode] == 200) {
                                                    NSLog(@"Tweet successful");
                                                }else {
                                                    NSLog(@"Tweet failed");
                                                }
                                            }];
                                        }
                                    }
                                    else
                                    {
                                        // What should do when account not available?
                                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=TWITTER"]];
                                    }
                                }
                                else {
                                    // Access denied by the user - do what you need to do
                                    NSLog(@"Authenticated : User rejected access to his account.");
                                } 
                            }];
}

- (IBAction)twitterPublish:(id)sender {
    if (NSClassFromString(@"SLComposeViewController") != nil) {
        // iOS6 use social framework
        SLComposeViewController *twController=[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        
        if(![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter] && failPublishOnAccountNotAvailable)
            return; // Twitter account not available, return (alternatively would ask to log in)
        
        SLComposeViewControllerCompletionHandler __block completionHandler=^(SLComposeViewControllerResult result){
            
            [twController dismissViewControllerAnimated:YES completion:nil];
            
            switch(result){
                case SLComposeViewControllerResultCancelled:
                default:
                {
                    NSLog(@"Cancelled.....");
                    
                }
                    break;
                case SLComposeViewControllerResultDone:
                {
                    NSLog(@"Posted....");
                }
                    break;
            }};
        
        [twController addImage:[UIImage imageNamed:@"Default"]];
        [twController setInitialText:@"Check out this article."];
        [twController addURL:[NSURL URLWithString:@"http://soulwithmobiletechnology.blogspot.com/"]];
        [twController setCompletionHandler:completionHandler];
        [self presentViewController:twController animated:YES completion:nil];
    }
        else if (NSClassFromString(@"TWTweetComposeViewController") != nil)
    {
        // iOS5 use twitter framework
        if ([TWTweetComposeViewController canSendTweet]) {
            // Initialize Tweet Compose View Controller
            TWTweetComposeViewController *vc = [[TWTweetComposeViewController alloc] init];
            // Settin The Initial Text
            [vc setInitialText:@"This tweet was sent using the new Twitter framework available in iOS 5."];
            // Adding an Image
            UIImage *image = [UIImage imageNamed:@"sample.jpg"];
            [vc addImage:image];
            // Adding a URL
            NSURL *url = [NSURL URLWithString:@"http://mobile.tutsplus.com"];
            [vc addURL:url];
            // Setting a Completing Handler
            [vc setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
                [self dismissModalViewControllerAnimated:YES];
            }];
            // Display Tweet Compose View Controller Modally
            [self presentViewController:vc animated:YES completion:nil];
        } else {
            // No twitter account available
        }
    }
}

#pragma mark - sina weibo share

- (IBAction)sinaPublish:(id)sender {
    if (NSClassFromString(@"SLComposeViewController") != nil) {
        // iOS6 use social framework
        SLComposeViewController *swController=[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeSinaWeibo];
        
            if(![SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo] && failPublishOnAccountNotAvailable)
                return; // SinaWeibo account not available, return
        
            SLComposeViewControllerCompletionHandler __block completionHandler=^(SLComposeViewControllerResult result){
                
                [swController dismissViewControllerAnimated:YES completion:nil];
                
                switch(result){
                    case SLComposeViewControllerResultCancelled:
                    default:
                    {
                        NSLog(@"Cancelled.....");
                        
                    }
                        break;
                    case SLComposeViewControllerResultDone:
                    {
                        NSLog(@"Posted....");
                    }
                        break;
                }};
            
            [swController addImage:[UIImage imageNamed:@"Default"]];
            [swController setInitialText:@"Check out this article."];
            [swController addURL:[NSURL URLWithString:@"http://soulwithmobiletechnology.blogspot.com/"]];
            [swController setCompletionHandler:completionHandler];
            [self presentViewController:swController animated:YES completion:nil];
    }
}

- (IBAction)sinaAutoPublish:(id)sender {
    if (NSClassFromString(@"SLRequest"))
    {
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierSinaWeibo];
        [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
            if (granted) {
                //NSURL *url = [NSURL URLWithString:@"https://api.weibo.com/2/comments/create.json"];
                NSURL *url = [NSURL URLWithString:@"http://api.t.sina.com.cn/statuses/update.json"];
                NSDictionary *params = @{@"status": @"This is a test"};
                
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeSinaWeibo requestMethod:SLRequestMethodPOST URL:url parameters:params];
                request.account = [[accountStore accountsWithAccountType:accountType] lastObject];
                
                [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    if ([urlResponse statusCode] == 200) {
                        NSLog(@"Post successful");
                    }else {
                        NSLog(@"Post failed");
                    }
                }];
            } else {
                
            }
        }];
    }
}

#pragma mark - vkontakte share

- (IBAction)vkontaktePublish:(id)sender {
}

- (IBAction)vkontakteAutoPublish:(id)sender {
}

#pragma mark - ios5 facebook

- (IBAction)fbiOS5AutoPublish:(id)sender {
    if (![FBSession.activeSession isOpen]) {
        NSLog(@"%@",FBSession.activeSession);
        BOOL sessionOpened = [FBSession openActiveSessionWithReadPermissions:nil allowLoginUI:NO completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            if (!error)
                [self fbiOS5AutoPublish:nil];
            else
                NSLog(@"Error: %@", [error localizedDescription]);
        }];
        if (!sessionOpened)
            NSLog(@"Could not open session");
        return;
    }
    
    //d = [NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@\n%@",self.textView.text,[[self.urls lastObject] absoluteString]]
    //                                           forKey:@"message"];
    //d = [NSMutableDictionary dictionaryWithObject:self.textView.text
    //                                           forKey:@"message"];
    NSDictionary *d = @{@"message":@"This is a third test"};//,
                        //UIImagePNGRepresentation([UIImage imageNamed:@"Default"]):@"source"};
    
    NSString *graphPath = @"me/feed";
    //graphPath = @"me/photos";

    //[d setObject:[[self.urls lastObject] absoluteString] forKey:@"link"];
    //[d setObject:UIImagePNGRepresentation([UIImage imageNamed:@"Default"]) forKey:@"source"];
    //graphPath = @"me/photos";
    
    //[d addEntriesFromDictionary:self.customParameters];
    
    // create the connection object
    FBRequestConnection *newConnection = [[FBRequestConnection alloc] init];
    FBRequest *request = [[FBRequest alloc] initWithSession:FBSession.activeSession
                                                  graphPath:graphPath
                                                 parameters:d
                                                 HTTPMethod:@"POST"];
    
    [newConnection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error)
        {            
            NSLog(@"Error: %@", [error localizedDescription]);
        }
        else
        {
            NSLog(@"Post success");
        };
    }];
    
    [newConnection start];
}

- (IBAction)fbiOS5Publish:(id)sender {
    DEFacebookComposeViewController *facebookViewComposer = [[DEFacebookComposeViewController alloc] init];
    
    // If you want to use the Facebook app with multiple iOS apps you can set an URL scheme suffix
    //    facebookViewComposer.urlSchemeSuffix = @"facebooksample";
    
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    [facebookViewComposer setInitialText:@"Look on this"];
    
    // optional
    [facebookViewComposer addImage:[UIImage imageNamed:@"Default"]];
    // and/or
    // optional
    //    [facebookViewComposer addURL:[NSURL URLWithString:@"http://applications.3d4medical.com/heart_pro.php"]];
    
    [facebookViewComposer setCompletionHandler:^(DEFacebookComposeViewControllerResult result) {
        switch (result) {
            case DEFacebookComposeViewControllerResultCancelled:
                NSLog(@"Facebook Result: Cancelled");
                break;
            case DEFacebookComposeViewControllerResultDone:
                NSLog(@"Facebook Result: Sent");
                break;
        }
        
        [self dismissModalViewControllerAnimated:YES];
    }];
    
    [self presentViewController:facebookViewComposer animated:YES completion:nil];
}

- (void)alternativeIOS6SharingWithoutSocial
{
    // on iOS6 uses automatically social framework
    UIImage *image = [UIImage imageNamed:@"Default"];
    NSURL *url = [NSURL URLWithString:@"http://www.myurl.com"];
    [FBDialogs presentOSIntegratedShareDialogModallyFrom:self initialText:@"This is a test" image:image url:url handler:^(FBOSIntegratedShareDialogResult result, NSError *error) {
        switch (result) {
            case FBOSIntegratedShareDialogResultSucceeded:
            {
                NSLog(@"Post succeeded");
            }
            case FBOSIntegratedShareDialogResultCancelled:
            {
                NSLog(@"Post cancelled");
            }
            case FBOSIntegratedShareDialogResultError:
            {
                // on iOS6 calls error if no account is available
                NSLog(@"Post ERROR %@", [error localizedDescription]);
            }
            default:
                break;
        }
    }];
}

@end
