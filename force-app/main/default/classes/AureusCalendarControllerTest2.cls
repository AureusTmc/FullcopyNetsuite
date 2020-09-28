/*
Name        :        AureusCalendarControllerTest
Date        :        04 -Nov- 2019 
Author      :        Jatin
Description :        It is the test class of AureusCalendarController.
*/ 
@isTest
public class AureusCalendarControllerTest2 { 
    @testSetup 
    Private static void createData(){ 
        AureusCalendarControllerTestHelper.createCalenderData();
    }   
    
    Private Static TestMethod void test_getCalendarData(){
        List<case> listOfcase = [select id  from case];
        List<Account> listOfCentre = [select id  from Account Where recordType.name='Centre'];
        List<Account> listOfTeacher = [select id  from Account Where recordType.name='Teacher'];
        List<Resource__c> listOfResource = [select id,center__c  from Resource__c];
        Test.startTest();
        ApexPages.currentPage().getParameters().put('caseId',listOfcase[0].id);
        AureusCalendarController objAureusCC= new AureusCalendarController();
        objAureusCC.getCenters();
        objAureusCC.getTeachers();  
        // test Default Center and Teacher
        system.assert(objAureusCC.teacherName == 'AllRosteredStaff'); 
        system.assert(objAureusCC.centerName ==listOfCentre[0].Id);
        
        // for test if centerUser reocrd is exist then change centerName 
        Centre_Users__c objOfCenterUser = AureusCalendarControllerTestHelper.createCentreUsers(listOfCentre[0].id,true);
        objAureusCC= new AureusCalendarController();
        objAureusCC.getCenters();
        system.assert(objAureusCC.centerName ==objOfCenterUser.Centre_Name__c);
        
        // get Instrument     
        Object[] techrId=new Object[9];
        techrId.add(listOfTeacher[0].id);
        AureusCalendarController.getInstruments(techrId);
        
        List <Teacher_Working_Hour__c> listOfTeacherWorkingHours = new List <Teacher_Working_Hour__c>();
        listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(listOfTeacher[0].id,listOfCentre[0].Id,True,true,2));
        // get Calender  data according to all teachers
        List<String> datesOfAppointment=new List<String>();
        datesOfAppointment.add(string.valueOf(date.today()));
        AureusCalendarController.getCalendarData(listOfCentre[0].id, 'AllStaff', '', datesOfAppointment, '');
        AureusCalendarController.getCalendarData(listOfCentre[0].id, 'AllRosteredStaff','', datesOfAppointment, '');
        // with instrument
        AureusCalendarController.getCalendarData(listOfCentre[0].id, 'AllRosteredStaff','', datesOfAppointment, 'Piano');
        AureusCalendarController.getCalendarData(listOfCentre[0].id, 'AllStaff','', datesOfAppointment, 'Piano');
        
        // selected teacher id
        AureusCalendarController.getCalendarData(listOfCentre[0].id, listOfTeacher[0].Id, '', datesOfAppointment, '');
        
