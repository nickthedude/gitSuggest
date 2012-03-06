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



@implementation TMGitSuggestEngine
@synthesize tViewController;
@synthesize repoScrollView;

@synthesize waitMessage;
@synthesize repoName;
@synthesize repoWatchers;
@synthesize bigRepoList;
@synthesize sortedArray;
@synthesize repoDictWithAttributes;
@synthesize gitAddress;
@synthesize userName;

- (IBAction)submit:(id)sender {
    repoCheckCount = 0;
    matchProgression = 0;
    NSArray *ar = [NSArray arrayWithArray:[self.gitAddress.stringValue pathComponents]];
    NSLog(@"%@", ar);
    self.repoName = [[ar objectAtIndex:3] stringByReplacingOccurrencesOfString:@".git" withString:@""];
    self.userName   = [ar objectAtIndex:2]; 
    
    [self kickoffSuggestionEngine];
    [self.waitMessage setHidden:NO];

                   
           
}

-(void) kickoffSuggestionEngine {
   
    self.repoWatchers = [[[NSMutableArray alloc] init] retain];
    self.bigRepoList = [[NSMutableArray alloc] init];
    self.repoDictWithAttributes = [[NSMutableDictionary alloc] init];
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[kLatestKivaLoansURL stringByAppendingFormat:@"%@/%@/watchers?per_page=100", self.userName, self.repoName]]];
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
    });

    
}

-(id) initWithUserName:(NSString *) user andRepoName:(NSString *) repo {
    
    if (self = [super init]) {
        repoCheckCount = 0;
        matchProgression = 0;
       
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
        matchProgression ++;
        [repoMatchDict setObject:[singleRepo objectForKey:@"name"] forKey:@"repoName"];
        [repoMatchDict setObject:[singleRepo objectForKey:@"watchers"] forKey:@"watchers"];
        [repoMatchDict setObject:[NSNumber numberWithInt:0] forKey:@"matchCount"];

        [repoDictWithAttributes setObject:repoMatchDict forKey:[singleRepo objectForKey:@"name"]];
        [repoMatchDict release];
        
        dispatch_async(kBgQueue, ^{
           
            NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[kLatestKivaLoansURL stringByAppendingFormat:@"%@/%@/watchers?per_page=100", [[singleRepo objectForKey:@"owner"] objectForKey:@"login"], [singleRepo objectForKey:@"name"]]]];
            [self performSelector:@selector(checkForMatchingWatchers:forRepoName:) withObject:data withObject:[singleRepo objectForKey:@"name"]];
        });
        matchProgressionHighMark = matchProgression;
    }
}
-(void) awakeFromNib {
    
    [self.waitMessage setHidden:YES];
    
}
-(void) checkForMatchingWatchers:(NSData *) data forRepoName:(NSString*) repo {
    matchProgression --;

    if (data != nil) {
        
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
        //not sure why but it stalls after 98 results
        if (matchProgression == (matchProgressionHighMark - 96) || matchProgression == 0) {
           // for (NSDictionary *dd in [repoDictWithAttributes allValues]) {
                
                //NSLog(@"%@ %@", [dd objectForKey:@"repoName"], [dd objectForKey:@"matchCount"]);
                NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"matchCount"  ascending:NO];
                self.sortedArray = [[repoDictWithAttributes allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];

            for (NSInteger i = 0; i < [sortedArray count]; i++) {
                NSLog(@"%@ %@", [[sortedArray objectAtIndex:i] objectForKey:@"repoName"], [[sortedArray objectAtIndex:i] objectForKey:@"matchCount"]);
            }
            
          //  }
            [self.waitMessage setHidden:YES];

        }
        NSLog(@"match progression = %ld", matchProgression);
        
               
        
    }
}


- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
//        NSTextField 
    [self.gitAddress.cell setPlaceholderString:@""];
    
    return YES;
}



@end
