/*
Name        :        EnrolmentProcessStep1CntrlTest
Date        :        21 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of EnrolmentProcessStep1Cntrl.
*/

@isTest
public class EnrolmentProcessStep1CntrlTest {
    public static testMethod void invokeEnrolmentProcessStep1Cntrl(){
        Map<string,string> entrdDataMap=TestUtil.createData(); 
        Enrolment__c objEnr=[select Id, Name, Package__r.Name, Student__r.Name, Teacher__r.Name, Parent__r.Name, 
                             Parent__r.PersonEmail, Trial_Date__c,Type__c,Stage__c from Enrolment__c 
                             where id=:entrdDataMap.get('objEnrol')];
        objEnr.Type__c='Trial';
        objEnr.Stage__c='Attended';
        objEnr.Parent__r.PersonEmail='testEmail@gmail.com';
        update objEnr;
        EnrolmentProcessStep1Cntrl objEps= new EnrolmentProcessStep1Cntrl();
        objEps.userEmail='testEmail@gmail.com';
        objEps.fetchEnrolments();
        objEps.completeEnrolments();
    }
}