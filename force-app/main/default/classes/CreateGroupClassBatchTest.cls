/*
Name        :        ClassEditControllerTest
Date        :        11 -Mar- 2020 
Author      :        Jatin
Description :        It is the test class of CreateGroupClassBatch for code coverage .
*/
@isTest
public class CreateGroupClassBatchTest {
 @testSetup 
    Private static void createData(){
       ClassEditControllerTestHelper.createGroupClassData1();       
    }  
    
    Private Static TestMethod void test_CreateGroupClassBatch(){
         LIst<Package__c> listOfPackage =  [select id,Program__c from package__C ];
        LIst<class__c> classList =  [select id from Class__C];
        List<Account> teacherAccountList =  [select id from Account where RecordType.name='Teacher'];
        List<Account> ListCentre =  [select id from Account where RecordType.name='Centre'];
        Test.startTest();
        List<Class__c > GroupClassList = new List<Class__C>();
        GroupClassList.add(AureusCalendarControllerTestHelper.createGroupClass('test Group Class5',listOfPackage[0].id,ListCentre[0].Id,listOfPackage[0].Program__c,date.today(),date.newInstance(date.today().year(),12,31),Time.newInstance(11,0,0,0),Time.newInstance(11,30,0,0),teacherAccountList[0].Id,false));
        GroupClassList.add(AureusCalendarControllerTestHelper.createGroupClass('test Group Class6',listOfPackage[2].id,ListCentre[1].Id,listOfPackage[0].Program__c,date.today().addMonths(1),date.newInstance(date.today().year(),12,31),Time.newInstance(12,0,0,0),Time.newInstance(12,45,0,0),teacherAccountList[1].Id,false));
        GroupClassList.add(AureusCalendarControllerTestHelper.createGroupClass('test Group Class7',listOfPackage[1].id,ListCentre[1].Id,listOfPackage[0].Program__c,date.today().addMonths(-1),date.newInstance(date.today().year(),12,31),Time.newInstance(13,0,0,0),Time.newInstance(13,15,0,0),teacherAccountList[1].Id,false));
        GroupClassList.add(AureusCalendarControllerTestHelper.createGroupClass('test Group Class8',listOfPackage[3].id,ListCentre[1].Id,listOfPackage[0].Program__c,date.today().addMonths(2),date.newInstance(date.today().year(),12,31),Time.newInstance(14,0,0,0),Time.newInstance(15,0,0,0),teacherAccountList[1].Id,false));
        GroupClassList[0].Class_End_Date__c = null;
        insert GroupClassList;
        
        Database.executeBatch(new CreateGroupClassBatch(New Set<string>{GroupClassList[0].id},System.today()), 200);
        List<Booking__c> listOfGroupClassBooking = [select Id from Booking__C where Booking_date__c >=: date.newInstance(date.today().year(),12,31) ];
        system.assert(listOfGroupClassBooking.size() > 0, 'listOfGroupClassBooking'+listOfGroupClassBooking.size());
        //Created by Jatin 17March 2020
        String CRON_EXP = '0 0 0 15 3 ? *';
        
        String jobId = System.schedule('CreateGroupClassScheduler',  CRON_EXP, new CreateGroupClassScheduler());
        Test.stopTest();
        
    }
   
}