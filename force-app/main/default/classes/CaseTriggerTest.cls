/*
Name        :        CaseTriggerTest
Date        :        20 April 2019
Re-Mpodified:		 20 May 2019
Author      :        Karan Singh Soni
Description :        It is the test class of CaseTrigger.
*/
@isTest
public class CaseTriggerTest {
    public Static testMEthod Void invokeCaseTrigger(){
        Firebase_Settings__c settings = New Firebase_Settings__c(name= 'setting',API_Key__c='Key=AAAAnpwAoa0:APA91bED0q97GSDONF-R-KvOr3ZPQM3Iid5O6Lq00ysF7XvZYwFZ8y2U6kF_loirGYtoNF6rgQPSTQFtYisty4GB_6w5xFf9cXDTRI8eXSulk6KX8cFjCgDEvf7KjnH4tu27V65Y0WEN',
                                                                 Endpoint__c='https://fcm.googleapis.com/fcm/send',Enable_Logs__c=true, Enable_Notifications__c = false);
        insert settings;
        Account objCentre=TestUtil.createAccount('Centre',false, false);
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        objcentre.Center_Email__c='testCentreEmail@gmail.com';
        insert objcentre;
        
        Opportunity objOpp = new Opportunity();
        objOpp.Name='TestOpp';
        objOpp.CloseDate=Date.today();
        objOpp.StageName='Trial Booked';
        insert objOpp;
        
        Case objCase=testUtil.createCase(False);
        objcase.Stage__c='Trial Attended';
        objCase.Enrolment__c=TestUtil.createEnrolment(true).id;
        objCase.Opportunity__c=objOpp.id;
        objcase.Status= 'New';
         objcase.Origin ='App';
        insert objcase;
        
        EmailMessage objMessage= new EmailMessage();
        objMessage.ParentId=objCase.Id;
        objMessage.ToAddress= objcentre.Center_Email__c;
        insert objMessage;
        
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',false);
        objBook.Enrolment__c=objCase.Enrolment__c;
        insert objBook;
        
        objCase.Enrolment__c=testUtil.createEnrolment(true).id;
        objcase.Stage__c='Lost';
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get(ConstantsClass.caseSalesEnqRecTypeName).getRecordTypeId();
        objcase.Lead__c=TestUtil.createLead(objcentre.Location__c, 'Website', 'testEmail@gmail.com', objcentre.id, true).id;
        objcase.Status= 'Open';
        update objCAse;
    }
    
    /*public Static testMEthod Void invokeCaseTrigger1(){
Account objCentre=TestUtil.createAccount('Centre',false, false);
Account objCustmr=testUtil.createAccount('Customer',true, false);

Account objtechr=TestUtil.createAccount('Teacher',False,true);
objcentre.Center_Email__c='testCentre1Email@gmail.com';
insert objcentre;
Case objCase=testUtil.createCase(False);
objcase.Stage__c='Trial Attended';
objCase.Enrolment__c=testUtil.createEnrolment(true).id;
insert objcase;

EmailMessage objMessage= new EmailMessage();
objMessage.ParentId=objCase.Id;
objMessage.ToAddress= objcentre.Center_Email__c;
insert objMessage;

Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',false);
objBook.Enrolment__c=objCase.Enrolment__c;
insert objBook;

objCase.Enrolment__c=testUtil.createEnrolment(true).id;
objcase.Stage__c='Lost';
objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get(ConstantsClass.caseSalesEnqRecTypeName).getRecordTypeId();
objcase.Lead__c=TestUtil.createLead(objcentre.Location__c, 'Website', 'testEmail@gmail.com', objcentre.id, true).id;
update objCAse;
} */
    //@Karan re-modified existing @ravi code
    public Static testMEthod Void invokeCaseTrigger2(){
        Firebase_Settings__c settings = New Firebase_Settings__c(name= 'setting',API_Key__c='Key=AAAAnpwAoa0:APA91bED0q97GSDONF-R-KvOr3ZPQM3Iid5O6Lq00ysF7XvZYwFZ8y2U6kF_loirGYtoNF6rgQPSTQFtYisty4GB_6w5xFf9cXDTRI8eXSulk6KX8cFjCgDEvf7KjnH4tu27V65Y0WEN',
                                                                 Endpoint__c='https://fcm.googleapis.com/fcm/send',Enable_Logs__c=true, Enable_Notifications__c = false);
        insert settings;
        Account objCentre=TestUtil.createAccount('Centre',false, false);
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        objcentre.Center_Email__c='testCentreEmail2@gmail.com';
        insert objcentre;
        
        Opportunity objOpp = new Opportunity();
        objOpp.Name='TestOpp';
        objOpp.CloseDate=Date.today();
        objOpp.StageName='Trial Booked';
        insert objOpp;
        
        Case objCase=testUtil.createCase(False);
        objcase.Stage__c='Trial Attended';
        objCase.Enrolment__c=testUtil.createEnrolment(true).id;
        objCase.SuppliedEmail = 'test@sample.com';
        objCase.SuppliedName='Test Karan';
        objCase.Opportunity__c=objOpp.Id;
        insert objcase;
        
        EmailMessage objMessage= new EmailMessage();
        objMessage.ParentId=objCase.Id;
        objMessage.ToAddress= objcentre.Center_Email__c;
        insert objMessage;
        
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',false);
        objBook.Enrolment__c=objCase.Enrolment__c;
        insert objBook;
        
        objCase.Enrolment__c=testUtil.createEnrolment(true).id;
        objcase.Stage__c='Lost';
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get(ConstantsClass.caseSalesEnqRecTypeName).getRecordTypeId();
        objcase.Lead__c=TestUtil.createLead(objcentre.Location__c, 'Website', 'testEmail@gmail.com', objcentre.id, true).id;
        
        update objCAse;
    } 
    
