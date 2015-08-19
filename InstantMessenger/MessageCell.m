//
//  MessageCell.m
//  InstantMessenger
//
//  Created by Steven Masini on 6/5/15.
//  Copyright (c) 2015 Steven Masini. All rights reserved.
//

#import "MessageCell.h"
#import <QuartzCore/QuartzCore.h>
#import "BubbleSpeech.h"

@interface MessageCell ()
@property (weak, nonatomic) IBOutlet BubbleSpeech   *containerView;
@property (weak, nonatomic) IBOutlet UILabel        *messageLabel;
@end

@implementation MessageCell

- (void)awakeFromNib {
    self.containerView.layer.cornerRadius    = 3.0f;
}

- (void)setLabelText:(NSString *)labelText {
    [self willChangeValueForKey:@"labelText"];
    _labelText = labelText;
    [self didChangeValueForKey:@"labelText"];
    self.messageLabel.text = labelText;
}

@end
