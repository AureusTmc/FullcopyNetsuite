@isTest
public class TrialEnrolmentSummaryControllerTest {
	
    public static testmethod void TrialEnrolmentSummaryControllerInvoke(){
        Map<string,string> entrdDataMap=TestUtil.createData(); 
        Enrolment__C objEnrol= new Enrolment__c();
        objEnrol.Id=entrdDataMap.get('objEnrol');
        objEnrol.Type__c='Trial';
        update objEnrol;
        ApexPages.currentPage().getParameters().put('id',entrdDataMap.get('objEnrol'));
        TrialEnrolmentSummaryController objTESC = new TrialEnrolmentSummaryController();
         test.startTest();
        objTESC.stripeToken='sk_test_BQokikJOvBiI2HlWgH4olfQ2';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id":"cus_EmndZcxxpUhDzD", "object": "customer", "account_balance": 0, "created": 1553840254, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "98B2456", "invoice_settings": { "custom_fields": null, "footer": null }, "livemode": false, "metadata": {}, "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/subscriptions" }, "tax_info": null, "tax_info_verification": null }'));
        objTESC.base64SignImg='sign';
        objTESC.completeEnrolment();
        test.stopTest();
    }
}