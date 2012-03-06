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
    NSMutableArray *repoWatchers;
    NSMutableArray *bigRepoList;
    NSMutableDictionary *repoDictWithAttributes; 
    NSInteger repoCheckCount;
    NSInteger matchProgression;

    
    
}
@property (nonatomic, retain) NSString *repoName;
@property (nonatomic, retain) NSMutableArray *repoWatchers;
@property (nonatomic, retain) NSMutableArray *bigRepoList;
@property (nonatomic, retain) NSMutableDictionary *repoDictWithAttributes;






-(id) initWithUserName:(NSString *) user andRepoName:(NSString *) repo;
-(void) compileListOfReposBasedOnWatchers;
-(void) addToBigListOfRepos:(NSData *) data;
-(void) enumerateThroughReposAndIncrementPopularity;
-(void) checkForMatchingWatchers:(NSData *) data forRepoName:(NSString*) repo;
@end
