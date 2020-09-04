/**
* @File Name : RescheduleAppointmentForPortalCntrlTest
* @Class Name : RescheduleAppointmentForPortalCntrl
* @Description : Test class for RescheduleAppointmentForPortalCntrl
* @Author : Karan Singh Soni
* @Last Modified By : Karan Singh Soni
* @Last Modified On : 9 Aug 2019
* @Modification Log : 
*==============================================================================
* Ver Date Author Modification
*==============================================================================
* 1.0 9 Aug 2019 Initial Version (92%)
**/
@isTest
public class RescheduleAppointmentForPortalCntrlTest {
    
    //------------------------------- Initialization of test data -------------------------------------------
    @testSetup static void initDataForTest(){
        Country__c cntry = new Country__c();
        cntry.Name = 'SG';
        cntry.Country_Name__c ='Singapore';
        cntry.Currency_Code__c ='SGD';
        cntry.Tax_Rate__c = 7;
        cntry.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
        cntry.Stripe_Base_Url__c ='https://api.stripe.com';
        cntry.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
        cntry.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
        insert cntry;
        
        Organisation__c org = new Organisation__c(Name='Test',Country__c=cntry.Id);
        insert org;
        Account objCentr=TestUtil.createAccount('Centre',false,false);
        objCentr.Country__c =cntry.Id;
        objCentr.Organisation__c=org.Id;
        insert objCentr;
        Account objTeachr=testUtil.createAccount('Teacher',false,true);
        Account objCustmr=TestUtil.createAccount('Customer',True,true);
        Booking__c objBook = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,true);
        List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,True,False,7);
        list<Center_Working_Hours__c> listCwh=TestUtil.createCenter_Working_Hours(objCentr.id, True,7);
    }
    
    //--------------------------------- for valid booking procedure --------------------------------------------
    public static testMethod void validBooking(){
        
        //-------------------------------- fetching data to method ------------------------------------------------
        Account objCentr = [Select id from Account where RecordType.Name = 'Centre' Limit 1];
        Account objTeachr = [Select id from Account WHERE RecordType.Name = 'Teacher' Limit 1];
        system.debug('objTeachr'+objTeachr);
        Package__c objPack = [Select id from Package__c limit 1];
        Booking__c objBook = [Select id from Booking__c Limit 1];
        Enrolment__c objENrol = [Select id from Enrolment__c  limit 1];
        
        //--------------------------------- changes in booking object ---------------------------------------------
        objBook.Status__c = ConstantsClass.scheduledStatus;
        objBook.End_Time__c = Time.newInstance(11, 11, 11, 11);
        objBook.Package__c = objPack.id;
        objBook.Center__c = objCentr.id;
        objBook.Enrolment__c = objENrol.id;
        objBook.Type__c = 'Make-up';
        update objBook;
        
        ApexPages.currentPage().getParameters().put('id',objBook.id);
        RescheduleAppointmentForPortalCntrl objReschAppCntrl = new RescheduleAppointmentForPortalCntrl();
        
        //------------------------------ Fetching Center's ,Teacher's And Plans ----------------------------------
        objReschAppCntrl.getTeachers();
        objReschAppCntrl.getLessons();
        objReschAppCntrl.instrumentName = 'Piano';
        objReschAppCntrl.slcdTechr = objTeachr.id;
        objReschAppCntrl.getTeachersForSelectedLesson();
        objReschAppCntrl.slcdDate = '12/12/2019';
        objReschAppCntrl.slcdSlot = '11:00';
        
        //----------------------------------- Saving Booking ---------------------------------------------------------
        objReschAppCntrl.saveBooking();
        objReschAppCntrl.refreshSummary();
    }
    
    //------------------------------- For inValid Booking (Error msg's) ----------------------------------------------
    public static testMethod void inValidBooking(){
        
        //--------------------------- For Booking Not Available ----------------------------------------------------
        {
            ApexPages.currentPage().getParameters().put('id','');
            RescheduleAppointmentForPortalCntrl objReschAppCntrl = new RescheduleAppointmentForPortalCntrl();
        }
        
        //--------------------------- For Link Validity Expired -----------------------------------------------------
        {
            Booking__c objBook = [Select id from Booking__c Limit 1];
            ApexPages.currentPage().getParameters().put('id',objBook.Id);
            RescheduleAppointmentForPortalCntrl objReschAppCntrl = new RescheduleAppointmentForPortalCntrl();
        }
        
        
    }
}