    //@nishi: for check status chnage then cover FirebaseNotificationHelper class call or not
    public Static testMEthod Void fakeResponseCaseTrigger(){
        Account objCentre=TestUtil.createAccount('Centre',false, false);
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        objcentre.Center_Email__c='testCentreEmail2@gmail.com';
        insert objcentre;
        Firebase_Settings__c settings = New Firebase_Settings__c(name= 'setting',API_Key__c='Key=AAAAnpwAoa0:APA91bED0q97GSDONF-R-KvOr3ZPQM3Iid5O6Lq00ysF7XvZYwFZ8y2U6kF_loirGYtoNF6rgQPSTQFtYisty4GB_6w5xFf9cXDTRI8eXSulk6KX8cFjCgDEvf7KjnH4tu27V65Y0WEN',
                                                                 Endpoint__c='https://fcm.googleapis.com/fcm/send',Enable_Logs__c=true, Enable_Notifications__c = true);
        insert settings;
        test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,
                                                                               '{"multicast_id":7430610622243333234,"success":1,"failure":0,"canonical_ids":0,"results":[{"message_id":"0:1566819879327140%95528c5095528c50"}]}'
                                                                              );
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        test.stopTest();
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.FCM_Token__c ='dVD5mKEVenc:APA91bEJuzKM2bFOg-b-P0HShpR0zF0XL1t15f78bGid0CXdK3F98YZGuTPbJEkamyyEU80fRXQM1f3pqOP_d-dUosGnziJo4ACLRSDw5oHs6nXL47QKelmxf6QkbkaLKxxiE9bAJDb3';
        insert objCustmr;
        Case objCase=testUtil.createCase(False);
        objcase.Stage__c='Trial Attended';
        objCase.Enrolment__c=testUtil.createEnrolment(true).id;
        objCase.SuppliedEmail = 'test@sample.com';
        objCase.SuppliedName='Test Karan';
        objCase.AccountId = objCustmr.id;
        objCase.Status='New';
        insert objcase;
        
        objCase.Enrolment__c=testUtil.createEnrolment(true).id;
        objcase.Stage__c='Lost';
        objcase.Origin = 'App';
        objCase.Status='Open';
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get(ConstantsClass.caseSalesEnqRecTypeName).getRecordTypeId();
        objcase.Lead__c=TestUtil.createLead(objcentre.Location__c, 'Website', 'testEmail@gmail.com', objcentre.id, true).id;
        
        update objCAse;
    } 
}