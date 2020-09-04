/*
Name        :        PackageTriggerTest
Date        :        25 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class for PackageTrigger.
*/

@isTest
public class PackageTriggerTest {
    public Static TestMethod Void invokePackageTrigger(){
        Account centr = new Account();
        centr.RecordTypeId =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId();
        centr.name='testCenter';
        centr.CentreName_Cust__c='testCenter'; 
        centr.Travel_Time__c=60.00;
        centr.Location__c='Aureus Forum';
        insert centr;
        
        Program__c prog =new Program__C();
        prog.Name='testProg';
        prog.Status__c='Active';
        prog.Instrument__c='Piano';
        prog.Billing__c='Monthly';
        prog.Scheduling__c='Monthly';
        insert prog;
        
        Package__c pack=new Package__c();
        pack.Name='Piano';
        pack.Program__c=prog.Id;
        pack.Location__c=centr.Id;
        pack.Duration__c='60';
        pack.Package_Fee__c=05.00;
        pack.Active__c=true;
        pack.Unit_Fee__c=05.00;
        pack.Registration_Fee__c=08.00;
        pack.Deposit_Fee__c=08.00;
        insert pack;
        
        Subscription__C objSubs=new Subscription__C();
        insert objSubs;
        
        Subscription_Line_Item__C objSLI=new Subscription_Line_Item__C();
        objSLI.Plan_Package__c=pack.Id;
        objSLI.Subscription__c=objSubs.Id;
        insert objSLI;
        
        pack.Package_Fee__c=010.00;
        
        update pack;
        
        
    }
}