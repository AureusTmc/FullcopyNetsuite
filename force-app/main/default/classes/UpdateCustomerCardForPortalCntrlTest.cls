@isTest
public class UpdateCustomerCardForPortalCntrlTest {
    @testSetup static void initDataForTest(){
        Account objCustmr=TestUtil.createAccount('Customer',True,true);
       // Account objCentre=TestUtil.createAccount('Centre',True,true);
        invoice__c invoiceObj=TestUtil.createInvoice(objCustmr.id,true);
        
    }
    
    public static testMethod void test1(){
        new UpdateCustomerCardForPortalCntrl();
        
        UpdateCustomerCardForPortalCntrl updateCustomerCardForPortalCntrlObj2=new UpdateCustomerCardForPortalCntrl();
        
        Country__c cntry = new Country__c();
        cntry.Name = 'SG';
        cntry.Country_Name__c ='Singapore';
        cntry.Currency_Code__c ='SGD';
        cntry.Tax_Rate__c = 7;
        cntry.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
        cntry.Stripe_Base_Url__c ='https://api.stripe.com';
        cntry.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
        cntry.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
        insert cntry;        
        Account objCenter=TestUtil.createAccount('Centre',false,false);
        objCenter.Country__c = cntry.Id;
        insert objCenter;
        
        Account objCustmr =[Select id from Account where recordType.name='Customer' LIMIT 1];
        objCustmr.Centre_Name__c = objCenter.Id;
        update objCustmr;
        invoice__c invoiceObj=[Select id FROM Invoice__c];
        //PageReference pageRef = Page.knowYourCustomerPage; 
        //pageRef.getParameters().put('id', String.valueOf(objCustmr.Id));
        apexpages.currentpage().getparameters().put('id',objCustmr.Id);
       // Test.setCurrentPage(pageRef);
        UpdateCustomerCardForPortalCntrl updateCustomerCardForPortalCntrlObj=new UpdateCustomerCardForPortalCntrl();
        objCustmr.Stripe_Customer_Id__c='StripID';
        update objCustmr;
        new UpdateCustomerCardForPortalCntrl();
        
        updateCustomerCardForPortalCntrlObj.getYears();
        updateCustomerCardForPortalCntrlObj.updateCard();
        
        
        UpdateCustomerCardForPortalCntrl.sendInvoiceMail(invoiceObj.id);
        
        test.startTest();
        BillingUtility.cls_data objClsData = new BillingUtility.cls_data();
        objClsData.id='card_1EQSP8Jja9IPifcSD7uJtvTz';
        objClsData.brand='Visa';
        objClsData.country='US';
        objClsData.customer='cus_EuGxgjwNxGcLDd';
        objClsData.cvc_check='pass';
        objClsData.exp_month=4;
        objClsData.exp_year=2024;
        objClsData.fingerprint='DodUMgRQg0xbj77T';
        objClsData.funding='credit';
        objClsData.last4='4242';
        
        
        BillingUtility.cls_sources objClsSourc= new BillingUtility.cls_sources();
        objClsSourc.stripeData=new List<BillingUtility.cls_data>{objClsData} ;
        objClsSourc.has_more=true;
        objClsSourc.total_count=1;
        objClsSourc.url='/v1/customers/cus_EuGxgjwNxGcLDd/sources';
        
        BillingUtility.StripeError objStripeError=new BillingUtility.StripeError();
        objStripeError.charge='charge';
        objStripeError.stripeType='stripeType';
        objStripeError.param='param';
        objStripeError.message='message';
        objStripeError.code='code';
        objStripeError.decline_code='decline_code';
        
        BillingUtility.StripeCard objStripeCard=new BillingUtility.StripeCard();
        objStripeCard.stripeType='stripeType';
        objStripeCard.country='US';
        objStripeCard.exp_month=4;
        objStripeCard.fingerprint='DodUMgRQg0xbj77T';
        objStripeCard.exp_year=2024;
        objStripeCard.last4='4242';
        objStripeCard.stripeObject='stripeObject';
        objStripeCard.id='card_1EQSP8Jja9IPifcSD7uJtvTz';
        objStripeCard.name='name';
        objStripeCard.brand='Visa';
        objStripeCard.error=objStripeError;
        objStripeCard.customer_id=objCustmr.id;
        objStripeCard.statusCode=200;
        
        BillingUtility.CardList objCardList=new BillingUtility.CardList();
        objCardList.count=1;
        objCardList.url='/v1/customers/cus_EuGxgjwNxGcLDd/sources';
        objCardList.stripeData=new List< BillingUtility.StripeCard>{objStripeCard};
            
        BillingUtility.StripeCustomer objStripeCustomer=new BillingUtility.StripeCustomer();
        objStripeCustomer.created=1;
        objStripeCustomer.account_balance=1000;
        objStripeCustomer.description='description';
        objStripeCustomer.error=objStripeError;
        objStripeCustomer.livemode=true;
        objStripeCustomer.default_source='default_source';
        objStripeCustomer.token='123';
        objStripeCustomer.id='123';
        objStripeCustomer.metadata=new Map<String,String>{'test' =>'test'};
            objStripeCustomer.cards =objCardList;
        objStripeCustomer.default_card='default_card';
        objStripeCustomer.statusCode=200;
        objStripeCustomer.sources=objClsSourc;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,JSON.serialize(objStripeCustomer)));  
        updateCustomerCardForPortalCntrlObj.selMonth='4';
        updateCustomerCardForPortalCntrlObj.selYear='2024';
        updateCustomerCardForPortalCntrlObj.updateCard();
        String error= UpdateCustomerCardForPortalCntrl.addCard('1233', objCustmr.id, false,'SG');
        
        UpdateCustomerCardForPortalCntrl.addCard('1233', objCustmr.id, true,'SG');
        //     '{  "id": "card_1Ec5R72eZvKYlo2CRjZBIqTG",  "object": "card",  "address_city": null,  "address_country": null,  "address_line1": null,  "address_line1_check": null,  "address_line2": null,  "address_state": null,  "address_zip": null,  "address_zip_check": null,  "brand": "Visa",  "country": "US",  "customer": "cus_F6I0JZYhhDqs6p",  "cvc_check": null,  "dynamic_last4": null,  "exp_month": 8,  "exp_year": 2020,  "fingerprint": "Xt5EWLLDS7FJjR1c",  "funding": "credit",  "last4": "4242",  "metadata": {},  "name": "Jenny Rosen",  "tokenization_method": null,"sources":{"last4":"1234","brand":"visa"}}'
        Test.stopTest();
        
    }
}