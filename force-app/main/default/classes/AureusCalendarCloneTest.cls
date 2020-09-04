/*
Name        :        AureusCalendarCloneTest
Date        :        4 April 2019(modified 15 april 2019,28 May 2019,24 June 2019,17 july 2019)
Author      :        Karan Singh Soni
Description :        It is the test class of AureusCalendarController.
*/
@isTest
public class AureusCalendarCloneTest {
    
    public static testMethod void invokeAureusCalendarController(){
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
        List<String> datesOfAppointment=new List<String>();
        string todayDate= string.valueOf(system.today());
        datesOfAppointment.add(todayDate);
        String bookingJson = '{"studentId":"'+objCustmr.Id+'","packageId":"'+objPack.Id+'","type":"Trial","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objCentr.Id+'","teacherId":"'+objTeachr.Id+'"}';
        
        ApexPages.currentPage().getParameters().put('id',objTeachr.id);
        AureusCalendarClone objAureusCC= new AureusCalendarClone();
        
        objAureusCC.getCenters();
        objAureusCC.getTeachers();
        Object[] techrId=new Object[9];
        techrId.add(objTeachr.id);
        AureusCalendarClone.getInstruments(techrId);
        // Covering the getCalendarData Method
        
        //getCalendarData called with respective teacher  
        AureusCalendarClone.getCalendarData(objCentr.id,objTeachr.Id,objRes.id, datesOfAppointment,'Piano');
        String secondDate = string.valueOf(system.today()+7);
        datesOfAppointment.add(secondDate);
        //getCalendarData called with AllStaff with instrument
        AureusCalendarClone.getCalendarData(objCentr.id, allStaff, objRes.id, datesOfAppointment, 'Piano');
        
        //getCalendarData called with AllStaff without instrument
        AureusCalendarClone.getCalendarData(objCentr.id, allStaff, objRes.id, datesOfAppointment, '');
        
        //getCalendarData called with AllRosteredStaff without instrument
        AureusCalendarClone.getCalendarData(objCentr.id, allRosteredStaff, objRes.id, datesOfAppointment, '');
        
        //getCalendarData called with Resource without instrument
        AureusCalendarClone.getCalendarData(objCentr.id, '', objRes.id, datesOfAppointment, '');
        
        //getCalendarData called with AllResource
        AureusCalendarClone.getCalendarData(objCentr.id, '', allResource, datesOfAppointment, '');
        
        //getCalendarData called with AllRosteredResource
        AureusCalendarClone.getCalendarData(objCentr.id, '', allRosteredResource, datesOfAppointment, '');
        
        //getWorkingHoursResource  is commented and will never will call
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,true);
        
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
        AureusCalendarClone.completedOrNoShow(objBook.id,'Trial','Completed');
        
