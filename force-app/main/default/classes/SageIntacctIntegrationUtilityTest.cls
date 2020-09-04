/*
Name    :       SageIntacctIntegrationUtilityTest
Date    :       18 JULY 2019    
author  :       karan singh soni
*/
@isTest
public class SageIntacctIntegrationUtilityTest {
    @isTest
    private static void unitTest1(){
        
        Sage_Intacct_Credentials__c sic = new Sage_Intacct_Credentials__c();
        sic.Name='test';
        sic.Endpoint__c='https://api.intacct.com/ia/xml/xmlgw.phtml';
        insert sic;
        
        List<Sage_GL_Account__c> sgaList = new List<Sage_GL_Account__c>();
        for(integer i=0;i<=3;i++){
            Sage_GL_Account__c sga = new Sage_GL_Account__c();
            if(i==0){
                sga.Name='Merchandise Card Receivable';
            }
            else if(i==1){
                sga.Name='Accounts Payable'; 
                sga.GL_Account_No__c='qwerty';
            }
            else if(i==2){
                sga.Name='AGP Cash at Bank - OCBC';
            }
            else{
                sga.Name='Merchant Account Fees';
            }
            sgaList.add(sga) ;
        }
        insert sgaList;
        
        Stripe_Payout_Log__c spl = new Stripe_Payout_Log__c();
        insert spl;
        
        Country__c country = new Country__c();
        country.Name = 'IN';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'INR';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        country.Currency_Code_PI__c='SGD';
        insert country;
        
        Organisation__c org = new Organisation__c();
        org.Country__c = country.id;
        insert org;
        
        Account Centre = TestUtil.createAccount('Centre',TRUE,TRUE);
        Centre.Country__c=country.id;
        centre.Organisation__c=org.id;
        update Centre;
        
        Account cust = TestUtil.createAccount('Customer',TRUE,TRUE);
        
        Invoice__c objInv = TestUtil.createInvoice(cust.id,TRUE);
        objInv.Center__c = Centre.id;
        objInv.SageInvoiceKey__c='xyz';
        objInv.MovedToSage__c=false;
        objInv.Admin_Fees__c=10;
        update objInv;
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,Centre.id,'60',true);
        objPack.Type_of_package__c='Promo';
        objPack.Type__c='Individual';
        objPack.Sage_Revenue_Template__c='svt';
        update objPack;
        
        Invoice_Line_Item__c ili = TestUtil.createInvLineItem(objInv.id, TRUE);
        ili.Package__c=objPack.id;
        ili.GST_Amount__c=10;
        ili.Discount_Amount__c=5;
        
        update ili;
        Invoice_Line_Item__c ili2 = TestUtil.createInvLineItem(objInv.id, TRUE);
        ili2.Remarks__c = 'azx';
        ili2.Discount_Amount__c=10;
        ili2.Is_Deposit__c=false;
        ili2.Month__c=Date.today();
        ili2.GST_Amount__c=10;
        update ili2;
        
        Invoice_Line_Item__c ili3 = TestUtil.createInvLineItem(objInv.id, TRUE);
        ili3.Remarks__c = 'azx';
        ili3.Discount_Amount__c=10;
        ili3.Is_Deposit__c=true;
        ili3.Month__c=Date.today();
        ili3.GST_Amount__c=0;
        update ili3;
        
        Payment__c objPay = TestUtil.createPayment(cust.id,TRUE);
        Payment__c objPay1 = TestUtil.createPayment(cust.id,TRUE);
        objPay1.SagePaymentKey__c='zzxc';
        objPay1.Invoice__c=objInv.id;
        objPay1.Stripe_Payout_Id__c=spl.id;
        update objPay1;
        objPay.Payment_Date__c=system.today();
        objPay.Payment_Amount__c=-1;
        objPay.Invoice__c=objInv.id;
        objPay.MovedToSage__c=false;
        objPay.Parent_Payment__c=objPay1.id;
        objPay.Stripe_Payout_Id__c=spl.id;
        update objPay;
        
        Set<String> setOfInvIds = new Set<String>();
        setOfInvIds.add(objInv.Id);
        setOfInvIds.add('asdf');
        
        test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>a0P0p000000AKnAEAW</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-08-28T03:47:39-07:00</sessiontimestamp><sessiontimeout>2019-08-28T09:47:39-07:00</sessiontimeout></authentication><result><status>success</status><function>getAPISession</function><controlid>a0P0p000000AKnAEAW</controlid><data><api><sessionid>oSHwMnFypzWA7wmIPlLj332aNYHvCQ..</sessionid><endpoint>https://api.intacct.com/ia/xml/xmlgw.phtml</endpoint><locationid>AGP</locationid></api></data></result></operation></response>'));
        
