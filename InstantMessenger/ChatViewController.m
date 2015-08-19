//
//  ChatViewController.m
//  InstantMessenger
//
//  Created by Steven Masini on 6/5/15.
//  Copyright (c) 2015 Steven Masini. All rights reserved.
//

#import "ChatViewController.h"

#import "Message.h"
#import "MessageCell.h"
#import "BubbleSpeech.h"

#import <Socket_IO_Client_Swift/Socket_IO_Client_Swift-Swift.h>

@interface ChatViewController () <UITableViewDataSource, UITextFieldDelegate>
// views
@property (weak, nonatomic) IBOutlet UIView         *accessoryView;
@property (weak, nonatomic) IBOutlet UITextField    *inputField;
@property (weak, nonatomic) IBOutlet UIButton       *sendButton;
@property (weak, nonatomic) IBOutlet UITableView    *tableView;

// popup
@property (nonatomic, strong) UIAlertController     *alert;

// constraint
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

// properties
@property (nonatomic, strong) NSUUID            *uuid;
@property (nonatomic, strong) NSMutableArray    *messages;
@property (nonatomic, strong) SocketIOClient    *client;

@property (nonatomic, assign) BOOL isKeyboardActive;
@end

static NSString *userMessageCellIdentifier      = @"UserMessageCell";
static NSString *friendMessageCellIdentifier    = @"FriendMessageCell";

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//  1) setup interface decoration
    self.sendButton.layer.cornerRadius = 3.0;
    self.navigationItem.title = @"Disconnect";
    
//  2) setup the message hosting array and the uuid
    self.messages = [NSMutableArray array];
    self.uuid = [NSUUID UUID];
    
//  3) setup the self sizing cell
    self.tableView.estimatedRowHeight = 75.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
//  4) setup the socket.io event listener
    [self setupChat];
    
//  5) setup the keyboard event listener
    [self setupKeyboardListener];
}

- (void)setupKeyboardListener {
//  1) add an observer to the event keyboard will show
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShowOrHide:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
//  2) add an observer to the event keyboard will hide
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShowOrHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)setupChat {
    
    __weak typeof(self) wself = self;
    
//  1) setup the socket.io client
    self.client = [[SocketIOClient alloc] initWithSocketURL:@"172.20.10.12:3000" options:nil];
    
//  2) add the event listener on "connect"
    [self.client on:@"connect" callback:^(NSArray *data, void (^ack)(NSArray *)) {
        wself.navigationItem.title = @"Connected";
        wself.navigationController.navigationBar.backgroundColor = [UIColor greenColor];
    }];
    
//  3) add the event listener on "disconnect"
    [self.client on:@"disconnect" callback:^(NSArray *data, void (^ack)(NSArray *)) {
        wself.navigationItem.title = @"Disconnect";
        wself.navigationController.navigationBar.backgroundColor = [UIColor redColor];
    }];
    
//  4) add the event listener on "error"
    [self.client on:@"error" callback:^(NSArray *data, void (^ack)(NSArray *)) {
        NSLog(@"ERROR: %@", data[0]);
        wself.navigationItem.title = @"Disconnect";
        wself.navigationController.navigationBar.backgroundColor = [UIColor redColor];
        if (!wself.alert) {
            [wself.inputField resignFirstResponder];
            
            wself.alert = [UIAlertController alertControllerWithTitle:@"Error" message:data[0] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                wself.alert = nil;
            }];
            [wself.alert addAction:okAction];
            [wself presentViewController:wself.alert animated:YES completion:NULL];
        }
    }];
    
//  5) add the event listener on "chat message"
    [self.client on:@"chat message" callback:^(NSArray *data, void (^ack)(NSArray *)) {
        NSLog(@"MESSAGE: %@", data);
        NSDictionary *param = data[0];
        
        Message *m = [Message new];
        m.message = param[@"message"];
        m.userIdentifier = param[@"userIdentifier"];
        
        [wself.messages addObject:m];
        [wself.tableView reloadData];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:wself.messages.count - 1 inSection:0];
        [wself.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }];
    
//  6) connect the client to the server
    [self.client connect];
}

#pragma mark - Observer

-(void)keyboardDidShowOrHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
//  1) retrieve the keyboard attributes
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]    getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]          getValue:&keyboardEndFrame];
    
//  2) setup the constraint according to the keyboard event
    if (self.isKeyboardActive) {
        self.bottomConstraint.constant = keyboardEndFrame.size.height;
    } else {
        self.bottomConstraint.constant = 0;
    }
    
//  3) animated the accessory view according to the keyboard event
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    [self.view layoutIfNeeded];
    
    [UIView commitAnimations];
    
//  4) table view scroll at the last message position
    if (self.messages.count) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
}

#pragma mark - IBAction

- (IBAction)sendAction:(id)sender {
    if (self.inputField.text.length > 0) {
//      1) setup the message to send to the server
        NSDictionary *param = @{@"message"          : self.inputField.text,
                                @"userIdentifier"   : self.uuid.UUIDString};

//      2) send the message to the server
        [self.client emit:@"chat message" withItems:@[param]];
        
//      3) clear the input field
        self.inputField.text = @"";
    }
}

- (IBAction)dismissAction:(id)sender {
    [self.inputField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.isKeyboardActive = YES;
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    self.isKeyboardActive = NO;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendAction:textField];
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//  1) retrieve the message from the array
    Message *m = self.messages[indexPath.row];
    
//  2) determine if the message has been sent by the user or from someone else
    NSString *cellIdentifier;
    if ([m.userIdentifier isEqualToString:self.uuid.UUIDString]) {
        cellIdentifier = userMessageCellIdentifier;
    } else {
        cellIdentifier = friendMessageCellIdentifier;
    }
    
//  3) setup the cell
    MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.labelText = m.message;

    return cell;
}

@end
