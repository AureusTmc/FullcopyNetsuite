/*
Name        :        RescheduleAppointmentCntrlTest
Date        :        22 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of RescheduleAppointmentCntrl.
*/

@isTEst
public class RescheduleAppointmentCntrlTest {
    public Static testMethod void invokeRescheduleAppointmentCntrl(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,true);
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objtechr.id,objCentr.Id,True,False,3);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        
        insert objENrol;
        
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        ObjBook.Enrolment__c=objEnrol.id;
        objBook.Center__c=objCentr.Id;
        objBook.Booking_Date__c=System.today().addDays(1);
        objBook.Start_Time__c=Time.newInstance(11,0,0,0);
        objBook.End_Time__c=Time.newInstance(12,0,0,0);
        objBook.Package__c=objPack.id;
        objbook.Status__c='Scheduled';
        objbook.Is_Reschedule_Booking__c=false;
        insert objBook;
        
        ApexPages.currentPage().getParameters().put('id',objBook.id);
        RescheduleAppointmentCntrl objReschedule= new RescheduleAppointmentCntrl();
        //objReschedule.getCenters();
        objReschedule.getTeachers();
        objReschedule.fetchTimeSlot();
        objReschedule.saveBooking();
    }
}