        SageIntacctIntegrationUtility.sessionWrapper objnew = new SageIntacctIntegrationUtility.sessionWrapper();
        objnew.senderId='sdsd';
        objnew.senderPassword='csd';
        objnew.endPointUrl='sdd';
        objnew.sessionId='sds';
        objnew.errorMsg='dcsds';
        
        SageIntacctIntegrationUtility.getGlAccountCodes();
        SageIntacctIntegrationUtility.resultWrapper objnew2 = new SageIntacctIntegrationUtility.resultWrapper();
        SageIntacctIntegrationUtility.revRecWrapper objnew3 = new SageIntacctIntegrationUtility.revRecWrapper();
        SageIntacctIntegrationUtility.newEnrolment(cust.id,setOfInvIds);
        SageIntacctIntegrationUtility.newStudioRental(cust.id,objInv.Id,objPay.Id);
        SageIntacctIntegrationUtility.packageUpgrade(objInv.Id,objPay.Id);  
        SageIntacctIntegrationUtility.changeEnrolment(objInv.Id);
        SageIntacctIntegrationUtility.createCustomer(new SageIntacctIntegrationUtility.sessionWrapper(), Centre);
        SageIntacctIntegrationUtility.createInvoice(new SageIntacctIntegrationUtility.sessionWrapper(),new Invoice__c());
        SageIntacctIntegrationUtility.createPayment(new SageIntacctIntegrationUtility.sessionWrapper(), new Payment__c(), 'invoiceKey');
        SageIntacctIntegrationUtility.reverseInvoice(new SageIntacctIntegrationUtility.sessionWrapper(),objInv);
        SageIntacctIntegrationUtility.reversePayment(new SageIntacctIntegrationUtility.sessionWrapper(), objPay);
        SageIntacctIntegrationUtility.createAdjustmentJournalEntries(new SageIntacctIntegrationUtility.sessionWrapper(), objPay); 
        SageIntacctIntegrationUtility.getRevRecognitionSchedule(objnew, 'invoiceKey');
        SageIntacctIntegrationUtility.getRevRecognitionEntries(objnew, new set<string>{'zxc'});
        SageIntacctIntegrationUtility.updateRevRecEntries(objnew, new Map<string,string>{'updRevRecEntryMap'=>'updRevRecEntryMap'}, new Map<string,string>{'newRevRecEntryMap'=>'newRevRecEntryMap'});
        SageIntacctIntegrationUtility.createStripeJournalEntries(spl,new List<Payment__c>());
        SageIntacctIntegrationUtility.existingCustomerPrepayment(objInv.id,objPay.id);
        SageIntacctIntegrationUtility.voidInvoice(objInv.id);
        SageIntacctIntegrationUtility.refundPayment(objPay.id);
        SageIntacctIntegrationUtility.paynowInvoice(objPay.id);
        SageIntacctIntegrationUtility.americanClubInvoice(objInv.id);
        
