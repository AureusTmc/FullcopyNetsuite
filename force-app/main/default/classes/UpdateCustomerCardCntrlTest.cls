/*
Name        :        UpdateCustomerCardCntrlTest
Date        :        20 may 2019
Author      :        Karan Singh Soni
Description :        It is the test class of UpdateCustomerCardCntrl.
*/

@isTest
public class UpdateCustomerCardCntrlTest {
	
    public static TestMethod void invokeUpdateCustomerCardCntrl(){
        Account objCustmr= TestUtil.createAccount('Customer', True, False);
        objCustmr.Stripe_Customer_Id__c='sk_test_BQokikJOvBiI2HlWgH4olfQ2';
        insert objCustmr;
        
        Invoice__C objInv=TestUtil.createInvoice(objCustmr.id,False);
        objInv.Status__c='Due';
        objInv.Parent_Account__c=objCustmr.id;
        insert objInv;
        
        apexpages.currentpage().getparameters().put('id',objCustmr.Id);
        
        UpdateCustomerCardCntrl objUpCustCard = new UpdateCustomerCardCntrl();
        objUpCustCard.selYear=String.valueOf(Date.today().year());
        objUpCustCard.selMonth=String.valueOf(Date.today().month());
        objUpCustCard.getYears();
        UpdateCustomerCardCntrl.sendInvoiceMail(objInv.Id);
		 
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{  "id": "card_1Ec5R72eZvKYlo2CRjZBIqTG",  "object": "card",  "address_city": null,  "address_country": null,  "address_line1": null,  "address_line1_check": null,  "address_line2": null,  "address_state": null,  "address_zip": null,  "address_zip_check": null,  "brand": "Visa",  "country": "US",  "customer": "cus_F6I0JZYhhDqs6p",  "cvc_check": null,  "dynamic_last4": null,  "exp_month": 8,  "exp_year": 2020,  "fingerprint": "Xt5EWLLDS7FJjR1c",  "funding": "credit",  "last4": "4242",  "metadata": {},  "name": "Jenny Rosen",  "tokenization_method": null}'));        
        UpdateCustomerCardCntrl.addCard('', objCustmr.Id,false);
        test.stopTest();
    }
     public static TestMethod void invokeUpdateCustomerCardCntrl1(){
        Account objCustmr= TestUtil.createAccount('Customer', True, False);
        objCustmr.Stripe_Customer_Id__c='sk_test_BQokikJOvBiI2HlWgH4olfQ2';
        insert objCustmr;
        
        Invoice__C objInv=TestUtil.createInvoice(objCustmr.id,False);
        objInv.Status__c='Due';
        objInv.Parent_Account__c=objCustmr.id;
        insert objInv;
        
        apexpages.currentpage().getparameters().put('id',objCustmr.Id);
        
        UpdateCustomerCardCntrl objUpCustCard = new UpdateCustomerCardCntrl();
        objUpCustCard.selYear=String.valueOf(Date.today().year());
        objUpCustCard.selMonth=String.valueOf(Date.today().month());
        objUpCustCard.getYears();
        UpdateCustomerCardCntrl.sendInvoiceMail(objInv.Id);
		 
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "cus_F6I0JZYhhDqs6p", "object": "customer", "account_balance": 0, "address": null, "created": 1558335411, "currency": "usd", "default_source": "0123456789", "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "5D1EDDA", "invoice_settings": { "custom_fields": null, "default_payment_method": null, "footer": null }, "livemode": false, "metadata": {}, "name": null, "phone": null, "preferred_locales": [], "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_F6I0JZYhhDqs6p/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_F6I0JZYhhDqs6p/subscriptions" }, "tax_exempt": "none", "tax_ids": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_F6I0JZYhhDqs6p/tax_ids" }, "tax_info": null, "tax_info_verification": null }'));        
        objUpCustCard.updateCard();
        test.stopTest();
    }
       public static TestMethod void invokeUpdateCustomerCardCntrl3(){
        Account objCustmr= TestUtil.createAccount('Customer', True, False);
        objCustmr.Stripe_Customer_Id__c='';
        insert objCustmr;
        
        Invoice__C objInv=TestUtil.createInvoice(objCustmr.id,False);
        objInv.Status__c='Due';
        objInv.Parent_Account__c=objCustmr.id;
        insert objInv;
        
        apexpages.currentpage().getparameters().put('id',objCustmr.Id);
        
        UpdateCustomerCardCntrl objUpCustCard = new UpdateCustomerCardCntrl();
       // objUpCustCard.selYear=String.valueOf(Date.today().year());
        //objUpCustCard.selMonth=String.valueOf(Date.today().month());
        //objUpCustCard.getYears();
        //UpdateCustomerCardCntrl.sendInvoiceMail(objInv.Id);
		 
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "cus_FSRw5Tblcl50mR", "object": "customer", "account_balance": 0, "address": null, "balance": 0, "created": 1563446424, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "6628100", "invoice_settings": { "custom_fields": null, "default_payment_method": null, "footer": null }, "livemode": false, "metadata": {}, "name": null, "phone": null, "preferred_locales": [], "shipping": null, "sources": { "object": "list", "data": [{"brand": "Visa","exp_month": 4,"exp_year": 2024,"last4": "4242"}], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_FSRw5Tblcl50mR/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_FSRw5Tblcl50mR/subscriptions" }, "tax_exempt": "none", "tax_ids": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_FSRw5Tblcl50mR/tax_ids" }, "tax_info": null, "tax_info_verification": null }'));        
        UpdateCustomerCardCntrl.addCard('', objCustmr.Id,true);
        test.stopTest();
    }
}