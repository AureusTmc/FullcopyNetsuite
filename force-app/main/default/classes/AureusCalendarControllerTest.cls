/*
Name        :        AureusCalendarControllerTest
Date        :        4 April 2019(modified 15 april 2019,28 May 2019,24 June 2019,17 july 2019)
Author      :        Karan Singh Soni
Description :        It is the test class of AureusCalendarController.
*/
@isTest
public class AureusCalendarControllerTest {
    
    public static testMethod void invokeAureusCalendarController(){
        Firebase_Settings__c objSetting = new Firebase_Settings__c();
        objSetting.Name = 'setting';
        objSetting.Enable_Notifications__c = false;
        insert objSetting;
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        Insert objCentr;
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.Centre_Name__c = objCentr.Id;
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
        //Account objCustmr1=TestUtil.createAccount('Customer',True,True);
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPackTemp=testUtil.createPackage(objProg.id,objCentr.id,'60',true); 
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0));
        Resource__c objRes=TestUtil.createResource(objCentr.Id,'TstId',objPack.id,true);
        
        String allStaff = 'AllStaff';
        String allRosteredStaff = 'AllRosteredStaff';
        
        String allResource = 'AllResource';
        String allRosteredResource = 'AllRosteredResource';
        
        List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,True,False,7);
        list<Center_Working_Hours__c> listCwh=TestUtil.createCenter_Working_Hours(objCentr.id, True,7);
        list<Resource_Working_Hour__c> listRwh=TestUtil.createResource_Working_Hour(objCentr.id,objRes.Id,true,7);
        
        String bookingJson = '{"studentId":"'+objCustmr.Id+'","packageId":"'+objPack.Id+'","type":"Trial","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objCentr.Id+'","teacherId":"'+objTeachr.Id+'"}';
        
        ApexPages.currentPage().getParameters().put('id',objTeachr.id);
        AureusCalendarController objAureusCC= new AureusCalendarController();
        objAureusCC.centerName = objCentr.Id;
        objAureusCC.instrumentName = '';
        objAureusCC.resourceId = '';
        List<SelectOption> centersOption = objAureusCC.getCenters();
        List<SelectOption> teachersOption = objAureusCC.getTeachers();
        Object[] techrId=new Object[9];
        techrId.add(objTeachr.id);
        AureusCalendarController.getInstruments(techrId);
        // Covering the getCalendarData Method
        
        //getCalendarData called with respective teacher  
        
        //getCalendarData called with AllStaff with instrument
        
        
        //getCalendarData called with AllRosteredStaff without instrument
        
        
        //getCalendarData called with Resource without instrument
        
        
        //getCalendarData called with AllResource
        //AureusCalendarController.getCalendarData(objCentr.id, '', allResource, datesOfAppointment, '');
        
        //getCalendarData called with AllRosteredResource
        //AureusCalendarController.getCalendarData(objCentr.id, '', allRosteredResource, datesOfAppointment, '');
        
        //getWorkingHoursResource  is commented and will never will call
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,true);
        objENrol.Center__c = objCentr.Id;
        Booking__c objBook = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        Booking__c busyBook = TestUtil.createBooking(objTeachr.id,'Lesson','busy',false);
        busyBook.Status__c = 'Scheduled';
        busyBook.Start_Time__c=Time.newInstance(10,0,0,0);
        busyBook.End_Time__c=Time.newInstance(11,0,0,0);
        insert busyBook;
        Booking__c objMakeupBook = TestUtil.createBooking(objTeachr.id,'Lesson','Make-up',false);
        objMakeupBook.Make_up_Utilize_Bookings__c = 
            objBook.Enrolment__c=objEnrol.Id;
        objBook.Student__c=objCustmr.id;
        objBook.status__c = 'Pending';
        objBook.Available_Make_up_Units__c = 0;
        insert objBook;
        
        Booking__History objBookHis=new Booking__History();
        objBookHis.ParentId=objBook.id;
        objBookHis.Field='Status__c';
        insert objBookHis;
        objBook.Booking_Date__c=date.today().addDays(2);
        objBook.Start_Time__c=Time.newInstance(11,0,0,0);
        objBook.End_Time__c=Time.newInstance(12,0,0,0);
        objBook.status__c = 'Scheduled';
        update objBook;
        
        objMakeupBook.Available_Make_up_Units__c = 0;
        objMakeupBook.Status__c = 'Scheduled';
        objMakeupBook.Make_up_Utilize_Bookings__c = objBook.Id + '-30;';
        insert objMakeupBook;
        
        objBookHis = [SELECT ParentId, Field FROM Booking__History WHERE Id =: objBookHis.Id];
        Case objCase=new Case();
        objCase.Enrolment__c=ObjEnrol.id;
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        objCase.Status='New';
        objCase.Origin='Email';
        objCase.AccountId=objCustmr.Id;
        insert objCase;
        
        
        
        objEnrol.Type__c='Trial';
        update objEnrol;
        AureusCalendarController.completedOrNoShow(objBook.id,'Trial','Completed');
        
        Map<String, Object> bookingReschedule= new Map<String, Object> ();
        bookingReschedule.put('Id',objBook.id);
        bookingReschedule.put('resource',objTeachr.id);
        bookingReschedule.put('date',system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'));
        bookingReschedule.put('isRecurring', 'true');
        bookingReschedule.put('Repeat','Weeks');
        bookingReschedule.put('RepeatEvery', '1');
        bookingReschedule.put('EndsAfter', '1');
        TestUtil.createAttachment(objTeachr.id,true);
        
        
        AureusCalendarController.showRescheduledBookings(bookingReschedule);
        //Send EMail phat rha
        //AureusCalendarController.sendEmail('TestSubject','TestBody',objCustmr.Id);
        
        AureusCalendarController.getEventDetails(objBook.Id);
        AureusCalendarController.getParentId(objBook.Id);
        
        //Cancel Regular Booking 
        AureusCalendarController.cancelBooking(objBook.id, 'Exams','Teacher MC',' makeupRemark', 'true', objCase.id, 'true');
        AureusCalendarController.findObjectAPIName(objBook.Id);
        
        AureusCalendarController.cancelBooking(busyBook.id, 'Exams','Teacher MC',' makeupRemark', 'true', objCase.id, 'true');
        //Cancel Regular Booking 
        // AureusCalendarController.cancelBooking(objMakeupBook.id, 'Exams','Teacher MC',' makeupRemark', objCase.id);
        
        
        
        Event objEvent=new Event();
        objEvent.DurationInMinutes=60;
        objEvent.ActivityDate=date.today();
        objEvent.ActivityDateTime=system.now();
        insert objEvent;
        AureusCalendarController.saveBookingNote('testtitle','testNote', objBook.Id);
        
        objPack.Type__c='Makeup';
        update objPack;
        AureusCalendarController.getTeacherAndCenter(objCentr.Id,objTeachr.Id);
        AureusCalendarController.getStudents('Teacher');
        
        AureusCalendarController.getCountOfBookings(bookingReschedule);
        bookingReschedule.remove('EndsAfter');
        bookingReschedule.put('EndsOn', dt.format('MM/DD/YYYY'));
        AureusCalendarController.getCountOfBookings(bookingReschedule);
        
        AureusCalendarController.getWeekDaySet(new List<Integer>{1,7});
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.Status__c='Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
        
        Subscription_Line_Item__c objSubsLine=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLine.Enrolment__c=objEnrol.id;
        objSubsLine.Plan_Package__c=objPack.id;
        objSubsLine.Status__c='Active';
        objSubsLine.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubsLine;
        
        
        // separate transaction
        
        
        //AureusCalendarController.updatePackageRequestCallout(objBook.Id,string.valueOf(Date.today()),objPackTemp.Id,objPack.id);
       
        AureusCalendarController.getBusyBookingDetails(objBook.id);
        AureusCalendarController.getNoticePeriod(objbook.Id,system.now().formatGMT('dd/MM HH:mm:ss/yyyy'));
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        AureusCalendarController.downgradeSubscriptionRequest(objBook.Id, system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),objPackTemp.Id,objPack.id, '2:00 PM', '', 'true', '0.0', '0.0', '0.0', mapOfCaseValues);
        //AureusCalendarController.cancelSubscriptionRequest(objbook.Id, String.valueOf(date.today()), String.valueOf(String.valueOf(date.today())));
        Datetime dtObj = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
		String dayOfWeek=dtObj.format('EEEE');
         Package__c objMakeup = testUtil.createPackage(objProg.id,objCentr.id,'60',False); 
        objMakeup.Type__c = 'Makeup';
        objMakeup.Active__c=true;
        insert objMakeup;
        
        //AureusCalendarControllerHelper.AddFifthMakeupMinutesToParent(String.valueof(objCustmr.Id), String.valueof(objTeachr.Id), 45, time.newInstance(11,11, 11, 11), date.today(), dayOfWeek, 15, time.newInstance(11,11, 11, 11), 60, objCentr.id);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        AureusCalendarController.createAdhocBookings(objPack.id,objCentr.id,objTeachr.Id,objCustmr.Id, '2', system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'));
        //AureusCalendarController.createBooking(bookingJson, 'redirectCase', objCase.id);
        //AureusCalendarController.getNoticePeriodByEndDate(objBook.Id, system.now().formatGMT('dd/MM HH:mm:ss/yyyy'));
        //AureusCalendarController.updatePackageOfCustomer(objBook.id, string.valueOf(Date.today()),objPackTemp.Id,objPack.id, '2:00 PM', '', 'true');
        test.stopTest();
        
        
    }
    @isTest
    public static void calendarTest(){
       List<String> datesOfAppointment=new List<String>();
        string todayDate= string.valueOf(system.today());
        datesOfAppointment.add(todayDate); 
        
       Firebase_Settings__c objSetting = new Firebase_Settings__c();
        objSetting.Name = 'setting';
        objSetting.Enable_Notifications__c = false;
        insert objSetting;
        
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
        Account objCentr=TestUtil.createAccount('Centre',false,false);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.Centre_Name__c = objCentr.Id;
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
        //Account objCustmr1=TestUtil.createAccount('Customer',True,True);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',False); 
        //@added on 24 June 2019 by Karan #########################################
        objPack.Unit_Fee__c = 30;
        insert objPack;
        
        Resource__c objRes=TestUtil.createResource(objCentr.Id,'TstId',objPack.id,true);
        
        //#########################################################################
        Package__c objPackTemp=testUtil.createPackage(objProg.id,objCentr.id,'60',true);
        Booking__c objBook = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBook.Package__c = objPack.Id;
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,true);
        objENrol.Effective_Date__c = Date.today().addDays(5);
        objBook.Enrolment__c = objENrol.Id;
        insert objBook;
        
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.center__c = objCentr.Id;
        objSubs.Status__c='Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
        
        Subscription_Line_Item__c objSubsLine=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLine.Enrolment__c=objEnrol.id;
        objSubsLine.Plan_Package__c=objPack.id;
        objSubsLine.Status__c='Active';
        objSubsLine.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubsLine;
        
        
        Booking__c busyBook = TestUtil.createBooking(objTeachr.id,'Lesson','busy',false);
        busyBook.Status__c = 'Scheduled';
        busyBook.Start_Time__c=Time.newInstance(10,0,0,0);
        busyBook.End_Time__c=Time.newInstance(11,0,0,0);
        insert busyBook;
        
        
        Case objCase=new Case();
        objCase.Enrolment__c=ObjEnrol.id;
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        objCase.Status='New';
        objCase.Origin='Email';
        objCase.AccountId=objCustmr.Id;
        insert objCase;
        
        AureusCalendarController.getEventsRealTime(objTeachr.Id,objRes.Id,objCentr.Id, String.valueOf(Date.today()),'Piano');
        AureusCalendarController.getPackageDetail(objCustmr.Id,objPack.id,objTeachr.Id);
		
		AureusCalendarControllerHelper.cancelBookingProceed(objCustmr.Id);
        
        
        
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        Booking__c objBookTemp = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBookTemp.Enrolment__c=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,true).Id;
        objBookTemp.Student__c=objCustmr.id;
        objBookTemp.status__c = 'Pending';
        objBookTemp.Available_Make_up_Units__c = 0;
        insert objBookTemp;
        AureusCalendarController.sendEnrolmentLinkByCase('', objBookTemp.Id, 'Trial');
        
        
        
        System.debug('@@@@objBook.id'+objBook.id);
       // Booking__c objBookings = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        //insert objBookings;
        // Added By Ravi
        Booking__c bkgCloneCopy = objBook.clone(false, false, false, false);
        bkgCloneCopy.Id=null;
        bkgCloneCopy.Package__c = objPack.Id;
        insert bkgCloneCopy;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        string effeDate='22/4/2019';
		// Added By Ravi
       	AureusCalendarController.updatePackageOfCustomer(bkgCloneCopy.id, string.valueOf(Date.today()),objPackTemp.Id,objPack.id, '2:00 PM', '', 'true', mapOfCaseValues);
       	
        test.stopTest();
        //@added on 24 June 2019 by Karan  Just to invoke public method#########################################
        AureusCalendarController.getPrePaymentPackage(objENrol.Id);
        AureusCalendarController.getInvoiceFromEnrolment(objENrol.Id);
        AureusCalendarController.getLessonRefundAmount([SELECT id,package__r.unit_fee__c From Enrolment__c WHERE Id =:objENrol.Id], Date.today());
        //##########################################################################
    	
        //----------- Added by karan on 17 july 2019
        objPack.Type_of_package__c = 'Prepayment';
        update objPack;
        objBook.Booking_Date__c = Date.newInstance(Date.today().year(),Date.today().month(),29);
        objBook.Type__c = 'Make-up';
        objBook.Make_up_Utilize_Bookings__c =objBook.Id+'-15';
        Booking__c  objBookClone = objBook.clone(false,false,false,false);
        objBookClone.Status__c = 'Scheduled';
        insert objBookClone;
    	AureusCalendarController.getPrePaymentPackage(objENrol.Id);
        Booking__c objBookTest = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBookTest.Student__c = objCustmr.Id;
        objBookTest.Teacher_Account__c = objTeachr.Id;
        objBookTest.Enrolment__c = objENrol.id;
        //objBook1.Duration__c = 45;
        objBookTest.Start_Time__c = time.newInstance(11,11, 11, 11);
        objBookTest.Booking_Date__c = Date.newInstance(Date.today().year(),Date.today().month(),Date.today().addDays(10).day());
        objBookTest.Type__c = ConstantsClass.typeRegular;
        objBookTest.Status__c = 'Scheduled';
        insert objBookTest;
        AureusCalendarController.updateEnrolment(objENrol.id, objTeachr.id, objpack.Id, String.valueOf(date.today()), '10:00 AM', '', 'true', 'Mon @ 6:30PM', objENrol.Package__r.Name,objpack.Name);
        
        AureusCalendarControllerHelper.cancelAllFutureMakeupBookings(new list< Booking__c > {objBookClone});
        objBookClone.Booking_Date__c = Date.newInstance(Date.today().year(),Date.today().month(),29);
        objBookClone.Type__c = 'Regular';
        update objBookClone;
        
         AureusCalendarController.createBusyAppointments(objCentr.Id,objTeachr.Id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),30, 'description','Travel', 1, 'teacher', objBook.Id);
        AureusCalendarController.createBusyAppointments(objCentr.Id,objRes.Id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),30, 'description','Travel', 1, 'resource', objBook.Id);
        //AureusCalendarControllerHelper.processBookingsAfterDateChange(objENrol, date.today(), date.today(), String.valueof(objCustmr.Id), String.valueof(objTeachr.Id), 45, time.newInstance(11,11, 11, 11), 'Monday');
        Package__c objPackTemp1 = testUtil.createPackage(objProg.id,objCentr.id,'60',false);
        objPackTemp1.Type__c = 'Makeup';
        insert objPackTemp1;
        Booking__c objBook1 = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBook1.Student__c = objCustmr.Id;
        objBook1.Teacher_Account__c = objTeachr.Id;
        //objBook1.Duration__c = 45;
        objBook1.Start_Time__c = time.newInstance(11,11, 11, 11);
        objBook1.Booking_Date__c = Date.newInstance(Date.today().year(),Date.today().month(),29);
        objBook1.Type__c = ConstantsClass.typeMakeup;
        objBook1.Status__c = 'Scheduled';
        insert objBook1;
        objENrol.Parent__c = objCustmr.Id;
        update objENrol;
        system.debug('objBook1'+objBook1);
        
        
          Package__c objPackTemp2 = testUtil.createPackage(objProg.id,objCentr.id,'45',false);
        objPackTemp2.Type__c = 'Makeup';
        insert objPackTemp2;
        objCustmr.Available_Make_up_Units__c = 45;
        update objCustmr; 
        AureusCalendarControllerHelper.createFifthBookingOnUpgrade(objENrol, new  Map<String, Booking__c>{objBook1.id => objBook1}, 45, time.newInstance(11,11, 11, 11), 45);
        AureusCalendarControllerHelper.fetchDesiredPackage(objPackTemp2.Id);
        AureusCalendarControllerHelper.getListOfTeacher( objCentr.id, new set< String >{objTeachr.Id}, 'Piano');
        

        //-----------End 17 july 2019
    }
    public static testMethod void invokeAureusCalendarController2(){
        
        
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
        Account objTeachr = testUtil.createAccount('Teacher',false,true);
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        Account objCustmr=TestUtil.createAccount('Customer',True,FALSE);
        objCustmr.personEmail = 'test2@tmc.com';
        objCustmr.Centre_Name__c = objCentr.Id;
        INSERT objCustmr;
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0));
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        update objCustmr;
        
        AureusCalendarControllerHelper.getListOfTeacher(objCentr.Id,new Set<String> {objTeachr.Id});
        
         List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,True,False,7);
        list<Center_Working_Hours__c> listCwh=TestUtil.createCenter_Working_Hours(objCentr.id, True,7);
        //list<Resource_Working_Hour__c> listRwh=TestUtil.createResource_Working_Hour(objCentr.id,objRes.Id,true,7);
        
        Program__c objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPackTemp=testUtil.createPackage(objProg.id,objCentr.id,'60',true); 
        Enrolment__c objENrol = TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Lesson_Day__c = dt.format('EEEE');
        
        insert objENrol;
        
       
     Resource__c objRes=TestUtil.createResource(objCentr.Id,'TstId',objPack.id,true);
        
        AureusCalendarController.updateEnrolmentLink(objENrol.Id);
        //AureusCalendarController.releaseBlockBooking(objENrol.Id, 'Customer Not Interested', '');
        Booking__c objBook = TestUtil.createBooking(objTeachr.id,'Lesson','Regular', false);  
        objBook.Enrolment__c = objENrol.Id;
        insert objBook;
        Centre_Users__c centerUserObj = new Centre_Users__c();
        centerUserObj.Designation__c = 'Centre Manager';
        centerUserObj.Centre_Name__c = objCentr.Id;
        centerUserObj.User_Name__c = UserInfo.getUserId();
        insert centerUserObj;
        Case caseObj =  TestUtil.createCase(true);
        
        AureusCalendarController objAureusCalndr = new AureusCalendarController();
        AureusCalendarController.getCenterUsers();
        dt.addDays(5);
        AureusCalendarController.getCancellationDetails(objBook.Id, dt.format('yyyy-MM-dd'));
        AureusCalendarController.getUpgradeDowngradeSummary(objBook.Id, objPack.Id, objPackTemp.Id, dt.format('yyyy-MM-dd'));
        AureusCalendarController.getPickListValues('Booking__c', 'Status__c');
        
        String bookingRecurringJson = '{"studentId":"'+objCustmr.Id+'","packageId":"'+objPack.Id+'","type":"Trial","duration":"30","Repeat":"Weeks","isRecurring":"true","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objCentr.Id+'","teacherId":"'+objTeachr.Id+'"}';
        AureusCalendarController.createBooking(bookingRecurringJson, 'true', caseObj.Id);
        
        bookingRecurringJson = '{"studentId":"'+objCustmr.Id+'","packageId":"'+objPack.Id+'","type":"home-trial","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objCentr.Id+'","teacherId":"'+objTeachr.Id+'"}';
        AureusCalendarController.createBooking(bookingRecurringJson, 'true', caseObj.Id);
        
        bookingRecurringJson = '{"studentId":"'+objCustmr.Id+'","packageId":"'+objPack.Id+'","type":"Makeup","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objCentr.Id+'","teacherId":"'+objTeachr.Id+'"}';
        AureusCalendarController.createBooking(bookingRecurringJson, 'true', caseObj.Id);
        
        /*String bookingJson = '{"studentId":"'+objCustmr.Id+'","packageId":"'+objPack.Id+'","type":"Trial","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objCentr.Id+'","teacherId":"'+objTeachr.Id+'"}';
        AureusCalendarController.createBooking(bookingJson, 'true', caseObj.Id);*/
        AureusCalendarController.getCaseDetails(caseObj.id);
        AureusCalendarController objAureusCC= new AureusCalendarController();
        objAureusCC.centerName = objCentr.Id;
        List<SelectOption> centersOption = objAureusCC.getCenters();
        List<SelectOption> teachersOption = objAureusCC.getTeachers();
        
        AureusCalendarController.getPlans(objBook.Id,objCentr.Id , objTeachr.id);
        AureusCalendarController.getAllTeachersAccordingToCenter(objBook.Id,objCentr.Id );
        AureusCalendarController.getEnrolmentProcessData(objBook.Id);
        
        
        
        //getCalendarData called with AllStaff without instrument
        
        //AureusCalendarController.cancelSubscriptionRequest(objBook.Id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'), system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'), system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'));
    }
    public static testMethod void invokeAureusCalendarController3(){
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
    
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
    	objCentr.Country__c = country.Id;
    	INSERT objCentr;
    
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.Centre_Name__c = objCentr.Id;
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
       
        //Account objCustmr1=TestUtil.createAccount('Customer',True,True);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPack2=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPackTemp=testUtil.createPackage(objProg.id,objCentr.id,'60',true); 
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0));
        Resource__c objRes=TestUtil.createResource(objCentr.Id,'TstId',objPack.id,true);
        
        String allStaff = 'AllStaff';
        String allRosteredStaff = 'AllRosteredStaff';
        
        String allResource = 'AllResource';
        String allRosteredResource = 'AllRosteredResource';
        
        List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,True,False,7);
        list<Center_Working_Hours__c> listCwh=TestUtil.createCenter_Working_Hours(objCentr.id, True,7);
        list<Resource_Working_Hour__c> listRwh=TestUtil.createResource_Working_Hour(objCentr.id,objRes.Id,true,7);
        List<String> datesOfAppointment=new List<String>();
        string todayDate= string.valueOf(system.today());
        datesOfAppointment.add(todayDate);
        String bookingJson = '{"studentId":"'+objCustmr.Id+'","packageId":"'+objPack.Id+'","type":"Trial","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objCentr.Id+'","teacherId":"'+objTeachr.Id+'"}';
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Stage__c = 'Enrolled';
        
        insert objENrol;
        Enrolment__c objENrol2 = TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol2.Lesson_Day__c = dt.format('EEEE');
        objENrol2.Stage__c = 'Enrolled';
        insert objENrol2;
        Enrolment__c objENrol3 = TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol3.Lesson_Day__c = dt.format('EEEE');
        objENrol3.Stage__c = 'Enrolled';
        insert objENrol3;
        Booking__c objBook = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        Booking__c objMakeupBook = TestUtil.createBooking(objTeachr.id,'Lesson','Make-up',false);
        objMakeupBook.Make_up_Utilize_Bookings__c = 
        objBook.Enrolment__c=objEnrol.Id;
        objBook.Student__c=objCustmr.id;
        objBook.status__c = 'Pending';
        objBook.Available_Make_up_Units__c = 0;
        insert objBook;
        
        Booking__History objBookHis=new Booking__History();
        objBookHis.ParentId=objBook.id;
        objBookHis.Field='Status__c';
        insert objBookHis;
        objBook.Booking_Date__c=date.today().addDays(2);
        objBook.Start_Time__c=Time.newInstance(11,0,0,0);
        objBook.End_Time__c=Time.newInstance(12,0,0,0);
        objBook.status__c = 'Scheduled';
        update objBook;
        
        objMakeupBook.Available_Make_up_Units__c = 0;
        objMakeupBook.Status__c = 'Scheduled';
        objMakeupBook.Make_up_Utilize_Bookings__c = objBook.Id + '-30;';
        insert objMakeupBook;
        
        
        objBookHis = [SELECT ParentId, Field FROM Booking__History WHERE Id =: objBookHis.Id];
        Case objCase=new Case();
        objCase.Enrolment__c=ObjEnrol.id;
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        objCase.Status='New';
        objCase.Origin='Email';
        objCase.AccountId=objCustmr.Id;
        insert objCase;

        Subscription__C objSubsc =  TestUtil.createSubscription(objCustmr.Id, FALSE);
        objSubsc.Center__c = objCentr.Id;
        Insert objSubsc;
        
        Subscription_Line_Item__c objSubscLine = TestUtil.createSubscriptionLineItem(objSubsc.Id, False);
        objSubscLine.Enrolment__c=objENrol.id;
        objSubscLine.Next_Bill_Date__c= Date.newInstance(System.today().year(), System.today().month() + 1, 1);
        insert objSubscLine;
        
        ApexPages.currentPage().getParameters().put('id',objTeachr.id);
        AureusCalendarController objAureusCC= new AureusCalendarController();
        objAureusCC.centerName = objCentr.Id;
        AureusCalendarController.getNoticePeriodByEndDate(objBook.Id, system.now().formatGMT('dd/MM HH:mm:ss/yyyy'));
        AureusCalendarController.cancelSubscriptionRequest(objbook.Id, String.valueOf(date.today()), String.valueOf(String.valueOf(date.today())), '', 'true');
        
        Booking__c Book = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        Book.Enrolment__c=objEnrol.Id;
        Book.Booking_Date__c = date.today().addDays(7);
        Book.Student__c=objCustmr.id;
        Book.status__c = 'Pending';
        Book.Available_Make_up_Units__c = 0;
        Book.center__c = objCentr.Id;
        insert Book;

        Package__c objMakeup2 = testUtil.createPackage(objProg.id,objCentr.id,'30',False); 
        objMakeup2.Type__c = 'Makeup';
        objMakeup2.Active__c=true;
        insert objMakeup2;

        Booking__c objBook2=TestUtil.createBooking(objTeachr.Id,'Lesson','Make-up',False);
        objBook2.Enrolment__c=objEnrol.Id;
        objBook2.status__c = 'Scheduled';
        objBook2.Booking_Date__c=date.newInstance(2019, 10, 29);
        objBook2.Package__c = objMakeup2.Id;
        insert objBook2;

		Booking__c objBook3 = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBook3.Enrolment__c=objEnrol.Id;
        objBook3.Booking_Date__c = date.today();
        objBook3.Student__c=objCustmr.id;
        objBook3.status__c = 'Pending';
        objBook3.Available_Make_up_Units__c = 0;
        objBook3.center__c = objCentr.Id;
        insert objBook3;
        
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c=date.newInstance(2019, 10, 29), Center__c=objCentr.id, End_Time__c=time.newInstance(10, 0, 0, 0), Enrolment__c=objEnrol.id,
                                                 Package__c=objPackTemp.id, Start_Time__c= time.newInstance(10, 30, 0, 0), Student__c=objCustmr.id, Teacher_Account__c=objTeachr.id, Remarks__c='40',
                                                 IsActive__c=FALSE ,Parent__c=objCustmr.id, Booking__c = objBook2.Id);
        insert objFifthLesson;


        AureusCalendarController.updateEnrolment(objENrol.id, objTeachr.id, objPack2.Id, String.valueOf(date.today()), '10:00 AM', '', 'true', 'Mon @ 5:00PM', objENrol.Package__r.Name,objpack.Name);
        objPack.Type__c = 'Individual';
        objPack.RecordTypeId=Schema.SObjectType.Package__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
        update objPack;
        
        AureusCalendarController.getPackageAccordingToTeacher(objCentr.Id, objTeachr.id,30);
        
        
        //AureusCalendarController.sendEnrolmentLinkByCase('', objBookTemp.Id, 'Trial');
        //boolean ischecked=AureusCalendarController.updateEnrolmentLink(objENrol.id);
    }
    
    @isTest 
    public static void invokeAureusCalendarController4(){
         List<String> datesOfAppointment=new List<String>();
            string todayDate= string.valueOf(system.today());
            datesOfAppointment.add(todayDate); 
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
    
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
    	objCentr.Country__c = country.Id;
    	INSERT objCentr;
    
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Centre_Name__c = objCentr.Id;
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
       
        //Account objCustmr1=TestUtil.createAccount('Customer',True,True);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPack2=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPackTemp=testUtil.createPackage(objProg.id,objCentr.id,'60',true); 
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0));
        Resource__c objRes=TestUtil.createResource(objCentr.Id,'TstId',objPack.id,true);
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Stage__c = 'Enrolled';
        insert objENrol;
        String allStaff = 'AllStaff';
        String allRosteredStaff = 'AllRosteredStaff';
        
        String allResource = 'AllResource';
        String allRosteredResource = 'AllRosteredResource';
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c=date.newInstance(2019, 8, 9),Center__c=objCentr.id,End_Time__c=time.newInstance(11, 0, 0, 0),Enrolment__c=objENrol.id,
                                                 Package__c=objPack.id,Start_Time__c= time.newInstance(10, 0, 0, 0),Student__c=objCustmr.id,Teacher_Account__c=objTeachr.id,Remarks__c='40',
                                                 IsActive__c=true,Parent__c=objCustmr.id);
        insert objFifthLesson;

        List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,True,False,7);
        list<Center_Working_Hours__c> listCwh=TestUtil.createCenter_Working_Hours(objCentr.id, True,7);
        list<Resource_Working_Hour__c> listRwh=TestUtil.createResource_Working_Hour(objCentr.id,objRes.Id,true,7);
        
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.center__c = objCentr.Id;
        objSubs.Status__c='Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
        
        Subscription_Line_Item__c objSubsLine=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLine.Enrolment__c=objEnrol.id;
        objSubsLine.Plan_Package__c=objPack.id;
        objSubsLine.Status__c='Active';
        objSubsLine.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubsLine;
        
        AureusCalendarController.getCalendarData(objCentr.id, 'AllStaff', objRes.id, datesOfAppointment, '');
        AureusCalendarController.getCalendarData(objCentr.id, 'AllStaff', objRes.id, datesOfAppointment, 'Piano');
        AureusCalendarController.getCalendarData(objCentr.id, '', objRes.id, datesOfAppointment, '');
        AureusCalendarController.getCalendarData(objCentr.id, 'AllRosteredStaff', objRes.id, datesOfAppointment, '');

        List<Fifth_Lesson__c> lessons = AureusCalendarControllerHelper.fetchFifthLessson(new Set<String>{objFifthLesson.Id});
        AureusCalendarControllerHelper.createBookingFromFifthLesson(lessons, 'placeholder');
        AureusCalendarControllerHelper.createBookingFromFifthLesson(lessons, 'adhoc');
        AureusCalendarControllerHelper.createBookingFromFifthLesson(lessons, 'makeup');
        AureusCalendarControllerHelper.getFifthLessonEvents(objCentr.id, new Set<String>{objTeachr.id},new List<String> {String.valueOf(date.newInstance(2019, 8, 9))});
        
        AureusCalendarControllerHelper.getListOfResource (objCentr.Id,new Set<String> {objRes.Id});
        AureusCalendarControllerHelper.fetchMakeupPackages(objCentr.Id, '45');
        AureusCalendarControllerHelper.getMapOfWeekDate(new List<String>{String.valueOf(System.today()), String.valueOf(System.today().addDays(7))});
        //@Added on 24 June 2019 as objBook was deleted in above method
        Booking__c objBookTemp = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBookTemp.Enrolment__c=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,true).Id;
        objBookTemp.Student__c=objCustmr.id;
        objBookTemp.status__c = 'Pending';
        objBookTemp.Available_Make_up_Units__c = 0;
        insert objBookTemp;
        
        Booking__c objBookActual = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBookActual.Enrolment__c = ObjEnrol.id;
        objBookActual.Student__c=objCustmr.id;
        objBookActual.status__c = 'Pending';
        objBookActual.Available_Make_up_Units__c = 0;
        objBookActual.Package__c =  objPack.Id;
        insert objBookActual;

      

        //##############################################################    
        AureusCalendarController.getWithrawalSummary(objBookActual.Id, String.valueOf(System.today()), String.valueOf(System.today().addDays(3)));
        AureusCalendarController.sendEnrolToIpad('messsage');
        AureusCalendarController.getUpgradeDowngradePackageSummary(objPack.Id, objPackTemp.Id,String.valueOf(date.today()) , '13:00:00 PM', objEnrol.Id, 'upgrade');
        
    	
    }

    @isTest 
    public static void invokeAureusCalendarController5(){
        List<String> datesOfAppointment=new List<String>();
            string todayDate= string.valueOf(system.today());
            datesOfAppointment.add(todayDate); 
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
    
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
    	objCentr.Country__c = country.Id;
    	INSERT objCentr;
    
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Centre_Name__c = objCentr.Id;
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
       
        //Account objCustmr1=TestUtil.createAccount('Customer',True,True);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPack2=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPackTemp=testUtil.createPackage(objProg.id,objCentr.id,'60',true); 
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0));
        Resource__c objRes=TestUtil.createResource(objCentr.Id,'TstId',objPack.id,true);
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Stage__c = 'Enrolled';
        insert objENrol;
        String allStaff = 'AllStaff';
        String allRosteredStaff = 'AllRosteredStaff';
        
        String allResource = 'AllResource';
        String allRosteredResource = 'AllRosteredResource';
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c=date.newInstance(2019, 8, 9),Center__c=objCentr.id,End_Time__c=time.newInstance(11, 0, 0, 0),Enrolment__c=objENrol.id,
                                                 Package__c=objPack.id,Start_Time__c= time.newInstance(10, 0, 0, 0),Student__c=objCustmr.id,Teacher_Account__c=objTeachr.id,Remarks__c='40',
                                                 IsActive__c=true,Parent__c=objCustmr.id);
        insert objFifthLesson;
        
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.center__c = objCentr.Id;
        objSubs.Status__c='Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
        
        Subscription_Line_Item__c objSubsLine=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLine.Enrolment__c=objEnrol.id;
        objSubsLine.Plan_Package__c=objPack.id;
        objSubsLine.Status__c='Active';
        objSubsLine.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubsLine;

        //@Added on 24 June 2019 as objBook was deleted in above method
        Booking__c objBookTemp = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBookTemp.Enrolment__c=objEnrol.id;
        objBookTemp.Student__c=objCustmr.id;
        objBookTemp.status__c = 'Pending';
        objBookTemp.Available_Make_up_Units__c = 0;
        objBookTemp.Start_Time__c=Time.newInstance(10,0,0,0);
        objBookTemp.End_Time__c=Time.newInstance(11,0,0,0);
        insert objBookTemp;
        
        Booking__c objBookActual = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBookActual.Enrolment__c = ObjEnrol.id;
        objBookActual.Student__c=objCustmr.id;
        objBookActual.status__c = 'Pending';
        objBookActual.Available_Make_up_Units__c = 0;
        objBookActual.Package__c =  objPack.Id;
        objBookActual.Start_Time__c=Time.newInstance(10,0,0,0);
        objBookActual.End_Time__c=Time.newInstance(11,0,0,0);
        insert objBookActual;
        
		Booking__History objBookHis1=new Booking__History();
        objBookHis1.ParentId=objBookActual.id;
        objBookHis1.Field='Status__c';
        insert objBookHis1;
        objBookActual.Enrolment__c = ObjEnrol.Id;
        update objBookActual;
        objBookHis1 = [SELECT ParentId, Field FROM Booking__History WHERE Id =: objBookHis1.Id];
         AureusCalendarController.getEventDetails(objBookActual.Id);
        
        Enrolment__c objENrol2=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol2.Type__c = 'Trial';
        insert objENrol2;
        AureusCalendarController.releaseBlockBooking(objENrol2.Id, 'Customer Not Interested', '');
        AureusCalendarControllerHelper.processFutureFifthLessons(objENrol, 'upgrade');
        AureusCalendarController.getUpgradeDowngradePackageSummary(objPackTemp.Id, objPack.Id,String.valueOf(date.today()) , '13:00:00 PM', objEnrol.Id, 'downgrade');
        AureusCalendarController.getTimeSlotsAccordingly(objCentr.Id, objTeachr.id, objPackTemp.Id, objEnrol.Id,String.valueOf(date.today()) );

        AureusCalendarController.getAdvanceDetails(objBookTemp.id);
        AureusCalendarController.getUpgradedDetails(objBookTemp.id);
        AureusCalendarController.getDowngradedDetails(objBookTemp.Id);
        
       AureusCalendarController.getEnrolmentUpdateDetails(objENrol.id);
    }

     @isTest 
    public static void invokeAureusCalendarController6(){

        List<String> datesOfAppointment=new List<String>();
            string todayDate= string.valueOf(system.today());
            datesOfAppointment.add(todayDate); 
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
    
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
    	objCentr.Country__c = country.Id;
    	INSERT objCentr;
    
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Centre_Name__c = objCentr.Id;
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
       
        //Account objCustmr1=TestUtil.createAccount('Customer',True,True);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPack2=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPackTemp=testUtil.createPackage(objProg.id,objCentr.id,'60',true); 
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0));
        Resource__c objRes=TestUtil.createResource(objCentr.Id,'TstId',objPack.id,true);
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Stage__c = 'Enrolled';
        insert objENrol;
        String allStaff = 'AllStaff';
        String allRosteredStaff = 'AllRosteredStaff';
        
        String allResource = 'AllResource';
        String allRosteredResource = 'AllRosteredResource';
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c=date.newInstance(2019, 8, 9),Center__c=objCentr.id,End_Time__c=time.newInstance(11, 0, 0, 0),Enrolment__c=objENrol.id,
                                                 Package__c=objPack.id,Start_Time__c= time.newInstance(10, 0, 0, 0),Student__c=objCustmr.id,Teacher_Account__c=objTeachr.id,Remarks__c='40',
                                                 IsActive__c=true,Parent__c=objCustmr.id);
        insert objFifthLesson;
        
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.center__c = objCentr.Id;
        objSubs.Status__c='Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
        
        Subscription_Line_Item__c objSubsLine=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLine.Enrolment__c=objEnrol.id;
        objSubsLine.Plan_Package__c=objPack.id;
        objSubsLine.Status__c='Active';
        objSubsLine.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubsLine;

        //@Added on 24 June 2019 as objBook was deleted in above method
        Booking__c objBookTemp = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBookTemp.Enrolment__c=objEnrol.id;
        objBookTemp.Student__c=objCustmr.id;
        objBookTemp.status__c = 'Pending';
        objBookTemp.Available_Make_up_Units__c = 0;
        objBookTemp.Start_Time__c=Time.newInstance(10,0,0,0);
        objBookTemp.End_Time__c=Time.newInstance(11,0,0,0);
        insert objBookTemp;
        
        Booking__c objBookActual = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBookActual.Enrolment__c = ObjEnrol.id;
        objBookActual.Student__c=objCustmr.id;
        objBookActual.status__c = 'Pending';
        objBookActual.Available_Make_up_Units__c = 0;
        objBookActual.Package__c =  objPack.Id;
        objBookActual.Start_Time__c=Time.newInstance(10,0,0,0);
        objBookActual.End_Time__c=Time.newInstance(11,0,0,0);
        insert objBookActual;
        String secondDate = string.valueOf(system.today()+7);
        datesOfAppointment.add(secondDate);
         Case objCase=new Case();
        objCase.Enrolment__c=ObjEnrol.id;
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        objCase.Status='New';
        objCase.Origin='Email';
        objCase.AccountId=objCustmr.Id;
        insert objCase;
        
        String bookingJson = '{"studentId":"'+objCustmr.Id+'","packageId":"'+objPack.Id+'","type":"Trial","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objCentr.Id+'","teacherId":"'+objTeachr.Id+'"}';
        AureusCalendarController.createBooking(bookingJson, 'redirectCase', objCase.id);
        
        Booking__c busyBook = TestUtil.createBooking(objTeachr.id,'Lesson','busy',false);
        busyBook.Status__c = 'Scheduled';
        busyBook.Start_Time__c=Time.newInstance(10,0,0,0);
        busyBook.End_Time__c=Time.newInstance(11,0,0,0);
        insert busyBook;
       
        AureusCalendarController.updateBooking(objBookTemp.id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                               system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),objTeachr.id,'True','true', 'true' ,objCase.Id);
        
        AureusCalendarController.updateBooking(busyBook.id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                               system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),objTeachr.id,'True','true', 'true', objCase.Id);
        
        AureusCalendarController.updateBooking(busyBook.id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                               system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),objTeachr.id,'True','false', 'true', objCase.Id);
   		
    }

     @isTest 
    public static void invokeAureusCalendarController7(){
        List<String> datesOfAppointment=new List<String>();
            string todayDate= string.valueOf(system.today());
            datesOfAppointment.add(todayDate); 
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
    
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
    	objCentr.Country__c = country.Id;
    	INSERT objCentr;
    
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Centre_Name__c = objCentr.Id;
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;

        
        
       
        //Account objCustmr1=TestUtil.createAccount('Customer',True,True);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPack2=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPackTemp=testUtil.createPackage(objProg.id,objCentr.id,'60',true); 
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0));
        Resource__c objRes=TestUtil.createResource(objCentr.Id,'TstId',objPack.id,true);

        List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,True,False,7);
        list<Center_Working_Hours__c> listCwh=TestUtil.createCenter_Working_Hours(objCentr.id, True,7);
        list<Resource_Working_Hour__c> listRwh=TestUtil.createResource_Working_Hour(objCentr.id,objRes.Id,true,7);
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Stage__c = 'Enrolled';
        insert objENrol;
        String allStaff = 'AllStaff';
        String allRosteredStaff = 'AllRosteredStaff';
        
        String allResource = 'AllResource';
        String allRosteredResource = 'AllRosteredResource';
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c=date.newInstance(2019, 8, 9),Center__c=objCentr.id,End_Time__c=time.newInstance(11, 0, 0, 0),Enrolment__c=objENrol.id,
                                                 Package__c=objPack.id,Start_Time__c= time.newInstance(10, 0, 0, 0),Student__c=objCustmr.id,Teacher_Account__c=objTeachr.id,Remarks__c='40',
                                                 IsActive__c=true,Parent__c=objCustmr.id);
        insert objFifthLesson;
        
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.center__c = objCentr.Id;
        objSubs.Status__c='Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
        
        Subscription_Line_Item__c objSubsLine=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLine.Enrolment__c=objEnrol.id;
        objSubsLine.Plan_Package__c=objPack.id;
        objSubsLine.Status__c='Active';
        objSubsLine.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubsLine;

        //@Added on 24 June 2019 as objBook was deleted in above method
        Booking__c objBookTemp = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBookTemp.Enrolment__c=objEnrol.id;
        objBookTemp.Student__c=objCustmr.id;
        objBookTemp.status__c = 'Pending';
        objBookTemp.Available_Make_up_Units__c = 0;
        objBookTemp.Start_Time__c=Time.newInstance(10,0,0,0);
        objBookTemp.End_Time__c=Time.newInstance(11,0,0,0);
        insert objBookTemp;
        
        Booking__c objBookActual = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBookActual.Enrolment__c = ObjEnrol.id;
        objBookActual.Student__c=objCustmr.id;
        objBookActual.status__c = 'Pending';
        objBookActual.Available_Make_up_Units__c = 0;
        objBookActual.Package__c =  objPack.Id;
        objBookActual.Start_Time__c=Time.newInstance(10,0,0,0);
        objBookActual.End_Time__c=Time.newInstance(11,0,0,0);
        insert objBookActual;
        String secondDate = string.valueOf(system.today()+7);
        datesOfAppointment.add(secondDate);
         Case objCase=new Case();
        objCase.Enrolment__c=ObjEnrol.id;
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        objCase.Status='New';
        objCase.Origin='Email';
        objCase.AccountId=objCustmr.Id;
        insert objCase;
        AureusCalendarController.getCalendarData(objCentr.id,objTeachr.Id,objRes.id, datesOfAppointment,'Piano');
        AureusCalendarController.getCalendarData(objCentr.id, '', allRosteredResource, datesOfAppointment, '');
         AureusCalendarController.getCalendarData(objCentr.id, '', allResource, datesOfAppointment, '');
        AureusCalendarController.getCalendarData(objCentr.id,objTeachr.Id,objRes.id, datesOfAppointment,'Piano');
        AureusCalendarController.getScheduledBookingSlots(objEnrol.id, System.today(), objCentr.id,objTeachr.Id);
        AureusCalendarController.fetchSelectedFifthLessons(System.today(), objCentr.id,objTeachr.Id,objEnrol.id);
    }
    
   /* @isTest
    public static void testUpdatePackageRequestCallout(){
       Account objCentr=TestUtil.createAccount('Centre',false,true);
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
        //Account objCustmr1=TestUtil.createAccount('Customer',True,True);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',False); 
        //@added on 24 June 2019 by Karan #########################################
        objPack.Unit_Fee__c = 30;
        insert objPack;
        //#########################################################################
        Package__c objPackTemp=testUtil.createPackage(objProg.id,objCentr.id,'60',true);
        Booking__c objBook = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,true);
        objENrol.Effective_Date__c = Date.today().addDays(5);
        objBook.Enrolment__c = objENrol.Id;
        insert objBook;
        
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.Status__c='Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
        
        Subscription_Line_Item__c objSubsLine=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLine.Enrolment__c=objEnrol.id;
        objSubsLine.Plan_Package__c=objPack.id;
        objSubsLine.Status__c='Active';
        objSubsLine.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubsLine;
        
        
         Booking__c busyBook = TestUtil.createBooking(objTeachr.id,'Lesson','busy',false);
        busyBook.Status__c = 'Scheduled';
        busyBook.Start_Time__c=Time.newInstance(10,0,0,0);
        busyBook.End_Time__c=Time.newInstance(11,0,0,0);
        insert busyBook;
        
        Case objCase=new Case();
        objCase.Enrolment__c=ObjEnrol.id;
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        objCase.Status='New';
        objCase.Origin='Email';
        objCase.AccountId=objCustmr.Id;
        insert objCase;
        
        AureusCalendarController.updateBooking(objBook.id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                               system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),objTeachr.id,'True','true', 'true' ,objCase.Id);
        
        AureusCalendarController.updateBooking(busyBook.id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                               system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),objTeachr.id,'True','true', 'true', objCase.Id);
        
        AureusCalendarController.updateBooking(busyBook.id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                               system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),objTeachr.id,'True','false', 'true', objCase.Id);
        System.debug('@@@@objBook.id'+objBook.id);
        
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        
        System.debug('@@@@objBook.id'+objBook.id);
       // Booking__c objBookings = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        //insert objBookings;
        // Added By Ravi
        Booking__c bkgCloneCopy = objBook.clone(false, false, false, false);
        bkgCloneCopy.Id=null;
        insert bkgCloneCopy;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        string effeDate='22/4/2019';
		// Added By Ravi
       	AureusCalendarController.updatePackageOfCustomer(bkgCloneCopy.id, effeDate,objPackTemp.Id,objPack.id, '2:00 PM', '', 'true', mapOfCaseValues);
       	
    } */
}