        test.stopTest();
    }
    
    @isTest
    private static void unitTest2(){
        
        Sage_Intacct_Credentials__c sic = new Sage_Intacct_Credentials__c();
        sic.Name='test';
        sic.Endpoint__c='https://api.intacct.com/ia/xml/xmlgw.phtml';
        insert sic;
        
        List<Sage_GL_Account__c> sgaList = new List<Sage_GL_Account__c>();
        for(integer i=0;i<=3;i++){
            Sage_GL_Account__c sga = new Sage_GL_Account__c();
            if(i==0){
                sga.Name='Merchandise Card Receivable';
            }
            else if(i==1){
                sga.Name='Accounts Payable'; 
                sga.GL_Account_No__c='qwerty';
            }
            else if(i==2){
                sga.Name='AGP Cash at Bank - OCBC';
            }
            else{
                sga.Name='Merchant Account Fees';
            }
            sgaList.add(sga) ;
        }
        insert sgaList;
        
        Stripe_Payout_Log__c spl = new Stripe_Payout_Log__c();
        insert spl;
        
        Country__c country = new Country__c();
        country.Name = 'IN';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = -7.0;
        country.Currency_Code__c = 'INR';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        country.Currency_Code_PI__c='SGD';
        insert country;
        
        Organisation__c org = new Organisation__c();
        org.Country__c = country.id;
        insert org;
        
        Account Centre = TestUtil.createAccount('Centre',TRUE,TRUE);
        Centre.Country__c=country.id;
        centre.Organisation__c=org.id;
        update Centre;
        
        Account cust = TestUtil.createAccount('Customer',TRUE,TRUE);
        
        Invoice__c objInv = TestUtil.createInvoice(cust.id,TRUE);
        objInv.Center__c = Centre.id;
        objInv.SageInvoiceKey__c='xyz';
        objInv.MovedToSage__c=false;
        objInv.Admin_Fees__c=10;
        update objInv;
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,Centre.id,'60',true);
        objPack.Type_of_package__c='Promo';
        objPack.Type__c='Individual';
        objPack.Sage_Revenue_Template__c='svt';
        update objPack;
        
        Invoice_Line_Item__c ili = TestUtil.createInvLineItem(objInv.id, TRUE);
        ili.Package__c=objPack.id;
        ili.GST_Amount__c=10;
        ili.Discount_Amount__c=5;
        update ili;
        Invoice_Line_Item__c ili2 = TestUtil.createInvLineItem(objInv.id, TRUE);
        ili2.Remarks__c = 'azx';
        ili2.Discount_Amount__c=10;
        ili2.Is_Deposit__c=false;
        ili2.Month__c=Date.today();
        ili2.GST_Amount__c=10;
        update ili2; 
        
        Payment__c objPay = TestUtil.createPayment(cust.id,TRUE);
        Payment__c objPay1 = TestUtil.createPayment(cust.id,TRUE);
        objPay1.SagePaymentKey__c='zzxc';
        objPay1.Invoice__c=objInv.id;
        objPay1.Stripe_Payout_Id__c=spl.id;
        objPay1.Payment_Amount__c=1;
        objPay1.SagePaymentKey__c='spk';
        update objPay1;
        objPay.Payment_Date__c=system.today();
        objPay.Payment_Amount__c=-1;
        objPay.Invoice__c=objInv.id;
        objPay.MovedToSage__c=false;
        objPay.Parent_Payment__c=objPay1.id;
        objPay.Stripe_Payout_Id__c=spl.id;
        update objPay;
        
        Set<String> setOfInvIds = new Set<String>();
        setOfInvIds.add(objInv.Id);
        setOfInvIds.add('asdf');
        
        test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>a0P0p000000AKnAEAW</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-08-28T03:47:39-07:00</sessiontimestamp><sessiontimeout>2019-08-28T09:47:39-07:00</sessiontimeout></authentication><result><status>success</status><function>getAPISession</function><controlid>a0P0p000000AKnAEAW</controlid><data><api><sessionid>oSHwMnFypzWA7wmIPlLj332aNYHvCQ..</sessionid><endpoint>https://api.intacct.com/ia/xml/xmlgw.phtml</endpoint><locationid>AGP</locationid></api></data></result></operation></response>'));
        
        SageIntacctIntegrationUtility.sessionWrapper objnew = new SageIntacctIntegrationUtility.sessionWrapper();
        objnew.senderId='sdsd';
        objnew.senderPassword='csd';
        objnew.endPointUrl='sdd';
        objnew.sessionId='sds';
        objnew.errorMsg='dcsds';
        
        SageIntacctIntegrationUtility.getGlAccountCodes();
        SageIntacctIntegrationUtility.resultWrapper objnew2 = new SageIntacctIntegrationUtility.resultWrapper();
        SageIntacctIntegrationUtility.revRecWrapper objnew3 = new SageIntacctIntegrationUtility.revRecWrapper();
        SageIntacctIntegrationUtility.newEnrolment(cust.id,setOfInvIds);
        SageIntacctIntegrationUtility.newStudioRental(cust.id,objInv.Id,objPay.Id);
        SageIntacctIntegrationUtility.packageUpgrade(objInv.Id,objPay.Id);  
        SageIntacctIntegrationUtility.changeEnrolment(objInv.Id);
        SageIntacctIntegrationUtility.createCustomer(new SageIntacctIntegrationUtility.sessionWrapper(), Centre);
        SageIntacctIntegrationUtility.createInvoice(new SageIntacctIntegrationUtility.sessionWrapper(),new Invoice__c());
        SageIntacctIntegrationUtility.fetchARInvoiceKey(objnew,'invoiceKey');
        SageIntacctIntegrationUtility.fetchVATprocessStatus(objnew,'invoiceKey');
        SageIntacctIntegrationUtility.createPayment(new SageIntacctIntegrationUtility.sessionWrapper(), new Payment__c(), 'invoiceKey');
        SageIntacctIntegrationUtility.applyARPayment(objnew,objInv);
        SageIntacctIntegrationUtility.reverseInvoice(new SageIntacctIntegrationUtility.sessionWrapper(),objInv);
        SageIntacctIntegrationUtility.reversePayment(new SageIntacctIntegrationUtility.sessionWrapper(), objPay);
        SageIntacctIntegrationUtility.createAdjustmentJournalEntries(new SageIntacctIntegrationUtility.sessionWrapper(), objPay); 
        SageIntacctIntegrationUtility.getRevRecognitionSchedule(objnew, 'invoiceKey');
        SageIntacctIntegrationUtility.getRevRecognitionEntries(objnew, new set<string>{'zxc'});
        SageIntacctIntegrationUtility.updateRevRecEntries(objnew, new Map<string,string>{'updRevRecEntryMap'=>'updRevRecEntryMap'}, new Map<string,string>{'newRevRecEntryMap'=>'newRevRecEntryMap'});
        
        SageIntacctIntegrationUtility.createStripeJournalEntries(spl,new List<Payment__c>());
        SageIntacctIntegrationUtility.existingCustomerPrepayment(objInv.id,objPay.id);
        SageIntacctIntegrationUtility.voidInvoice(objInv.id);
        SageIntacctIntegrationUtility.refundPayment(objPay.id);
        SageIntacctIntegrationUtility.paynowInvoice(objPay.id);
        SageIntacctIntegrationUtility.americanClubInvoice(objInv.id);
        SageIntacctIntegrationUtility.adhocInvoice(objInv.id);
        
        test.stopTest();
    }
    
    @isTest
    private static void unitTest3(){
        Country__c country = new Country__c();
        country.Name = 'IN';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'INR';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        country.Currency_Code_PI__c='SGD';
        insert country;
        
        Organisation__c org = new Organisation__c();
        org.Country__c = country.id;
        org.Sage_Company__c = 'AGP';
        insert org;
        
        Account Centre = TestUtil.createAccount('Centre',TRUE,TRUE);
        Centre.Country__c=country.id;
        centre.Organisation__c=org.id;
        update Centre;
        
        Account cust = TestUtil.createAccount('Customer',TRUE,TRUE);
        
        Invoice__c objInv = TestUtil.createInvoice(cust.id,TRUE);
        objInv.Center__c = Centre.id;
        objInv.MovedToSage__c=true;
        objInv.SageOrderEntryKey__c = 'orderKey';
        objInv.Admin_Fees__c=10;
        update objInv;
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,Centre.id,'60',true);
        objPack.Type_of_package__c='Promo';
        objPack.Type__c='Individual';
        objPack.Sage_Revenue_Template__c='svt';
        update objPack;
        
        Invoice_Line_Item__c ili = TestUtil.createInvLineItem(objInv.id, TRUE);
        ili.Package__c=objPack.id;
        ili.GST_Amount__c=10;
        ili.Discount_Amount__c=5;
        update ili;
        Invoice_Line_Item__c ili2 = TestUtil.createInvLineItem(objInv.id, TRUE);
        ili2.Remarks__c = 'azx';
        ili2.Discount_Amount__c=10;
        ili2.Is_Deposit__c=false;
        ili2.Month__c=Date.today();
        ili2.GST_Amount__c=10;
        update ili2; 
        
        Payment__c objPay = TestUtil.createPayment(cust.id,TRUE);
        Payment__c objPay1 = TestUtil.createPayment(cust.id,TRUE);
        objPay1.SagePaymentKey__c='zzxc';
        objPay1.Invoice__c=objInv.id;
        objPay1.Payment_Amount__c=1;
        objPay1.SagePaymentKey__c='spk';
        update objPay1;
        objPay.Payment_Date__c=system.today();
        objPay.Payment_Amount__c=-1;
        objPay.Invoice__c=objInv.id;
        objPay.MovedToSage__c=false;
        objPay.Parent_Payment__c=objPay1.id;
        update objPay;
        
        database.executeBatch(new SageFetchARInvoiceKey(new set<string>{objInv.Id}),1);
        
        SchedulableContext sc;
        SageFetchARInvoiceKey sfk = new SageFetchARInvoiceKey();
        sfk.execute(sc);
        
    }
}