//
//  ViewController.m
//  JsonTest
//
//  Created by masato on 2014/06/11.
//  Copyright (c) 2014年 abcc. All rights reserved.
//

#import "ViewController.h"
#import "FMDatabase.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    // NSUserDefaultsの取得
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // KEY_BOOLの内容を取得し、BOOL型変数へ格納
    BOOL isBool = [defaults boolForKey:@"KEY_BOOL"];
    // isBoolがNOの場合、アラート表示
    if (!isBool) {
        //データベース作成・接続
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"arm.db"];
        BOOL success = [fileManager fileExistsAtPath:writableDBPath];
        if(!success){
            NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"arm.db"];
            success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
        }
        
        FMDatabase* db = [FMDatabase databaseWithPath:writableDBPath];
        if(![db open])
        {
            NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
        
        [db setShouldCacheStatements:YES];
        
        //テーブル作成
        NSString    *sql = @"CREATE TABLE Survey (sur_id TEXT,sur_name TEXT NOT NULL,sur_division TEXT NOT NULL,PRIMARY KEY(sur_id));";
        NSString    *sql2 = @"CREATE TABLE Question (q_id TEXT,q_name TEXT NOT NULL,PRIMARY KEY(q_id));";
        NSString    *sql3 = @"CREATE TABLE Enterprise (e_id TEXT, e_name TEXT NOT NULL, division TEXT NOT NULL, PRIMARY KEY(e_id));";
        NSString    *sql4 = @"CREATE TABLE Section(e_id TEXT,sec_id TEXT,sec_name TEXT NOT NULL, PRIMARY KEY(e_id,sec_id),FOREIGN KEY(e_id) REFERENCES Enterprise(e_id));";
        NSString    *sql5 = @"CREATE TABLE Choice (cho_id TEXT, choice1 TEXT NOT NULL, choice2 TEXT NOT NULL, choice3 TEXT, choice4 TEXT, choice5 TEXT, choice6 TEXT, PRIMARY KEY(cho_id));";
        
        NSString    *sql6 = @"CREATE TABLE QuestionDetail (sur_id TEXT, q_id TEXT, qd_id TEXT,qd_name TEXT NOT NULL, cho_kubun TEXT NOT NULL,cho_id TEXT,PRIMARY KEY(sur_id,q_id,qd_id) ,FOREIGN KEY(sur_id) REFERENCES Survey(sur_id),FOREIGN KEY(q_id) REFERENCES Question(q_id),FOREIGN KEY(cho_id) REFERENCES Choice(cho_id));";
        
        NSString    *sql7 = @"CREATE TABLE Answer (sur_id TEXT, q_id TEXT, qd_id TEXT,e_id TEXT,sec_id TEXT,ans_date NUMERIC,answerer TEXT NOT NULL,charge TEXT NOT NULL,ans_cho TEXT,ans_str TEXT,memo TEXT,PRIMARY KEY(sur_id,q_id,qd_id,e_id,sec_id,ans_date) ,FOREIGN KEY(sur_id) REFERENCES Survey(sur_id),FOREIGN KEY(q_id) REFERENCES Question(q_id),FOREIGN KEY(qd_id) REFERENCES QuestionDetail(qd_id),FOREIGN KEY(e_id) REFERENCES Enterprise(e_id),FOREIGN KEY(sec_id) REFERENCES Section(sec_id));";
        
        NSString    *sql8 = @"create table Comment (sur_id TEXT not null,q_id TEXT not null,qd_id TEXT not null,e_id TEXT not null,comment TEXT,primary key (sur_id,q_id,qd_id,e_id),foreign key (sur_id) references Survey (sur_id),foreign key (q_id) references Question (q_id),foreign key (qd_id) references QuestionDetail (sur_id),foreign key (e_id) references Enterprise (e_id));";
        
        NSString    *sql9 =@"CREATE TABLE Temporary (sur_id TEXT, q_id TEXT, qd_id TEXT,e_id TEXT,sec_id TEXT,ans_date NUMERIC,answerer TEXT NOT NULL,charge TEXT NOT NULL,ans_cho TEXT,ans_str TEXT,memo TEXT,PRIMARY KEY(sur_id,q_id,qd_id,e_id,sec_id,ans_date) ,FOREIGN KEY(sur_id) REFERENCES Survey(sur_id),FOREIGN KEY(q_id) REFERENCES Question(q_id),FOREIGN KEY(qd_id) REFERENCES QuestionDetail(qd_id),FOREIGN KEY(e_id) REFERENCES Enterprise(e_id),FOREIGN KEY(sec_id) REFERENCES Section(sec_id));";
        
        [db executeUpdate:sql];
        [db executeUpdate:sql2];
        [db executeUpdate:sql3];
        [db executeUpdate:sql4];
        [db executeUpdate:sql5];
        [db executeUpdate:sql6];
        [db executeUpdate:sql7];
        [db executeUpdate:sql8];
        [db executeUpdate:sql9];
        [db close];
        // KEY_BOOLにYESを設定
        [defaults setBool:YES forKey:@"KEY_BOOL"];
        // NSUserDefaultsに保存する
        [defaults setInteger:10001 forKey:@"KEY_I"];
        // 設定を保存
        [defaults synchronize];
    }
    
    
    //DB接続
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"arm.db"];
    BOOL success = [fileManager fileExistsAtPath:writableDBPath];
    if(!success){
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"arm.db"];
        success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    }
    
    FMDatabase* db = [FMDatabase databaseWithPath:writableDBPath];
    if(![db open])
    {
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
    
    [db setShouldCacheStatements:YES];
    //Surveyを内部DBへImport
    [self surveyimport:db];
    
    [db close];

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)surveyimport:(FMDatabase*) db{
    //PHPのURL
    NSURL *jsonUrl = [NSURL URLWithString:@"http://asoarm.chobi.net/data/survey.php"];
    NSError *error = nil;
    NSData *jsonData = [NSData dataWithContentsOfURL:jsonUrl options:kNilOptions error:&error];
    NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    
    for( NSDictionary * json in jsonResponse )
    {
        NSString* sur_id = [json objectForKey:@"sur_id"];
        NSString* sur_name = [json objectForKey:@"sur_name"];
        NSString* sur_division = [json objectForKey:@"sur_division"];
        NSString*   sql = [ NSString stringWithFormat :@"insert into Survey values (\"%@\",\"%@\",\"%@\");",sur_id,sur_name,sur_division];
        [db executeUpdate:sql];
    }

}
@end
