/*
Name        :        InvoiceTriggerTest
Date        :        21 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of InvoiceTrigger.
*/
@isTest
public class InvoiceTriggerTest {
    public static testMethod void invokeInvoiceTrigger(){
        
        Country__c country = new Country__c(); 
        country.Name = 'IN';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD'; 
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com'; 
        country.Stripe_Publishable_Key__c = 'ABC'; 
        country.Stripe_Secret_Key__c = 'deede'; 
        insert country;
        
        Account objCentr=TestUtil.createAccount('Centre',False,FALSE);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Account objCustmr = testUtil.createAccount('Customer',true,False); 
        objcustmr.Admin_Fees_Required__c=true;
        objcustmr.Admin_Fees__c='3';
        insert objcustmr;
        
        Invoice__c objinvoice = testUtility.createInvoice(objcustmr.id, false);
        objInvoice.Center__c = objCentr.Id;
        objInvoice.Parent_Account__c=objcustmr.id;
        insert objInvoice;
        
        Invoice_Line_Item__c objInvLneItm=TestUtil.createInvLineItem(objinvoice.id,True);
        objInvLneItm.Amount__c=30;
        update objInvLneItm;
        
        Invoice_Line_Item__c objInvLneItm2=TestUtil.createInvLineItem(objinvoice.id,True);
        objInvLneItm2.Amount__c=-60;
        
        update objInvLneItm2;
        
        update objInvoice;
        System.debug('Invoice '+objInvoice.Gross_Total__c);
    }
    public static testMethod void invokeInvoiceTrigger2(){
        
        Country__c country = new Country__c(); 
        country.Name = 'IN';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD'; 
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com'; 
        country.Stripe_Publishable_Key__c = 'ABC'; 
        country.Stripe_Secret_Key__c = 'deede'; 
        insert country;
        
        Account objCentr=TestUtil.createAccount('Centre',False,FALSE);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Map<String, String> mapOfStatusInvoice = new Map<String, String>();
    	Account objCustmr = testUtil.createAccount('Customer',true,False); 
        objcustmr.Admin_Fees_Required__c=true;
        objcustmr.Admin_Fees__c='3';
        insert objcustmr;
               
        Invoice__c objinvoice = testUtility.createInvoice(objcustmr.id, false);
        objInvoice.Parent_Account__c=objcustmr.id;
        objInvoice.Center__c = objCentr.Id;
        insert objInvoice;
        
         mapOfStatusInvoice.put(objinvoice.Id, objcustmr.Id);
        InvoiceTriggerHelper.procesStatusInvoice(mapOfStatusInvoice);
        
        Invoice_Line_Item__c objInvLneItm=TestUtil.createInvLineItem(objinvoice.id,false);
        objInvLneItm.Amount__c=30;
        objInvLneItm.Is_Deposit__c = false;
        insert objInvLneItm;
		update objInvoice;
    }
}