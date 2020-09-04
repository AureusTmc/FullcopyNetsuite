@isTest
public class CCExpNotificationSchedularTest {
    @TestSetup 
    public static void setup(){
        Account objCustmr = new Account(
            LastName = 'ra',
            FirstName = 'Aksha',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId(),
            PersonBirthdate = Date.newInstance(2002,04,15),
            Nationality__c = 'India',
            Gender__c = 'Female');
        objCustmr.Expiry_Month__c = Date.today().addMonths(1).month();
        objCustmr.Expiry_Year__c = Date.today().year();
        objCustmr.FCM_Token__c ='dVD5mKEVenc:APA91bEJuzKM2bFOg-b-P0HShpR0zF0XL1t15f78bGid0CXdK3F98YZGuTPbJEkamyyEU80fRXQM1f3pqOP_d-dUosGnziJo4ACLRSDw5oHs6nXL47QKelmxf6QkbkaLKxxiE9bAJDb3';
        objCustmr.Booking_Reminded_Notification__c = true;
        objCustmr.Card_Number__c ='1234';
        insert objCustmr;
        Firebase_Settings__c settings = New Firebase_Settings__c(name= 'setting',API_Key__c='Key=AAAAnpwAoa0:APA91bED0q97GSDONF-R-KvOr3ZPQM3Iid5O6Lq00ysF7XvZYwFZ8y2U6kF_loirGYtoNF6rgQPSTQFtYisty4GB_6w5xFf9cXDTRI8eXSulk6KX8cFjCgDEvf7KjnH4tu27V65Y0WEN',
                                                                 Endpoint__c='https://fcm.googleapis.com/fcm/send',Enable_Logs__c=true);
        insert settings;
    }
    @isTest
    public static void testCCExpNotificationSchedular() {
        test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,
                                                                               '{"multicast_id":7430610622243333234,"success":1,"failure":0,"canonical_ids":0,"results":[{"message_id":"0:1566819879327140%95528c5095528c50"}]}'
                                                                              );
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        test.stopTest();
        
        // This test runs a scheduled job at lunch time 2pm every month 1 day
        String CRON_EXP = '0 0 14 1 * ? * ';
        // Schedule the test job
        String jobId = System.schedule('CCExpNotificationSchedular', CRON_EXP, new CCExpNotificationSchedular());
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered); 
        // Verify the next time the job will run 
        Datetime nextSchduletime = datetime.newInstance(DATE.today().year(), DATE.today().addMonths(1).month(), 1,14,00,00);
        System.assertEquals(string.valueOf(nextSchduletime.addMonths(1)), String.valueOf(ct.NextFireTime.addMonths(1)));   
        
        CCExpNotificationSchedular objTaskSchd= new CCExpNotificationSchedular();
        objTaskSchd.execute(Null);
    }
}