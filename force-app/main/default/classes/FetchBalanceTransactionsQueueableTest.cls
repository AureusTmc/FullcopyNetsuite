@isTest
public class FetchBalanceTransactionsQueueableTest{
    @testSetup 
    static void setup() {
        String paymentTransactionRcTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByDeveloperName().get('Payment_Transaction').getRecordTypeId();
        String refundPaymentRcTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByDeveloperName().get('Refund').getRecordTypeId();
        
        Account acc = TestUtil.createAccount('Customer',TRUE,FALSE);
        insert acc;
        
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
        
        Organisation__c org = new Organisation__c(
            Name = 'Test Org',
            Bank_Account_Number__c = '123456789',
            Bank_Name__c = 'Test Bank Name',
            Branch_Code__c = '001',
            Country__c = country.Id
        );
        insert org;
        
        Stripe_Payout_Log__c payoutObj = new Stripe_Payout_Log__c(Organisation__c = org.Id);
        insert payoutObj;
        
        List<Payment__c> paymentList = new List<Payment__c>();
        
        //add payment records
        paymentList.add(new Payment__c(RecordTypeId = paymentTransactionRcTypeId, Parent_Account__c = acc.Id, Transaction_ID__c = 'po_1F7B21Jja9IPifcSMtoJfYU9'));
        paymentList.add(new Payment__c(RecordTypeId = refundPaymentRcTypeId, Parent_Account__c = acc.Id, Transaction_ID__c = 'po_1F7B21Jja9IPifcSMtoJfYU8'));
        
        insert paymentList;
    }
    
    @isTest
    public static void validatePaymentUpdate(){
        
        Id payoutId = [SELECT Id FROM Stripe_Payout_Log__c LIMIT 1][0].Id;
        Integer limitOfRec = 10;
        
        Test.startTest();
        String body = '{"object": "list", "data": [{"id": "txn_1F7B21Jja9IPifcSz55SWDYy", "amount": 8560, "currency": "sgd", "description": "STRIPE PAYOUT", "fee": 0, "fee_details": [], "source": "po_1F7B21Jja9IPifcSMtoJfYU9", "type": "charge"}, {"id": "txn_1F7B21Jja9IPifcSz55SWDYy", "amount": 8560, "currency": "sgd", "description": "STRIPE PAYOUT", "fee": 0, "fee_details": [], "source": "po_1F7B21Jja9IPifcSMtoJfYU8", "type": "refund"}], "has_more": false}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body));
        Id jobId = System.enqueueJob(new FetchBalanceTransactionsQueueable(payoutId, limitOfRec));
        
        // @jatin: 10/29/2019 
        FetchBalanceTransactionsQueueable.BalanceTransactionWrapper balTransaction = (FetchBalanceTransactionsQueueable.BalanceTransactionWrapper) System.JSON.deserialize(body, FetchBalanceTransactionsQueueable.BalanceTransactionWrapper.class);
        String endingObjId = balTransaction.data.get(balTransaction.data.size()-1).id; //store last object's id for future use
        Id jobId2 = System.enqueueJob(new FetchBalanceTransactionsQueueable(payoutId, limitOfRec, endingObjId));
         
        
        	                          
        Test.stopTest();
        system.debug('query'+[SELECT COUNT() from Payment__c WHERE Stripe_Payout_Id__c=: payoutId]);
        //System.assertEquals(2, [SELECT COUNT() from Payment__c WHERE Stripe_Payout_Id__c=: payoutId]);
        //ystem.assertEquals('Processed in SF', [SELECT Status__c FROM Stripe_Payout_Log__c WHERE Id=:payoutId][0].Status__c);
        
        FetchBalanceTransactionsQueueable.BalanceTransactionWrapper obj1;
        FetchBalanceTransactionsQueueable.DataWrapper obj2;
        FetchBalanceTransactionsQueueable.FeeDetailsWrapper obj3;
    }
     @isTest
    public static void validatePaymentUpdate2(){
        String CRON_EXP = '0 0 0 15 3 ? *';
        Id payoutId = [SELECT Id FROM Stripe_Payout_Log__c LIMIT 1][0].Id;
        Test.startTest();
        String body = '{"object": "list", "data": [{"id": "txn_1F7B21Jja9IPifcSz55SWDYy", "amount": 8560, "currency": "sgd", "description": "STRIPE PAYOUT", "fee": 0, "fee_details": [], "source": "po_1F7B21Jja9IPifcSMtoJfYU9", "type": "charge"}, {"id": "txn_1F7B21Jja9IPifcSz55SWDYy", "amount": 8560, "currency": "sgd", "description": "STRIPE PAYOUT", "fee": 0, "fee_details": [], "source": "po_1F7B21Jja9IPifcSMtoJfYU8", "type": "refund"}], "has_more": false}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body));
        	String jobId1 = System.schedule('FetchBalanceTransactionsScheduler',  CRON_EXP, new FetchBalanceTransactionsScheduler());
        Test.stopTest();
        
    }
}