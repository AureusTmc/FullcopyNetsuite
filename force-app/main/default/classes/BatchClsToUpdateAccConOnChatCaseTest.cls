@isTest
public class BatchClsToUpdateAccConOnChatCaseTest {
@isTest
    public static void method(){
        Id customerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
         Account acnt1 = new Account();
        acnt1.RecordTypeId = customerId;
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
        
        Case case2 = new Case();
        case2.Status= 'New';
        case2.Origin ='Chat';
        case2.email__c ='tesst@gmail.com';
        insert case2;
        
        
        
        LiveChatVisitor chatVisit = new LiveChatVisitor();
        insert chatVisit;
        
        LiveChatTranscript l1 = new LiveChatTranscript();
        l1.LiveChatVisitorId = chatVisit.Id;
        l1.ContactId = con1.Id;
        l1.CaseId = case1.Id;
        Insert l1;
        
        Test.startTest();

            BatchClsToUpdateAccConOnChatCase obj = new BatchClsToUpdateAccConOnChatCase();
            DataBase.executeBatch(obj);

        Test.stopTest();

    }
     public static void method1(){
        Id customerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
         Account acnt1 = new Account();
        acnt1.RecordTypeId = customerId;
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
        
        Case case2 = new Case();
        case2.Status= 'New';
        case2.Origin ='Chat';
        case2.email__c ='tet@gmail.com';
         case2.suppliedname ='gitika khandelwal';
        insert case2;
        
        
        
        LiveChatVisitor chatVisit = new LiveChatVisitor();
        insert chatVisit;
        
        LiveChatTranscript l1 = new LiveChatTranscript();
        l1.LiveChatVisitorId = chatVisit.Id;
        l1.ContactId = con1.Id;
        l1.CaseId = case1.Id;
        Insert l1;
        
        Test.startTest();

            BatchClsToUpdateAccConOnChatCase obj = new BatchClsToUpdateAccConOnChatCase();
            DataBase.executeBatch(obj);

        Test.stopTest();

    }
}