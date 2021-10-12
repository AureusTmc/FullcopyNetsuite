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
        this.payoutIdSet =payoutIdSet;
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
        system.debug('payoutIdSet'+payoutIdSet);
        List<String> listOfpayoutIds = new List<String>();
        for(Id payoutId:payoutIdSet){
            listOfpayoutIds.add(payoutId);
        }
        Map<Id,Payout__c> mapOfPayout = AureusHRUtility.getEmployeePayout(listOfpayoutIds);
        Map<Id,Payout__c> mapOfaccToPayout = new Map<Id,Payout__c>();
        
        for(Payout__c pt: mapOfPayout.values()){            
               mapOfaccToPayout.put(pt.id,pt);
        }
        system.debug('accIds'+accIds);
        system.debug('accToPayoutMap'+mapOfaccToPayout);
       
        AureusHRManagementUtil.createPayItemForSalaryPayroll(accIds,currentDate,mapOfaccToPayout.keyset());

        AureusHRManagementUtil.calcualterPayoutCPFAmount(accounts,payoutIdSet,currentDate);
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
     
}