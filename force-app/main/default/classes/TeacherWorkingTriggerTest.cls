/*
Name        :        TeacherWorkingTriggerTest
Date        :        20 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of TeacherWorkingTrigger.
*/
@isTest
public class TeacherWorkingTriggerTest {
    @testSetup 
    Private static void createData(){
        AureusCalendarControllerTestHelper.createCalenderData();
    } 
    
    @isTest
    Private static void test1(){
        
        /*Account acc=new account();
acc.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
acc.LastName='testTeacher';
insert acc;       

Account objTeacher=TestUtil.createAccount('Teacher',False,true);
Account objCenter=TestUtil.createAccount('Centre',False,true);
List <Teacher_Working_Hour__c> listOfTeacherWorkingHours = new List <Teacher_Working_Hour__c>();
listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(objTeacher.id,objCenter.Id,True,False,7));
listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(objTeacher.id,objCenter.Id,True,true,2));
*/
        Country__c objCountry = AureusCalendarControllerTestHelper.createCountryRecord ('Singapore','SGD',true);
        List<Account> ListCentre = new List<Account>();
        ListCentre.add(AureusCalendarControllerTestHelper.createCentre('Aureus Northpoint', objCountry.Id,FALSE));
        ListCentre.add(AureusCalendarControllerTestHelper.createCentre('Aureus AMK Hub', objCountry.Id,FALSE));
        Insert ListCentre; 
        // Create 2 Teachers 
        List<Account> ListOfTeacherAccount = new List<Account>();
        ListOfTeacherAccount.add(testUtil.createAccount('Teacher',false,False));
        ListOfTeacherAccount.add(testUtil.createAccount('Teacher',false,False));
        ListOfTeacherAccount.add(testUtil.createAccount('Teacher',false,False));
        Insert ListOfTeacherAccount; 
        // Create Teacher Working Hours 
        List <Teacher_Working_Hour__c> listOfTeacherWorkingHours = new List <Teacher_Working_Hour__c>();
        listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(ListOfTeacherAccount[0].id,ListCentre[0].Id,True,False,7));
        listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(ListOfTeacherAccount[1].id,ListCentre[1].Id,True,False,7));
        listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(ListOfTeacherAccount[1].id,ListCentre[1].Id,True,true,1));
    }
    @isTest
    Private static void test2(){
        List<Account> listOfTeacher = [select id  from Account Where recordType.name='Teacher'];
        DateTime dateChange = DateTime.newInstance(system.today(), Time.newInstance(0, 0, 0, 0));
        List <Teacher_Working_Hour__c> listOfTeacherWorkingHours =[select id, Resource__c from Teacher_Working_Hour__c where Teacher_Name__c =: listOfTeacher[0].id and  Working_Day__c=: dateChange.format('EEE')];
        List<Resource__c> listOfResource = [select id,center__c  from Resource__c];
        List<Booking__c> listOfBooking = [select id,Teacher_Account__c,resource__C  from Booking__c where type__c !='busy' and Teacher_Account__c =:listOfTeacher[0].id];
        for(Booking__c objBook : listOfBooking){
            objBook.Lesson_Type__c='In Centre';
        }
        update listOfBooking;
        
       
        listOfTeacherWorkingHours[0].Resource__c = listOfResource[0].id;
        update listOfTeacherWorkingHours;
        
        listOfBooking = [select id,Teacher_Account__c  from Booking__c where type__c !='busy' and resource__C =:listOfResource[0].id and Teacher_Account__c =:listOfTeacher[0].id]; 
        system.assert(listOfBooking.size() >0 , listOfBooking.size());
        listOfTeacherWorkingHours[0].Resource__c = listOfResource[1].id;
        update listOfTeacherWorkingHours;
        
        listOfBooking = [select id,Teacher_Account__c  from Booking__c where type__c !='busy' and resource__C =:listOfResource[0].id and Teacher_Account__c =:listOfTeacher[0].id]; 
        system.assert(listOfBooking.size() ==0 , listOfBooking.size());
        listOfBooking = [select id,Teacher_Account__c  from Booking__c where type__c !='busy' and resource__C =:listOfResource[1].id and Teacher_Account__c=:listOfTeacher[0].id]; 
        system.assert(listOfBooking.size() >0 , listOfBooking.size());
    }
}