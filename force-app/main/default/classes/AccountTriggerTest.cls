@isTest
public class AccountTriggerTest {
    
    public static testMethod void testMethod1(){
        List<User> uList = [SELECT Id,Name FROM User Where id =: Label.B2BMA_Integration_UserId];
        if(uList.size() > 0){
            System.runAs(uList.get(0)){
                Account objCustmr=TestUtil.createAccount('Customer',True,True);
                objCustmr.PI_to_SF_Sync__pc = 'true';
                update objCustmr;
            }
        }
    }
    @isTest
    Private static void unitTest2(){
        Account objCustmr=TestUtil.createAccount('Customer',true,False);
        objCustmr.Employee_Status__c = 'Probation';
        objCustmr.Joining_Date__c = system.today();
        objCustmr.Employee_Duty_Type__c ='Duty';
        objCustmr.Job_Title__c = 'Chauffeur';
        insert objCustmr;
    }
    @isTest
    Private static void unitTest3(){
        try{
            Account objCustmr=TestUtil.createAccount('Customer',true,False);
            objCustmr.Employee_Status__c = 'Probation';
            insert objCustmr;
        }catch(exception e){
            
        }
    }
    @isTest
    Private static void unitTest4(){
        try{
            Account objCustmr=TestUtil.createAccount('Customer',true,False);
            objCustmr.Employee_Status__c = 'Probation';
            objCustmr.Joining_Date__c = system.today();
            insert objCustmr;
            objCustmr.Employee_Status__c = 'Confirm';
            update objCustmr;
        }catch(exception e){
            
        }
    }
    @isTest
    Private static void unitTest5(){
        try{
            Account objCustmr=TestUtil.createAccount('Customer',true,False);
            objCustmr.Employee_Status__c = 'Draft';
            objCustmr.Joining_Date__c = system.today();
            insert objCustmr;
            objCustmr.Employee_Status__c = 'Confirm';
            update objCustmr;
        }catch(exception e){
            
        }
    }
    
    @isTest
    Private static void unitTest6(){
        try{
            Account objCustmr=TestUtil.createAccount('Customer',true,False);
            objCustmr.Employee_Status__c = 'Draft';
            objCustmr.Joining_Date__c = system.today();
            objCustmr.Onboarding_Stage__c ='In Process';
            insert objCustmr;
            objCustmr.Onboarding_Stage__c = 'Completed';
            update objCustmr;
        }catch(exception e){
            
        }
    }
    
    @isTest
    Private static void unitTest7(){
        try{
            Account objCustmr=TestUtil.createAccount('Customer',true,False);
            objCustmr.Employee_Status__c = 'Draft';
            objCustmr.Joining_Date__c = system.today();
            objCustmr.Onboarding_Stage__c ='In Process';
            insert objCustmr;
            objCustmr.Onboarding_Stage__c = 'Completed';
            objCustmr.Employee_Duty_Type__c = 'Duty';
            update objCustmr;
        }catch(exception e){
            
        }
    }
    
    
}