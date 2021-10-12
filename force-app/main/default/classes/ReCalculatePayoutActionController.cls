// pending - calculate from date of payout record year, month
// redefine duplicate code from this class and createemployee batch

public class ReCalculatePayoutActionController{
    public static Map<String,Integer> monthMap = new Map<String,Integer>{
        'January'=>1,
        'February'=>2,
        'March'=>3,
        'April'=>4,
        'May'=>5,
        'June'=>6,
        'July'=>7,
        'August'=>8,
        'September'=>9,
        'October'=>10,
        'November'=>11,
        'December'=>12
    };
    @AuraEnabled
    public static boolean getCalculatePayout(String payoutId){
        try{ 
            date dateOfToday = system.today();
            Integer yInt = dateOfToday.Year(); Integer mInt = dateOfToday.month();
            Datetime dateTimeOfToday = (datetime) dateOfToday;
            Date startMonthDate = date.newInstance(yInt,mInt,1); 
            Date lastMonthDate = date.newInstance(yInt,mInt,Date.DaysInMonth(yInt,mInt));
            // --------------------
            String mString = dateTimeOfToday.format('MMMM');
            String yString = dateTimeOfToday.format('yyyy');
            
            Map<Id,Payout__c> accToPayoutMap = AureusHRUtility.getEmployeePayout(new List<String>{payoutId});
            for(Id empId : accToPayoutMap.keyset()){
                Payout__c pay = accToPayoutMap.get(empId);
                yInt = Integer.valueOf(pay.Year__c); 
                mInt = monthMap.get(pay.Month__c);
                startMonthDate = date.newInstance(yInt,mInt,1); 
                lastMonthDate = date.newInstance(yInt,mInt,Date.DaysInMonth(yInt,mInt));
                
                dateTimeOfToday = (datetime) startMonthDate;
                mString = dateTimeOfToday.format('MMMM');
                yString = dateTimeOfToday.format('yyyy');
            }
            Map<Id,List<Employee_Work_Week__c>> accToWorkWeekMap = AureusHRUtility.getEmployeeWorkWeek(accToPayoutMap.keyset(), lastMonthDate);
            Map<Id,List<Salary_Detail__c>> accToSalaryMap = AureusHRUtility.getEmployeeSalary(accToPayoutMap.keyset(), lastMonthDate);
            
            
            // CPF Details for calculate cpf data
            CalculatePayoutService.cpfDetailsMap = CalculatePayoutService.getEmpCPFDetails();
            CalculatePayoutService.employeeWeekMap = accToWorkWeekMap;
            
            Map<Id, Account> accountMap = new Map<Id, Account>([Select id,Joining_Date__c,Issue_Date__c,PersonBirthdate,ID_Type__c,Age__c,Last_Working_Date__c from Account where (recordType.Name='Employee' or recordType.Name='Teacher') AND Id IN: accToPayoutMap.keyset()]);
            // update list of payout and at optimization need to module work for below code
            List<Payout__c> payoutList = new List<Payout__c>();
            for(Id empId : accToPayoutMap.keyset()){
                Payout__c payout = accToPayoutMap.get(empId);
                Account acc = accountMap.get(empId);
                CalculatePayoutService.employeeRecords  = new List<Account>{acc};
                CalculatePayoutService.setupEmployeeWeekData();
                decimal workingDays = 0;
                decimal empSalary = 0;
                Date startDate = startMonthDate;
                Date endDate = lastMonthDate;
                AureusHRUtility.workingDaysWrapper wd = new AureusHRUtility.workingDaysWrapper();
                if(accToWorkWeekMap.containsKey(empId)){
                    //Method to calculate employees working days in a month
                    wd = AureusHRUtility.calcEmpWorkingDaysInaMonth(yInt,mInt,startDate,endDate,accToWorkWeekMap.get(empId));
                    workingDays = wd.workingDays;
                }
                AureusHRUtility.EmployeeSalaryWrapper sw = new AureusHRUtility.EmployeeSalaryWrapper();
                if( accToSalaryMap != null && acc != null && acc.Id != null && accToSalaryMap.containsKey(acc.Id)){
                    sw = AureusHRUtility.calcEmployeeSalaryInaMonth(yInt,mInt,startDate,endDate,accToSalaryMap.get(empId),wd,acc.Joining_Date__c,acc.Last_Working_Date__c);    
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
                payout.No_of_working_days__c = sw.actualWorkingDays;
                payout.Month__c = mString;
                payout.Year__c = yString;
                payout.Employer_CPF_Amount__c = 0;
                payout.Employee_CPF_Amount__c = 0;
                // Calculate CPF
                payout = CalculatePayoutService.calculateEmployeeCPF(acc,payout);
                payoutList.add(payout);
            } 
            if(!payoutList.isEmpty()){
                update payoutList;
                
                //below code to run only on button click -> 'Calculate Payout'
                if(!System.isBatch()){
                    //creating PayItems for approved leave requests for the Payouts - Start
                    Set<Id> payoutIdSet = new Set<Id>();
                    Date processDate;
                    for(Payout__c payout: payoutList){
                        payoutIdSet.add(payout.Id);
                        Integer year = Integer.valueOf(payout.Year__c); 
                        Integer month = monthMap.get(payout.Month__c);
                        processDate = Date.newInstance(year,month,1); 
                        System.debug(processDate);
                        break;
                    }
                    if(processDate != NULL){
                        AureusHRManagementUtil.createPayItemWithoutPLR(payoutIdSet, null, processDate, null);
                        AureusHRManagementUtil.calcLossAndCreatePayItemForUnpaidLeave(payoutIdSet, null, processDate, null); 
                    }
                    //creating PayItems for approved leave requests for the Payouts - End
                }
            }
            return true;
        }catch(Exception e){
            system.debug(''+e.getmessage());
            return false;
        }
    }
      //Nishi : 9-Apr-2021:for calculate teacher working hrs  and created payitem accordingly and calculate CPF amount accordingly
    @AuraEnabled
    public static boolean getCalculatePayoutTeacherTieredHrs(String payoutId){
        try{ 
            date dateOfToday = system.today();
            Integer yInt = dateOfToday.Year(); Integer mInt = dateOfToday.month();
            Datetime dateTimeOfToday = (datetime) dateOfToday;
            Date startMonthDate = date.newInstance(yInt,mInt,1); 
            Date lastMonthDate = date.newInstance(yInt,mInt,Date.DaysInMonth(yInt,mInt));
            // --------------------
            String mString = dateTimeOfToday.format('MMMM');
            String yString = dateTimeOfToday.format('yyyy');
            
            Map<Id,Payout__c> accToPayoutMap = AureusHRUtility.getEmployeePayout(new List<String>{payoutId});
            Map<Id, Account> accountMap = new Map<Id, Account>([Select id,Joining_Date__c,Issue_Date__c,PersonBirthdate,ID_Type__c,Age__c,Last_Working_Date__c from Account where (recordType.Name='Teacher') AND Id IN: accToPayoutMap.keyset()]);
           
            //below code to run only on button click -> 'Calculate Payout'
            if(!System.isBatch()){
                Set<Id> payoutIdSet = new Set<Id>();
                Date processDate;
                for(Payout__c payout: accToPayoutMap.values()){
                    payoutIdSet.add(payout.Id);
                    Integer year = Integer.valueOf(payout.Year__c); 
                    Integer month = monthMap.get(payout.Month__c);
                    processDate = Date.newInstance(year,month,1); 
                    System.debug(processDate);
                    break;
                }
                if(processDate != NULL && accountMap != null && accountMap.size() > 0){
                    AureusHRManagementUtil.createPayItemForSalaryPayroll(accToPayoutMap.keyset(),processDate,payoutIdSet);
                    AureusHRManagementUtil.calcualterPayoutCPFAmount(accountMap.values(),payoutIdSet,processDate);
                }
                
            }
            
            return true;
        }catch(Exception e){
            system.debug(''+e.getmessage());
            return false;
        }
    }
}