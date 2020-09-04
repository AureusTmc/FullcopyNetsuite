@isTest
public class RevenueCommissionTriggerTest{
    @isTest
    public static void unitTest(){
        Account objAcc1 = new Account();
        string centerRecordType =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId();
        objAcc1.name='testCenter';
        objAcc1.CentreName_Cust__c='testCenter'; 
        objAcc1.Travel_Time__c=60.00;
        objAcc1.Location__c='Aureus Forum';
        objAcc1.Center_Email__c='rajesh@techmatrixconsulting.com';
        objAcc1.Centre_Status__c='Active';
        insert objAcc1;
        
        Account objAcc = new Account();
        string s=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
        objAcc.RecordTypeId =s; 
        objAcc.LastName='testEmployee';
        objAcc.Teacher_Bio__c='testbio';
        objAcc.CentreName_Cust__c='testCenter';
        objAcc.Status__c='Working';   
        objAcc.Employee_Status__c = 'Confirm';
        objAcc.Main_Centre__c = objAcc1.Id;
        objAcc.Joining_Date__c = Date.Today().addDays(-10);
        objAcc.Last_Working_Date__c = Date.today().addDays(10);
        objAcc.Issue_Date__c = Date.Today().addDays(-30);
        objAcc.ID_Type__c = 'Permanent Resident';
        objAcc.PersonBirthdate = date.today().addYears(-30);
        objAcc.Payout_Type__c='Commission';
        objAcc.Individual_Commission__c  = 12;
        objAcc.Employee_Duty_Type__c = 'Duty';
        objAcc.Group_Commission__c = 1;
        insert objAcc; 
        
        // Employee work week
        Revenue_Commission__c rc = new Revenue_Commission__c(
            Month__c = DateTime.Now().format('MMMMM'),
            Employee__c = objAcc.Id,
            Individual_Revenue__c = 321,
            Year__c = DateTime.Now().format('YYYY'),
            Group_Revenue__c = 1
        );
        
        Payitem_Master__c pim = new Payitem_Master__c(
            Active__c = true,
            CPF__c = 'Non-CPF',
            Name = 'Individual Commission (OW)'
        );
        insert pim;
        Payitem_Master__c pim2 = new Payitem_Master__c(
            Active__c = true,
            CPF__c = 'Non-CPF',
            Name = 'Group Commission (OW)'
        );
        insert pim2;
        Payout__c pay = new Payout__c(Employee_Name__c = objAcc.Id, Month__c = DateTime.Now().format('MMMMM'), Year__c = DateTime.Now().format('YYYY'));
        insert pay;
        PayItem__c pitm = new PayItem__c (
            Amount__c = 12,
            CPF__c = 'Non-CPF',
            No_of_Days__c = 1,
            Payitem__c = pim.Id,
            Payout__c = pay.Id,
            System_Generated__c = true,
            Value__c = 12
        );
        insert pitm ;
        PayItem__c pitm2 = new PayItem__c (
            Amount__c = 12,
            CPF__c = 'Non-CPF',
            No_of_Days__c = 1,
            Payitem__c = pim2.Id,
            Payout__c = pay.Id,
            System_Generated__c = true,
            Value__c = 12
        );
        insert pitm2;
        
        Test.StartTest();
        database.insert(rc, false) ;
        
        rc.Individual_Revenue__c = 0;
        database.update(rc, false);
        Test.StopTest();
    }
}