/**
* @File Name : MakeAppointmentForPortalControllerTest
* @Class Name : MakeAppointmentForPortalController
* @Description : Test class for MakeAppointmentForPortalController
* @Author : Karan Singh Soni
* @Last Modified By : Karan Singh Soni
* @Last Modified On : 12 Aug 2019
* @Modification Log : 
*==============================================================================
* Ver Date Author Modification
*==============================================================================
* 1.0 09 Aug 2019 Initial Version	(41%)
* 1.1 12 Aug 2019					(82%)
**/

@isTest
public class MakeAppointmentForPortalControllerTest {

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
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',false); 
        objPack.Type__c = 'Makeup';
        insert objPack;
         package__c objPackNew = testUtil.createPackage(objProg.id,objCentr.id,'45',false); 
        objPackNew.Type__c = 'Makeup';
        insert objPackNew;
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Parent__c = objCustmr.id;
        objENrol.Type__c = ConstantsClass.typeRegular;
        objENrol.Stage__c = ConstantsClass.enroledStatus;
        objENrol.Student__c = objCustmr.id;
        insert objENrol;
        List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,True,False,7);
        list<Center_Working_Hours__c> listCwh=TestUtil.createCenter_Working_Hours(objCentr.id, True,7);
    }
    
    //--------------------------------- for valid Appointment procedure --------------------------------------------
    public static testMethod void validAppointment(){
        
        //-------------------------------- fetching data to method ------------------------------------------------
        Account objCustmr = [SELECT Id FROM Account WHERE RecordType.Name = 'Customer' LIMIT 1 ];
        Account objTeacher = [SELECT Id FROM Account WHERE RecordType.Name = 'Teacher' LIMIT 1 ];
        Account objCenter = [SELECT Id FROM Account WHERE RecordType.Name = 'Centre' LIMIT 1 ];
        system.debug('objCustmr'+objCustmr);
        Package__c objPack = [SELECT id FROM Package__c LIMIT 1];
        Enrolment__c objENrol = [SELECT id FROM Enrolment__c  LIMIT 1];
        Booking__c objBook = [ SELECT Id FROM Booking__c LIMIT 1 ];
        
        
        //-------------------------------- Changes in Enrolment ---------------------------------------------------
        
        system.debug('@@@@'+[select Student__r.Name from Enrolment__c where Id =: objENrol.Id ].Student__r.Name);
        ApexPages.currentPage().getParameters().put('id',objCustmr.Id);
        MakeAppointmentForPortalController objMakeAppnt = new MakeAppointmentForPortalController();
        objMakeAppnt.enrollmentId = objENrol.id;
        objMakeAppnt.assignFlagValue = true;
        objMakeAppnt.updateFlagValue();
        //objMakeAppnt.prcType = 'Any Times Available';
        
        //-------------------------------- changes in Account ----------------------------------------------------
        objCustmr.Available_Make_up_Units__c = 30;
        update objCustmr;
        
        //-------------------------------- Changes in Booking -------------------------------------------------
        objBook.RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        objBook.Booking_Date__c = System.today();
        objBook.Start_Time__c = Time.newInstance(11, 11, 11, 11);
        objBook.End_Time__c = Time.newInstance(11, 11, 11, 11);
        objBook.Status__c = 'Scheduled';
		objBook.Type__c = 'Regular';
        objBook.Teacher_Account__c = objTeacher.id;
        update objBook;
        
        //-------------------------------- Inserting a new Teacher Working hour --------------------------------
        	String currDay = DateTime.now().format('E');
        	Teacher_Working_Hour__c tw = new Teacher_Working_Hour__c();
            tw.Active__c = true;
            tw.Break_Time__c = False;
            tw.Teacher_Name__c = objTeacher.id;
            tw.Center_Name__c = objCenter.Id;
            tw.Working_Day__c = currDay.toLowerCase();
            tw.Start_Time__c=Time.newInstance(7,0,0,0);
            tw.End_Time__c=Time.newInstance(23,0,0,0);
        	insert tw;
        
        
       //-------------------------------- select Student -------------------------------------------------------
        objMakeAppnt.selectedStudent();
        
        //@commented as per rajesh sir  will call end of SaveBooking(9 aug 2019 1:30 pm)
        //system.debug('objMakeAppnt'+objMakeAppnt.newModelList);
        //-------------------------------- saveCurrentRecord -----------------------------------------------------
        //objMakeAppnt.saveCurrentRecord();   
        //--------------------------------- backSecondScreen ---------------------------------------------------
        //objMakeAppnt.backSecondScreen();    @commented as per rajesh sir
        //@commented as per rajesh sir
        
        
        //--------------------------------- checkAvlMakeup,Refresh Summary ----------------------------------------------------
        objMakeAppnt.slcPkgdDuration = 30;
        objMakeAppnt.checkAvlMakeup();
        objMakeAppnt.slcdSlot = '11:00';
        objMakeAppnt.refreshSummary();
        

        //-------------------------------- Changes in newModelList -------------------------------------------
        objMakeAppnt.newModelList[0].selectedPackageId = objPack.id;	//selecting a package by the user
        
        //--------------------------------- Fetching Time Slot ------------------------------------------------
        objMakeAppnt.fetchTimeSlot();
        
        //--------------------------------- Save Booking --------------------------------------------------------
        objMakeAppnt.saveBooking();
        
        //--------------------------------- Fetching Teacher -----------------------------------------------------
        objMakeAppnt.getTeachersForSelectedLesson();
        
        //--------------------------------- Changing teacher --------------------------------------------------
        objMakeAppnt.changeTchr();		//will empty the selected package id;	
        
        //--------------------------------- Saving Current record ----------------------------------------------
        //objMakeAppnt.indexNo = 0;
        //objMakeAppnt.saveCurrentRecord(); 
        
        
        
    }
    
    //------------------------------- For inValid Appointment (Error msg's) ----------------------------------------------
    public static testMethod void inValidAppointment(){
        
        //------------------------------ Parent Account not Found --------------------------------------
        {
            ApexPages.currentPage().getParameters().put('id',Null);
            MakeAppointmentForPortalController objMakeAppnt = new MakeAppointmentForPortalController();
        }
        {
             ApexPages.currentPage().getParameters().put('id','DummyId');
            MakeAppointmentForPortalController objMakeAppnt = new MakeAppointmentForPortalController();
            
        }
        
        //---------------------------- checkAvlMakeup ---------------------------------------------------------
        {
            ApexPages.currentPage().getParameters().put('id','DummyId');
            MakeAppointmentForPortalController objMakeAppnt = new MakeAppointmentForPortalController();
            objMakeAppnt.checkAvlMakeup();
        }
        
    }
    
}