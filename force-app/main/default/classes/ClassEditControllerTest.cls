/*
Name        :        ClassEditControllerTest
Date        :        11 -Mar- 2020 
Author      :        Jatin
Description :        It is the test class  for code coverage ClassEditController,WithDrawlEnrolmentClassProcessController
						UpgradeEnrolmentClassProcessController,UpdateEnrolmentClassProcessController,UpgradeToIndividualProcessController.
*/
@isTest
public class ClassEditControllerTest {
    @testSetup 
    Private static void createData(){
        ClassEditControllerTestHelper.createGroupClassData();
    }  
    
    Private Static TestMethod void test_fetchGroupLessonBookingDetails(){
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c from Booking__c Where class__C != null];
        List<Booking__c> listGroupLessonBooking = [select Id,enrolment__C,center__c from Booking__c Where recordType.Name =: ConstantsClass.groupLessonBookingRecordType];
        List<case> listOfcase = [select id,Type from case];
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c where id=:listGroupLessonBooking[0].enrolment__C limit 1];
        Test.startTest();
        ClassEditController.fetchBookDetailsForScreen(listGroupClassBooking[0].id);
        ClassEditController.getGroupStudents('test',listGroupLessonBooking[0].center__c);
        //AureusCalendarController.cancelBooking(listGroupLessonBooking[0].id, 'Exams','Teacher MC',' makeupRemark', 'true', listOfcase[0].id, 'true');
        Booking__C objBooking = new Booking__C(id=listGroupLessonBooking[0].id,
                                               Status__c = ConstantsClass.statusCanceled,
                                               Available_Make_up_Units__c =30,
                                               Make_up_Expiry_Date__c = system.today(),
                                               Type__c = ConstantsClass.groupLessonTypeBooking,
                                               enrolment__C = listGroupLessonBooking[0].enrolment__C);
        update objBooking;
        ClassEditController.getPendingMakeupBookings(objBooking.enrolment__C,system.today());
        String bookingRecurringJson = '{"groupClassId":"'+listGroupClassBooking[0].id+'","studentId":"'+objEnrol.Student__c+'","packageId":"'+objEnrol.Package__c+'","type":"Group Lesson","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"2019-04-22T15:00:00","centerId":"'+objEnrol.Center__c+'","teacherId":"'+objEnrol.Teacher__c+'"}';
        ClassEditController.createGroupbooking(bookingRecurringJson, 'false', listOfcase[0].Id);
        Test.stopTest();
    }
    Private Static TestMethod void test_getUpgradeGroupClassPackageSummary(){
        List<Booking__c> listGroupLessonBooking = [select Id,enrolment__C,enrolment__r.teacher__c,center__c,package__c,Group_Class__r.class__c from Booking__c Where recordType.Name =: ConstantsClass.groupLessonBookingRecordType];
        LIst<Package__c> packageList =  [select id from package__C where id !=: listGroupLessonBooking[0].package__c];
        LIst<class__c> classList =  [select id from Class__C];
        LIst<Account> teacherAccountList =  [select id from Account where id !=: listGroupLessonBooking[0].enrolment__r.teacher__c and RecordType.name='Teacher'];
        
        List<case> listOfcase = [select id,Type from case];
        Test.startTest();
        ClassEditController.getUpgradeGroupClassPackageSummary(listGroupLessonBooking[0].Package__c,packageList[0].id, 
                                                               String.valueOf(system.today().addDays(2)),String.valueOf(system.today().AddDays(7)),
                                                               '12:00:00 AM', '11:00:00 PM',
                                                               listGroupLessonBooking[0].enrolment__C,'GroupToHigherPackage',
                                                               teacherAccountList[0].id,listGroupLessonBooking[0].enrolment__r.teacher__c,
                                                               classList[0].id,classList[1].id);
        ClassEditController.getUpgradeGroupClassPackageSummary(listGroupLessonBooking[0].Package__c,packageList[0].id, 
                                                               String.valueOf(system.today().addDays(2)),String.valueOf(system.today().AddDays(7)),
                                                               '12:00:00 AM', '11:00:00 PM',
                                                               listGroupLessonBooking[0].enrolment__C,'GroupToSameClass',
                                                               teacherAccountList[0].id,listGroupLessonBooking[0].enrolment__r.teacher__c,
                                                               classList[0].id,classList[0].id);
        ClassEditController.getUpgradeGroupClassPackageSummary(listGroupLessonBooking[0].Package__c,packageList[0].id, 
                                                               String.valueOf(system.today().addDays(2)),String.valueOf(system.today().AddDays(7)),
                                                               '12:00:00 AM', '11:00:00 PM',
                                                               listGroupLessonBooking[0].enrolment__C,'GroupToIndividual',
                                                               teacherAccountList[0].id,listGroupLessonBooking[0].enrolment__r.teacher__c,
                                                               '','');
        
        Test.stopTest();
        
    }
    
    Private Static TestMethod void test_getGroupLessonEnrolmentUpdateDetails(){
        List<Booking__c> listGroupLessonBooking = [select Id,enrolment__C,enrolment__r.teacher__c,center__c,package__c,Group_Class__r.class__c from Booking__c Where recordType.Name =: ConstantsClass.groupLessonBookingRecordType];
        LIst<Package__c> packageList =  [select id from package__C where id !=: listGroupLessonBooking[0].package__c];
        LIst<class__c> classList =  [select id from Class__C];
        LIst<Account> teacherAccountList =  [select id from Account where id !=: listGroupLessonBooking[0].enrolment__r.teacher__c and RecordType.name='Teacher'];
        
        List<case> listOfcase = [select id,Type from case];
        Test.startTest();
        ClassEditController.getGroupLessonEnrolmentUpdateDetails(listGroupLessonBooking[0].enrolment__c,'GroupToIndividual');
        ClassEditController.getGroupLessonEnrolmentUpdateDetails(listGroupLessonBooking[0].enrolment__c,'GroupToSameClass');
        ClassEditController.getGroupLessonEnrolmentUpdateDetails(listGroupLessonBooking[0].enrolment__c,'GroupToHigherPackage');
        ClassEditController.getNewEffectiveGroupDateSlots(listGroupLessonBooking[0].Package__C,listGroupLessonBooking[0].enrolment__r.teacher__c);
        ClassEditController.markCompleteOrNoShow(listGroupLessonBooking[0].id,'noShow');
        
        Test.stopTest();
        
    }
    Private Static TestMethod void test_getPackageAccordingToTeacherOrInstrument(){
        List<Booking__c> listGroupLessonBooking = [select Id,enrolment__r.teacher__c,center__c,package__r.Duration__c,package__r.Program__r.Instrument__c from Booking__c Where recordType.Name =: ConstantsClass.groupLessonBookingRecordType];
        LIst<class__c> classList =  [select id from Class__C];
        ClassEditController.getPackageAccordingToTeacherOrInstrument(listGroupLessonBooking[0].center__c,Integer.ValueOf(listGroupLessonBooking[0].package__r.Duration__c),listGroupLessonBooking[0].package__r.Program__r.Instrument__c);
        ClassEditController.getUpgradePackageAccordingToTeacher(listGroupLessonBooking[0].center__c, listGroupLessonBooking[0].enrolment__r.teacher__c, 
                                                                listGroupLessonBooking[0].id,'GroupToIndividual');
        ClassEditController.getUpgradePackageAccordingToTeacher(listGroupLessonBooking[0].center__c, listGroupLessonBooking[0].enrolment__r.teacher__c, 
                                                                listGroupLessonBooking[0].id,'GroupToHigherPackage');
        ClassEditController.getUpgradePackageAccordingToTeacher(listGroupLessonBooking[0].center__c, listGroupLessonBooking[0].enrolment__r.teacher__c, 
                                                                listGroupLessonBooking[0].id,'GroupToSameClass');
        ClassEditController.getGroupLessonTimeSlotsAccordingly(string.valueOf(system.today().AddDays(7)),classList[0].id);
        ClassEditController.getTimeSlotsGroupClassAccordingly(listGroupLessonBooking[0].center__c,listGroupLessonBooking[0].enrolment__r.teacher__c,listGroupLessonBooking[0].package__c,string.valueOf(system.today().AddDays(7)));
        
        
    }
    
    public static TestMethod void test_cancelGroupLessonSubscriptionRequest(){
        List<Booking__c> listOfBooking = [select id,center__c,Package__c,Teacher_Account__c,Start_Time__c,Booking_Date__c,End_Time__c,Enrolment__c,parent__c from Booking__c
                                          where RecordType.name =:ConstantsClass.groupLessonBookingRecordType limit 2]; 
        
        test.startTest(); 
        List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
        DateTime dt = DateTime.newInstance(listOfBooking[0].Booking_Date__c, Time.newInstance(0,0,0,0));
        
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(listOfBooking[0].center__c,listOfBooking[0].Teacher_Account__c,listOfBooking[0].parent__c,listOfBooking[0].Package__c,
                                                                               dt.adddays(1).format('EEEE'),'Enrolled','Regular',false));
        listOfEnrolment[0].Effective_Date__c = system.today();
        listOfEnrolment[0].Package_Process_Type__c = ConstantsClass.enrollmentProcessCancelType;
        listOfEnrolment[0].Package_Process_Status__c = ConstantsClass.enrollmentProcessPendingStatus;
        insert listOfEnrolment;
        Booking__C objBooking = new Booking__C(id=listOfBooking[0].id,
                                               Status__c = ConstantsClass.statusCanceled,
                                               Available_Make_up_Units__c =30,
                                               Make_up_Expiry_Date__c = system.today(),
                                               Type__c = ConstantsClass.groupLessonTypeBooking,
                                               enrolment__C = listOfBooking[0].enrolment__C);
        update objBooking;
        ClassEditController.cancelGroupLessonSubscriptionRequest(listOfBooking[0].Id, String.valueOf(date.today()), String.valueOf(Date.newInstance(System.today().year(), System.today().month(), 15)), '', 'true');
        
        test.stopTest();
    }
    public static TestMethod void test_cancelGroupLessonSubscriptionRequest2(){
        List<Booking__c> listOfBooking = [select id,center__c,Package__c,Teacher_Account__c,Start_Time__c,Booking_Date__c,End_Time__c,Enrolment__c,parent__c from Booking__c
                                          where RecordType.name =:ConstantsClass.groupLessonBookingRecordType limit 2]; 
        
        test.startTest(); 
        ClassEditController.cancelGroupLessonSubscriptionRequest(listOfBooking[0].Id, String.valueOf(date.today()), String.valueOf(Date.newInstance(System.today().year(), System.today().month() + 1, 15)), '', 'true');
        
        test.stopTest();
    }
    public static TestMethod void test_updateGroupClassToSamePackageOfCustomer(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType]; 
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c where id=:listOfBooking[0].enrolment__C limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        LIst<class__c> classList =  [select id from Class__C];
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c,Booking_Date__c from Booking__c Where class__C != null and Booking_Date__c >:listOfBooking[0].Booking_Date__c.addMonths(1)];
        List<case> listOfcase = [select id,Type from case];
        test.startTest();  
        String bookingRecurringJson = '{"groupClassId":"'+listOfBooking[0].id+'","studentId":"'+objEnrol.Student__c+'","packageId":"'+objEnrol.Package__c+'","type":"Group Lesson","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"'+string.valueOf(listGroupClassBooking[0].Booking_Date__c)+'T15:00:00","centerId":"'+objEnrol.Center__c+'","teacherId":"'+objEnrol.Teacher__c+'"}';
        ClassEditController.createGroupbooking(bookingRecurringJson, 'false', listOfcase[0].Id);
        Booking__C objBooking = new Booking__C(id=listOfBooking[0].id,
                                               Status__c = ConstantsClass.statusCanceled,
                                               Available_Make_up_Units__c =30,
                                               Make_up_Expiry_Date__c = system.today(),
                                               Type__c = ConstantsClass.groupLessonTypeBooking,
                                               enrolment__C = listOfBooking[0].enrolment__C,
                                               Booking_Date__c = system.today());
        update objBooking;
        ClassEditController.updateGroupClassToSamePackageOfCustomer(listOfBooking[0].id,(listGroupClassBooking[0].Booking_Date__c.month())+'/' +  listGroupClassBooking[0].Booking_Date__c.day()+'/'+ listGroupClassBooking[0].Booking_Date__c.year(),listOfPackage[0].id,
                                                                    listOfBooking[0].Package__c, '11:00 AM' ,'','true',
                                                                    classList[0].id,classList[1].id, listOfBooking[0].Teacher_Account__c);
        
        ClassEditController.updateGroupClassToSamePackageOfCustomer(listOfBooking[0].id,system.today().month()+'/' + system.today().day()+'/'+ system.today().year(),listOfPackage[0].id,
                                                                    listOfBooking[0].Package__c, '11:00 AM' ,'','true',
                                                                    classList[0].id,classList[1].id, listOfBooking[0].Teacher_Account__c);
        test.stopTest();
    }
    public static TestMethod void test_upgradePackageClassOfCustomer(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType]; 
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c where id=:listOfBooking[0].enrolment__C limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        LIst<class__c> classList =  [select id from Class__C];
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c,Booking_Date__c from Booking__c Where class__C != null and Booking_Date__c >:listOfBooking[0].Booking_Date__c.addMonths(1)];
        List<case> listOfcase = [select id,Type from case];
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        
        test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        
        ClassEditController.upgradePackageClassOfCustomer(listOfBooking[0].id,system.today().month()+'/' + system.today().day()+'/'+ system.today().year(), listOfPackage[0].id, 
                                                          listOfBooking[0].Package__c,'7:00:00 PM',listOfcase[0].id,'true', mapOfCaseValues,
                                                          classList[0].id,classList[1].id, listOfBooking[0].Teacher_Account__c);
        test.stopTest();
    }
    public static TestMethod void test_upgradePackageClassOfCustomer2(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType]; 
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c where id=:listOfBooking[0].enrolment__C limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        LIst<class__c> classList =  [select id from Class__C];
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c,Booking_Date__c from Booking__c Where class__C != null and Booking_Date__c >:listOfBooking[0].Booking_Date__c.addMonths(1)];
        List<case> listOfcase = [select id,Type from case];
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        String bookingRecurringJson = '{"groupClassId":"'+listOfBooking[0].id+'","studentId":"'+objEnrol.Student__c+'","packageId":"'+objEnrol.Package__c+'","type":"Group Lesson","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"'+string.valueOf(listGroupClassBooking[0].Booking_Date__c)+'T15:00:00","centerId":"'+objEnrol.Center__c+'","teacherId":"'+objEnrol.Teacher__c+'"}';
        ClassEditController.createGroupbooking(bookingRecurringJson, 'false', listOfcase[0].Id);
        Booking__C objBooking = new Booking__C(id=listOfBooking[0].id,
                                               Status__c = ConstantsClass.statusCanceled,
                                               Available_Make_up_Units__c =30,
                                               Make_up_Expiry_Date__c = system.today(),
                                               Type__c = ConstantsClass.groupLessonTypeBooking,
                                               enrolment__C = listOfBooking[0].enrolment__C,
                                               Booking_Date__c = listGroupClassBooking[0].Booking_Date__c);
        update objBooking;
        test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        ClassEditController.upgradePackageClassOfCustomer(listOfBooking[0].id,(listGroupClassBooking[0].Booking_Date__c.month())+'/' +  listGroupClassBooking[0].Booking_Date__c.day()+'/'+ listGroupClassBooking[0].Booking_Date__c.year(), listOfPackage[0].id, 
                                                          listOfBooking[0].Package__c,'7:00:00 PM',listOfcase[0].id,'true', mapOfCaseValues,
                                                          classList[0].id,classList[1].id, listOfBooking[0].Teacher_Account__c);
        test.stopTest();
    }
    public static TestMethod void test_upgradeToIndividualClassOfCustomer(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType]; 
        Enrolment__c objEnrol = [select id,Center__c,Center__r.Country__c,Center__r.Organisation__c, Teacher__c,Package__c,Student__c from Enrolment__c where id=:listOfBooking[0].enrolment__C limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        LIst<class__c> classList =  [select id from Class__C];
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c,Booking_Date__c from Booking__c Where class__C != null and Booking_Date__c >:listOfBooking[0].Booking_Date__c.addMonths(1)];
        List<case> listOfcase = [select id,Type from case];  
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        String bookingRecurringJson = '{"groupClassId":"'+listOfBooking[1].id+'","studentId":"'+objEnrol.Student__c+'","packageId":"'+objEnrol.Package__c+'","type":"Group Lesson","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"'+string.valueOf(listGroupClassBooking[0].Booking_Date__c)+'T15:00:00","centerId":"'+objEnrol.Center__c+'","teacherId":"'+objEnrol.Teacher__c+'"}';
        ClassEditController.createGroupbooking(bookingRecurringJson, 'false', listOfcase[0].Id);
        Booking__C objBooking = new Booking__C(id=listOfBooking[0].id,
                                               Status__c = ConstantsClass.statusCanceled,
                                               Available_Make_up_Units__c =30,
                                               Make_up_Expiry_Date__c = system.today(),
                                               Type__c = ConstantsClass.groupLessonTypeBooking,
                                               enrolment__C = listOfBooking[0].enrolment__C,
                                              Booking_Date__c = listGroupClassBooking[0].Booking_Date__c);
        update objBooking;    
        test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        ClassEditController.upgradeToIndividualClassOfCustomer(listOfBooking[0].id,(listGroupClassBooking[0].Booking_Date__c.month())+'/' +  listGroupClassBooking[0].Booking_Date__c.day()+'/'+ listGroupClassBooking[0].Booking_Date__c.year(), listOfPackage[0].id, 
                                                               listOfBooking[0].Package__c,'7:00:00 PM',listOfcase[0].id,'true', mapOfCaseValues,
                                                                listOfBooking[0].Teacher_Account__c,listOfteacher[0].id);
        test.stopTest();
    }
    public static TestMethod void test_upgradeToIndividualClassOfCustomer2(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType]; 
        Enrolment__c objEnrol = [select id,Center__c,Center__r.Organisation__c,Center__r.Country__c,Teacher__c,Package__c,Student__c from Enrolment__c where id=:listOfBooking[0].enrolment__C limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        LIst<class__c> classList =  [select id from Class__C];
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c,Booking_Date__c from Booking__c Where class__C != null and Booking_Date__c >:listOfBooking[0].Booking_Date__c.addMonths(1)];
        List<case> listOfcase = [select id,Type from case];
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        Leave_Request__c request = new Leave_Request__c(Employee__c = listOfteacher[0].Id, Leave_End_Date__c = System.today().addDays(14), 
                                                        Leave_Start_Date__c = System.today().addDays(14), Leave_Type__c = 'Teacher MC',
                                                        Status__c = 'Approved');
        INSERT request;
        
        Public_Holiday__c holiday = new Public_Holiday__c(Country__c = objEnrol.Center__r.Country__c, Execution_Date__c = System.today(), Organisation_Status__c = 'Closed',
                                                         Public_Holiday_Date__c = System.today().addDays(21), Status__c = 'Execution completed', Organisation__c = objEnrol.Center__r.Organisation__c);
        INSERT holiday;
       
        test.startTest(); 
       
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
       
        ClassEditController.upgradeToIndividualClassOfCustomer(listOfBooking[0].id,system.today().month()+'/' + system.today().day()+'/'+ system.today().year(), listOfPackage[0].id, 
                                                               listOfBooking[0].Package__c,'7:00:00 PM',listOfcase[0].id,'true', mapOfCaseValues,
                                                                listOfBooking[0].Teacher_Account__c,listOfteacher[0].id);
        test.stopTest();
    }
}