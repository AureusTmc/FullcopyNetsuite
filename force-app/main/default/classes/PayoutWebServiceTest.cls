@isTest
private class PayoutWebServiceTest{

	@testSetup static void setup(){
		Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
		Organisation__c organisationcObj = new Organisation__c (
			Name = 'test value'
            
		);
        organisationcObj.Country__c = country.id;
		insert organisationcObj;
		 
	}

	public static testMethod void payoutWebServiceWithOutOrgId(){
       Test.startTest();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/PayoutWebService';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{ "id": "we_1FTkUdBDN6eYqE9Q6DnysyjJ", "object": "webhook_endpoint", "api_version": "2019-10-08", "application": null, "created": 1571124655, "enabled_events": [ "payout.created" ], "livemode": false, "status": "enabled", "url": "https://full-aureusgroup.cs74.force.com/services/apexrest/PayoutWebService/a1A6F00000BjtTTUAZ" }');
        
        RestContext.request = req;
        RestContext.response= res;
        PayoutWebService.createPayoutLog();
        Test.stopTest();     
        System.assert(RestContext.response.statusCode == 400,RestContext.response.statusCode );  
    }
	public static testMethod void payoutWebServiceWithOrgId(){
       List<Organisation__c> listOrganisation = [SELECT Id FROM Organisation__c];
	   Test.startTest();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/PayoutWebService/'+listOrganisation[0].Id;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{ "created": 1326853478, "livemode": false, "id": "evt_00000000000000", "type": "payout.created", "object": "event", "request": null, "pending_webhooks": 1, "api_version": "2019-10-08", "data": { "object": { "id": "po_00000000000000", "object": "payout", "amount": 1100, "arrival_date": 1572607988, "automatic": true, "balance_transaction": "txn_00000000000000", "created": 1572607988, "currency": "sgd", "description": "STRIPE PAYOUT", "destination": "ba_1FZyNMBDN6eYqE9QSjESUqE4", "failure_balance_transaction": null, "failure_code": null, "failure_message": null, "livemode": false, "metadata": { }, "method": "standard", "source_type": "card", "statement_descriptor": null, "status": "in_transit", "type": "bank_account" } } }');
        
        RestContext.request = req;
        RestContext.response= res;
        PayoutWebService.createPayoutLog();
        Test.stopTest();     
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );  
        System.assert([Select Id,Organisation__c from Stripe_Payout_Log__c].Organisation__c == listOrganisation[0].Id );
    }
}