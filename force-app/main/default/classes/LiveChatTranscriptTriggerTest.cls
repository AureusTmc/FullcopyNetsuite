@isTest
public class LiveChatTranscriptTriggerTest {
    
    public static testMethod void test(){
        
        Account acnt1 = new Account();
        acnt1.RecordTypeId = '0126F000001QKPcQAO';
        acnt1.FirstName = 'Test';
        acnt1.LastName = 'Check';
        acnt1.PersonEmail = 'tesst@gmail.com';
        insert acnt1;
        
        Contact con1 = new Contact();
        con1.FirstName = 'Test';
        con1.LastName = 'Check';
        con1.Email = 'test@gmail.com';
        insert con1;
        
        Case case1 = new Case();
        case1.Status= 'New';
        case1.Origin ='Chat';
        case1.ContactId = con1.Id;
        insert case1;
        
        LiveChatVisitor chatVisit = new LiveChatVisitor();
        insert chatVisit;
        
        LiveChatTranscript l1 = new LiveChatTranscript();
        l1.LiveChatVisitorId = chatVisit.Id;
        l1.ContactId = con1.Id;
        l1.CaseId = case1.Id;
        Insert l1;
        
        l1.Status = 'Completed';
        update l1;
        
    }
    
    public static testMethod void test1(){
        
        Account acnt1 = new Account();
        acnt1.RecordTypeId = '0126F000001QKPcQAO';
        acnt1.FirstName = 'Test';
        acnt1.LastName = 'Check';
        acnt1.PersonEmail = 'test@gmail.com';
        insert acnt1;
        
        Contact con1 = new Contact();
        con1.FirstName = 'Test';
        con1.LastName = 'Check';
        con1.Email = 'test@gmail.com';
        insert con1;
        
        Case case1 = new Case();
        case1.Status= 'New';
        case1.Origin ='Chat';
        case1.ContactId = con1.Id;
        insert case1;
        
        LiveChatVisitor chatVisit = new LiveChatVisitor();
        insert chatVisit;
        
        LiveChatTranscript l1 = new LiveChatTranscript();
        l1.LiveChatVisitorId = chatVisit.Id;
        l1.ContactId = con1.Id;
        l1.CaseId = case1.Id;
        Insert l1;
        
        l1.Status = 'Completed';
        update l1;
        
    }
    
}