@isTest
public class ServiceRequestCancellationTest {
    
    testmethod static void invokeTestMethod(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,true);
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        
        insert objENrol;
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        ObjBook.Enrolment__c=objEnrol.id;
        objBook.Center__c=objCentr.Id;
        objBook.Booking_Date__c=System.today();
        
        insert objBook;
        Case casObj= TestUtil.createCase(true);
        
        Case casObject= TestUtil.createCase(false);
        casObject.Subject='Lesson Cancellation within 24 hrs';
        casObject.Type='Lesson Cancel'; 
        casObject.Booking__c=objBook.Id;
        casObject.Id=casObj.Id;
        
        ServiceRequestCancellationClass.findCase(casObj.Id);
         ServiceRequestCancellationClass.updateCaseRequest('Confirm',casObj.Id);
        
    }
    
     testmethod static void invokeTestMethodsecond(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,true);
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        
        insert objENrol;
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        ObjBook.Enrolment__c=objEnrol.id;
        objBook.Center__c=objCentr.Id;
        objBook.Booking_Date__c=System.today();
        
        insert objBook;
        Case casObj= TestUtil.createCase(true);
        
        Case casObject= TestUtil.createCase(false);
        casObject.Subject='Lesson Cancellation within 24 hrs';
        casObject.Type='Lesson Cancel'; 
        casObject.Booking__c=objBook.Id;
        casObject.Id=casObj.Id;
        
         ServiceRequestCancellationClass.updateCaseRequest('Reject',casObj.Id);
        
    }

}