@isTest
public class enrolmentPrcRedirectCntrlTest {
    
    testMethod static void invokeenrolmentPrcRedirectCntrlMethod(){
        ApexPages.currentPage().getParameters().put('userEmail','xyz@gmail.com');
         Account objCentr=TestUtil.createAccount('Centre',False,true);
      
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.PersonEmail='xyz@gmail.com';
        insert objCustmr; 
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',false);  
        objPack.RecordtypeId=pkgLessRecId;
        
            objPack.Type_of_package__c='Promo';
            objPack.Type__c='Individual';
        	objPack.Active__c=true;
            objPack.Location__c=objCentr.Id;
        
        insert objPack;
        
        List<Enrolment__c> enrolObjList = new List<Enrolment__c>(); 
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c=ConstantsClass.typeTrial;
        objEnrol.Stage__c='Pending Enrolment';
       /* objEnrol.Trial_Date__c=System.today().addDays(2);
        objEnrol.Lessons_Start_Date__c=System.today().addDays(2);*/
        
        insert objENrol;
        
        enrolmentPrcRedirectCntrl enrolObj= new enrolmentPrcRedirectCntrl();
        enrolObj.redirectToAntoher();
        
        
    }

}