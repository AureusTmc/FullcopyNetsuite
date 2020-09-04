/*
Name        :        TrialNoShowTaskSchedulerTest
Date        :        21,22 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of TrialNoShowTaskScheduler.
*/

@isTest
public class TrialNoShowTaskSchedulerTest {
    public Static testMethod void invokeTrialNoShowTaskScheduler(){
         Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User usr = new User(LastName = 'Singh',
                            FirstName='Karan',
                            Alias = 'Singh',
                            Email = 'Karan1.liveston@asdf.com',
                            Username = 'Karan1.liveston@asdf.com',
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
            objcase.Stage__c='Trial No Show';
            objCase.Status='Open';
            objcase.Trial_No_Show_Date__c=system.today().addDays(-2);
            objCase.Enrolment__c=testUtil.createEnrolment(true).id;
            objCase.OwnerId=usr.Id;
            insert objcase;
            
           TrialNoShowTaskScheduler objTrialNoShow = new TrialNoShowTaskScheduler();
            objTrialNoShow.execute(Null);
        }
        
    }
    
    public Static testMethod void invokeTrialNoShowTaskScheduler2(){
         Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User usr = new User(LastName = 'Singh',
                            FirstName='Karan',
                            Alias = 'Singh',
                            Email = 'Karan1.liveston@asdf.com',
                            Username = 'Karan1.liveston@asdf.com',
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
            objcase.Stage__c='Trial No Show';
            objCase.Status='Open';
            objcase.Trial_No_Show_Date__c=system.today().addDays(-4);
            objCase.Enrolment__c=testUtil.createEnrolment(true).id;
            objCase.OwnerId=usr.Id;
            insert objcase;
            
           TrialNoShowTaskScheduler objTrialNoShow = new TrialNoShowTaskScheduler();
            objTrialNoShow.execute(Null);
        }
        
    }
    public Static testMethod void invokeTrialNoShowTaskScheduler3(){
         Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User usr = new User(LastName = 'Singh',
                            FirstName='Karan',
                            Alias = 'Singh',
                            Email = 'Karan1.liveston@asdf.com',
                            Username = 'Karan1.liveston@asdf.com',
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
            objcase.Stage__c='Trial No Show';
            objCase.Status='Open';
            objcase.Trial_No_Show_Date__c=system.today().addDays(-7);
            objCase.Enrolment__c=testUtil.createEnrolment(true).id;
            objCase.OwnerId=usr.Id;
            insert objcase;
            
           TrialNoShowTaskScheduler objTrialNoShow = new TrialNoShowTaskScheduler();
            objTrialNoShow.execute(Null);
        }
        
    }
     public Static testMethod void invokeTrialNoShowTaskScheduler4(){
         Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User usr = new User(LastName = 'Singh',
                            FirstName='Karan',
                            Alias = 'Singh',
                            Email = 'Karan1.liveston@asdf.com',
                            Username = 'Karan1.liveston@asdf.com',
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
            objcase.Stage__c='Trial No Show';
            objCase.Status='Open';
            objcase.Trial_No_Show_Date__c=system.today().addDays(-10);
            objCase.Enrolment__c=testUtil.createEnrolment(true).id;
            objCase.OwnerId=usr.Id;
            insert objcase;
            
           TrialNoShowTaskScheduler objTrialNoShow = new TrialNoShowTaskScheduler();
            objTrialNoShow.execute(Null);
        }
        
    }
}