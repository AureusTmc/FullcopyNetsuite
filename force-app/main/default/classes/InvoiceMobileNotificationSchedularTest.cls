@isTest
public class InvoiceMobileNotificationSchedularTest {
    @TestSetup 
    public static void setup(){
        MobileAppUtility.init();
    }
    @isTest
    public static void testInvoiceMobileNotificationSchedular() {
        Firebase_Settings__c settings = New Firebase_Settings__c(name= 'setting',API_Key__c='Key=AAAAnpwAoa0:APA91bED0q97GSDONF-R-KvOr3ZPQM3Iid5O6Lq00ysF7XvZYwFZ8y2U6kF_loirGYtoNF6rgQPSTQFtYisty4GB_6w5xFf9cXDTRI8eXSulk6KX8cFjCgDEvf7KjnH4tu27V65Y0WEN',
                                                                 Endpoint__c='https://fcm.googleapis.com/fcm/send',Enable_Logs__c=true);
        insert settings;
        test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,
                                                                               '{"multicast_id":7430610622243333234,"success":1,"failure":0,"canonical_ids":0,"results":[{"message_id":"0:1566819879327140%95528c5095528c50"}]}'
                                                                              );
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        test.stopTest();
        Account objCustmr = new Account(
            LastName = 'ra',
            FirstName = 'Aksha',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId(),
            PersonBirthdate = Date.newInstance(2002,04,15),
            Nationality__c = 'India',
            Gender__c = 'Female');
        objCustmr.FCM_Token__c ='dVD5mKEVenc:APA91bEJuzKM2bFOg-b-P0HShpR0zF0XL1t15f78bGid0CXdK3F98YZGuTPbJEkamyyEU80fRXQM1f3pqOP_d-dUosGnziJo4ACLRSDw5oHs6nXL47QKelmxf6QkbkaLKxxiE9bAJDb3';
        objCustmr.Booking_Reminded_Notification__c = true;
        insert objCustmr;
        Invoice__c invoice = new Invoice__c(
            Parent_Account__c=objCustmr.id,
            Invoice_Date__c = system.today(),
            Due_Date__c = system.today().addDays(-3),
            Status__c = 'Due',
            Total_Invoice_Amount__c = 213.75);
        //MovedToSage__c = false,
        //Voided_on_Sage__c = false);
        insert invoice;
        // This test runs a scheduled job at midnight 1pm
        String CRON_EXP = '0 0 14 * * ? * ';
        // Schedule the test job
        String jobId = System.schedule('InvoiceMobileNotificationSchedular', CRON_EXP, new InvoiceMobileNotificationSchedular());
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered); 
        // Verify the next time the job will run 
        Datetime nextSchduletime = datetime.newInstance(DATE.today().year(), DATE.today().month(), DATE.today().addDays(1).day(),14,00,00);
        System.assertEquals(string.valueOf(nextSchduletime.addDays(1)), String.valueOf(ct.NextFireTime.addDays(1)));   
        InvoiceMobileNotificationSchedular objTaskSchd= new InvoiceMobileNotificationSchedular();
        objTaskSchd.execute(Null);
    }
}