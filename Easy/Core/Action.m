//
//  Action.m
//  article
//
//  Created by EasyIOS on 14-4-8.
//  Copyright (c) 2014年 zhuchao. All rights reserved.
//

#import "Action.h"

@implementation Action

DEF_SINGLETON(Action)

//1、params
//2、key params

- (ActionBlockN)GET_MSG
{
	ActionBlockN block = ^ Action * ( id first,id second,... )
	{
        if ( first && second)
		{
            if ( [second isKindOfClass:[NSDictionary class]] )
			{
                self.msg.key = @"";
                NSString * path = [NSString stringWithFormat:@"%@%@",BASE_URL,first];
				NSDictionary *	params = (NSDictionary *)second;
                [self GET:path params:params];
                
            }else{
                va_list args;
				va_start( args, second );
				
				NSString *	key = (NSString *)first;
                NSString * path = [NSString stringWithFormat:@"%@%@",BASE_URL,second];
				NSDictionary *	params = va_arg( args, NSDictionary * );
                
				if ( key && params )
				{
                    self.msg.key = key;
                    [self GET:path params:params];
				}
				va_end( args );
            }
        }
        return self;
	};
	return [block copy];
}

//1、path params
//2、key path params
- (ActionBlockN)POST_MSG
{
	ActionBlockN block = ^ Action * ( id first,id second,... )
	{
        if ( first && second)
		{
            if ( [second isKindOfClass:[NSDictionary class]] )
			{
                NSString * path = (NSString *)first;
				NSDictionary *	params = (NSDictionary *)second;
                self.msg.key = @"";
                [self POST:path params:params];
            }else{
                va_list args;
				va_start( args, second );
				
				NSString *	key = (NSString *)first;
                NSString * path = (NSString *)second;
				NSDictionary *	params = va_arg( args, NSDictionary * );
                
				if ( key && params )
				{
                    self.msg.key = key;
                    [self POST:path params:params];
				}
				va_end( args );
            }
        }
        return self;
	};
	return [block copy];
}

+(id)Action{
    return [[[self class] alloc] init];
}
- (id)init
{
    self = [super initWithHostName:HOST_URL customHeaderFields:@{@"x-client-identifier" : CLIENT}];
    self.msg = [ActionData Data];
	return self;
}

- (id)initWithCache
{
    self = [self init];
    [self useCache];
	return self;
}

-(MKNetworkOperation*) GET:(NSString*) path
                    params:(NSDictionary *) params
{
    
    
    MKNetworkOperation *op = [self operationWithPath:path
                                              params:params
                                          httpMethod:@"GET"];
    self.msg.url = op.url;
    self.msg.state = SendingState;
    self.msg.method = @"GET";
    self.msg.params = params;
    
    NSLog(@"%@",self.msg.url);
    [op addCompletionHandler:^(MKNetworkOperation* completedOperation) {
        [completedOperation responseJSONWithCompletionHandler:^(id jsonObject) {
            self.msg.output = jsonObject;
            NSLog(@"%@",jsonObject);
            [self checkCode:self.msg];
            if([completedOperation isCachedResponse]){
                NSLog(@"iscache:YES");
            }else{
                NSLog(@"iscache:NO");
            }
        }];
    } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
        
        self.msg.error = error;
        if(error.userInfo!= nil && [error.userInfo objectForKey:@"NSLocalizedDescription"]){
            self.msg.discription = [error.userInfo objectForKey:@"NSLocalizedDescription"];
        }
        self.msg.state = FailState;
        NSLog(@"Failed:%@",error);
    }];
    [self enqueueOperation:op];
    return op;
}

-(MKNetworkOperation*) POST:(NSString*) path
                     params:(NSDictionary *) dictParams
{
    
    self.msg.params = dictParams;
    
    NSString *image = @"";
    NSMutableDictionary *params = [dictParams mutableCopy];
    if([params objectForKey:@"POST_IMG"]){
        image = [params objectForKey:@"POST_IMG"];
        [params removeObjectForKey:@"POST_IMG"];
    }
    MKNetworkOperation *op = [self operationWithPath:path
                                              params:params
                                          httpMethod:@"POST"];
    self.msg.url = op.url;
    self.msg.method = @"POST";
    self.msg.state = SendingState;
    
    if(![image isEqualToString:@""]){
        [op addFile:image forKey:@"image"];
        [op setFreezable:YES];
    }
    
    NSLog(@"%@",self.msg.url);
    [op addCompletionHandler:^(MKNetworkOperation* completedOperation) {
        
        NSLog(@"%@",[completedOperation responseString]);
        [completedOperation responseJSONWithCompletionHandler:^(id jsonObject) {
            self.msg.output = jsonObject;
            NSLog(@"%@",jsonObject);
            [self checkCode:self.msg];
            if([completedOperation isCachedResponse]){
                NSLog(@"iscache:YES");
            }else{
                NSLog(@"iscache:NO");
            }
        }];
    } errorHandler:^(MKNetworkOperation *errorOp, NSError* error) {
        self.msg.error = error;
        if(error.userInfo!= nil && [error.userInfo objectForKey:@"NSLocalizedDescription"]){
            self.msg.discription = [error.userInfo objectForKey:@"NSLocalizedDescription"];
        }
        self.msg.state = FailState;
        NSLog(@"Failed:%@",error);
    }];
    [self enqueueOperation:op];
    return op;
}


-(void)checkCode:(ActionData *)msg{
    if([[msg.output objectForKey:CODE_KEY] intValue] == RIGHT_CODE){
        msg.discription = [msg.output objectForKey:MSG_KEY];
        if (msg.state != SuccessState) {
            msg.state = SuccessState;
        }
    }else{
        if([msg.output objectForKey:MSG_KEY]){
            msg.discription = [msg.output objectForKey:MSG_KEY];
            NSLog(@"Error:%@",msg.discription);
        }
         msg.state = ErrorState;
    }
}
@end