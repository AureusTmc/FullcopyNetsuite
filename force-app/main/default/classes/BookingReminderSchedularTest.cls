@istest
public class BookingReminderSchedularTest {
    @TestSetup 
    public static void setup(){
        MobileAppUtility.init();
    }
     @isTest
    public static void testBookingReminderSchedular() {
         Firebase_Settings__c settings = New Firebase_Settings__c(name= 'setting',API_Key__c='Key=AAAAnpwAoa0:APA91bED0q97GSDONF-R-KvOr3ZPQM3Iid5O6Lq00ysF7XvZYwFZ8y2U6kF_loirGYtoNF6rgQPSTQFtYisty4GB_6w5xFf9cXDTRI8eXSulk6KX8cFjCgDEvf7KjnH4tu27V65Y0WEN',
                                                                 Endpoint__c='https://fcm.googleapis.com/fcm/send',Enable_Logs__c=true);
        insert settings;
        test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,
                                                                               '{"multicast_id":7430610622243333234,"success":1,"failure":0,"canonical_ids":0,"results":[{"message_id":"0:1566819879327140%95528c5095528c50"}]}'
                                                                              );
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        test.stopTest();
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.FCM_Token__c ='dVD5mKEVenc:APA91bEJuzKM2bFOg-b-P0HShpR0zF0XL1t15f78bGid0CXdK3F98YZGuTPbJEkamyyEU80fRXQM1f3pqOP_d-dUosGnziJo4ACLRSDw5oHs6nXL47QKelmxf6QkbkaLKxxiE9bAJDb3';
        objCustmr.Booking_Reminded_Notification__c = true;
        insert objCustmr;
        List<Booking__C> listOfBooking = [Select Id from booking__c WHERE Status__c = 'Scheduled'];
        listOfBooking[0].Booking_Date__c = Date.today().addDays(1); 
        listOfBooking[0].Parent__c=objCustmr.id;
        update listOfBooking;
        // This test runs a scheduled job at midnight 1pm
         String CRON_EXP = '0 0 1 * * ? * ';
        // Schedule the test job
        String jobId = System.schedule('BookingReminderSchedular', CRON_EXP, new BookingReminderSchedular());
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
        // Verify the job has not run 
        System.assertEquals(0, ct.TimesTriggered); 
        // Verify the next time the job will run 
        Datetime nextSchduletime = datetime.newInstance(DATE.today().year(), DATE.today().month(), DATE.today().addDays(1).day(),01,00,00);
        System.assertEquals(string.valueOf(nextSchduletime), String.valueOf(ct.NextFireTime));   
        
        BookingReminderSchedular objTaskSchd= new BookingReminderSchedular();
        objTaskSchd.execute(Null);
    }
}