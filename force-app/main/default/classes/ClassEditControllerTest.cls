/*
Name        :        ClassEditControllerTest
Date        :        11 -Mar- 2020 
Author      :        Jatin
Description :        It is the test class  for code coverage ClassEditController,WithDrawlEnrolmentClassProcessController
UpgradeEnrolmentClassProcessController,UpdateEnrolmentClassProcessController,UpgradeToIndividualProcessController,ClassEditControllerTest.
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
        
        test.stopTest();
    }
    public static TestMethod void test_updateGroupClassToSamePackageOfCustomer2(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType]; 
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c where id=:listOfBooking[0].enrolment__C limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        LIst<class__c> classList =  [select id from Class__C];
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c,Booking_Date__c from Booking__c Where class__C != null and Booking_Date__c >:listOfBooking[0].Booking_Date__c.addMonths(1)];
        List<case> listOfcase = [select id,Type from case];
        List<Subscription_Line_Item__c> listOfSubscriptionitem = [Select id,Next_Bill_Date__c from Subscription_Line_Item__c  where Enrolment__c=:listOfBooking[0].Enrolment__c];
        
        
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
        ClassEditController.updateGroupClassToSamePackageOfCustomer(listOfBooking[0].id,system.today().month()+'/' + system.today().day()+'/'+ system.today().year(),listOfPackage[0].id,
                                                                    listOfBooking[0].Package__c, '11:00 AM' ,'','true',
                                                                    classList[0].id,classList[1].id, listOfBooking[0].Teacher_Account__c);
        
        test.stopTest();
    }
    public static TestMethod void test_updateGroupClassToSamePackageOfCustomer3(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,
                                          Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType]; 
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c,class__c from Enrolment__c where id=:listOfBooking[0].enrolment__C limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        LIst<class__c> classList =  [select id,Class_Date__c from Class__C];
        List<case> listOfcase = [select id,Type from case];
        List<Subscription_Line_Item__c> listOfSubscriptionitem = [Select id,Next_Bill_Date__c from Subscription_Line_Item__c  where Enrolment__c=:listOfBooking[0].Enrolment__c];
        listOfSubscriptionitem[0].Next_Bill_Date__c =  Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
        update listOfSubscriptionitem[0];
        List<Booking__c> listOfcreateBooking = new List<Booking__c>();
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,objEnrol.Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1).adddays(-7),
                                                                                 'Scheduled',ConstantsClass.groupLessonBookingRecordType,ConstantsClass.groupLessonTypeBooking,false));
        insert       listOfcreateBooking;
        test.startTest();  
        ClassEditController.updateGroupClassToSamePackageOfCustomer(listOfBooking[0].id,(listOfBooking[0].Booking_Date__c.month())+'/' +  listOfBooking[0].Booking_Date__c.day()+'/'+ listOfBooking[0].Booking_Date__c.year(),listOfPackage[0].id,
                                                                    listOfBooking[0].Package__c, '11:00 AM' ,'','true',
                                                                     classList[0].id,classList[0].id, listOfBooking[0].Teacher_Account__c);
        listOfcreateBooking = new List<Booking__c>();
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,objEnrol.Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().adddays(1),'Scheduled',ConstantsClass.groupLessonBookingRecordType,ConstantsClass.typeMakeup,false));
        listOfcreateBooking[0].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[0].Available_Make_up_Units__c = 1;
        listOfcreateBooking[0].Make_up_Utilize_Bookings__c = listOfBooking[0].Id + '-30;'+ listOfBooking[1].Id + '-30';
        
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,objEnrol.Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().addDays(15).adddays(7),ConstantsClass.statusCanceled,ConstantsClass.groupLessonBookingRecordType,ConstantsClass.groupLessonTypeBooking,false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,objEnrol.Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,system.today().addMonths(-1).adddays(7),ConstantsClass.statusCanceled,ConstantsClass.groupLessonBookingRecordType,ConstantsClass.groupLessonTypeBooking,false));
        
        listOfcreateBooking[1].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[1].Available_Make_up_Units__c = 1;
        listOfcreateBooking[2].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[2].Available_Make_up_Units__c = 1;
        
        upsert  listOfcreateBooking;
        UpdateEnrolmentClassProcessController.deductMakeupHours(new set<id>{listOfcreateBooking[0].id},objEnrol.Student__c,objEnrol.id);
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
         List<Subscription_Line_Item__c> listOfSubscriptionitem = [Select id,Next_Bill_Date__c from Subscription_Line_Item__c  where Enrolment__c=:listOfBooking[0].Enrolment__c];
       
        List<case> listOfcase = [select id,Type from case];
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        listOfSubscriptionitem[0].Next_Bill_Date__c =  Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
        update listOfSubscriptionitem[0];
        test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        
        ClassEditController.upgradePackageClassOfCustomer(listOfBooking[0].id,system.today().month()+'/' + system.today().day()+'/'+ system.today().year(), listOfPackage[0].id, 
                                                          listOfBooking[0].Package__c,'7:00:00 PM',listOfcase[0].id,'true', mapOfCaseValues,
                                                          classList[0].id,classList[1].id, listOfBooking[0].Teacher_Account__c);
        test.stopTest();
    }
    public static TestMethod void test_upgradePackageClassOfCustomer2(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType]; 
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c,Booking_Date__c from Booking__c Where class__C != null and Booking_Date__c >:listOfBooking[0].Booking_Date__c.addMonths(1)];
        Booking__C objBooking = new Booking__C(id=listOfBooking[0].id,
                                               Status__c = ConstantsClass.statusCanceled,
                                               Available_Make_up_Units__c =30,
                                               Make_up_Expiry_Date__c = system.today(),
                                               Type__c = ConstantsClass.groupLessonTypeBooking,
                                               enrolment__C = listOfBooking[0].enrolment__C,
                                               Booking_Date__c = listGroupClassBooking[0].Booking_Date__c);
        update objBooking;
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c where id=:listOfBooking[0].enrolment__C limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        LIst<class__c> classList =  [select id from Class__C];
        List<case> listOfcase = [select id,Type from case];
        
        test.startTest(); 
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        String bookingRecurringJson = '{"groupClassId":"'+listOfBooking[0].id+'","studentId":"'+objEnrol.Student__c+'","packageId":"'+objEnrol.Package__c+'","type":"Group Lesson","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"'+string.valueOf(listGroupClassBooking[0].Booking_Date__c)+'T15:00:00","centerId":"'+objEnrol.Center__c+'","teacherId":"'+objEnrol.Teacher__c+'"}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        
        ClassEditController.upgradePackageClassOfCustomer(listOfBooking[0].id,(listGroupClassBooking[0].Booking_Date__c.month())+'/' +  listGroupClassBooking[0].Booking_Date__c.day()+'/'+ listGroupClassBooking[0].Booking_Date__c.year(), listOfPackage[0].id, 
                                                          listOfBooking[0].Package__c,'7:00:00 PM',listOfcase[0].id,'true', mapOfCaseValues,
                                                          classList[0].id,classList[1].id, listOfBooking[0].Teacher_Account__c);
        ClassEditController.createGroupbooking(bookingRecurringJson, 'false', listOfcase[0].Id);
        
        test.stopTest();
    }
     public static TestMethod void test_upgradePackageClassOfCustomer3(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType]; 
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c,Booking_Date__c from Booking__c Where class__C != null and Booking_Date__c >:listOfBooking[0].Booking_Date__c.addMonths(1)];
        Booking__C objBooking = new Booking__C(id=listOfBooking[0].id,
                                               Status__c = ConstantsClass.statusCanceled,
                                               Available_Make_up_Units__c =30,
                                               Make_up_Expiry_Date__c = system.today(),
                                               Type__c = ConstantsClass.groupLessonTypeBooking,
                                               enrolment__C = listOfBooking[0].enrolment__C,
                                               Booking_Date__c = listGroupClassBooking[0].Booking_Date__c);
        update objBooking;
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c where id=:listOfBooking[0].enrolment__C limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        LIst<class__c> classList =  [select id from Class__C];
        List<case> listOfcase = [select id,Type from case];
        test.startTest(); 
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        String bookingRecurringJson = '{"groupClassId":"'+listOfBooking[0].id+'","studentId":"'+objEnrol.Student__c+'","packageId":"'+objEnrol.Package__c+'","type":"Group Lesson","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"'+string.valueOf(listGroupClassBooking[0].Booking_Date__c)+'T15:00:00","centerId":"'+objEnrol.Center__c+'","teacherId":"'+objEnrol.Teacher__c+'"}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        
        ClassEditController.upgradePackageClassOfCustomer(listOfBooking[0].id,(listGroupClassBooking[0].Booking_Date__c.month())+'/' +  listGroupClassBooking[0].Booking_Date__c.day()+'/'+ listGroupClassBooking[0].Booking_Date__c.year(), listOfPackage[0].id, 
                                                          listOfBooking[0].Package__c,'7:00:00 PM',listOfcase[0].id,'true', mapOfCaseValues,
                                                          classList[0].id,classList[0].id, listOfBooking[0].Teacher_Account__c);
         ClassEditController.createGroupbooking(bookingRecurringJson, 'false', listOfcase[0].Id);
         List<Booking__c> listOfcreateBooking = new List<Booking__c>();
         listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,objEnrol.Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                  listOfBooking[0].Package__c,date.today().adddays(1),'Scheduled',ConstantsClass.groupLessonBookingRecordType,ConstantsClass.typeMakeup,false));
         listOfcreateBooking[0].Make_up_Expiry_Date__c = System.today();
         listOfcreateBooking[0].Available_Make_up_Units__c = 1;
         listOfcreateBooking[0].Make_up_Utilize_Bookings__c = listOfBooking[0].Id + '-30;'+ listOfBooking[1].Id + '-30';
         
         listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,objEnrol.Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                  listOfBooking[0].Package__c,date.today().addDays(15).adddays(7),ConstantsClass.statusCanceled,ConstantsClass.groupLessonBookingRecordType,ConstantsClass.groupLessonTypeBooking,false));
         listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,objEnrol.Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                  listOfBooking[0].Package__c,system.today().addMonths(-1).adddays(7),ConstantsClass.statusCanceled,ConstantsClass.groupLessonBookingRecordType,ConstantsClass.groupLessonTypeBooking,false));
         
         listOfcreateBooking[1].Make_up_Expiry_Date__c = System.today();
         listOfcreateBooking[1].Available_Make_up_Units__c = 1;
         listOfcreateBooking[2].Make_up_Expiry_Date__c = System.today();
         listOfcreateBooking[2].Available_Make_up_Units__c = 1;
         
         upsert  listOfcreateBooking;
         UpgradeEnrolmentClassProcessController.deductMakeupHours(new set<id>{listOfcreateBooking[0].id},objEnrol.Student__c,objEnrol.id);
        test.stopTest();
    }
    public static TestMethod void test_upgradeToIndividualClassOfCustomer(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType]; 
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c,Booking_Date__c from Booking__c Where class__C != null and Booking_Date__c >:listOfBooking[0].Booking_Date__c.addMonths(1)];
        
        Booking__C objBooking = new Booking__C(id=listOfBooking[0].id,
                                               Status__c = ConstantsClass.statusCanceled,
                                               Available_Make_up_Units__c =30,
                                               Make_up_Expiry_Date__c = system.today(),
                                               Type__c = ConstantsClass.groupLessonTypeBooking,
                                               enrolment__C = listOfBooking[0].enrolment__C,
                                               Booking_Date__c = listGroupClassBooking[0].Booking_Date__c);
        update objBooking;    
        Enrolment__c objEnrol = [select id,Center__c,Center__r.Country__c,Center__r.Organisation__c, Teacher__c,Package__c,Student__c from Enrolment__c where id=:listOfBooking[0].enrolment__C limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        List<case> listOfcase = [select id,Type from case];
        LIst<class__c> classList =  [select id from Class__C];
        test.startTest();
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        String bookingRecurringJson = '{"groupClassId":"'+listOfBooking[1].id+'","studentId":"'+objEnrol.Student__c+'","packageId":"'+objEnrol.Package__c+'","type":"Group Lesson","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"'+string.valueOf(listGroupClassBooking[0].Booking_Date__c)+'T15:00:00","centerId":"'+objEnrol.Center__c+'","teacherId":"'+objEnrol.Teacher__c+'"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        ClassEditController.upgradeToIndividualClassOfCustomer(listOfBooking[0].id,(listGroupClassBooking[0].Booking_Date__c.month())+'/' +  listGroupClassBooking[0].Booking_Date__c.day()+'/'+ listGroupClassBooking[0].Booking_Date__c.year(), listOfPackage[0].id, 
                                                               listOfBooking[0].Package__c,'7:00:00 PM',listOfcase[0].id,'true', mapOfCaseValues,
                                                               listOfBooking[0].Teacher_Account__c,listOfteacher[0].id);
        ClassEditController.createGroupbooking(bookingRecurringJson, 'false', listOfcase[0].Id);
        test.stopTest();
    }
    public static TestMethod void test_upgradeToIndividualClassOfCustomer2(){
        Enrolment__c objEnrol = [select id,Center__c,Center__r.Organisation__c,Center__r.Country__c,Teacher__c,Package__c,Student__c from Enrolment__c limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        Leave_Request__c request = new Leave_Request__c(Employee__c = listOfteacher[0].Id, Leave_End_Date__c = System.today().addDays(14), 
                                                        Leave_Start_Date__c = System.today().addDays(14), Leave_Type__c = 'Teacher MC',
                                                        Status__c = 'Approved');
        INSERT request;
        
        Public_Holiday__c holiday = new Public_Holiday__c(Country__c = objEnrol.Center__r.Country__c, Execution_Date__c = System.today(), Organisation_Status__c = 'Closed',
                                                          Public_Holiday_Date__c = System.today().addDays(7), Status__c = 'Execution completed', Organisation__c = objEnrol.Center__r.Organisation__c);
        INSERT holiday;
        test.startTest(); 
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType and enrolment__C=:objEnrol.id ]; 
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        
        
        ClassEditController.upgradeToIndividualClassOfCustomer(listOfBooking[0].id,system.today().month()+'/' + system.today().day()+'/'+ system.today().year(), listOfPackage[0].id, 
                                                               listOfBooking[0].Package__c,'7:00:00 PM','','true', mapOfCaseValues,
                                                               listOfBooking[0].Teacher_Account__c,listOfteacher[0].id);
        test.stopTest();
    }
    public static TestMethod void test_upgradeToIndividualClassOfCustomer3(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType]; 
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c,Booking_Date__c from Booking__c Where class__C != null and Booking_Date__c >:listOfBooking[0].Booking_Date__c.addMonths(1)];
        List<Subscription_Line_Item__c> listOfSubscriptionitem = [Select id,Next_Bill_Date__c from Subscription_Line_Item__c  where Enrolment__c=:listOfBooking[0].Enrolment__c];
        
        Booking__C objBooking = new Booking__C(id=listOfBooking[0].id,
                                               Status__c = ConstantsClass.statusCanceled,
                                               Available_Make_up_Units__c =30,
                                               Make_up_Expiry_Date__c = system.today(),
                                               Type__c = ConstantsClass.groupLessonTypeBooking,
                                               enrolment__C = listOfBooking[0].enrolment__C,
                                               Booking_Date__c = listGroupClassBooking[0].Booking_Date__c);
        update objBooking;  
        listOfSubscriptionitem[0].Next_Bill_Date__c =  Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
        update listOfSubscriptionitem[0];
        Enrolment__c objEnrol = [select id,Center__c,Center__r.Country__c,Center__r.Organisation__c, Teacher__c,Package__c,Student__c from Enrolment__c where id=:listOfBooking[0].enrolment__C limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        List<case> listOfcase = [select id,Type from case];
        LIst<class__c> classList =  [select id from Class__C];
        test.startTest();
        Map<String, String> mapOfCaseValues = new Map<String, String>();
        mapOfCaseValues.put('previousPackage', 'Demo Previous Package');
        mapOfCaseValues.put('newPackage', 'Demo New Package');
        mapOfCaseValues.put('previousLessonDayTime', 'Wednesday, 10:00 AM 2019');
        mapOfCaseValues.put('newLessonDayTime', 'Wednesday, 11:00 AM 2019');
        mapOfCaseValues.put('currentDepositonFile', '0.0');
        mapOfCaseValues.put('newPackageDeposit', '5.0');
        mapOfCaseValues.put('invoiceForCurrentMonth', '0.0');
        String bookingRecurringJson = '{"groupClassId":"'+listOfBooking[1].id+'","studentId":"'+objEnrol.Student__c+'","packageId":"'+objEnrol.Package__c+'","type":"Group Lesson","duration":"30","Repeat":"Weeks","isRecurring":"false","RepeatEvery":"1", "EndsAfter":"1","date":"'+string.valueOf(listGroupClassBooking[0].Booking_Date__c)+'T15:00:00","centerId":"'+objEnrol.Center__c+'","teacherId":"'+objEnrol.Teacher__c+'"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        ClassEditController.upgradeToIndividualClassOfCustomer(listOfBooking[0].id,(listGroupClassBooking[0].Booking_Date__c.month())+'/' +  listGroupClassBooking[0].Booking_Date__c.day()+'/'+ listGroupClassBooking[0].Booking_Date__c.year(), listOfPackage[0].id, 
                                                               listOfBooking[0].Package__c,'7:00:00 PM',listOfcase[0].id,'true', mapOfCaseValues,
                                                               listOfBooking[0].Teacher_Account__c,listOfteacher[0].id);
        ClassEditController.createGroupbooking(bookingRecurringJson, 'false', listOfcase[0].Id);
        test.stopTest();
    }
    // added by nishi: 25-Sep-2020: for cover some changes functions
    public static TestMethod void test_newOssiaChangesCoverage(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType and  type__c !='busy' ]; 
        List<Booking__c> listOfBusyBooking = [select id,Teacher_Account__c  from Booking__c where type__c ='busy' ];
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c where id=:listOfBooking[0].enrolment__C limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        LIst<class__c> classList =  [select id from Class__C];
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c,Booking_Date__c from Booking__c Where class__C != null and Booking_Date__c >:listOfBooking[0].Booking_Date__c.addMonths(1)];
        List<case> listOfcase = [select id,Type from case];
        test.startTest(); 
        Map<String, Object> bookingReschedule= new Map<String, Object> ();
        bookingReschedule.put('Id',listOfBooking[0].id);
        bookingReschedule.put('date',system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'));
        bookingReschedule.put('isRecurring', 'true');
        bookingReschedule.put('Repeat','Weeks');
        bookingReschedule.put('RepeatEvery', '1');
        bookingReschedule.put('EndsAfter', '1');
        bookingReschedule.put('resource',listOfteacher[0].id);
        TestUtil.createAttachment(listOfteacher[0].id,true);
        ClassEditController.showRescheduledGroupClassBookings(bookingReschedule);
        ClassEditController.updateGroupClassBooking(listOfBooking[0].id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                                    system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),listOfBooking[0].Teacher_Account__c,'True','true');
        
        ClassEditController.updateGroupClassBooking(listOfBusyBooking[0].id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                                    system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),listOfteacher[0].Id,'True','true');
        
        ClassEditController.updateGroupClassBooking(listOfBooking[1].id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                                    system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),listOfBooking[0].Teacher_Account__c,'True','false');
        ClassEditController.updateGroupClassBooking(listOfBooking[1].id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                                    system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),listOfBooking[0].Teacher_Account__c,'True','false');
        ClassEditController.getWithdrawGroupClassSummary(listOfBooking[0].Id, String.valueOf(System.today()), String.valueOf(System.today().addDays(3)));
        test.stopTest();
    }
    
     // added by nishi: 25-Sep-2020: for cover some Reschedule  For All Future Group Class Bookings changes functions
    public static TestMethod void test_RescheduleForAllFutureGroupClassBookings(){
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType and  type__c !='busy' ]; 
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c,Center__r.Organisation__c,Center__r.Country__c from Enrolment__c where id=:listOfBooking[0].enrolment__C limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        LIst<class__c> classList =  [select id from Class__C];
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c,Booking_Date__c,Type__c from Booking__c Where
                                                  class__C != null and Booking_Date__c >:listOfBooking[0].Booking_Date__c.addMonths(1)
                                                  and Type__c =: ConstantsClass.groupTypeBooking];
        List<case> listOfcase = [select id,Type from case];
        test.startTest();
        Leave_Request__c request = new Leave_Request__c(Employee__c = listOfteacher[0].Id, Leave_End_Date__c = System.today().addDays(14), 
                                                        Leave_Start_Date__c = System.today().addDays(14), Leave_Type__c = 'Teacher MC',
                                                        Status__c = 'Approved');
        INSERT request;
        
        Public_Holiday__c holiday = new Public_Holiday__c(Country__c = objEnrol.Center__r.Country__c, Execution_Date__c = System.today(), 
                                                          Organisation_Status__c = 'Closed',
                                                          Public_Holiday_Date__c = System.today().addDays(7), Status__c = 'Execution completed',
                                                          Organisation__c = objEnrol.Center__r.Organisation__c);
        INSERT holiday;
        List<Booking__c> listOfcreateBooking = new List<Booking__c>();
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,objEnrol.Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().adddays(1),'Scheduled',ConstantsClass.groupLessonBookingRecordType,ConstantsClass.typeMakeup,false));
        listOfcreateBooking[0].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[0].Available_Make_up_Units__c = 1;
        listOfcreateBooking[0].Make_up_Utilize_Bookings__c = listOfBooking[0].Id + '-30;'+ listOfBooking[1].Id + '-30';
        
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,objEnrol.Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().addDays(15).adddays(7),ConstantsClass.statusCanceled,ConstantsClass.groupLessonBookingRecordType,ConstantsClass.groupLessonTypeBooking,false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,objEnrol.Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,system.today().addMonths(-1).adddays(7),ConstantsClass.statusCanceled,ConstantsClass.groupLessonBookingRecordType,ConstantsClass.groupLessonTypeBooking,false));
        
        listOfcreateBooking[1].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[1].Available_Make_up_Units__c = 1;
        listOfcreateBooking[2].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[2].Available_Make_up_Units__c = 1;
        
        upsert  listOfcreateBooking;
         
        ClassEditController.updateGroupClassBooking(listGroupClassBooking[0].id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                                    system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),listOfBooking[0].Teacher_Account__c,'True','true');
        ClassEditController.updateGroupClassBooking(listGroupClassBooking[0].id,system.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                                    system.now().adddays(2).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),listOfteacher[0].Id,'True','true');
        test.stopTest();
    }
     // added by nishi: 25-Sep-2020: for cover some Reschedule  For All Future Group Class Bookings changes functions
    public static TestMethod void test_ReschedulesameDay(){
        LIst<class__c> classList =  [select id from Class__C];
        Enrolment__c objEnrol = [select id,Center__c,Teacher__c,Package__c,Student__c from Enrolment__c where class__C=:classList[0].id limit 1];
        List<account> listOfteacher = [select id from account where id !=: objEnrol.Teacher__c and recordType.name='Teacher'];
        List<Package__c> listOfPackage = [select id from Package__c where id !=: objEnrol.Package__c];
        List<Booking__c> listGroupClassBooking = [select Id,enrolment__C,center__c,Booking_Date__c,Type__c from Booking__c Where
                                                  class__C =: classList[0].id 
                                                  and Type__c =: ConstantsClass.groupTypeBooking];
        List<Booking__c> listOfBooking = [SELECT Id,center__c,Teacher_Account__c,Package__c,Enrolment__c,Enrolment__r.Package__r.Name,Package__r.name,Booking_Date__c,parent__C,Group_class__C
                                          FROM Booking__c  where RecordType.name =:ConstantsClass.groupLessonBookingRecordType and  type__c !='busy'
                                          and Enrolment__c=:objEnrol.id];
        List<case> listOfcase = [select id,Type from case];
        List<Booking__c> listOfcreateBooking = new List<Booking__c>();
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,objEnrol.Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().adddays(1),'Scheduled',ConstantsClass.groupLessonBookingRecordType,ConstantsClass.typeMakeup,false));
        listOfcreateBooking[0].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[0].Available_Make_up_Units__c = 1;
        listOfcreateBooking[0].Make_up_Utilize_Bookings__c = listOfBooking[0].Id + '-30;'+ listOfBooking[1].Id + '-30';
        listOfcreateBooking[0].id =listOfBooking[0].id;
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,objEnrol.Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,date.today().addDays(15).adddays(7),ConstantsClass.statusCanceled,ConstantsClass.groupLessonBookingRecordType,ConstantsClass.groupLessonTypeBooking,false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(listOfBooking[0].Teacher_Account__c,objEnrol.Id,listOfBooking[0].parent__c,listOfBooking[0].center__c,
                                                                                 listOfBooking[0].Package__c,system.today().addMonths(-1).adddays(7),ConstantsClass.statusCanceled,ConstantsClass.groupLessonBookingRecordType,ConstantsClass.groupLessonTypeBooking,false));
        
        listOfcreateBooking[1].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[1].Available_Make_up_Units__c = 1;
        listOfcreateBooking[1].id =listOfBooking[1].id;
        listOfcreateBooking[2].Make_up_Expiry_Date__c = System.today();
        listOfcreateBooking[2].Available_Make_up_Units__c = 1;
        
        listOfcreateBooking[2].id =listOfBooking[2].id;        
        upsert  listOfcreateBooking;
        test.startTest(); 
        TestUtil.createAttachment(listOfteacher[0].id,true);
        
        ClassEditController.updateGroupClassBooking(listGroupClassBooking[0].id,datetime.newInstance(listGroupClassBooking[0].Booking_Date__c, time.newInstance(12,00,00,00)).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                                    system.now().adddays(1).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),listOfBooking[0].Teacher_Account__c,'True','true');
        ClassEditController.updateGroupClassBooking(listGroupClassBooking[0].id,datetime.newInstance(listGroupClassBooking[0].Booking_Date__c, time.newInstance(12,00,00,00)).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),
                                                    datetime.newInstance(listGroupClassBooking[0].Booking_Date__c, time.newInstance(12,00,00,00)).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss'),listOfteacher[0].Id,'True','true');
        test.stopTest();
    }
}