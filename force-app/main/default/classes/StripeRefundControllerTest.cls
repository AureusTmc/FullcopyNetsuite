@isTest
public class StripeRefundControllerTest {
	@isTest
    private static void unitTest(){
        
        Country__c country = new Country__c();
        country.Name = 'IN';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'INR';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
    	Account objCustmr=TestUtil.createAccount('Customer',True,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        insert objCustmr;
        Invoice__c objInv = TestUtil.createInvoice(objCustmr.Id,FALSE);
        objInv.Center__c = objCentr.Id;
        INSERT objInv;
        Payment__c objPayment = new Payment__c(); 
        objPayment.Invoice__c = objInv.Id;
        objPayment.Parent_Account__c = objCustmr.id;
        objPayment.Payment_Amount__c = 500;
        objPayment.Transaction_ID__c = 'test';
        insert objPayment;
        test.startTest();
        	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"status": "succeeded"}'));
        	StripeRefundController.initiateRefund('20',objPayment.id,'test');    
        Test.stopTest();
            
    }
     
}