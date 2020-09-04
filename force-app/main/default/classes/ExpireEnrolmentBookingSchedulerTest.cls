@isTest
public class ExpireEnrolmentBookingSchedulerTest {

    static testMethod void  testMethodfirst(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,true);
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Pending Enrolment';
        objEnrol.Enrolment_Email_Date__c= System.Now().addDays(-3);
        
        insert objENrol;
        
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        ObjBook.Enrolment__c=objEnrol.id;
        objBook.Center__c=objCentr.Id;
        objBook.Booking_Date__c=System.today();
        
        insert objBook;
        ExpireEnrolmentBookingScheduler objexpire= new ExpireEnrolmentBookingScheduler();
            objexpire.execute(Null);
        
    }
}