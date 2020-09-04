/*
Name        :        LeadTriggerTest
Date        :        20 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of LeadTrigger.
*/
@isTest
public class LeadTriggerTest {
    public static testmethod void beforeAfterInsertInvokation(){
        Account objCntr=TestUtil.createAccount('Centre',False,true);
        Account objCustmr=Testutil.createAccount('Customer', false,true);
        Lead objLead=Testutil.createLead(objCntr.Location__c,'Website','testEmail@gmail.com',objCntr.Id,false);
        objLead.Location__c = 'Aureus Westgate';
        //objLead.Preferred_Session__c = 'Westgate';
        insert objLead;
        
        Lead objLead1=Testutil.createLead(objCntr.Location__c,'Website','testEmail@gmail.com',objCntr.Id,false);
        objLead1.Location__c = '';
        objLead1.Preferred_Session__c = '3 - 7 June (United Square)';
        insert objLead1;
    }
}