//
//  ViewController.m
//  SocialIntegration
//
//  Created by Francesco Mattia on 25/06/2013.
//  Copyright (c) 2013 AKQA. All rights reserved.
//

#import "ViewController.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface ViewController ()

@end

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

- (IBAction)autoPublish:(id)sender {
    if (NSClassFromString(@"SLComposeViewController") != nil) {
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        
        ACAccountType *facebookAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
        
        // Specify App ID and permissions
        NSDictionary *options = @{
                                  ACFacebookAppIdKey: @"133004096754741",
                                  ACFacebookPermissionsKey: @[@"publish_stream", @"publish_actions"],
                                  ACFacebookAudienceKey: ACFacebookAudienceFriends
                                  };
        
        [accountStore requestAccessToAccountsWithType:facebookAccountType
                                              options:options completion:^(BOOL granted, NSError *e) {
        if (granted) {
              NSArray *accounts = [accountStore
                                   accountsWithAccountType:facebookAccountType];
              ACAccount *facebookAccount = [accounts lastObject];
              NSDictionary *parameters = @{@"message": @"My first iOS 6 Facebook posting "};
              
              NSURL *feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/feed"];
              
              SLRequest *feedRequest = [SLRequest
                                        requestForServiceType:SLServiceTypeFacebook
                                        requestMethod:SLRequestMethodPOST
                                        URL:feedURL 
                                        parameters:parameters];
              
              feedRequest.account = facebookAccount;
              
              [feedRequest performRequestWithHandler:^(NSData *responseData, 
                                                       NSHTTPURLResponse *urlResponse, NSError *error)
              {
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
    }
}

- (IBAction)publish:(id)sender {
    if (NSClassFromString(@"SLComposeViewController") != nil) {
        SLComposeViewController *fbController=[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        
        if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
        {
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
}



@end
