/**
 * Name :createPayItemForSalaryPayrollBatch
 * Date: 4-May-2021
 * Author: Nishi
 * Description: for calculate teacher working hrs  and created payitem accordingly
 */
global without sharing class createPayItemForSalaryPayrollBatch implements Database.Batchable<sObject>, Database.stateful{
    Set<Id> empIdSet = new Set<Id>();
    Set<Id> payoutIdSet = new Set<Id>();
    date currentDate = system.today();
    Integer currYear = currentDate.Year();
    Integer currMonth = currentDate.month();
    Datetime dtm = (datetime) currentDate;
    string strCurrMonth = dtm.format('MMMM');
    Integer currDay = currentDate.day();
    Date startMonthDate = date.newInstance(currYear,currMonth,1); 
    Date lastMonthDate = date.newInstance(currYear,currMonth,Date.DaysInMonth(currYear,currMonth));
    public createPayItemForSalaryPayrollBatch(){
        createEmployeePayoutBatch.inFutureContext = false;
    }
    public createPayItemForSalaryPayrollBatch(Date processDate, set<Id>employeeIdSet,set<Id>payoutIdSet){
        createEmployeePayoutBatch.inFutureContext = false;
        empIdSet = employeeIdSet;
        currentDate = processDate;
        payoutIdSet =payoutIdSet;
        currentDate = processDate;
        currYear = currentDate.Year();
        currMonth = currentDate.month();
        dtm = (datetime) currentDate;
        strCurrMonth = dtm.format('MMMM');
        currDay = currentDate.day();
        startMonthDate = date.newInstance(currYear,currMonth,1); 
        lastMonthDate = date.newInstance(currYear,currMonth,Date.DaysInMonth(currYear,currMonth));
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        createEmployeePayoutBatch.inFutureContext = false;
        system.debug('empIdSet ** '+empIdSet);
        if(!empIdSet.isEmpty()){ 
            return Database.getQueryLocator([Select id,Total_Working_Days__c,Paid_By__c,Joining_Date__c,Issue_Date__c,ID_Type__c,PersonBirthdate,Age__c,Last_Working_Date__c,SINDA_Contribution__c,MBMF_Contribution__c,EUCF_Contribution__c,CDAC_Contribution__c from Account where Employee_Status__c in ('Probation','Confirm') and (recordType.Name='Teacher') and (Joining_Date__c=null or Joining_Date__c<=:lastMonthDate) and (Last_Working_Date__c=null or Last_Working_Date__c>=:startMonthDate) AND Id IN : empIdSet]);    
        }else{        
            return Database.getQueryLocator([Select id,Total_Working_Days__c,Paid_By__c,Joining_Date__c,Issue_Date__c,ID_Type__c,PersonBirthdate,Age__c,Last_Working_Date__c,SINDA_Contribution__c,MBMF_Contribution__c,EUCF_Contribution__c,CDAC_Contribution__c from Account where Employee_Status__c in ('Probation','Confirm') and (recordType.Name='Teacher') and (Joining_Date__c=null or Joining_Date__c<=:lastMonthDate) and (Last_Working_Date__c=null or Last_Working_Date__c>=:startMonthDate)]);    
        }
    }
    
    global void execute(Database.BatchableContext BC, List<Account> accounts){
        Set<Id> accIds = new Set<Id>();
        
        for(Account acc:accounts){
            accIds.add(acc.Id);
        }
        Map<Id,Payout__c> accToPayoutMap = new Map<Id,Payout__c>([SELECT Id from Payout__c
                                                                    where Employee_Name__c in:accIds 
                                                                    and month__c=:strCurrMonth 
                                                                    and year__c=:''+currYear+''
                                                                    and id=:payoutIdSet]);
        AureusHRManagementUtil.createPayItemForSalaryPayroll(accIds,currentDate,accToPayoutMap.keyset());
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
     
}