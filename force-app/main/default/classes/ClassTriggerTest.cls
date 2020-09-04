/*
Name        :        ClassTriggerTest
Date        :        14 -Mar- 2020 
Author      :        Jatin
Description :        It is the test class of ClassTrigger and ClassTriggerHelper for code coverage.
*/
@isTest
public class ClassTriggerTest {
    @testSetup 
    Private static void createData(){
        ClassEditControllerTestHelper.createGroupClassData();
    }  
    Private Static TestMethod void test_fetchGroupLessonBookingDetails(){
        LIst<Package__c> listOfPackage =  [select id,Program__c from package__C ];
        LIst<class__c> classList =  [select id from Class__C];
        List<Account> teacherAccountList =  [select id from Account where RecordType.name='Teacher'];
        List<Account> ListCentre =  [select id from Account where RecordType.name='Centre'];
        List<Class__c > GroupClassList = new List<Class__C>();
        GroupClassList.add(AureusCalendarControllerTestHelper.createGroupClass('test Group Class5',listOfPackage[0].id,ListCentre[0].Id,listOfPackage[0].Program__c,date.today(),date.newInstance(date.today().year(),12,31),Time.newInstance(11,0,0,0),Time.newInstance(11,30,0,0),teacherAccountList[0].Id,false));
        GroupClassList.add(AureusCalendarControllerTestHelper.createGroupClass('test Group Class6',listOfPackage[2].id,ListCentre[1].Id,listOfPackage[0].Program__c,date.today().addMonths(1),date.newInstance(date.today().year(),12,31),Time.newInstance(12,0,0,0),Time.newInstance(12,45,0,0),teacherAccountList[1].Id,false));
        GroupClassList.add(AureusCalendarControllerTestHelper.createGroupClass('test Group Class7',listOfPackage[1].id,ListCentre[1].Id,listOfPackage[0].Program__c,date.today().addMonths(-1),date.newInstance(date.today().year(),12,31),Time.newInstance(13,0,0,0),Time.newInstance(13,15,0,0),teacherAccountList[1].Id,false));
        GroupClassList.add(AureusCalendarControllerTestHelper.createGroupClass('test Group Class8',listOfPackage[3].id,ListCentre[1].Id,listOfPackage[0].Program__c,date.today().addMonths(2),date.newInstance(date.today().year(),12,31),Time.newInstance(14,0,0,0),Time.newInstance(15,0,0,0),teacherAccountList[1].Id,false));
        GroupClassList[0].Class_End_Date__c = null;
        insert GroupClassList;
        
    }
}