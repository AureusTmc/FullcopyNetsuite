@isTest
public class UpdateEnrolmentNoTest {

    testMethod Static void invokeUpdateEnrolmentNoMethod(){
         Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,true);
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        
        insert objENrol;
		 delete objENrol;
        
    }
}