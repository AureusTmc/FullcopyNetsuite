/*
Name        :        TaskSchedulerTest
Date        :        2 April 2019
Author      :        Ravi
Description :        It is the test class of TaskScheduler.
*/

@isTest
public class TaskSchedulerTest {
    public static TestMethod Void invokeTaskScheduler(){
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User usr = new User(LastName = 'Singh',
                            FirstName='Karan',
                            Alias = 'Singh',
                            Email = 'Karan.liveston@asdf.com',
                            Username = 'Karan.liveston@asdf.com',
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        
        insert usr;
        System.runAs(usr){
            Case objCase=testUtil.createCase(false);
            objCase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get(ConstantsClass.caseSalesEnqRecTypeName).getRecordTypeId();
            objcase.Stage__c='Enquiry';
            objCase.Status='Open';
            objcase.Enquiry_Date__c=system.today().addDays(-1);
            objCase.Enrolment__c=testUtil.createEnrolment(true).id;
            objCase.OwnerId=usr.Id;
            insert objcase;
            system.debug('objcase.Enquiry_Date__c'+objcase.Enquiry_Date__c);
            TaskScheduler objTaskSchd= new TaskScheduler();
            objTaskSchd.execute(Null);
        }
        
    }
    
    public static TestMethod Void invokeTaskSchedulertwo(){
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User usr = new User(LastName = 'Singh',
                            FirstName='Karan',
                            Alias = 'Singh',
                            Email = 'Karan.liveston@asdf.com',
                            Username = 'Karan.liveston@asdf.com',
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        
        insert usr;
        System.runAs(usr){
            Case objCase=testUtil.createCase(false);
            objCase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get(ConstantsClass.caseSalesEnqRecTypeName).getRecordTypeId();
            objcase.Stage__c='Enquiry';
            objCase.Status='Open';
            objcase.Enquiry_Date__c=system.today().addDays(-2);
            objCase.Enrolment__c=testUtil.createEnrolment(true).id;
            objCase.OwnerId=usr.Id;
            insert objcase;
            system.debug('objcase.Enquiry_Date__c'+objcase.Enquiry_Date__c);
            TaskScheduler objTaskSchd= new TaskScheduler();
            objTaskSchd.execute(Null);
        }
        
    }
    
    public static TestMethod Void invokeTaskSchedulerFour(){
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User usr = new User(LastName = 'Singh',
                            FirstName='Karan',
                            Alias = 'Singh',
                            Email = 'Karan.liveston@asdf.com',
                            Username = 'Karan.liveston@asdf.com',
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        
        insert usr;
        System.runAs(usr){
            Case objCase=testUtil.createCase(false);
            objCase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get(ConstantsClass.caseSalesEnqRecTypeName).getRecordTypeId();
            objcase.Stage__c='Enquiry';
            objCase.Status='Open';
            objcase.Enquiry_Date__c=system.today().addDays(-4);
            objCase.Enrolment__c=testUtil.createEnrolment(true).id;
            objCase.OwnerId=usr.Id;
            insert objcase;
            system.debug('objcase.Enquiry_Date__c'+objcase.Enquiry_Date__c);
            TaskScheduler objTaskSchd= new TaskScheduler();
            objTaskSchd.execute(Null);
        }
        
    }
    
     public static TestMethod Void invokeTaskSchedulerSeven(){
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User usr = new User(LastName = 'Singh',
                            FirstName='Karan',
                            Alias = 'Singh',
                            Email = 'Karan.liveston@asdf.com',
                            Username = 'Karan.liveston@asdf.com',
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        
        insert usr;
        System.runAs(usr){
            Case objCase=testUtil.createCase(false);
            objCase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get(ConstantsClass.caseSalesEnqRecTypeName).getRecordTypeId();
            objcase.Stage__c='Enquiry';
            objCase.Status='Open';
            objcase.Enquiry_Date__c=system.today().addDays(-7);
            objCase.Enrolment__c=testUtil.createEnrolment(true).id;
            objCase.OwnerId=usr.Id;
            insert objcase;
            system.debug('objcase.Enquiry_Date__c'+objcase.Enquiry_Date__c);
            TaskScheduler objTaskSchd= new TaskScheduler();
            objTaskSchd.execute(Null);
        }
        
    }
    
    
     public static TestMethod Void invokeTaskSchedulerTen(){
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User usr = new User(LastName = 'Singh',
                            FirstName='Karan',
                            Alias = 'Singh',
                            Email = 'Karan.liveston@asdf.com',
                            Username = 'Karan.liveston@asdf.com',
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        
        insert usr;
        System.runAs(usr){
            Case objCase=testUtil.createCase(false);
            objCase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get(ConstantsClass.caseSalesEnqRecTypeName).getRecordTypeId();
            objcase.Stage__c='Enquiry';
            objCase.Status='Open';
            objcase.Enquiry_Date__c=system.today().addDays(-10);
            objCase.Enrolment__c=testUtil.createEnrolment(true).id;
            objCase.OwnerId=usr.Id;
            insert objcase;
            system.debug('objcase.Enquiry_Date__c'+objcase.Enquiry_Date__c);
            TaskScheduler objTaskSchd= new TaskScheduler();
            objTaskSchd.execute(Null);
        }
        
    }
    
    
    
}