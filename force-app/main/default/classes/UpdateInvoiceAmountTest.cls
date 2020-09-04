@isTest
public class UpdateInvoiceAmountTest {

     static  testMethod void invokeUpdateInvoiceAmount(){
        list<Invoice_Line_Item__c> invList = new list<Invoice_Line_Item__c>();
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Invoice__c invObj =TestUtil.createInvoice(objCustmr.Id,True);
        Account objCentr=TestUtil.createAccount('Centre',False,true);
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        
        insert objENrol;
        
        Invoice_Line_Item__c invLineObj= TestUtil.createInvLineItem(invObj.Id,false);
        invLineObj.Enrolment__c=objENrol.Id;
        invLineObj.Is_Deposit__c=true;
        invLineObj.Amount__c=23;
         invList.add(invLineObj);
         insert invList;
         UpdateInvoiceAmountClass.sumInvoiceLineAmount(invList); 
         delete invList;
         UpdateInvoiceAmountClass.deleteInvoiceLineAmount(invList); 
        
    }
    
}