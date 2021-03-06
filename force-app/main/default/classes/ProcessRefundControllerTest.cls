/*
	Name		: 	ProcessRefundControllerTest
	Date		: 	24 June 2019
	Author		:	Karan Singh Soni
	Description :	This test class is used for test refund with stripe
*/
@istest
public class ProcessRefundControllerTest {
    public static testMethod void invokeProcessRefundController1(){
        
        Country__c country = new Country__c();
        country.Name = 'SG';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
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
        objCustmr.Centre_Name__c = objCentr.Id;
        objCustmr.Country_PI__pc = 'Singapore';
        insert objCustmr;
        
        Payment__c objPay = TestUtil.createPayment( objCustmr.Id,false );
        insert objPay;
         test.startTest();
        test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"status": "succeeded"}'));
        ProcessRefundController.initRefund( objPay.Id );
         test.stopTest();
    }
    public static testMethod void invokeProcessRefundController2(){
        Account objCustmr = TestUtil.createAccount('Customer', true, true );
        Payment__c objPay = TestUtil.createPayment( objCustmr.Id,false );
        objPay.Payment_Amount__c = 30;
        insert objPay;
        try{
        ProcessRefundController.initRefund( objPay.Id );    
        }catch(Exception e){
            
        }
        
    }
}