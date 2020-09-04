/*
Name        :        MakeupAppointmentCntrlTest
Date        :        20 may 2019
Author      :        Karan Singh Soni
Description :        It is the test class of MakeupAppointmentCntrl.
*/

@isTest
public class MakeupAppointmentCntrlTest {
    
    public static TestMethod void invokeMakeupAppointmentCntrl(){
        
        Account objCentr=TestUtil.createAccount('Centre',false,true);
        Account objTeachr = testUtil.createAccount('Teacher',false,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',false);
        objPack.Type__c='Makeup';
        insert objPack;
        List<Teacher_working_Hour__c> listTwh=TestUtil.createTeacher_Working_Hour(objTeachr.Id, objCentr.Id,true,false,7);
        
        Account objCustmr= TestUtil.createAccount('Customer', True, False);
        objCustmr.Stripe_Customer_Id__c='sk_test_BQokikJOvBiI2HlWgH4olfQ2';
        insert objCustmr;
        
        Enrolment__c objENrol = TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,true);
        Booking__c objBook = TestUtil.createBooking(objTeachr.id,'Lesson','Regular', false);  
        objBook.Enrolment__c = objENrol.Id;
        objBook.End_Time__c =Time.newInstance(18,0,0,0);
        insert objBook;
        
        Booking__c objCancelBook = TestUtil.createBooking(objTeachr.id,'Lesson','Regular', false);  
        objCancelBook.Enrolment__c = objENrol.Id;
        objCancelBook.Student__c=objCustmr.Id;
        objCancelBook.End_Time__c =Time.newInstance(18,0,0,0);
        objCancelBook.Status__c='Canceled';
        objCancelBook.Make_up_Expiry_Date__c=Date.today().addDays(1);
        objCancelBook.Available_Make_up_Units__c=30;
        insert objCancelBook;
        
        apexpages.currentpage().getparameters().put('id',objCustmr.Id);
        
        MakeupAppointmentCntrl objMakeApp = new MakeupAppointmentCntrl();
        objMakeApp.slcdStu=objENrol.Id;
        objMakeApp.slcPkgdDuration=45;
        objMakeApp.slcdPkg=objPack.Id;
        objMakeApp.slcdTchr=objTeachr.Id;
        objMakeApp.slcdSlot='23:00';
        
        objMakeApp.getCenterName();
        objMakeApp.getMakeupPkg();
        objMakeApp.getTeachers();
        objMakeApp.checkAvlMakeup();
        objMakeApp.fetchTimeSlot();
        objMakeApp.refreshSummary();
        objMakeApp.saveBooking();
    }
}