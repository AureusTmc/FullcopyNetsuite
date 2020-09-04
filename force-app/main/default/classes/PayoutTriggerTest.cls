@isTest
public class PayoutTriggerTest {
    
    public static testMethod void util1(){
         Account acc =new Account();
        acc.Name = 'test';
        insert acc;
        
        Payout__c payout = new Payout__c();
        payout.Total_Payable__c = 1000;
        payout.Employer_CPF_Amount__c = 1345;
        payout.Employee_Name__c = acc.id;
        insert payout;
        
    } 

}