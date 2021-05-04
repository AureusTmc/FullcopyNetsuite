global without sharing class createEmployeePayoutBatch implements Database.Batchable<sObject>, Database.stateful{
    date currentDate = system.today();
    Integer currYear = currentDate.Year();
    Integer currMonth = currentDate.month();
    Datetime dtm = (datetime) currentDate;
    string strCurrMonth = dtm.format('MMMM');
    Integer currDay = currentDate.day();
    Date startMonthDate = date.newInstance(currYear,currMonth,1); 
    Date lastMonthDate = date.newInstance(currYear,currMonth,Date.DaysInMonth(currYear,currMonth));
    Set<Id> empIdSet = new Set<Id>();
    global Set<Id> allEmpIdSet;
    global  Set<Id> allPayoutIdSet;
    global Payroll_Batch__c payrollBatch = new Payroll_Batch__c();
    public static boolean inFutureContext = true;
    public createEmployeePayoutBatch(){
        allEmpIdSet = new Set<Id>();
        allPayoutIdSet = new Set<Id>();
    }
    public createEmployeePayoutBatch(Date processDate, set<Id>employeeIdSet, Payroll_Batch__c payrollBth){
        allEmpIdSet = new Set<Id>();
        allPayoutIdSet = new Set<Id>();
        empIdSet = employeeIdSet;
        payrollBatch = payrollBth;
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
        system.debug('empIdSet ** '+empIdSet);
        if(!empIdSet.isEmpty()){ 
            return Database.getQueryLocator([Select id,Total_Working_Days__c,Paid_By__c,Joining_Date__c,Issue_Date__c,ID_Type__c,PersonBirthdate,Age__c,Last_Working_Date__c,SINDA_Contribution__c,MBMF_Contribution__c,EUCF_Contribution__c,CDAC_Contribution__c from Account where Employee_Status__c in ('Probation','Confirm') and (recordType.Name='Employee' or recordType.Name='Teacher') and (Joining_Date__c=null or Joining_Date__c<=:lastMonthDate) and (Last_Working_Date__c=null or Last_Working_Date__c>=:startMonthDate) AND Id IN : empIdSet]);    
        }else{        
            return Database.getQueryLocator([Select id,Total_Working_Days__c,Paid_By__c,Joining_Date__c,Issue_Date__c,ID_Type__c,PersonBirthdate,Age__c,Last_Working_Date__c,SINDA_Contribution__c,MBMF_Contribution__c,EUCF_Contribution__c,CDAC_Contribution__c from Account where Employee_Status__c in ('Probation','Confirm') and (recordType.Name='Employee' or recordType.Name='Teacher') and (Joining_Date__c=null or Joining_Date__c<=:lastMonthDate) and (Last_Working_Date__c=null or Last_Working_Date__c>=:startMonthDate)]);    
        }
    }
    
    global void execute(Database.BatchableContext BC, List<Account> accounts){
        inFutureContext = false;
        Set<Id> accIds = new Set<Id>();
        for(Account acc:accounts){
            accIds.add(acc.Id);
        }
        system.debug('@@accIds'+accIds);
        Map<Id,List<Employee_Work_Week__c>> accToWorkWeekMap = new Map<Id,List<Employee_Work_Week__c>>();
        for(Employee_Work_Week__c eww: [Select id,Employee__c ,Effective_Date__c,Monday__c,Tuesday__c,Wednesday__c,Thursday__c,Friday__c,Saturday__c,Sunday__c from Employee_Work_Week__c 
                            where Employee__c in:accIds and Effective_Date__c!=null and Effective_Date__c<=:lastMonthDate order by Effective_Date__c desc]){
            List<Employee_Work_Week__c> tempList = new List<Employee_Work_Week__c>();
            if(accToWorkWeekMap.containsKey(eww.Employee__c)){
                tempList.addAll(accToWorkWeekMap.get(eww.Employee__c));
            }
            tempList.add(eww);
            
            accToWorkWeekMap.put(eww.Employee__c,tempList);
        }

        
        system.debug('@@accToWorkWeekMap'+accToWorkWeekMap);
        Map<Id,List<Salary_Detail__c>> accToSalaryMap = new Map<Id,List<Salary_Detail__c>>();
        for(Salary_Detail__c salDet: [select id,Total_Salary__c,Effective_Date__c,Employee_Name__c, Basic_Salary__c, Housing_Allowance__c, Transport_Allowance__c from Salary_Detail__c where Employee_Name__c in:accIds and Total_Salary__c>0 and Effective_Date__c!=null and Effective_Date__c<=:lastMonthDate and Status__c='Active' order by Effective_Date__c desc]){
            List<Salary_Detail__c> tempList = new List<Salary_Detail__c>();
            if(accToSalaryMap.containsKey(salDet.Employee_Name__c)){
                tempList.addAll(accToSalaryMap.get(salDet.Employee_Name__c));
            }
            tempList.add(salDet);
            accToSalaryMap.put(salDet.Employee_Name__c,tempList);
        }
        system.debug('@@accToSalaryMap'+accToSalaryMap);
        Map<Id,Payout__c> accToPayoutMap = new Map<Id,Payout__c>(); 
        
        for(Payout__c pt: [SELECT Id, Name, Month__c, Year__c, Salary__c, Total_Amount__c, Employee_CPF_Amount__c, Employer_CPF_Amount__c, 
                            Total_CPF__c, Employee_Name__c, CDAC__c, MBMF__c, SINDA__c, EUCF__c, SDL__c, Total_OW_Amount__c, Total_AW_Amount__c, 
                            Total_Non_CPF_Amount__c, Status__c, Payroll_Batch__c, No_of_working_days__c, Daily_Rate__c, Total_Payable__c, 
                            Monthly_Working_Days__c, Monthly_Salary__c, Basic_Salary__c, Housing_Allowance__c, Transport_Allowance__c from Payout__c where Employee_Name__c in:accIds and month__c=:strCurrMonth and year__c=:''+currYear+'']){            
               accToPayoutMap.put(pt.Employee_Name__c,pt);
        }
        system.debug('@@accToPayoutMap'+accToPayoutMap);
        List<Payout__c> payoutList = new List<Payout__c>();
        // CPF Details for calculate cpf data
        CalculatePayoutService.cpfDetailsMap = CalculatePayoutService.getEmpCPFDetails();
        CalculatePayoutService.employeeWeekMap = accToWorkWeekMap;
        CalculatePayoutService.employeeRecords  = accounts;
        CalculatePayoutService.setupEmployeeWeekData();
        List<Account> updateAccountList = new List<Account>();
        List<Payitem__c> payitemList = new List<Payitem__c>();
        Map<String,Id> payitemMasterMap = new Map<String,Id>();
        for(Payitem_Master__c pi : [SELECT Id,Name FROM Payitem_Master__c WHERE Name = 'Salary in Lieu (Employee)' OR Name = 'Salary in Lieu (Employer)']){
            if(pi.Name.indexOf('Employee') != -1) payitemMasterMap.put('Employee', pi.Id);
            if(pi.Name.indexOf('Employer') != -1) payitemMasterMap.put('Employer', pi.Id);
        }
         system.debug('@@payitemMasterMap'+payitemMasterMap);
        for(Account acc:accounts){
            decimal workingDays = 0;
            decimal empSalary = 0;
            Date startDate = startMonthDate;
            Date endDate = lastMonthDate;
            AureusHRUtility.workingDaysWrapper wd = new AureusHRUtility.workingDaysWrapper();
            if(accToWorkWeekMap.containsKey(acc.Id)){
                //Method to calculate employees working days in a month
                wd = AureusHRUtility.calcEmpWorkingDaysInaMonth(currYear,currMonth,startDate,endDate,accToWorkWeekMap.get(acc.Id));
                workingDays = wd.workingDays;
            }
            
            system.debug('WorkingDays==='+workingDays);
            AureusHRUtility.EmployeeSalaryWrapper sw = new AureusHRUtility.EmployeeSalaryWrapper();
            if(accToSalaryMap.containsKey(acc.Id)){
                sw = AureusHRUtility.calcEmployeeSalaryInaMonth(currYear,currMonth,startDate,endDate,accToSalaryMap.get(acc.Id),wd,acc.Joining_Date__c,acc.Last_Working_Date__c);    
            }
            
            Payout__c payout = new Payout__c();
            if(accToPayoutMap.containsKey(acc.Id)){
                //payout.Id =  accToPayoutMap.get(acc.Id).Id;   
                payout =  accToPayoutMap.get(acc.Id);   
            }else{
                payout.Employee_Name__c = acc.Id;
            }
            if(String.isBlank(payout.Id)){
                payout.SINDA_Contribution__c = acc.SINDA_Contribution__c;
                payout.MBMF_Contribution__c = acc.MBMF_Contribution__c;
                payout.EUCF_Contribution__c = acc.EUCF_Contribution__c ;
                payout.CDAC_Contribution__c = acc.CDAC_Contribution__c ;
            }
            If(sw.monthlySalary>0){
                payout.Monthly_Salary__c = sw.monthlySalary.setScale(2);
            }
            payout.Monthly_Working_Days__c = workingDays;
            
            if(sw.actualSalary>0){
                payout.Salary__c = sw.actualSalary.setScale(2);
            }else{
                payout.Salary__c = 0;
            }
            
            if(sw.basicSalary > 0){
                payout.Basic_Salary__c = sw.basicSalary.setScale(2);
            }else{
                payout.Basic_Salary__c = 0;
            }
            
            if(sw.housingAllowance > 0){
                payout.Housing_Allowance__c = sw.housingAllowance.setScale(2);
            }else{
                payout.Housing_Allowance__c = 0;
            }
            
            if(sw.transportAllowance  > 0){
                payout.Transport_Allowance__c = sw.transportAllowance .setScale(2);
            }else{
                payout.Transport_Allowance__c = 0;
            }
            
            payout.No_of_working_days__c = sw.actualWorkingDays;
            
            payout.Month__c = strCurrMonth;
            payout.Year__c = ''+currYear+'';
            
            payout.Employer_CPF_Amount__c = 0;
            payout.Employee_CPF_Amount__c = 0;
            // calculate CPF
            payout = CalculatePayoutService.calculateEmployeeCPF(acc,payout);
            if(!empIdSet.isEmpty()){
                payout.Payroll_Batch__c = payrollBatch.id;
                payout.Status__c = 'Processed';
            }
            payoutList.add(payout);
            
            // create new payitem, if account having information
            if(acc.Total_Working_Days__c != null){
                Id mId = null;
                if(payitemMasterMap.containsKey(acc.Paid_By__c)){
                    mId = payitemMasterMap.get(acc.Paid_By__c);
                }
                Payitem__c payItem = new PayItem__c(
                    Type__c = 'Days',
                    Value__c = acc.Total_Working_Days__c,
                    Payout__r = payout,
                    Payitem__c = mId 
                );
                payitemList.add(payItem);
                
                acc.Total_Working_Days__c = null; 
                updateAccountList.add(acc);             
           }
        } 
          system.debug('@@payoutList'+payoutList);
        upsert payoutList;
        if(!updateAccountList.isEmpty()){
            update updateAccountList;
        }
         system.debug('@@updateAccountList'+updateAccountList);
        if(!payitemList.isEmpty()){
            for(Payitem__c pi : payitemList){
                pi.Payout__c = pi.Payout__r.id;
            }
            insert payitemList;
        }
        system.debug('@@payitemList'+payitemList);
        //----------------
        //creating PayItems for approved leave requests for the Payouts - Start
        Set<Id> payoutIdSet = new Set<Id>();
        for(Payout__c payout: payoutList){
            payoutIdSet.add(payout.Id);
        }
        allEmpIdSet.addAll(accIds);
        allPayoutIdSet.addAll(payoutIdSet);
        system.debug('@@payoutIdSet'+payoutIdSet);
        AureusHRManagementUtil.createPayItemWithoutPLR(payoutIdSet, null, currentDate, null);
        AureusHRManagementUtil.calcLossAndCreatePayItemForUnpaidLeave(payoutIdSet, null, currentDate, null); 
         //creating PayItems for approved leave requests for the Payouts - End
    }
    
    global void finish(Database.BatchableContext BC){
        system.debug('accIds'+allEmpIdSet);
        system.debug('payoutIdSet'+allPayoutIdSet);
        ////Nishi : 9-Apr-2021:Acreating PayItems for approved working Hrs requests for the Payouts - Start
        //AureusHRManagementUtil.createPayItemForSalaryPayroll(accIds,currentDate,payoutIdSet);
        Database.executeBatch(new createPayItemForSalaryPayrollBatch(currentDate, allEmpIdSet,allPayoutIdSet),100);
         ////Nishi : 9-Apr-2021:Acreating PayItems for approved working Hrs requests for the Payouts - end
    }
     
}