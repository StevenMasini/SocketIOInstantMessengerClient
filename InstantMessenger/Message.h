//
//  Message.h
//  InstantMessenger
//
//  Created by Steven Masini on 6/5/15.
//  Copyright (c) 2015 Steven Masini. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Message : NSObject
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *userIdentifier;
@end
