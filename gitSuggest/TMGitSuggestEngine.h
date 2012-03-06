//
//  TMGitSuggestEngine.h
//  gitSuggest
//
//  Created by Nicholas Iannone on 3/5/12.
//  Copyright (c) 2012 Tiny Mobile Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMGitSuggestEngine : NSObject {
    
    NSString *repoName;
    NSString *userName;

    NSMutableArray *repoWatchers;
    NSMutableArray *bigRepoList;
    NSMutableDictionary *repoDictWithAttributes; 
    NSInteger repoCheckCount;
    NSInteger matchProgression;
    NSInteger matchProgressionHighMark;

    
    
}
@property (nonatomic, retain) NSString *repoName;
@property (nonatomic, retain) NSString *userName;
@property (nonatomic, retain) NSMutableArray *repoWatchers;
@property (nonatomic, retain) NSMutableArray *bigRepoList;
@property (nonatomic, retain) NSMutableDictionary *repoDictWithAttributes;
@property (assign) IBOutlet NSTextField *gitAddress;
@property (assign) IBOutlet NSArrayController *tViewController;






-(id) initWithUserName:(NSString *) user andRepoName:(NSString *) repo;
-(void) compileListOfReposBasedOnWatchers;
-(void) addToBigListOfRepos:(NSData *) data;
-(void) enumerateThroughReposAndIncrementPopularity;
-(void) checkForMatchingWatchers:(NSData *) data forRepoName:(NSString*) repo;
- (IBAction)submit:(id)sender;
-(void) kickoffSuggestionEngine;


@end
