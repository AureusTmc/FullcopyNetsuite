/*
        Name        : SendInvoiceInMailBatchTest
        Date        : 2019/07/31
        Description : This test class is used to cover the SendInvoiceInMailBatch.
 */ 
@isTest
private class SendInvoiceInMailBatchTest {
	//Use to insert test records for the test class 
    @testsetup
    public static void setup(){
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
        	//Insert email template
            EmailTemplate validEmailTemplate = new EmailTemplate();
            validEmailTemplate.isActive = true;
            validEmailTemplate.Name = 'Invoice Overdue';
            validEmailTemplate.DeveloperName = 'Invoice_Overdue';
            validEmailTemplate.TemplateType = 'text';
            validEmailTemplate.FolderId = UserInfo.getUserId();
            
            insert validEmailTemplate;   
        }
    	    
        //Insert test Customer
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.Want_Invoice_As_Email__c = true;
        insert objCustmr;
        
        //Insert test Centre
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Location__c = 'Aureus 112 Katong';
        insert objCentr;
        
        //Insert test Teacher
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        
        //Insert test Program
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        
        //Insert test Package
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);   
        
        //Insert test Enrolment
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,True);
        
         //Insert test Invoice
        Invoice__c objinvoice = testUtility.createInvoice(objCustmr.id, false);
        objinvoice.Center__c = objCentr.Id;
        objinvoice.Invoice_Date__c = System.today();
        objinvoice.Email_Sent__c = false;
        objinvoice.Invoice_Type__c = 'Recurring';
        insert objinvoice;
        
        //Insert test Invoice Line Item
        Invoice_Line_Item__c objInvLneItm=TestUtil.createInvLineItem(objinvoice.id,false);
        objInvLneItm.Enrolment__c=objENrol.id;
        objInvLneItm.Remarks__c='Program Fees';
        objInvLneItm.Discount_Amount__c=30;
        insert objInvLneItm;
        
    }
    
    @isTest
    public static void testInvokeMethod(){
        Test.startTest();
        Set<String> setOfString = new Set<String>();
        for(Invoice__c objInv : [SELECT Id FROM Invoice__c]){
            setOfString.add(objInv.id);
        }
        Database.executeBatch(new SendInvoiceInMailBatch(setOfString));
        Test.stopTest();
    }
}