        Map<String, Object> bookingReschedule= new Map<String, Object> ();
        bookingReschedule.put('Id',objBook.id);
        bookingReschedule.put('resource',objTeachr.id);
        bookingReschedule.put('date',system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'));
        bookingReschedule.put('isRecurring', 'true');
        bookingReschedule.put('Repeat','Weeks');
        bookingReschedule.put('RepeatEvery', '1');
        bookingReschedule.put('EndsAfter', '1');
        TestUtil.createAttachment(objTeachr.id,true);
        
        
        AureusCalendarClone.showRescheduledBookings(bookingReschedule);
        //Send EMail phat rha
        //AureusCalendarController.sendEmail('TestSubject','TestBody',objCustmr.Id);
        
        AureusCalendarClone.getEventDetails(objBook.Id);
        AureusCalendarClone.getParentId(objBook.Id);
        
        //Cancel Regular Booking 
        AureusCalendarClone.cancelBooking(objBook.id, 'Exams','Teacher MC',' makeupRemark', 'true', objCase.id, 'true');
        
        
        AureusCalendarClone.cancelBooking(busyBook.id, 'Exams','Teacher MC',' makeupRemark', 'true', objCase.id, 'true');
        //Cancel Regular Booking 
        // AureusCalendarController.cancelBooking(objMakeupBook.id, 'Exams','Teacher MC',' makeupRemark', objCase.id);
        
        
        
        Event objEvent=new Event();
        objEvent.DurationInMinutes=60;
        objEvent.ActivityDate=date.today();
        objEvent.ActivityDateTime=system.now();
        insert objEvent;
        AureusCalendarClone.saveBookingNote('testtitle','testNote', objEvent.id);
        
        objPack.Type__c='Makeup';
        update objPack;
        AureusCalendarClone.getTeacherAndCenter(objCentr.Id,objTeachr.Id);
        AureusCalendarClone.getStudents('Teacher');
        
        AureusCalendarClone.getCountOfBookings(bookingReschedule);
        bookingReschedule.remove('EndsAfter');
        bookingReschedule.put('EndsOn', dt.format('MM/DD/YYYY'));
        AureusCalendarClone.getCountOfBookings(bookingReschedule);
        AureusCalendarClone.getEventsRealTime(objTeachr.Id,objRes.Id,objCentr.Id, String.valueOf(Date.today()),'Piano');
        AureusCalendarClone.getPackageDetail(objCustmr.Id,objPack.id,objTeachr.Id);
        
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
        AureusCalendarClone.getAdvanceDetails(objBook.id);
        AureusCalendarClone.getUpgradedDetails(objBook.id);
        AureusCalendarClone.getDowngradedDetails(objBook.Id);
        
        // separate transaction
        
        
        //AureusCalendarController.updatePackageRequestCallout(objBook.Id,string.valueOf(Date.today()),objPackTemp.Id,objPack.id);
        AureusCalendarClone.createBusyAppointments(objCentr.Id,objTeachr.Id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),30, 'description','Travel', 1, 'teacher');
        AureusCalendarClone.createBusyAppointments(objCentr.Id,objRes.Id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),30, 'description','Travel', 1, 'resource');
        AureusCalendarClone.getBusyBookingDetails(objBook.id);
        AureusCalendarClone.getNoticePeriod(objbook.Id,system.now().formatGMT('dd/MM HH:mm:ss/yyyy'));
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        AureusCalendarClone.downgradeSubscriptionRequest(objBook.Id, system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),objPackTemp.Id,objPack.id, '2:00 PM', '', 'true', '0.0', '0.0', '0.0', mapOfCaseValues);
        //AureusCalendarController.cancelSubscriptionRequest(objbook.Id, String.valueOf(date.today()), String.valueOf(String.valueOf(date.today())));
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        AureusCalendarClone.createAdhocBookings(objPack.id,objCentr.id,objTeachr.Id,objCustmr.Id, '2', system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'));
        AureusCalendarClone.createBooking(bookingJson, 'redirectCase', objCase.id);
        //AureusCalendarController.getNoticePeriodByEndDate(objBook.Id, system.now().formatGMT('dd/MM HH:mm:ss/yyyy'));
        //AureusCalendarController.updatePackageOfCustomer(objBook.id, string.valueOf(Date.today()),objPackTemp.Id,objPack.id, '2:00 PM', '', 'true');
        test.stopTest();
        
        
    }
    @isTest
    public static void calendarTest(){
       
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
        
        AureusCalendarClone.updateBooking(objBook.id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                               system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),objTeachr.id,'True','true', 'true' ,objCase.Id);
        
        AureusCalendarClone.updateBooking(busyBook.id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                               system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),objTeachr.id,'True','true', 'true', objCase.Id);
        
        AureusCalendarClone.updateBooking(busyBook.id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
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
       	AureusCalendarClone.updatePackageOfCustomer(bkgCloneCopy.id, string.valueOf(Date.today()),objPackTemp.Id,objPack.id, '2:00 PM', '', 'true', mapOfCaseValues);
       	
        test.stopTest();
        //@added on 24 June 2019 by Karan  Just to invoke public method#########################################
        AureusCalendarClone.getPrePaymentPackage(objENrol.Id);
        AureusCalendarClone.getInvoiceFromEnrolment(objENrol.Id);
        AureusCalendarClone.getLessonRefundAmount([SELECT id,package__r.unit_fee__c From Enrolment__c WHERE Id =:objENrol.Id], Date.today());
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
    	AureusCalendarClone.getPrePaymentPackage(objENrol.Id);
        AureusCalendarClone.updateEnrolment(objENrol.id, objTeachr.id, objpack.Id, String.valueOf(date.today()), '10:00 AM', '', 'true', 'Mon @ 6:30PM', objENrol.Package__r.Name,objpack.Name);
        
        AureusCalendarControllerHelper.cancelAllFutureMakeupBookings(new list< Booking__c > {objBookClone});
        objBookClone.Booking_Date__c = Date.newInstance(Date.today().year(),Date.today().month(),29);
        objBookClone.Type__c = 'Regular';
        update objBookClone;
        try{
            AureusCalendarControllerHelper.processBookingsAfterDateChange(objENrol, date.today(), date.today(), String.valueof(objCustmr.Id), String.valueof(objTeachr.Id), 45, time.newInstance(11,11, 11, 11), 'Monday');
           
        }catch(Exception e){}
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
        Datetime dt = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
		String dayOfWeek=dt.format('EEEE');
         AureusCalendarControllerHelper.AddFifthMakeupMinutesToParent(String.valueof(objCustmr.Id), String.valueof(objTeachr.Id), 45, time.newInstance(11,11, 11, 11), date.today(), dayOfWeek, 15, time.newInstance(11,11, 11, 11), 60, objCentr.id);
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
        
        Account objTeachr = testUtil.createAccount('Teacher',false,true);
        Account objCentr=TestUtil.createAccount('Centre',false,true);
        Account objCustmr=TestUtil.createAccount('Customer',True,FALSE);
        objCustmr.personEmail = 'test2@tmc.com';
        INSERT objCustmr;
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0));
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        update objCustmr;
        Program__c objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',true); 
        Package__c objPackTemp=testUtil.createPackage(objProg.id,objCentr.id,'60',true); 
        Enrolment__c objENrol = TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Lesson_Day__c = dt.format('EEEE');
        insert objENrol;
        Booking__c objBook = TestUtil.createBooking(objTeachr.id,'Lesson','Regular', false);  
        objBook.Enrolment__c = objENrol.Id;
        insert objBook;
        Centre_Users__c centerUserObj = new Centre_Users__c();
        centerUserObj.Designation__c = 'Centre Manager';
        centerUserObj.Centre_Name__c = objCentr.Id;
        centerUserObj.User_Name__c = UserInfo.getUserId();
        insert centerUserObj;
        Case caseObj =  TestUtil.createCase(true);
        
        AureusCalendarClone objAureusCalndr = new AureusCalendarClone();
        AureusCalendarClone.getCenterUsers();
        dt.addDays(5);
        AureusCalendarClone.getCancellationDetails(objBook.Id, dt.format('yyyy-MM-dd'));
        AureusCalendarClone.getUpgradeDowngradeSummary(objBook.Id, objPack.Id, objPackTemp.Id, dt.format('yyyy-MM-dd'));
        AureusCalendarClone.getPickListValues('Booking__c', 'Status__c');
        
        String bookingRecurringJson = '{"studentId":"'+objCustmr.Id+'","packageId":"'+objPack.Id+'","type":"Trial","duration":"30","Repeat":"Weeks","isRecurring":"true","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objCentr.Id+'","teacherId":"'+objTeachr.Id+'"}';
        AureusCalendarClone.createBooking(bookingRecurringJson, 'true', caseObj.Id);
        
        bookingRecurringJson = '{"studentId":"'+objCustmr.Id+'","packageId":"'+objPack.Id+'","type":"home-trial","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objCentr.Id+'","teacherId":"'+objTeachr.Id+'"}';
        AureusCalendarClone.createBooking(bookingRecurringJson, 'true', caseObj.Id);
        
        bookingRecurringJson = '{"studentId":"'+objCustmr.Id+'","packageId":"'+objPack.Id+'","type":"Makeup","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objCentr.Id+'","teacherId":"'+objTeachr.Id+'"}';
        AureusCalendarClone.createBooking(bookingRecurringJson, 'true', caseObj.Id);
        
        String bookingJson = '{"studentId":"'+objCustmr.Id+'","packageId":"'+objPack.Id+'","type":"Trial","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objCentr.Id+'","teacherId":"'+objTeachr.Id+'"}';
        AureusCalendarClone.createBooking(bookingJson, 'true', caseObj.Id);
        AureusCalendarClone.getCaseDetails(caseObj.id);
        //AureusCalendarController.cancelSubscriptionRequest(objBook.Id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'), system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'), system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'));
    }
    
    public static testMethod void invokeAureusCalendarController3(){
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
        Subscription__C objSubsc =  TestUtil.createSubscription(objCustmr.Id, true);
        
        Subscription_Line_Item__c objSubscLine = TestUtil.createSubscriptionLineItem(objSubsc.Id, False);
        objSubscLine.Enrolment__c=objENrol.id;
        objSubscLine.Next_Bill_Date__c= Date.newInstance(System.today().year(), System.today().month() + 1, 1);
        insert objSubscLine;
        
        ApexPages.currentPage().getParameters().put('id',objTeachr.id);
        AureusCalendarClone objAureusCC= new AureusCalendarClone();
        AureusCalendarClone.getNoticePeriodByEndDate(objBook.Id, system.now().formatGMT('dd/MM HH:mm:ss/yyyy'));
        AureusCalendarClone.cancelSubscriptionRequest(objbook.Id, String.valueOf(date.today()), String.valueOf(String.valueOf(date.today())), '', 'true');
        
        AureusCalendarClone.updateEnrolment(objENrol.id, objTeachr.id, objpack.Id, String.valueOf(date.today()), '10:00 AM', '', 'true', 'Mon @ 5:00PM', objENrol.Package__r.Name,objpack.Name);
        objPack.Type__c = 'Individual';
        objPack.RecordTypeId=Schema.SObjectType.Package__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
        update objPack;
        
        AureusCalendarClone.getPackageAccordingToTeacher(objCentr.Id, objTeachr.id,30);
        AureusCalendarClone.getEnrolmentUpdateDetails(objENrol.id);
        AureusCalendarClone.getUpgradeDowngradePackageSummary(objPack.Id, objPackTemp.Id,String.valueOf(date.today()) , '13:00:00 PM', objEnrol.Id, 'upgrade');
        AureusCalendarClone.getTimeSlotsAccordingly(objCentr.Id, objTeachr.id, objPackTemp.Id, objEnrol.Id,String.valueOf(date.today()) );
        
        //@Added on 24 June 2019 as objBook was deleted in above method
        Booking__c objBookTemp = TestUtil.createBooking(objTeachr.id,'Lesson','Regular',false);
        objBookTemp.Enrolment__c=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,true).Id;
        objBookTemp.Student__c=objCustmr.id;
        objBookTemp.status__c = 'Pending';
        objBookTemp.Available_Make_up_Units__c = 0;
        insert objBookTemp;
        //##############################################################    
        AureusCalendarClone.getWithrawalSummary(objBookTemp.Id, String.valueOf(date.today()), String.valueOf(date.today().addDays(3)));
        AureusCalendarClone.sendEnrolToIpad('messsage');
        AureusCalendarClone.getPlans(objBook.Id,objCentr.Id , objTeachr.id);
        AureusCalendarClone.getAllTeachersAccordingToCenter(objBook.Id,objCentr.Id );
        AureusCalendarClone.getEnrolmentProcessData(objBook.Id);
        objAureusCC.getCenters();
        objAureusCC.getTeachers();
        AureusCalendarClone.sendEnrolmentLinkByCase('', objBookTemp.Id, 'Trial');
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