@isTest
public class payNowDetailControllerTest {
	
    static testMethod void unitTest1(){
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
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Country__c = cntry.Id;
        Insert objCentr;
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        //objCustmr.Country_PI__pc='Singapore';
        objCustmr.Stripe_Customer_Id__c='cus_FXE7nkS0iwBAn3';
        objCustmr.Centre_Name__c=objCentr.Id;
        insert objCustmr;
        
        Invoice__c inv = TestUtil.createInvoice(objCustmr.Id,false);
        inv.Paid_Amount__c =10;
        inv.Admin_Fees__c=5;
        inv.Center__c=objCentr.Id;
        insert inv;
        system.debug('== result '+ [SELECT Id,GST_Tax__c,Balance_Amount__c FROM Invoice__c where ID=:inv.Id]);
        Invoice__c inv2 = [SELECT Id,GST_Tax__c,Balance_Amount__c FROM Invoice__c where ID=:inv.Id];
        system.debug('== invoice from test class '+inv2);
        
        Invoice_Line_Item__c invLine=TestUtil.createInvLineItem(inv2.Id,false);
        invLine.Discount_Amount__c=5;
        // edited on 3rd Nov 2019 by Ravi...
        invLine.Currency_Code__c='SGD';
        insert invLine;
        
        Test.setCurrentPageReference(new PageReference('Page.PayNowDetails'));
		System.currentPageReference().getParameters().put('id', inv2.Id);
        List<Invoice__c> InvoicesListTOUpdate = new List<Invoice__c>();
        payNowDetailController payObj = new payNowDetailController();
        payobj.displayUpdateCard = true;
        payobj.InvoicesListTOUpdate = InvoicesListTOUpdate;
        test.startTest();
        payObj.callPaymentGate();
        test.stopTest();
    } 
    
    static testMethod void unitTest2(){
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.Stripe_Customer_Id__c='cus_FXE7nkS0iwBAn3';
        insert objCustmr;
        Invoice__c inv = TestUtil.createInvoice(objCustmr.Id,false);
        inv.Paid_Amount__c =23;
        inv.Admin_Fees__c=8.0;
        insert inv;
        system.debug('== result '+ [SELECT Id,GST_Tax__c,Balance_Amount__c FROM Invoice__c where ID=:inv.Id]);
        Invoice__c inv2 = [SELECT Id,GST_Tax__c,Balance_Amount__c FROM Invoice__c where ID=:inv.Id];
        system.debug('== invoice from test class '+inv2);
        
        Invoice_Line_Item__c invLine=TestUtil.createInvLineItem(inv2.Id,false);
        invLine.Discount_Amount__c=5;
        invLine.Currency_Code__c='SGD';
        insert invLine;
        
        Test.setCurrentPageReference(new PageReference('Page.PayNowDetails'));
		System.currentPageReference().getParameters().put('id', inv2.Id);
        payNowDetailController payObj = new payNowDetailController();
        
        test.startTest();
        payObj.callPaymentGate();
        test.stopTest();
        
    } 
    
}