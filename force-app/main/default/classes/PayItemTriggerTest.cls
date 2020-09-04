@isTest
public class PayItemTriggerTest{
    @isTest
    public static void unitTest(){
        Account objAcc1 = new Account();
        string centerRecordType =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId();
        objAcc1.name='testCenter';
        objAcc1.CentreName_Cust__c='testCenter'; 
        objAcc1.Travel_Time__c=60.00;
        objAcc1.Location__c='Aureus Forum';
        objAcc1.Center_Email__c='test@techmatrixconsulting.com';
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
        insert objAcc;   
        
        
        Payitem_Master__c pim = new Payitem_Master__c(
            Active__c = true,
            CPF__c = 'Non-CPF',
            Name = 'NS Make-up Pay'
        );
        insert pim;
        Payout__c pay = new Payout__c();
        insert pay;
        Test.StartTest();
        PayItem__c pitm = new PayItem__c (
            Amount__c = 12,
            CPF__c = 'Non-CPF',
            No_of_Days__c = 1,
            Payitem__c = pim.Id,
            Payout__c = pay.Id
        );
        insert pitm ;
        Test.StopTest();
    }
}