        // get Calender  data according to all resources
        AureusCalendarController.getCalendarData(listOfResource[0].center__c, '', listOfResource[0].id, datesOfAppointment, '');
        AureusCalendarController.getCalendarData(listOfResource[0].center__c, '', 'AllRosteredResource', datesOfAppointment, '');
        AureusCalendarController.getCalendarData(listOfResource[0].center__c, '', 'AllResource', datesOfAppointment, '');  
        AureusCalendarController.getCalendarData(listOfResource[0].center__c, '', 'AllLesson', datesOfAppointment, '');
        AureusCalendarController.getCalendarData(listOfResource[0].center__c, '', 'AllNonLesson', datesOfAppointment, '');
        Test.stopTest();
        //added new DatesOfAppoinment
    }
    Private Static TestMethod void test_getCalendarData2(){
        List<case> listOfcase = [select id  from case];
        List<Account> listOfCentre = [select id  from Account Where recordType.name='Centre'];
        List<Account> listOfTeacher = [select id  from Account Where recordType.name='Teacher'];
        List<Resource__c> listOfResource = [select id,center__c  from Resource__c];
        List<String> datesOfAppointment=new List<String>();
        Test.startTest();
        datesOfAppointment.add(string.valueOf(date.today().addDays(3)));
        AureusCalendarController.getCalendarData(listOfResource[0].center__c, '', 'AllResource', datesOfAppointment, ''); 
        AureusCalendarController.getNewEffectiveDateSlots(listOfCentre[0].id, listOfTeacher[0].Id);
        Test.stopTest();
    }
    
    Private Static TestMethod void test_getBooking(){
        List<case> listOfcase = [select id,Type from case];
        List<Booking__c> listOfBooking = [select id,Teacher_Account__c  from Booking__c where type__c !='busy' ]; 
        List<Booking__c> listOfBusyBooking = [select id,Teacher_Account__c  from Booking__c where type__c ='busy' ];
        List<Account> listOfTeacher = [select id  from Account Where recordType.name='Teacher' and id !=: listOfBusyBooking[0].Teacher_Account__c];
        List<Resource__c> listOfResource = [select id,center__c  from Resource__c];
        Test.startTest();
        AureusCalendarController objAureusCC= new AureusCalendarController();
        
        AureusCalendarController.updateBooking(listOfBooking[0].id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                               system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),listOfBooking[0].Teacher_Account__c,'True','true', 'true' ,
                                               listOfcase[1].Id,'false');
        
        AureusCalendarController.updateBooking(listOfBusyBooking[0].id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                               system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),listOfTeacher[0].Id,'True','true', 'true', listOfcase[2].Id,'true');
        
        AureusCalendarController.updateBooking(listOfBooking[1].id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                               system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),listOfBooking[0].Teacher_Account__c,'True','false', 'true', 
                                               listOfcase[3].Id,'false');
        AureusCalendarController.updateBooking(listOfBooking[1].id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                               system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),listOfBooking[0].Teacher_Account__c,'True','false', 'true', 
                                               listOfcase[3].Id,'true');
    }
    Private Static TestMethod void test_updateResourceBooking(){
        List<case> listOfcase = [select id,Type from case];
        List<Booking__c> listOfBooking = [select id,Teacher_Account__c  from Booking__c where type__c !='busy' ]; 
        List<Booking__c> listOfBusyBooking = [select id,Teacher_Account__c  from Booking__c where type__c ='busy' ];
        List<Account> listOfTeacher = [select id  from Account Where recordType.name='Teacher' and id !=: listOfBusyBooking[0].Teacher_Account__c];
        List<Resource__c> listOfResource = [select id,center__c  from Resource__c];
        Test.startTest();
        AureusCalendarController.updateResourceBooking(listOfBooking[1].id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                                       system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                                       listOfResource[1].id,'True','false', 'true', listOfcase[3].Id);
        AureusCalendarController.updateResourceBooking(listOfBooking[1].id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                                       system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                                       listOfResource[1].id,'false','true', 'false', listOfcase[3].Id);
        
        
        listOfcase = [select id,Type from case where id =: listOfcase[3].id];
        Test.stopTest();
        // system.assert(listOfcase[0].Type == ConstantsClass.rescheduleType,listOfcase[0].Type);
        // system.assert([select id from Booking__c where status__c =: ConstantsClass.scheduledStatus and Category__c =: ConstantsClass.bookingCategoryPlaceHolder].size() >0);
    }
    
    public static TestMethod void  test_getEventOrParent(){
        List<Booking__c> listOfBooking = [select id,Student__c,Enrolment__c  from Booking__c where type__c !='busy' limit 1]; 
        Enrolment__c objEnrol = [select id from Enrolment__c where id !=:listOfBooking[0].Enrolment__c limit 1];
        listOfBooking[0].Enrolment__c = objEnrol.Id;
        update listOfBooking[0];
        Booking__History objBookHis=new Booking__History();
        objBookHis.ParentId=listOfBooking[0].id;
        objBookHis.Field='Enrolment__c';
        insert objBookHis;
        List<Booking__History> listBookHis = [SELECT ParentId,  Field, OldValue, NewValue FROM Booking__History where ParentId =:listOfBooking[0].id];
        system.debug('###objBookHis'+listBookHis);
        system.debug('###objBookHis'+listBookHis.size());
        
        Test.startTest();
        AureusCalendarController.getEventDetails(listOfBooking[0].Id);
        AureusCalendarController.getParentId(listOfBooking[0].Id);
        
        // test if parent Id is Exist
        List<Account> listOfCustomer = [select id  from Account where recordType.name='Customer' and Also_a_Student__c= false];
        List<Account> listOfstudent = [select id  from Account where Id =:listOfBooking[0].Student__c];
        listOfstudent[0].Parent__c =  listOfCustomer[0].id;
        listOfstudent[0].Also_a_Student__c =  false;
        update listOfstudent;
        AureusCalendarController.getEventDetails(listOfBooking[0].Id);
        AureusCalendarController.getParentId(listOfBooking[0].Id);
        
        Test.stopTest();
    }   
    
    public static TestMethod void  test_cancelBooking(){
        List<Booking__c> listOfBooking = [select id,Student__c,Duration__c  from Booking__c where type__c !='busy' limit 1]; 
        List<case> listOfcase = [select id,Type from case];
        Test.startTest();
        //Cancel Regular Booking 
        AureusCalendarController.cancelBooking(listOfBooking[0].id, 'Exams','Teacher MC',' makeupRemark', 'true', listOfcase[0].id, 'true');
        AureusCalendarController.findObjectAPIName(listOfBooking[0].Id);
        
        // If booking is Busy type
        listOfBooking = [select id,Student__c,Duration__c  from Booking__c where type__c ='busy' limit 1]; 
        AureusCalendarController.cancelBooking(listOfBooking[0].id, 'Exams','Teacher MC',' makeupRemark', 'true', listOfcase[1].id, 'true');
        
        // If booking is Make-up type
        List<Booking__c> listOfmakeupBooking = [select id,Student__c,Duration__c  from Booking__c where type__c ='Make-up' limit 1]; 
        listOfmakeupBooking[0].Available_Make_up_Units__c = 0;
        listOfmakeupBooking[0].Make_up_Utilize_Bookings__c = listOfBooking[0].Id + '-30;';
        listOfmakeupBooking[0].Make_up_Expiry_Date__c= date.today();
        update listOfmakeupBooking[0];
        
        AureusCalendarController.cancelBooking(listOfmakeupBooking[0].id, 'Exams','Teacher MC',' makeupRemark', 'true', listOfcase[2].id, 'true');
        
        Test.stopTest();
        listOfcase = [select id,Type from case where id =: listOfcase[2].id];
        system.assert(listOfcase[0].Type == ConstantsClass.cancelType,listOfcase[0].Type);
        system.assert([select id from Booking__c where Category__c =: ConstantsClass.bookingCategoryPlaceHolder].size() >0);
    }
    
    public static TestMethod void  test_CreateAdhocBookings(){
        List<Resource__c> ListOfResource = [select id from Resource__c ]; 
        ListOfResource[0].Available_For_Aureus_Lesson__c = true;
        update ListOfResource[0];
        List<Booking__c> listOfBooking = [select id,Student__c,Package__c, center__c,enrolment__C,Teacher_Account__c,Parent__c from Booking__c where type__c ='Regular' limit 1];  
        // test if parent Id is Exist
        /* List<Account> listOfCustomer = [select id  from Account where recordType.name='Customer' and Also_a_Student__c= false];
List<Account> listOfstudent = [select id  from Account where Id =:listOfBooking[0].Student__c];
listOfCustomer[0].Stripe_Customer_Id__c = 'ch_1AxWbTFytruJp2FXW6iuRd1X;'; 
update listOfCustomer[0];

listOfstudent[0].Parent__c =  listOfCustomer[0].id;
listOfstudent[0].Also_a_Student__c =  false;
update listOfstudent;

test.startTest();
Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
AureusCalendarController.createAdhocBookings(listOfBooking[0].Package__c,listOfBooking[0].center__c,listOfBooking[0].Teacher_Account__c,listOfBooking[0].Parent__c, '2',
system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),'','');
AureusCalendarController.createAdhocBookings(listOfBooking[0].Package__c,listOfBooking[0].center__c,listOfBooking[0].Teacher_Account__c,listOfBooking[0].Parent__c, '2',
system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),'In Centre',ListOfResource[0].id);

test.stopTest();*/
        List<Package__c> listOfPackage =[SELECT Name, Id, Unit_Fee__c, Duration__c
                                         FROM Package__c
                                         Where id =: listOfBooking[0].Package__c];
        AureusCalendarControllerHelper.createAppointmentForAdhoc(listOfPackage[0], listOfBooking[0].Teacher_Account__c,listOfBooking[0].Student__c,listOfBooking[0].center__c,2, 
                                                                 string.valueOf(system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss')),listOfBooking[0].Parent__c,'In Centre',ListOfResource[0].id,listOfBooking[0].enrolment__C);
        AureusCalendarControllerHelper.createAppointmentForAdhoc(listOfPackage[0], listOfBooking[0].Teacher_Account__c,listOfBooking[0].Student__c,listOfBooking[0].center__c,2, 
                                                                 string.valueOf(system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss')),listOfBooking[0].Parent__c,'Online','',listOfBooking[0].enrolment__C);
    }
    
    public Static TestMethod void test_completedOrNoShow() {
        List<Booking__c> listOfBooking = [select id,Enrolment__c from Booking__c where type__c ='Regular' limit 1];  
        test.startTest();
        AureusCalendarController.completedOrNoShow(listOfBooking[0].id,'Audition','Completed',false);
        Enrolment__c objEnrol = [select id from Enrolment__c where id=:listOfBooking[0].Enrolment__c];
        objEnrol.Type__c='Trial';
        update objEnrol;
        AureusCalendarController.completedOrNoShow(listOfBooking[0].id,'Trial','Completed',false);
        AureusCalendarController.completedOrNoShow(listOfBooking[0].id,'Trial','No-show',false);
        AureusCalendarController.updateOnlineLesson('Online',listOfBooking[0].id,'false','');
        AureusCalendarController.updateOnlineLesson('Online',objEnrol.id,'true',system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'));
        test.stopTest();
    }
    public Static TestMethod void test_ShowRescheduledBookings() {
        List<Booking__c> listOfBooking = [select id,Teacher_Account__c,Center__c,Student__c from Booking__c where type__c ='Regular' limit 1]; 
        List<Account> listOfTeacher = [select id  from Account Where recordType.name='Teacher' and id !=: listOfBooking[0].Teacher_Account__c];
        Map<String, Object> bookingReschedule= new Map<String, Object> ();
        bookingReschedule.put('Id',listOfBooking[0].id);
        bookingReschedule.put('date',system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'));
        bookingReschedule.put('isRecurring', 'true');
        bookingReschedule.put('Repeat','Weeks');
        bookingReschedule.put('RepeatEvery', '1');
        bookingReschedule.put('EndsAfter', '1');
        test.startTest();
        // schadule Booking for other teacher
        bookingReschedule.put('resource',listOfTeacher[0].id);
        TestUtil.createAttachment(listOfTeacher[0].id,true);
        AureusCalendarController.showRescheduledBookings(bookingReschedule);
        
        // schadule Booking for same booking teacher
        bookingReschedule.put('resource',listOfBooking[0].Teacher_Account__c);
        TestUtil.createAttachment(listOfBooking[0].Teacher_Account__c,true);
        AureusCalendarController.showRescheduledBookings(bookingReschedule);
        
        List<Account> listOfCustomer = [select id  from Account where recordType.name='Customer' and Also_a_Student__c= false];
        List<Account> listOfstudent = [select id  from Account where Id =:listOfBooking[0].Student__c];
        
        listOfstudent[0].Parent__c =  listOfCustomer[0].id;
        listOfstudent[0].Also_a_Student__c =  false;
        update listOfstudent;
        
        AureusCalendarController.showRescheduledBookings(bookingReschedule);
        AureusCalendarController.getCountOfBookings(bookingReschedule);
        bookingReschedule.remove('EndsAfter');
        bookingReschedule.put('EndsOn', '2019/02/03');
        AureusCalendarController.getCountOfBookings(bookingReschedule);
        test.stopTest();
    }
    
    public Static TestMethod void test_getWeekDay_Or_PickListSet_Or_saveBookingNote() {
        AureusCalendarController.getWeekDaySet(new List<Integer>{1,7});
        AureusCalendarController.getPickListValues('Booking__c', 'Status__c');
        List<Booking__c> listOfBooking = [select id,Teacher_Account__c,Center__c,Student__c from Booking__c where type__c ='Regular' limit 1]; 
        AureusCalendarController.saveBookingNote('testtitle','testNote', listOfBooking[0].Id);
    }
    
    public static TestMethod void test_getTeacherAndCenter_Or_getStudents(){
        List<Account> listOfCentre = [select id  from Account Where recordType.name='Centre'];
        List<Account> listOfTeacher = [select id  from Account Where recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id  from Package__c Where Location__c =: listOfCentre[0].id];
        listOfPackage[0].Type__c='Makeup';
        update listOfPackage[0];
        test.startTest();
        AureusCalendarController.getTeacherAndCenter(listOfCentre[0].Id,listOfTeacher[0].Id);
        AureusCalendarController.getStudents('Teacher');
        test.stopTest();
    }
    public static TestMethod void test_createBooking(){
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c  limit 1];
        case objCase = [select id  from case limit 1];
        test.startTest();
        String bookingRecurringJson = '{"studentId":"'+objEnrol.Student__c+'","packageId":"'+objEnrol.Package__c+'","type":"Trial","duration":"30","Repeat":"Weeks","isRecurring":"true","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objEnrol.Center__c+'","teacherId":"'+objEnrol.Teacher__c+'"}';
        AureusCalendarController.createBooking(bookingRecurringJson, 'true', objCase.Id,'Online');
        
        bookingRecurringJson = '{"studentId":"'+objEnrol.Student__c+'","packageId":"'+objEnrol.Package__c+'","type":"home-trial","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objEnrol.Center__c+'","teacherId":"'+objEnrol.Teacher__c+'"}';
        AureusCalendarController.createBooking(bookingRecurringJson, 'true', objCase.Id,'In Center');
        
        bookingRecurringJson = '{"studentId":"'+objEnrol.Student__c+'","packageId":"'+objEnrol.Package__c+'","type":"Makeup","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objEnrol.Center__c+'","teacherId":"'+objEnrol.Teacher__c+'"}';
        AureusCalendarController.createBooking(bookingRecurringJson, 'true', objCase.Id,'Online');
        
        bookingRecurringJson = '{"studentId":"'+objEnrol.Student__c+'","packageId":"'+objEnrol.Package__c+'","type":"Trial","duration":"30","Repeat":"Weeks","isRecurring":"true","availableHours":"50" ,"RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objEnrol.Center__c+'","teacherId":"'+objEnrol.Teacher__c+'"}';
        AureusCalendarController.createBooking(bookingRecurringJson, 'true', objCase.Id,'In Center');
        
        /*bookingRecurringJson = '{"studentId":"'+objEnrol.Student__c+'","packageId":"'+objEnrol.Package__c+'","type":"Makeup","duration":"30","Repeat":"Weeks","isRecurring":"true","RepeatEvery":"1", "EndsOn":"2019/04/03","date":"2019-04-22T15:00:00","centerId":"'+objEnrol.Center__c+'","teacherId":"'+objEnrol.Teacher__c+'"}';
AureusCalendarController.createBooking(bookingRecurringJson, 'true', objCase.Id);*/
        test.stopTest();
    }
    public static TestMethod void test_getEventsRealTime(){
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c  limit 1];
        List<Resource__c> ListOfResource = [select id from Resource__c ]; 
        test.startTest();
        AureusCalendarController.getEventsRealTime(objEnrol.Teacher__c,ListOfResource[0].Id,objEnrol.Center__c, String.valueOf(Date.today()),'Piano'); 
        test.stopTest(); 
    }
    public static TestMethod void test_getPackageDetail(){
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c  limit 1]; 
        AureusCalendarController.getPackageDetail(objEnrol.Student__c,objEnrol.Package__c,objEnrol.Teacher__c);
    }
    public static TestMethod void test_getAdvance_Upgraded_Downgrad_Details(){
        List<Booking__c> listOfBooking = [select id,enrolment__r.Package__r.Duration__c,enrolment__r.Package__r.Type__c,Enrolment__c,enrolment__r.Package__r.Location__c,
                                          enrolment__r.Package__r.Program__r.Instrument__c from Booking__c where type__c ='Regular' limit 1]; 
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c,Package__r.Duration__c,Package__r.Type__c,Package__r.Location__c,Package__r.Program__r.Instrument__c from Enrolment__c where id=:listOfBooking[0].Enrolment__c limit 1];
        objEnrol.Lesson_Start_time__c=Time.newInstance(11,0,0,0);
        update objEnrol;
        test.startTest(); 
        AureusCalendarController.getAdvanceDetails(listOfBooking[0].id);
        AureusCalendarController.getUpgradedDetails(listOfBooking[0].id,'');
        AureusCalendarController.getDowngradedDetails(listOfBooking[0].Id);
        test.stopTest();
    } 
    public static TestMethod void test_updatePackageOfCustomer(){
        List<Booking__c> listOfBooking = [select id,Package__c,Start_Time__c,Booking_Date__c,End_Time__c from Booking__c where type__c ='Regular' limit 1]; 
        List<Package__c> listOfPackage = [select id from Package__c where id != :listOfBooking[0].Package__c limit 1];
        /*Package__c objpack = new Package__c(id=listOfBooking[0].Package__c,Deposit_Fee__c =10);
update objpack;
*/case objCase = [select id  from case limit 1];
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        AureusCalendarController.updatePackageOfCustomer(string.valueOf(listOfBooking[0].id), '2019-11-9', string.valueOf(listOfPackage[0].id), 
                                                         string.valueOf(listOfBooking[0].Package__c),'7:00:00 PM',string.valueOf(objCase.id),'true', mapOfCaseValues);
        test.stopTest();
    }
    
    public static TestMethod void test_createBusyAppointments(){
        List<Booking__c> listOfBooking = [select id,Teacher_Account__c,center__c from Booking__c where type__c ='Regular']; 
        List<Resource__c> listOfResource = [select id,center__c  from Resource__c];
        test.startTest();
        AureusCalendarController.createBusyAppointments(listOfBooking[0].Center__c,listOfBooking[0].Teacher_Account__c,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),30, 'description','Travel', 1, 'teacher', listOfBooking[0].Id);
        AureusCalendarController.createBusyAppointments(listOfBooking[1].Center__c,listOfResource[0].Id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),30, 'description','Others', 1, 'resource', listOfBooking[1].Id);    
        test.stopTest();
    }
    
    public static TestMethod void test_getBusyBookingDetails_NoticePeriod(){
        List<Booking__c> listOfBusyBooking = [select id,Teacher_Account__c,center__c from Booking__c where type__c ='Busy' and RecordType.name =:ConstantsClass.recordTypeLesson]; 
        List<Booking__c> listOfBooking = [select id,Teacher_Account__c,center__c,enrolment__c,parent__c,package__c from Booking__c where type__c !='Busy' and RecordType.name =:ConstantsClass.recordTypeLesson]; 
        /*List<Booking__c> listOfcreateBooking = new List<Booking__c>();
listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].enrolment__c,listOfBooking[0].parent__c,listOfBooking[0].center__c,listOfBooking[0].package__c,date.today().addDays(2),'Scheduled','Lesson','busy',false));
listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].enrolment__c,listOfBooking[0].parent__c,listOfBooking[0].center__c,listOfBooking[0].package__c,date.today(),'Pending','Lesson','Regular',false));
listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].enrolment__c,listOfBooking[0].parent__c,listOfBooking[0].center__c,listOfBooking[0].package__c,date.today().addDays(2),'Scheduled','Lesson','busy',false));
insert listOfcreateBooking;*/
        test.startTest();
        AureusCalendarController.getBusyBookingDetails(listOfBusyBooking[0].Id);
        AureusCalendarController.getNoticePeriod(listOfBooking[0].Id,system.now().adddays(-3).formatGMT('dd/MM HH:mm:ss/yyyy'));
        
        listOfBusyBooking[0].RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(constantsClass.recordTypeFacility).getRecordTypeId();
        update listOfBusyBooking[0];
        AureusCalendarController.getBusyBookingDetails(listOfBusyBooking[0].Id);
        
        test.stopTest();
    }
    
    public static TestMethod void test_downgradeSubscriptionRequest(){
        List<Booking__c> listOfBooking = [select id,Package__c,Start_Time__c,Booking_Date__c,End_Time__c,Enrolment__c from Booking__c where type__c ='Regular'  and RecordType.name =:ConstantsClass.recordTypeLesson limit 2]; 
        List<Package__c> listOfPackage = [select id from Package__c where id !=:listOfBooking[0].Package__c limit 2];
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        
        AureusCalendarController.downgradeSubscriptionRequest(listOfBooking[0].Id, system.now().month()+'/' + system.now().day()+'/'+system.now().year(),listOfBooking[0].Package__c,
                                                              listOfPackage[0].id, '2:00 PM', '', 'true', '1.0', '10.0', '10.0', mapOfCaseValues);
        test.stopTest();
        AdvanceActionsHelper.convertToDate(string.valueOf(date.today()));
    }
    public static TestMethod void test_downgradeSubscriptionNextMonthInvoiceRequest(){
        List<Booking__c> listOfBooking = [select id,Package__c,Start_Time__c,Booking_Date__c,End_Time__c,Enrolment__c from Booking__c where type__c ='Regular'  and RecordType.name =:ConstantsClass.recordTypeLesson limit 2]; 
        List<Package__c> listOfPackage = [select id from Package__c where id !=:listOfBooking[0].Package__c limit 2];
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
         mapOfCaseValues.put('currentDepositonFile', '0.0');
         mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('positiveNextMonthInvoiceAmount', '5.0');
        mapOfCaseValues.put('negativeNextMonthInvoiceAmount', '1.0');
         mapOfCaseValues.put('lessonNextLessonCharge', '1');
        LIst<Enrolment__c> listenrolment =  [SELECT Id, Student__c, Center__c, Center__r.Name, Teacher__c, Package__c, Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c, Parent__c, Parent__r.Available_Make_up_Units__c,Student__r.Name,Parent__r.Name,
                                             Package_Process_Type__c, Package_Process_Request_Date__c, New_Package_Id__c, Package_Process_Status__c, Effective_Date__c,
                                             New_Teacher__c, Next_Lesson_Start_time__c, New_Lesson_Day__c, Stage__c,New_Centre__c, Type__c, Class__c,New_Class__c 
                                             FROM Enrolment__c 
                                             WHERE Id =:listOfBooking[0].Enrolment__c];
        List<subscription__C> listsub = [select id,Parent__c from subscription__c where Parent__c=:listenrolment[0].Parent__c];
        Date nextMonthDate = Date.newInstance(system.today().addMonths(1).year(),system.today().addMonths(1).month(),01);
        List<Subscription__c> listOfSub = InvoiceGeneraterController.getSubscriptionList(listsub[0].id,nextMonthDate);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        Set<string> invoiceIds = BillingUtility.createInvoiceFromSubscription(listOfSub,NULL,nextMonthDate);
        AureusCalendarController.downgradeSubscriptionRequest(listOfBooking[0].Id, system.now().month()+'/' + system.now().day()+'/'+system.now().year(),listOfBooking[0].Package__c,
                                                              listOfPackage[0].id, '2:00 PM', '', 'true', '1.0', '10.0', '10.0', mapOfCaseValues);
        test.stopTest();
        AdvanceActionsHelper.convertToDate(string.valueOf(date.today()));
    }
    public static TestMethod void test_getNoticePeriodByEndDate(){
        List<Booking__c> listOfBooking = [select id,Teacher_Account__c,center__c,enrolment__c,parent__c,package__c,Booking_Date__c from Booking__c where type__c !='Busy' and RecordType.name =:ConstantsClass.recordTypeLesson]; 
        List<Booking__c> listOfcreateBooking = new List<Booking__c>();
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].enrolment__c,listOfBooking[0].parent__c,listOfBooking[0].center__c,listOfBooking[0].package__c,date.today().addDays(2),'Scheduled','Lesson','busy',false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].enrolment__c,listOfBooking[0].parent__c,listOfBooking[0].center__c,listOfBooking[0].package__c,date.today(),'Pending','Lesson','Regular',false));
        insert listOfcreateBooking;
        test.startTest();
        AureusCalendarController.getNoticePeriodByEndDate(listOfBooking[0].Id,  listOfBooking[0].Booking_Date__c.month()+'/' +  listOfBooking[0].Booking_Date__c.day()+'/'+ listOfBooking[0].Booking_Date__c.year());
        test.stopTest();
    }
    public static TestMethod void test_cancelSubscriptionRequest(){
        List<Booking__c> listOfBooking = [select id,center__c,Package__c,Teacher_Account__c,Start_Time__c,Booking_Date__c,End_Time__c,Enrolment__c,parent__c from Booking__c where type__c ='Regular'  and RecordType.name =:ConstantsClass.recordTypeLesson limit 2]; 
         List<Subscription_Line_Item__c> listOfSubscriptionitem = [Select id,Next_Bill_Date__c from Subscription_Line_Item__c  where Enrolment__c=:listOfBooking[0].Enrolment__c];
       date startdate =system.today();
        test.startTest();
        AureusCalendarController.cancelSubscriptionRequest(listOfBooking[0].Id, String.valueOf(date.today()), String.valueOf(date.today().addDays(15)), '', 'true');
        List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
        DateTime dt = DateTime.newInstance(listOfBooking[0].Booking_Date__c, Time.newInstance(0,0,0,0));
        
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(listOfBooking[0].center__c,listOfBooking[0].Teacher_Account__c,listOfBooking[0].parent__c,listOfBooking[0].Package__c,
                                                                               dt.adddays(1).format('EEEE'),'Enrolled','Regular',false));
        listOfEnrolment[0].Effective_Date__c = system.today();
        listOfEnrolment[0].Package_Process_Type__c = ConstantsClass.enrollmentProcessCancelType;
        listOfEnrolment[0].Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;
        insert listOfEnrolment;
        List<Booking__c> listOfcreateBooking = new List<Booking__c>();
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfEnrolment[0].Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().adddays(1),ConstantsClass.statusCanceled,'Lesson','Regular',false));
        listOfcreateBooking[0].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[0].Available_Make_up_Units__c = 1;
        
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfEnrolment[0].Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1).adddays(7),ConstantsClass.statusCanceled,'Lesson','Regular',false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfEnrolment[0].Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().addDays(15).adddays(7),ConstantsClass.statusCanceled,'Lesson','Regular',false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfEnrolment[0].Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,system.today().addMonths(-1).adddays(7),ConstantsClass.statusCanceled,'Lesson','Regular',false));
      
        listOfcreateBooking[1].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[1].Available_Make_up_Units__c = 1;
         listOfcreateBooking[2].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[2].Available_Make_up_Units__c = 1;
        insert listOfcreateBooking;
        AureusCalendarController.cancelSubscriptionRequest(listOfBooking[0].Id, String.valueOf(date.today()), String.valueOf(date.today().addDays(15)), '', 'true');
        test.stopTest();
    }
     public static TestMethod void test_cancelSubscriptionRequest2(){
        List<Booking__c> listOfBooking = [select id,center__c,Package__c,Teacher_Account__c,Start_Time__c,Booking_Date__c,End_Time__c,Enrolment__c,parent__c from Booking__c where type__c ='Regular'  and RecordType.name =:ConstantsClass.recordTypeLesson limit 2]; 
         List<Subscription_Line_Item__c> listOfSubscriptionitem = [Select id,Next_Bill_Date__c from Subscription_Line_Item__c  where Enrolment__c=:listOfBooking[0].Enrolment__c];
       date startdate =system.today();
        test.startTest();
        List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
        DateTime dt = DateTime.newInstance(listOfBooking[0].Booking_Date__c, Time.newInstance(0,0,0,0));
         List<Invoice_Line_Item__c> lineitem = [select id,Month__C,invoice__c from Invoice_Line_Item__c where enrolment__c =:listOfBooking[0].Enrolment__c];
      
         List<invoice__c> listOfinvoice = new List<invoice__c>();
         listOfinvoice.add(AureusCalendarControllerTestHelper.createInvoice(listOfBooking[0].parent__c,listOfBooking[0].center__c,false));
         listOfinvoice.add(new Invoice__c(id=lineitem[0].invoice__c, 
                                        Invoice_Date__c =Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1),
                                        Status__c ='Paid'));
         upsert listOfinvoice;
         
         List<Invoice_Line_Item__c> listOfInvoice_Line_Item = new List<Invoice_Line_Item__c>();
         listOfInvoice_Line_Item.add(AureusCalendarControllerTestHelper.createInvLineItem(listOfinvoice[0].id,10,listOfBooking[0].Teacher_Account__c,date.today().addDays(2),
                                                                                          listOfBooking[0].Enrolment__c,listOfSubscriptionitem[0].id,listOfBooking[0].Package__c,1.00,false));
         listOfInvoice_Line_Item.add(AureusCalendarControllerTestHelper.createInvLineItem(listOfinvoice[0].id,10,listOfBooking[0].Teacher_Account__c,date.today().addDays(2),
                                                                                          listOfBooking[0].Enrolment__c,listOfSubscriptionitem[0].id,listOfBooking[0].Package__c,1.00,false));
         listOfInvoice_Line_Item.add(new Invoice_Line_Item__c(Month__C= Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1),
                                                              id=lineitem[0].id ));
         upsert  listOfInvoice_Line_Item;    
         
         List<Payment__c> listOfPayment = new List<Payment__c>();
         listOfPayment.add(AureusCalendarControllerTestHelper.createPayment(listOfBooking[0].parent__c,listOfinvoice[0].id,false));
         insert listOfPayment;
         /* listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(listOfBooking[0].center__c,listOfBooking[0].Teacher_Account__c,listOfBooking[0].parent__c,listOfBooking[0].Package__c,
dt.adddays(1).format('EEEE'),'Enrolled','Regular',false));
listOfEnrolment[0].Effective_Date__c = system.today();
listOfEnrolment[0].Package_Process_Type__c = ConstantsClass.enrollmentProcessCancelType;
listOfEnrolment[0].Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;
        insert listOfEnrolment;
        */
         List<Booking__c> listOfcreateBooking = new List<Booking__c>();
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].Enrolment__c,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().adddays(1),ConstantsClass.statusCanceled,'Lesson','Regular',false));
        listOfcreateBooking[0].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[0].Available_Make_up_Units__c = 1;
        
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].Enrolment__c,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1).adddays(7),ConstantsClass.statusCanceled,'Lesson','Regular',false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].Enrolment__c,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().addDays(15).adddays(7),ConstantsClass.statusCanceled,ConstantsClass.recordTypeLesson,'Regular',false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfBooking[0].Enrolment__c,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1).adddays(-7),ConstantsClass.scheduledStatus,'Lesson','Regular',false));
      
        listOfcreateBooking[1].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[1].Available_Make_up_Units__c = 1;
         listOfcreateBooking[2].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[2].Available_Make_up_Units__c = 1;
        insert listOfcreateBooking;
        startdate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);

        listOfSubscriptionitem[0].Next_Bill_Date__c = startdate;
        update listOfSubscriptionitem[0];
        startdate = date.today().addDays(15);
       
        AureusCalendarController.cancelSubscriptionRequest(listOfBooking[0].Id, String.valueOf(date.today()), String.valueOf(date.today()), '', 'true');
        test.stopTest();
    }
   
     public static TestMethod void test_cancelSubscriptionRequest4(){
        List<Booking__c> listOfBooking = [select id,center__c,Package__c,Teacher_Account__c,Start_Time__c,Booking_Date__c,End_Time__c,Enrolment__c,parent__c from Booking__c where type__c ='Regular'  and RecordType.name =:ConstantsClass.recordTypeLesson limit 2]; 
         List<Subscription_Line_Item__c> listOfSubscriptionitem = [Select id,Next_Bill_Date__c from Subscription_Line_Item__c  where Enrolment__c=:listOfBooking[0].Enrolment__c];
       date startdate =system.today();
        test.startTest();
        List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
        DateTime dt = DateTime.newInstance(listOfBooking[0].Booking_Date__c, Time.newInstance(0,0,0,0));
        
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(listOfBooking[0].center__c,listOfBooking[0].Teacher_Account__c,listOfBooking[0].parent__c,listOfBooking[0].Package__c,
                                                                               dt.adddays(1).format('EEEE'),'Enrolled','Regular',false));
        listOfEnrolment[0].Effective_Date__c = system.today();
        listOfEnrolment[0].Package_Process_Type__c = ConstantsClass.enrollmentProcessCancelType;
        listOfEnrolment[0].Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;
        insert listOfEnrolment;
        List<Booking__c> listOfcreateBooking = new List<Booking__c>();
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfEnrolment[0].Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().adddays(1),ConstantsClass.statusCanceled,'Lesson','Regular',false));
        listOfcreateBooking[0].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[0].Available_Make_up_Units__c = 1;
        
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfEnrolment[0].Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1).adddays(7),ConstantsClass.statusCanceled,'Lesson','Regular',false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfEnrolment[0].Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().addDays(15).adddays(7),ConstantsClass.statusCanceled,'Lesson','Regular',false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,listOfEnrolment[0].Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,system.today().addMonths(-1).adddays(7),ConstantsClass.statusCanceled,'Lesson','Regular',false));
      
        listOfcreateBooking[1].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[1].Available_Make_up_Units__c = 1;
         listOfcreateBooking[2].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[2].Available_Make_up_Units__c = 1;
        insert listOfcreateBooking;
        listOfSubscriptionitem[0].Next_Bill_Date__c = system.today().addMonths(-1);
        update listOfSubscriptionitem[0];
        AureusCalendarController.cancelSubscriptionRequest(listOfBooking[0].Id, String.valueOf(date.today()), String.valueOf(system.today().addMonths(-1)), '', 'true');
        test.stopTest();
    }
    
    public static TestMethod void test_fetchCurrentMonthPaymentEntry_getCaseDetails_getCenterUsers(){
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c limit 1];
        List<case> listOfcase = [select id  from case];
        test.startTest(); 
        AureusCalendarController.fetchCurrentMonthPaymentEntry(objEnrol,date.today().addDays(-3));
        AureusCalendarController.getCaseDetails(listOfcase[0].id);
        AureusCalendarController.getCenterUsers();
        test.stopTest(); 
    }
    public static TestMethod void test_getCancellationDetails_getUpgradeDowngradeSummary(){
        List<Booking__c> listOfBooking = [select id,Package__c,Start_Time__c,Booking_Date__c,End_Time__c,Enrolment__c from Booking__c where type__c ='Regular'  and RecordType.name =:ConstantsClass.recordTypeLesson limit 2]; 
        List<Package__c> listOfPackage = [select id from Package__c where id !=:listOfBooking[0].Package__c limit 2];
        test.startTest(); 
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0)).addDays(5);
        AureusCalendarController.getCancellationDetails(listOfBooking[0].Id,string.valueOf(date.today().addDays(3)));
        AureusCalendarController.getUpgradeDowngradeSummary(listOfBooking[0].Id, listOfBooking[0].Package__c, listOfPackage[0].Id,listOfBooking[0].Booking_Date__c.month()+'/' +  listOfBooking[0].Booking_Date__c.day()+'/'+ listOfBooking[0].Booking_Date__c.year());
        test.stopTest(); 
    }
    public static TestMethod void test_getEnrolmentProcessData_getAllTeachersAccordingToCenter(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c FROM Booking__c]; 
        listOfBooking[0].type__c ='Trial';
        listOfBooking[0].status__c ='Completed';
        update listOfBooking[0];
        test.startTest(); 
        // AureusCalendarController.getEnrolmentProcessData(listOfBooking[0].Id);
        AureusCalendarController.getAllTeachersAccordingToCenter(listOfBooking[0].Id,listOfBooking[0].Center__C );
        test.stopTest();
    }
    public static TestMethod void test_getPlans_sendEnrolToIpad(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c FROM Booking__c]; 
        
        test.startTest(); 
        AureusCalendarController.getPlans(listOfBooking[0].Id,listOfBooking[0].center__c , listOfBooking[0].Teacher_Account__c);
        // AureusCalendarController.sendEnrolToIpad('messsage');
        test.stopTest();
    }
    public static TestMethod void test_getWithrawalSummary_getTimeSlotsAccordingly(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c FROM Booking__c]; 
        List<Package__c> listOfPackage = [select id from Package__c where id !=:listOfBooking[0].Package__c limit 2];
        test.startTest(); 
        AureusCalendarController.getWithrawalSummary(listOfBooking[0].Id, String.valueOf(System.today()), String.valueOf(System.today().addDays(3)));
        AureusCalendarController.getTimeSlotsAccordingly(listOfBooking[0].center__c, listOfBooking[0].Teacher_Account__c, listOfPackage[0].Id, listOfBooking[0].Enrolment__c,String.valueOf(date.today()) );
        test.stopTest();
    }
    
    public static TestMethod void test_getUpgradeDowngradePackageSummary(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c FROM Booking__c]; 
        List<Package__c> listOfPackage = [select id from Package__c where id !=:listOfBooking[0].Package__c limit 2];
        test.startTest(); 
        AureusCalendarController.getUpgradeDowngradePackageSummary(listOfBooking[0].Package__c, listOfPackage[0].Id,String.valueOf(date.today()) ,
                                                                   '13:00:00 PM',  listOfBooking[0].Enrolment__c, 'upgrade'); 
        AureusCalendarController.getUpgradeDowngradePackageSummary(listOfBooking[0].Package__c, listOfPackage[0].Id,String.valueOf(date.today()) , '13:00:00 PM',  listOfBooking[0].Enrolment__c, 'downgrade'); 
        
        test.stopTest();
    }
    
    public static TestMethod void test_getEnrolmentUpdateDetails_getPackageAccordingToTeacher(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c FROM Booking__c]; 
        List<Package__c> listOfPackage = [select id from Package__c where id =:listOfBooking[0].Package__c limit 2];
        test.startTest(); 
        AureusCalendarController.getEnrolmentUpdateDetails(listOfBooking[0].Enrolment__c);
        AureusCalendarController.getPackageAccordingToTeacher(listOfBooking[0].center__c, listOfBooking[0].Teacher_Account__c,30);
        
        listOfPackage[0].Type__c = 'Individual';
        listOfPackage[0].RecordTypeId=Schema.SObjectType.Package__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
        update listOfPackage[0];
        
        AureusCalendarController.getPackageAccordingToTeacher(listOfBooking[0].center__c, listOfBooking[0].Teacher_Account__c,30);
        test.stopTest();
    }
    
    public static TestMethod void test_updateEnrolment(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C
                                          FROM Booking__c  where type__c='Regular'  and RecordType.name =:ConstantsClass.recordTypeLesson]; 
        List<Enrolment__c> enrolmentList = [SELECT Id,Teacher__c ,Package__c,
                                            (Select Id, Next_Bill_Date__c  FROM Subscription_Line_Items__r) 
                                            FROM Enrolment__c WHERE Id =: listOfBooking[0].Enrolment__c];
        List<account> listOfteacher = [select id from account where id !=: enrolmentList[0].Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: enrolmentList[0].Package__c];
        
        //Create Booking Records
        test.startTest();  
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        AureusCalendarController.updateEnrolment(enrolmentList[0].id, listOfteacher[0].id,
                                                 listOfPackage[0].id,
                                                 listOfBooking[0].Booking_Date__c.month()+'/' +  listOfBooking[0].Booking_Date__c.day()+'/'+ listOfBooking[0].Booking_Date__c.year(),
                                                 listOfBooking[0].Booking_Date__c.month()+'/' +  listOfBooking[0].Booking_Date__c.day()+'/'+ listOfBooking[0].Booking_Date__c.year(),
                                                 '11:00 AM', '', 'true', 'Fri @ 11:00 AM',
                                                 listOfBooking[1].Enrolment__r.Package__r.Name, listOfBooking[1].Package__r.name);
        test.stopTest();
    }
    
    public static TestMethod void test_sendEnrolmentLinkByCase(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c FROM Booking__c]; 
        test.startTest(); 
        AureusCalendarController.sendEnrolmentLinkByCase('', listOfBooking[0].Id, 'Trial');
        test.stopTest();
    }
    public static TestMethod void test_getPrePaymentPackage_updateEnrolmentLink_releaseBlockBooking(){
        List<Enrolment__c> enrolmentList = [SELECT Id,Teacher__c ,Package__c
                                            FROM Enrolment__c ];
        List<Enrolment__c> enrolmentcancelList = [SELECT Id,Teacher__c ,Package__c
                                                  FROM Enrolment__c where stage__c ='Cancelled'];
        test.startTest(); 
        AureusCalendarController.getPrePaymentPackage(enrolmentList[0].Id);
        AureusCalendarController.updateEnrolmentLink(enrolmentList[0].Id);
        AureusCalendarController.releaseBlockBooking(enrolmentcancelList[0].Id, 'Customer Not Interested', '');
        test.stopTest();
    }
    
    public static TestMethod void test_AureusCalendarControllerHelperMethods(){
        List<Booking__c> listOfBooking = [SELECT Id,Type__c,Student__c,center__c,Teacher_Account__c,Package__c,Enrolment__c,Booking_Date__c,
                                          Available_Make_up_Units__c,end_Time__c
                                          FROM Booking__c]; 
        List<Enrolment__c> enrolmentList = [SELECT Id,Teacher__c ,Package__c,center__c,Parent__c
                                            FROM Enrolment__c ];
        List<Booking__c> listOfmakeupBooking = [SELECT Id,Type__c,Student__c,center__c,Teacher_Account__c,Package__c,Enrolment__c,Booking_Date__c,
                                                Available_Make_up_Units__c,end_Time__c,Student__r.Name,parent__c
                                                from Booking__c where type__c ='Make-up'  and RecordType.name =:ConstantsClass.recordTypeLesson limit 1]; 
        listOfmakeupBooking[0].Available_Make_up_Units__c = 0;
        listOfmakeupBooking[0].Make_up_Utilize_Bookings__c = listOfBooking[0].Id + '-30;'+ listOfBooking[1].Id + '-30';
        listOfmakeupBooking[0].Make_up_Expiry_Date__c= date.today();
        update listOfmakeupBooking[0];
        
        test.startTest(); 
        AureusCalendarControllerHelper.cancelAllFutureMakeupBookings(new list< Booking__c > {listOfmakeupBooking[0]});
        AureusCalendarControllerHelper.createFifthBookingOnUpgrade(enrolmentList[0], new  Map<String, Booking__c>{listOfmakeupBooking[0].id => listOfmakeupBooking[0]}, 30, time.newInstance(11,11, 11, 11), 30);
        
        account parentObj = new Account(id =enrolmentList[0].parent__c,Available_Make_up_Units__c =30 );
        update parentObj;
        
        AureusCalendarControllerHelper.createFifthBookingOnUpgrade(enrolmentList[0], new  Map<String, Booking__c>{listOfmakeupBooking[0].id => listOfmakeupBooking[0]}, 30, time.newInstance(11,11, 11, 11), 30);
        AureusCalendarControllerHelper.fetchDesiredPackage(enrolmentList[0].Package__c);
        
    }
    public static TestMethod void test_AureusCalendarControllerHelperMethods2(){
        List<Enrolment__c> enrolmentList = [SELECT Id,Teacher__c,Lesson_Mode__c ,Package__c,center__c,Parent__c,Effective_Date__c
                                            FROM Enrolment__c ];
        enrolmentList[0].Lesson_Mode__c ='In Centre';
        update enrolmentList;
        List<Booking__c> listOfBooking = [SELECT Id,Type__c,Student__c,center__c,Teacher_Account__c,Package__c,Enrolment__c,Booking_Date__c,
                                          Available_Make_up_Units__c,end_Time__c
                                          FROM Booking__c where Enrolment__c =:enrolmentList[0].id]; 
        List<Fifth_Lesson__c> listOfFifthLesson = [select id,Booking_Date__c,Teacher_Account__c,Center__c from Fifth_Lesson__c where Enrolment__c=: listOfBooking[0].Enrolment__c limit 2];
        
        test.startTest(); 
        AureusCalendarControllerHelper.fetchMakeupPackages(enrolmentList[0].center__c, '45'); 
        List<Fifth_Lesson__c> lessons = AureusCalendarControllerHelper.fetchFifthLessson(new Set<String> {listOfFifthLesson[0].Id});
        AureusCalendarControllerHelper.createBookingFromFifthLesson(lessons, 'placeholder');
        AureusCalendarControllerHelper.createBookingFromFifthLesson(lessons, 'adhoc');
        AureusCalendarControllerHelper.createBookingFromFifthLesson(lessons, 'makeup');
        AureusCalendarControllerHelper.getFifthLessonEvents(listOfFifthLesson[0].center__c, new Set<String>{listOfFifthLesson[0].Teacher_Account__c},new List<String>
                                                            {String.valueOf(listOfFifthLesson[0].Booking_Date__c)});
        AureusCalendarControllerHelper.processFutureFifthLessons(enrolmentList[0], 'upgrade');
        enrolmentList[0].Next_Lesson_Start_time__c = Time.newInstance(11,0,0,0);
        enrolmentList[0].new_package_Id__c = listOfBooking[0].Package__c;
        enrolmentList[0].New_Teacher__c =listOfBooking[0].Teacher_Account__c;
        update enrolmentList[0];
        AureusCalendarControllerHelper.processFutureFifthLessons(enrolmentList[0], 'upgrade');
        test.stopTest(); 
        
    }
    
    //  11-Mar-2020: jatin: for cover Group class methods
    public static TestMethod void test_AureusCalendarGroupClassMethods(){
        List<Booking__c> listOfBooking = [select id,enrolment__r.Package__r.Duration__c,enrolment__r.Package__r.Type__c,Enrolment__c,enrolment__r.Package__r.Location__c,Teacher_Account__c,
                                          enrolment__r.Package__r.Program__r.Instrument__c,Group_Class__r.Class__c,Booking_Date__c,
                                          Start_Time__c,End_Time__c,status__c,Center__c,remarks__c,recordTypeId,
                                          Category__c,Group_Class__c,Student__r.Name
                                          from Booking__c 
                                          where RecordType.name =:ConstantsClass.groupLessonBookingRecordType]; 
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Parent__C,Student__c,Package__r.Duration__c,Package__r.Type__c,Package__r.Location__c,Package__r.Program__r.Instrument__c 
                                 from Enrolment__c where id=:listOfBooking[0].Enrolment__c limit 1];
        
        test.startTest();
        objEnrol.Lesson_Start_time__c=Time.newInstance(11,0,0,0);
        update objEnrol;
        List<Account> newTeacherList = [select id from Account Where recordType.name='Teacher' and id !=: objEnrol.id ];
        List<Package__C> newPackageIdList = [select id from package__c Where id != : objEnrol.Package__c ];
        List<case> listOfcase = [select id,Type from case];
        List<class__c> listOfClass = [select Id from CLass__c];
        List<Booking__c> listOfBusyGroupLesssonBooking = [select id,Teacher_Account__c,center__c 
                                                          from Booking__c
                                                          where type__c ='Busy' 
                                                          and RecordType.name =:ConstantsClass.groupLessonBookingRecordType]; 
        
        AureusCalendarController.getBusyBookingDetails(listOfBusyGroupLesssonBooking[0].Id);
        AureusCalendarController.getUpgradedDetails(listOfBooking[0].id,'Group Lesson');
        
        AureusCalendarController.cancelBooking(listOfBooking[0].id, 'Exams','Teacher MC',' makeupRemark', 'true', listOfcase[0].id, 'true');
        AureusCalendarController.getUpgradedClassDetails(objEnrol.Center__c,objEnrol.Teacher__c,objEnrol.Package__c,string.valueOf(date.today()),listOfBooking[0].Group_Class__r.Class__c);
        AureusCalendarController.getTimeSlotsAccordinglyToChangeEnrolSpecificUsers(objEnrol.Center__c,objEnrol.Teacher__c, objEnrol.Package__c, objEnrol.id, string.valueOf(date.today()));
        AureusCalendarController.getChangeEnrollmentPackageSummary('change enrollment',objEnrol.Id,newTeacherList[0].id,objEnrol.Teacher__c,                 
                                                                   newPackageIdList[0].id,objEnrol.Package__c, 
                                                                   string.valueOf(date.today().addDays(2)),string.valueOf(date.today()), 
                                                                   '13:00:00 PM','11:00:00 AM');
        AureusCalendarController.fetchGroupPackages(objEnrol.Center__c,objEnrol.Teacher__c);
        AureusCalendarController.saveNewClass(objEnrol.Center__c,objEnrol.Teacher__c, objEnrol.Package__c, 
                                              String.valueOf(date.today()), '13:00:00', 
                                              objEnrol.Package__r.Duration__c, 20,
                                              'Group Theory Lesson',10,20,false,'');
        AureusCalendarController.createPlaceholderForGroupClass(listOfBooking,'cancel', '');
        AureusCalendarController.initEnroll(new Enrolment__c());
        AureusCalendarController.getLessonRefundAmount(objEnrol,system.today());
        test.stopTest();
    }
}