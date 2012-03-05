//
//  TMGitSuggestEngine.m
//  gitSuggest
//
//  Created by Nicholas Iannone on 3/5/12.
//  Copyright (c) 2012 Tiny Mobile Inc. All rights reserved.
//

#import "TMGitSuggestEngine.h"
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1
#define kLatestKivaLoansURL @"https://api.github.com/repos/" //2

@interface NSDictionary(JSONCategories)
+(NSDictionary*)dictionaryWithContentsOfJSONURLString:(NSString*)urlAddress;
-(NSData*)toJSON;
@end

@implementation NSDictionary(JSONCategories)

+(NSDictionary*)dictionaryWithContentsOfJSONURLString:(NSString*)urlAddress
{
    NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: urlAddress] ];
    __autoreleasing NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error != nil) return nil;
    return result;
}

-(NSData*)toJSON
{
    NSError* error = nil;
    id result = [NSJSONSerialization dataWithJSONObject:self options:kNilOptions error:&error];
    if (error != nil) return nil;
    return result;    
}
@end

@implementation TMGitSuggestEngine

@synthesize repoName;
@synthesize repoWatchers;
@synthesize bigRepoList;
@synthesize repoDictWithAttributes;


-(id) initWithUserName:(NSString *) user andRepoName:(NSString *) repo {
    
    if (self = [super init]) {
        self.repoName = repo;
        self.repoWatchers = [[NSMutableArray alloc] init];
        self.bigRepoList = [[NSMutableArray alloc] init];
        repoCheckCount = 0;
        self.repoDictWithAttributes = [[NSMutableDictionary alloc] init];
        dispatch_async(kBgQueue, ^{
            NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[kLatestKivaLoansURL stringByAppendingFormat:@"%@/%@/watchers", user, self.repoName]]];
            [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
        });
    }
    
    return self;
}


- (void)fetchedData:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSArray* json = [NSJSONSerialization JSONObjectWithData:responseData //1
                                                         options:kNilOptions 
                                                           error:&error];
    for (NSDictionary *l in json) {
        
        
        [repoWatchers addObject:[l objectForKey:@"login"]];
          
        
    }
    NSLog(@"%@", repoWatchers);
    [self compileListOfReposBasedOnWatchers];
    
}   

-(void) compileListOfReposBasedOnWatchers {
    
    for (NSString *loginName in self.repoWatchers) {
        
        NSLog(@"repo check for :%@",loginName);
        dispatch_sync(kBgQueue, ^{
           
            NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.github.com/users/%@/repos", loginName]]];
            [self performSelectorOnMainThread:@selector(addToBigListOfRepos:) withObject:data waitUntilDone:YES];
        });
    }
    
}

-(void) addToBigListOfRepos:(NSData *) data {
    NSError* error;
    NSArray* json = [NSJSONSerialization JSONObjectWithData:data //1
                                                    options:kNilOptions 
                                                      error:&error];
    for (NSDictionary *dict in json) {
        if ([[dict valueForKey:@"fork"] intValue] == 0) {
            [self.bigRepoList addObject:dict];
        }
    }
    repoCheckCount ++;

//    for (NSDictionary *repo in self.bigRepoList) {
//        NSLog(@"%@",[repo valueForKey:@"name"]);
//
//    }
    if (repoCheckCount == [self.repoWatchers count]) {
        [self enumerateThroughReposAndIncrementPopularity];
    }
}

-(void) enumerateThroughReposAndIncrementPopularity {
    
    for (NSDictionary *singleRepo in self.bigRepoList) {
        NSMutableDictionary *repoMatchDict = [[NSMutableDictionary alloc] init];
        
        [repoMatchDict setObject:[singleRepo objectForKey:@"name"] forKey:@"repoName"];
        [repoMatchDict setObject:[singleRepo objectForKey:@"watchers"] forKey:@"watchers"];
        [repoMatchDict setObject:[NSNumber numberWithInt:0] forKey:@"matchCount"];

        [repoDictWithAttributes setObject:repoMatchDict forKey:[singleRepo objectForKey:@"name"]];
        [repoMatchDict release];
        
        dispatch_async(kBgQueue, ^{
           
            NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[kLatestKivaLoansURL stringByAppendingFormat:@"%@/%@/watchers", [[singleRepo objectForKey:@"owner"] objectForKey:@"login"], [singleRepo objectForKey:@"name"]]]];
            [self performSelector:@selector(checkForMatchingWatchers:forRepoName:) withObject:data withObject:[singleRepo objectForKey:@"name"]];
        });
        
    }
}

-(void) checkForMatchingWatchers:(NSData *) data forRepoName:(NSString*) repo {
    
    NSError* error;
    NSArray* json = [NSJSONSerialization JSONObjectWithData:data //1
                                                    options:kNilOptions 
                                                      error:&error];
    for (NSString *originalWatcher in self.repoWatchers) {
        
            for (NSInteger i = 0; i < [json count]; i++) {
            if ([originalWatcher isEqualToString:[[json objectAtIndex:i] objectForKey:@"login"]]) {
                [[repoDictWithAttributes objectForKey:repo] setObject:[NSNumber numberWithInt:[[[repoDictWithAttributes objectForKey:repo] objectForKey:@"matchCount"] intValue] + 1] forKey:@"matchCount"];
            
            }
        }
        
        
        
        
        
        //compare the original names with the login names returned and see if there is any matches
    
    }
    for (NSDictionary *dd in [repoDictWithAttributes allValues]) {
    
        NSLog(@"%@ %@", [dd objectForKey:@"repoName"], [dd objectForKey:@"matchCount"]);
            
    }
}



@end
