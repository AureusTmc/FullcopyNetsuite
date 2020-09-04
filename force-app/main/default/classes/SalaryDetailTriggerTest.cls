@isTest
public class SalaryDetailTriggerTest {
    @isTest
    public static void test(){
        Account acc =new Account();
        acc.Name = 'test';
        insert acc;

        Salary_Detail__c sal = new Salary_Detail__c();
        sal.Basic_Salary__c = 123;
        sal.Employee_Name__c = acc.id;
        //sal.Effective_Date__c = system.today();
        insert sal;
        
        sal.Basic_Salary__c=1234;
        sal.Effective_Date__c = system.today().addDays(2);
        update sal;
        

        try {
            Salary_Detail__c sal1 = new Salary_Detail__c();
            sal1.Basic_Salary__c = 123;
            sal1.Employee_Name__c = acc.id;
            sal1.Effective_Date__c = system.today().addDays(2);
            insert sal1;
        } catch (DMLException e) {
            //System.assert(e.getMessage().contains('expected message'), 'message=' + e.getMessage());
        }
        
    }
}