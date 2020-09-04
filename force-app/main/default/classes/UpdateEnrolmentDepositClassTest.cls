@isTest
public class UpdateEnrolmentDepositClassTest {

    private static testMethod void UpdateEnrolmentDepositMethod(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,true);
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        
        insert objENrol;
        Invoice__c objInvoice = TestUtil.createInvoice(objCustmr.Id,false); 
        objInvoice.Center__c=objCentr.Id;
        objInvoice.Status__c='Due';
        Insert objInvoice;
        
        Invoice_Line_Item__c invLineObj= TestUtil.createInvLineItem(objInvoice.Id,false);
        invLineObj.Enrolment__c=objENrol.Id;
        invLineObj.Is_Deposit__c=true;
        invLineObj.Amount__c=23;
         //invList.add(invLineObj);
         insert invLineObj;
        objInvoice.Status__c='Void';
        Update objInvoice;
    }
}