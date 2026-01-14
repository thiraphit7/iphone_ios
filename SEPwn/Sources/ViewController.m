/*
 * ViewController.m - SEPwn Main View Controller Implementation
 */

#import "ViewController.h"
#import "jailbreak.h"

@interface ViewController ()

@property (nonatomic, assign) BOOL isJailbreaking;
@property (nonatomic, strong) NSMutableString *logBuffer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.logBuffer = [NSMutableString new];
    self.isJailbreaking = NO;
    
    [self setupUI];
    [self updateStatus];
}

- (void)setupUI {
    self.titleLabel.text = [NSString stringWithFormat:@"SEPwn v%s", SEPWN_VERSION];
    self.statusLabel.text = @"Ready";
    self.stageLabel.text = [NSString stringWithFormat:@"Target: iOS %s (%s)", TARGET_IOS_VERSION, TARGET_BUILD];
    self.progressView.progress = 0.0;
    
    self.jailbreakButton.layer.cornerRadius = 10;
    self.jailbreakButton.clipsToBounds = YES;
    
    self.logTextView.text = @"";
    self.logTextView.layer.cornerRadius = 8;
    self.logTextView.layer.borderWidth = 1;
    self.logTextView.layer.borderColor = [UIColor systemGrayColor].CGColor;
    
    [self appendLog:@"SEPwn iOS 26.1 Jailbreak"];
    [self appendLog:[NSString stringWithFormat:@"Version: %s", SEPWN_VERSION]];
    [self appendLog:[NSString stringWithFormat:@"Target: %s (%s)", TARGET_DEVICE, TARGET_BUILD]];
    [self appendLog:@""];
    [self appendLog:@"Tap 'Jailbreak' to begin."];
}

- (void)updateStatus {
    const jailbreak_state_t *state = jailbreak_get_state();
    
    if (state == NULL) {
        self.statusLabel.text = @"Not initialized";
        return;
    }
    
    if (state->success) {
        self.statusLabel.text = @"Jailbroken!";
        self.statusLabel.textColor = [UIColor systemGreenColor];
        self.jailbreakButton.enabled = NO;
        [self.jailbreakButton setTitle:@"Done" forState:UIControlStateNormal];
    } else if (self.isJailbreaking) {
        self.statusLabel.text = [NSString stringWithFormat:@"Stage %d: %s", 
                                 state->stage, STAGE_NAMES[state->stage]];
    } else {
        self.statusLabel.text = @"Ready";
    }
}

- (void)appendLog:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.logBuffer appendFormat:@"%@\n", message];
        self.logTextView.text = self.logBuffer;
        
        // Scroll to bottom
        NSRange range = NSMakeRange(self.logTextView.text.length - 1, 1);
        [self.logTextView scrollRangeToVisible:range];
    });
}

- (void)progressCallback:(int)stage progress:(int)progress message:(const char *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        float totalProgress = (float)stage / (float)STAGE_COUNT + (float)progress / 100.0 / (float)STAGE_COUNT;
        self.progressView.progress = totalProgress;
        
        if (message) {
            [self appendLog:[NSString stringWithUTF8String:message]];
        }
        
        [self updateStatus];
    });
}

static void progress_callback_wrapper(jailbreak_stage_t stage, int progress, const char *message) {
    // This would need to be connected to the ViewController instance
    NSLog(@"[SEPwn] Stage %d, Progress %d%%: %s", stage, progress, message ? message : "");
}

static void log_callback_wrapper(const char *message) {
    NSLog(@"[SEPwn] %s", message);
}

- (IBAction)jailbreakButtonTapped:(id)sender {
    if (self.isJailbreaking) {
        return;
    }
    
    self.isJailbreaking = YES;
    self.jailbreakButton.enabled = NO;
    [self.jailbreakButton setTitle:@"Running..." forState:UIControlStateNormal];
    
    [self appendLog:@""];
    [self appendLog:@"=== Starting Jailbreak ==="];
    [self appendLog:@""];
    
    // Run jailbreak in background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Initialize jailbreak
        jailbreak_config_t config = {
            .verbose = YES,
            .dry_run = NO,
            .skip_post_exploit = NO,
            .progress_callback = progress_callback_wrapper,
            .log_callback = log_callback_wrapper
        };
        
        int ret = jailbreak_init(&config);
        if (ret != 0) {
            [self appendLog:@"[-] Failed to initialize jailbreak"];
            [self jailbreakFailed];
            return;
        }
        
        // Run jailbreak
        ret = jailbreak_run();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ret == 0) {
                [self jailbreakSucceeded];
            } else {
                [self jailbreakFailed];
            }
        });
    });
}

- (void)jailbreakSucceeded {
    self.isJailbreaking = NO;
    self.progressView.progress = 1.0;
    self.statusLabel.text = @"Jailbroken!";
    self.statusLabel.textColor = [UIColor systemGreenColor];
    [self.jailbreakButton setTitle:@"Done" forState:UIControlStateNormal];
    
    [self appendLog:@""];
    [self appendLog:@"=== Jailbreak Successful! ==="];
    [self appendLog:@""];
    [self appendLog:@"Your device is now jailbroken."];
    [self appendLog:@"You can now install tweaks and packages."];
    
    // Show success alert
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!"
                                                                   message:@"Your device has been jailbroken."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)jailbreakFailed {
    self.isJailbreaking = NO;
    self.jailbreakButton.enabled = YES;
    [self.jailbreakButton setTitle:@"Retry" forState:UIControlStateNormal];
    self.statusLabel.text = @"Failed";
    self.statusLabel.textColor = [UIColor systemRedColor];
    
    const char *error = jailbreak_get_error();
    [self appendLog:@""];
    [self appendLog:@"=== Jailbreak Failed ==="];
    if (error) {
        [self appendLog:[NSString stringWithFormat:@"Error: %s", error]];
    }
    [self appendLog:@""];
    [self appendLog:@"Please try again or check the logs for details."];
    
    // Show failure alert
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed"
                                                                   message:@"Jailbreak failed. Please try again."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
