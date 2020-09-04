/**
* Name: TerminationEnrolmentProcessTest
* Author: Jatin
* Date : 16-March-2020
* Description: this class Used to test TerminationEnrolmentProcessController controller class
*/
@isTest
public class TerminationEnrolmentProcessTest {
    
    @testSetup
    private static void createData(){
        PianoRentalTestHelper.createPianoRentalData();
    }
    private static testMethod  void testTerminationEnrolment(){
        
        list<Enrolment__c> lstEnrolments = [SELECT Id FROM Enrolment__c];
        
        ApexPages.StandardController objStandarCon = new ApexPages.StandardController(lstEnrolments[0]);
        TerminationEnrolmentProcessController objTerminationEnrolment = new TerminationEnrolmentProcessController(objStandarCon);
        objTerminationEnrolment.getTerminationReason();
    }
    private static testMethod  void testTerminationEnrolment2(){
        list<Enrolment__c> lstEnrolments = [SELECT Id,(SELECT Id, Subscription_Start_Date__c, Name FROM Subscription_Line_Items__r) FROM Enrolment__c];
        list<Subscription_Line_Item__c> lstSubscription  = new list<Subscription_Line_Item__c>();
        
        for(Enrolment__c objEnrolment :lstEnrolments){
            for(Subscription_Line_Item__c objSubscription :objEnrolment.Subscription_Line_Items__r){
                objSubscription.Subscription_Start_Date__c = Null;
                lstSubscription.add(objSubscription);
            }
        }
        update lstSubscription;
        ApexPages.StandardController objStandarCon = new ApexPages.StandardController(lstEnrolments[0]);
        TerminationEnrolmentProcessController objTerminationEnrolment = new TerminationEnrolmentProcessController(objStandarCon);
        delete lstSubscription;
        
        objStandarCon = new ApexPages.StandardController(lstEnrolments[0]);
        objTerminationEnrolment = new TerminationEnrolmentProcessController(objStandarCon);
        objTerminationEnrolment.TerminationReasonName ='';
    }
}