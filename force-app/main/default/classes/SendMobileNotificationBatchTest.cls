@isTest
public class SendMobileNotificationBatchTest {
    @TestSetup 
    public static void setup(){
        MobileAppUtility.init();
    }
    @isTest
    public static void test() {
        
        test.startTest();
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200,
                                                                               '{"multicast_id":7430610622243333234,"success":1,"failure":0,"canonical_ids":0,"results":[{"message_id":"0:1566819879327140%95528c5095528c50"}]}'
                                                                              );
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Account parent = [SELECT id from account where recordtype.Name = 'Customer' LIMIT 1];
        
        List<MobileNotificationWrapper> notis = new List<MobileNotificationWrapper>();
        MobileNotificationWrapper noti = new MobileNotificationWrapper(
        	parent.id,
            'token',
            'title1123',
            'body'
        );
        notis.add(noti);
        Database.executeBatch(new SendMobileNotificationBatch(notis),90);
        test.stopTest();
    }
}