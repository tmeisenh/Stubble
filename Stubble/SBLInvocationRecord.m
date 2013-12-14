#import "SBLInvocationRecord.h"

@interface SBLInvocationRecord ()

@property (nonatomic, readonly) NSInvocation *invocation;
@property (nonatomic) NSArray *matchers;

@end

@implementation SBLInvocationRecord

- (instancetype)initWithInvocation:(NSInvocation *)invocation {
	if (self = [super init]) {
		[invocation retainArguments];
		_invocation = invocation;
	}
	return self;
}

- (void)setMatchers:(NSArray *)matchers {
	NSLog(@"setMatchers: %p %@", self, matchers);
	_matchers = matchers;
}

- (BOOL)matchesInvocation:(NSInvocation *)invocation {
	NSLog(@"matchesInvocation: %@", invocation);
	NSLog(@"matchers: %p %@", self, self.matchers);
	NSInvocation *recordedInvocation = self.invocation;
	BOOL matchingInvocation = recordedInvocation.selector == invocation.selector;
    for (int i = 2; i < recordedInvocation.methodSignature.numberOfArguments; i++) {
        // Need unsafe unretained here - http://stackoverflow.com/questions/11874056/nsinvocation-getreturnvalue-called-inside-forwardinvocation-makes-the-returned
        __unsafe_unretained id argumentMatcher = nil;
        __unsafe_unretained id argument = nil;
        [recordedInvocation getArgument:&argumentMatcher atIndex:i];
        [invocation getArgument:&argument atIndex:i];
		
        if ([self.matchers lastObject]) {
			matchingInvocation &= [self.matchers[0] matchesArgument:&argument];
		} else if ([self typeIsObject:[recordedInvocation.methodSignature getArgumentTypeAtIndex:i]]) {
            matchingInvocation &= [argumentMatcher isEqual:argument];
        } else {
            matchingInvocation &= argumentMatcher == argument;
        }
    }
    return matchingInvocation;
}

- (BOOL)typeIsObject:(const char *)type {
    return strcmp(type, "@") == 0;
}

- (const char *)returnType {
	return self.invocation.methodSignature.methodReturnType;
}

- (NSString *)description {
	return NSStringFromSelector(self.invocation.selector);
}

@end