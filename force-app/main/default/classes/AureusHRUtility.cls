public class AureusHRUtility{

    Public static Boolean calledOnce = false;
    
    Public static string individualCommission = 'Individual Commission (OW)';
    Public static string groupCommission = 'Group Commission (OW)';
    
    public static Boolean isCalculatePayout = true;
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
    
    public static workingDaysWrapper calcEmpWorkingDaysInaMonth(Integer currYear,Integer currMonth,Date startDate,Date endDate,List<Employee_Work_Week__c> empWorkWeekList){
        Decimal workingDays = 0;
        Map<Date,decimal> dateToDailyWorkDayMap = new Map<Date,decimal>(); 
        Integer workWeekListSize = empWorkWeekList.size();
        for(Employee_Work_Week__c eww: empWorkWeekList){
            if(eww.Effective_Date__c.year()==currYear && eww.Effective_Date__c.month()==currMonth && eww.Effective_Date__c.day()!=1 && workWeekListSize>1){
                for(Date dt=eww.Effective_Date__c;dt<=endDate;dt=dt.addDays(1)){
                    Datetime dtm = (datetime) dt;
                    string dayOfWeek = dtm.format('EEEE');
                    
                    if(eww.get(dayOfWeek+'__c')=='Full Day'){
                        workingDays = workingDays + 1;
                        dateToDailyWorkDayMap.put(dt,1);
                    }else if(eww.get(dayOfWeek+'__c')=='Half Day'){
                        workingDays = workingDays + 0.5;
                        dateToDailyWorkDayMap.put(dt,0.5);
                    }
                }
                endDate = eww.Effective_Date__c.addDays(-1);
            }else{
                for(Date dt=startDate;dt<=endDate;dt=dt.addDays(1)){
                    Datetime dtm = (datetime) dt;
                    string dayOfWeek = dtm.format('EEEE');
                    
                    if(eww.get(dayOfWeek+'__c')=='Full Day'){
                        workingDays = workingDays + 1;
                        dateToDailyWorkDayMap.put(dt,1);
                    }else if(eww.get(dayOfWeek+'__c')=='Half Day'){
                        workingDays = workingDays + 0.5;
                        dateToDailyWorkDayMap.put(dt,0.5);
                    }
                }
                break;
            }
        }
        workingDaysWrapper wd = new workingDaysWrapper();
        wd.workingDays = workingDays;
        wd.dateToDailyWorkDayMap = dateToDailyWorkDayMap;
        return wd;
        
    }
    
    public static EmployeeSalaryWrapper calcEmployeeSalaryInaMonth(Integer currYear,Integer currMonth,Date startDate,Date endDate,List<Salary_Detail__c> salDetList,workingDaysWrapper wd,Date joiningDate, Date lastWorkingDate){
        Boolean prorate = false;
        decimal empSalary = 0;
        decimal TotalActualWorkingDays = 0;
        decimal actualSalary = 0;
        Boolean joiningMonth = false;
        Boolean lastWorkingMonth = false;
        decimal basicSalary= 0;
        decimal housingAllowance= 0;
        decimal transportAllowance= 0;
        
        Map<date,decimal> dailySalaryMap = new Map<date,decimal>();
        if(joiningDate!=null && joiningDate.month()==currMonth && joiningDate.year()==currYear){
            joiningMonth = true;
        }
        if(lastWorkingDate!=null && lastWorkingDate.month()==currMonth && lastWorkingDate.year()==currYear){
            lastWorkingMonth = true;
        }
        
        system.debug('joiningMonth==='+joiningMonth);
        system.debug('lastWorkingMonth==='+lastWorkingMonth);
        
        
        Integer salDetSize = salDetList.size();
        if(wd.dateToDailyWorkDayMap!=null && wd.dateToDailyWorkDayMap.size()>0 && wd.workingDays>0){
            for(Salary_Detail__c sd: salDetList){
                decimal tempDailyRate = sd.Total_Salary__c/wd.workingDays;
                decimal basicSalaryRate= sd.Basic_Salary__c / wd.workingDays;
                decimal housingAllowanceRate= sd.Housing_Allowance__c / wd.workingDays;
                decimal transportAllowanceRate= sd.Transport_Allowance__c / wd.workingDays;
                
                if(sd.Effective_Date__c.year()==currYear && sd.Effective_Date__c.month()==currMonth && sd.Effective_Date__c.day()!=1 && salDetSize>1){
                    decimal countProRateDays = 0;
                    decimal actualWorkingDays = 0;
                    for(Date dt=sd.Effective_Date__c;dt<=endDate;dt=dt.addDays(1)){
                        if(wd.dateToDailyWorkDayMap.containsKey(dt)){
                            countProRateDays = countProRateDays + wd.dateToDailyWorkDayMap.get(dt);
                            if(joiningMonth && lastWorkingMonth && dt>=joiningDate && dt<=lastWorkingDate){
                                actualWorkingDays = actualWorkingDays + wd.dateToDailyWorkDayMap.get(dt);
                                dailySalaryMap.put(dt,(wd.dateToDailyWorkDayMap.get(dt)*tempDailyRate));    
                            }else If(!lastWorkingMonth && joiningMonth && dt>=joiningDate){
                                actualWorkingDays = actualWorkingDays + wd.dateToDailyWorkDayMap.get(dt);
                                dailySalaryMap.put(dt,(wd.dateToDailyWorkDayMap.get(dt)*tempDailyRate));
                            }else If(!joiningMonth && lastWorkingMonth && dt<=lastWorkingDate){
                                actualWorkingDays = actualWorkingDays + wd.dateToDailyWorkDayMap.get(dt);
                                dailySalaryMap.put(dt,(wd.dateToDailyWorkDayMap.get(dt)*tempDailyRate));
                            }else if(!joiningMonth && !lastWorkingMonth){
                                actualWorkingDays = actualWorkingDays + wd.dateToDailyWorkDayMap.get(dt);
                                dailySalaryMap.put(dt,(wd.dateToDailyWorkDayMap.get(dt)*tempDailyRate));
                            }
                        }
                    }
                    if(countProRateDays>0){
                        empSalary = (countProRateDays*tempDailyRate);
                        
                    }
                    if(actualWorkingDays>0){
                        actualSalary = (actualWorkingDays*tempDailyRate);
                        basicSalary= (actualWorkingDays * basicSalaryRate);
                        housingAllowance= (actualWorkingDays  * housingAllowanceRate);
                        transportAllowance= (actualWorkingDays * transportAllowanceRate);
                        TotalActualWorkingDays = actualWorkingDays;
                        system.debug('actualSalary1==='+actualSalary +'-----'+actualWorkingDays+'-----'+tempDailyRate);
                    }
                    endDate = sd.Effective_Date__c.addDays(-1);
                    
                    prorate = true;                    
                }else{
                    decimal countProRateDays = 0;
                    decimal actualWorkingDays = 0;
                    for(Date dt=startDate;dt<=endDate;dt=dt.addDays(1)){
                        if(wd.dateToDailyWorkDayMap.containsKey(dt)){
                            countProRateDays = countProRateDays + wd.dateToDailyWorkDayMap.get(dt);
                            if(joiningMonth && lastWorkingMonth && dt>=joiningDate && dt<=lastWorkingDate){
                                actualWorkingDays = actualWorkingDays + wd.dateToDailyWorkDayMap.get(dt);
                                dailySalaryMap.put(dt,(wd.dateToDailyWorkDayMap.get(dt)*tempDailyRate));    
                            }else If(!lastWorkingMonth && joiningMonth && dt>=joiningDate){
                                actualWorkingDays = actualWorkingDays + wd.dateToDailyWorkDayMap.get(dt);
                                dailySalaryMap.put(dt,(wd.dateToDailyWorkDayMap.get(dt)*tempDailyRate));
                            }else If(!joiningMonth && lastWorkingMonth && dt<=lastWorkingDate){
                                actualWorkingDays = actualWorkingDays + wd.dateToDailyWorkDayMap.get(dt);
                                dailySalaryMap.put(dt,(wd.dateToDailyWorkDayMap.get(dt)*tempDailyRate));
                            }else if(!joiningMonth && !lastWorkingMonth){
                                actualWorkingDays = actualWorkingDays + wd.dateToDailyWorkDayMap.get(dt);
                                dailySalaryMap.put(dt,(wd.dateToDailyWorkDayMap.get(dt)*tempDailyRate));
                            }
                        }
                    }
                    if(prorate){
                        if(countProRateDays>0){
                            empSalary = empSalary + (countProRateDays*tempDailyRate);
                        }
                    }else{
                        empSalary = sd.Total_Salary__c;
                    }
                    
                    if(actualWorkingDays>0){
                        actualSalary = actualSalary + (actualWorkingDays*tempDailyRate);
                        basicSalary= basicSalary + (actualWorkingDays * basicSalaryRate);
                        housingAllowance= housingAllowance + (actualWorkingDays  * housingAllowanceRate);
                        transportAllowance= transportAllowance + (actualWorkingDays * transportAllowanceRate);
                        TotalActualWorkingDays += actualWorkingDays;
                        system.debug('actualSalary2==='+(actualWorkingDays*tempDailyRate) +'-----'+actualWorkingDays+'-----'+tempDailyRate);
                    }                        
                    
                    break;
                }
            }
        }
        system.debug('empSalary==='+empSalary);
        system.debug('actualSalary==='+actualSalary);
        EmployeeSalaryWrapper sw = new EmployeeSalaryWrapper();
        sw.monthlySalary = empSalary;
        sw.actualSalary = actualSalary;
        sw.actualWorkingDays = TotalActualWorkingDays;
        sw.dailySalaryMap = dailySalaryMap;
        sw.basicSalary= basicSalary;
        sw.housingAllowance= housingAllowance;
        sw.transportAllowance = transportAllowance;
        return sw;
    }
    
    
    public class workingDaysWrapper{
        public decimal workingDays{get;set;}
        Public Map<Date,decimal> dateToDailyWorkDayMap{get;set;}
        public workingDaysWrapper(){
            dateToDailyWorkDayMap = new Map<Date,decimal>();
        }
    }
    
    /*@future
    public static void calculatePayout(Set<Id> idSet){
        for(String cId : idSet){
            ReCalculatePayoutActionController.getCalculatePayout(cId);
        }
    }*/
    public static void getCalculatePayout(Set<Id> idSet){
        if(isCalculatePayout ){
            isCalculatePayout = false;
            ID jobID = System.enqueueJob(new AsyncExecutionCalculatePayout(idSet));
        }
    }
    public class AsyncExecutionCalculatePayout implements Queueable {
        public Set<Id> idSet = new Set<Id>();
        public AsyncExecutionCalculatePayout(Set<Id> idSet){
            this.idSet = idSet;
        }
        public void execute(QueueableContext context) {
            calculatePayout(idSet);      
        }
    }
    @future
    public static void calculatePayout(Set<Id> idSet){
        /*for(String cId : idSet){
            ReCalculatePayoutActionController.getCalculatePayout(cId);
        }*/
        date dateOfToday = system.today();
        Integer yInt = dateOfToday.Year(); Integer mInt = dateOfToday.month();
        Datetime dateTimeOfToday = (datetime) dateOfToday;
        Date startMonthDate = date.newInstance(yInt,mInt,1); 
        Date lastMonthDate = date.newInstance(yInt,mInt,Date.DaysInMonth(yInt,mInt));
        // --------------------
        String mString = dateTimeOfToday.format('MMMM');
        String yString = dateTimeOfToday.format('yyyy');
        
        List<Id> payoutIdList = new List<Id>();
        payoutIdList.addAll(idSet);
        
        Map<Id,Payout__c> accToPayoutMap = AureusHRUtility.getEmployeePayout(payoutIdList);
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
        
        Map<Id, Account> accountMap = new Map<Id, Account>([Select id,Joining_Date__c,Issue_Date__c,PersonBirthdate,ID_Type__c,Age__c,Last_Working_Date__c from Account where Employee_Status__c in ('Probation','Confirm') and (recordType.Name='Employee' or recordType.Name='Teacher') AND Id IN: accToPayoutMap.keyset()]);
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
        }
    }
    
    public static Map<Id,List<Employee_Work_Week__c>> getEmployeeWorkWeek(Set<Id> empIdList, Date lastMonthDate){
        
        Map<Id,List<Employee_Work_Week__c>> accToWorkWeekMap = new Map<Id,List<Employee_Work_Week__c>>();
        for(Employee_Work_Week__c eww: [Select id,Employee__c ,Effective_Date__c,Monday__c,Tuesday__c,Wednesday__c,Thursday__c,Friday__c,Saturday__c,Sunday__c from Employee_Work_Week__c where Employee__c IN : empIdList and Effective_Date__c!=null and Effective_Date__c<=:lastMonthDate order by Effective_Date__c desc]){
            if(!accToWorkWeekMap.containsKey(eww.Employee__c)){
                accToWorkWeekMap.put(eww.Employee__c, new List<Employee_Work_Week__c>());
            }
            accToWorkWeekMap.get(eww.Employee__c).add(eww);
        }
        return accToWorkWeekMap;
    }
    
    public static Map<Id,List<Salary_Detail__c>> getEmployeeSalary(Set<Id> empIdList, Date lastMonthDate){
        Map<Id,List<Salary_Detail__c>> accToSalaryMap = new Map<Id,List<Salary_Detail__c>>();
        for(Salary_Detail__c salDet: [select id,Total_Salary__c,Effective_Date__c,Employee_Name__c, Basic_Salary__c, Housing_Allowance__c, Transport_Allowance__c from Salary_Detail__c where Employee_Name__c in:empIdList and Total_Salary__c>0 and Effective_Date__c!=null and Effective_Date__c<=:lastMonthDate and Status__c='Active' order by Effective_Date__c desc]){
            if(!accToSalaryMap.containsKey(salDet.Employee_Name__c)){
                accToSalaryMap.put(salDet.Employee_Name__c, new List<Salary_Detail__c >());
            }
            accToSalaryMap.get(salDet.Employee_Name__c).add(salDet);
        }
        return accToSalaryMap;
    }
    
    public static Map<Id,Payout__c> getEmployeePayout(List<String> payoutIdList){
        Map<Id,Payout__c> accToPayoutMap = new Map<Id,Payout__c>(); 
        for(Payout__c pt: [SELECT Name, Id, Month__c, Year__c, Salary__c, Total_Amount__c, Employee_CPF_Amount__c, Employer_CPF_Amount__c, Total_CPF__c, Employee_Name__c, CDAC__c, MBMF__c, SINDA__c, EUCF__c, SDL__c, Total_OW_Amount__c, Total_AW_Amount__c, Total_Non_CPF_Amount__c, Status__c, Payroll_Batch__c, No_of_working_days__c, Daily_Rate__c, Total_Payable__c, Monthly_Working_Days__c, Monthly_Salary__c, Payment_Mode__c, Basic_Salary__c, Housing_Allowance__c, Transport_Allowance__c from Payout__c where Id in:payoutIdList]){            
            accToPayoutMap.put(pt.Employee_Name__c,pt);
        }
        return accToPayoutMap;
    }
    
    Public class EmployeeSalaryWrapper{
        public decimal monthlySalary{get;set;}
        public decimal actualSalary{get;set;}
        public decimal actualWorkingDays{get;set;}
        public Map<date,decimal> dailySalaryMap{get;set;}
        public decimal basicSalary {get;set;}
        public decimal housingAllowance {get;set;}
        public decimal transportAllowance {get;set;}
        
        public EmployeeSalaryWrapper(){
            dailySalaryMap = new Map<date,decimal>();
        }
    }
    
    Public static Boolean nricValidation(string nricNumber){
        
            if (nricNumber.trim().length() != 9) 
                return false;
        
            nricNumber = nricNumber.toUpperCase();
        
             
            List<string> icArray = new List<string>();
            for(Integer i = 0; i < 9; i++) {
                icArray.add(nricNumber.substring(i,i+1));
            }
            
            try{
               icArray[1] = string.valueOf(Integer.valueOf(icArray[1])*2);
               icArray[2] = string.valueOf(Integer.valueOf(icArray[2])*7);
               icArray[3] = string.valueOf(Integer.valueOf(icArray[3])*6);
               icArray[4] = string.valueOf(Integer.valueOf(icArray[4])*5);
               icArray[5] = string.valueOf(Integer.valueOf(icArray[5])*4);
               icArray[6] = string.valueOf(Integer.valueOf(icArray[6])*3);
               icArray[7] = string.valueOf(Integer.valueOf(icArray[7])*2);
            }catch(exception e){
                return false;
            }
            
            Integer weight = 0;
            for(integer i = 1; i < 8; i++) {
                weight += Integer.valueOf(icArray[i]);
            }
        
            integer offset = ((icArray[0] == 'T' || icArray[0] == 'G') ? 4:0);
            Integer temp = Math.mod((offset + weight),11);
        
            List<string> st = new List<string>{'J','Z','I','H','G','F','E','D','C','B','A'};
            List<string> fg = new List<string>{'X','W','U','T','R','Q','P','N','M','L','K'};
            
            string theAlpha;
            if (icArray[0] == 'S' || icArray[0] == 'T') { theAlpha = st[temp]; }
            else if (icArray[0] == 'F' || icArray[0] == 'G') { theAlpha = fg[temp]; }
        
            return (icArray[8] == theAlpha);
    }
}