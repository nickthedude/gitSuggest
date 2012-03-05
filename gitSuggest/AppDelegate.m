//
//  AppDelegate.m
//  gitSuggest
//
//  Created by Nicholas Iannone on 3/5/12.
//  Copyright (c) 2012 Tiny Mobile Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "TMGitSuggestEngine.h"
@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    TMGitSuggestEngine *gEngine = [[TMGitSuggestEngine alloc] initWithUserName:@"cocos2d" andRepoName:@"cocos2d-iphone-extensions"];
    
}

@end
