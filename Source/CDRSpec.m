#import "CDRSpec.h"
#import "CDRExample.h"
#import "CDRExampleGroup.h"
#import "CDRSharedExampleGroupPool.h"

void fail(NSString *reason)
{
    [[CDRSpecFailure specFailureWithReason:[NSString stringWithFormat:@"Failure: %@", reason]] raise];
}

@implementation CDRSpec

@synthesize currentGroup = currentGroup_, rootGroup = rootGroup_;

#pragma mark Memory
- (id)init
{
    if((self = [super init]))
    {
        rootGroup_ = [[CDRExampleGroup alloc] initWithText:[[self class] description]];
        self.currentGroup = rootGroup_;
        
        describe =
        [^(NSString *text, CDRSpecBlock block)
          {
              CDRExampleGroup *parentGroup = [self currentGroup];
              
              [self setCurrentGroup:[CDRExampleGroup groupWithText:text]];
              [parentGroup add:[self currentGroup]];
              
              block();
              [self setCurrentGroup:parentGroup];
          } copy];
        
        beforeEach =
        [^(CDRSpecBlock block)
          {
              [[self currentGroup] addBefore:block];
          } copy];
        
        afterEach =
        [^(CDRSpecBlock block)
          {
              [[self currentGroup] addAfter:block];
          } copy];
        
        it =
        [^(NSString *text, CDRSpecBlock block)
          {
              [[self currentGroup] add:[CDRExample exampleWithText:text andBlock:block]];
          } copy];
        
        itShouldBehaveLike =
        [^(NSString *groupName)
         {
             itShouldBehaveLikeWithContext(nil, groupName, ^ NSDictionary * { return [self sharedExampleContext]; });
         } copy];
        
        itShouldBehaveLikeWithContext =
        [^(NSString *subject, NSString *groupName, NSDictionary *(^context)(void))
         {
             [CDRSharedExampleGroupPool runGroupForName:groupName withExample:self subject:subject context:context];
         } copy];
    }
    return self;
}

- (void)dealloc
{
    self.rootGroup = nil;
    self.currentGroup = nil;
    
    [_sharedExampleContext         release];
    [describe                      release];
    [beforeEach                    release];
    [afterEach                     release];
    [it                            release];
    [itShouldBehaveLike            release];
    [itShouldBehaveLikeWithContext release];
    
    [super dealloc];
}

- (NSMutableDictionary *)sharedExampleContext
{
    return _sharedExampleContext;
}

- (void)defineBehaviors
{
    _sharedExampleContext = [[NSMutableDictionary alloc] init];
    [rootGroup_ addBefore:^{  }];
    
    [self declareBehaviors];
    
    [rootGroup_ addAfter:^{ [_sharedExampleContext removeAllObjects]; }];
}

- (void)failWithException:(NSException *)exception {
    [[CDRSpecFailure specFailureWithReason:[exception reason]] raise];
}

@end
