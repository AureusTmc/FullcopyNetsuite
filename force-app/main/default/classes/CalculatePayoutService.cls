/*
    Name - CalculatePayoutService
    Date - 18 June 2019
*/
public class CalculatePayoutService{
    
    public static List<Account> employeeRecords = new List<Account>();
    public static Payroll_Batch__c payrollBatch = new Payroll_Batch__c();
    public static Map<Id,List<Employee_Work_Week__c>> employeeWeekMap = new Map<Id,List<Employee_Work_Week__c>> ();
    public static Map<String,Map<Decimal,List<CPF_Category__c>>> cpfDetailsMap = new Map<String,Map<Decimal,List<CPF_Category__c>>>();
    public static Map<Id,Payout__c> existingpayoutsMap = new Map<Id,Payout__c>(); 
    public static Map<Id,List<Employee_Work_Week__c>> accToWorkWeekMap = new Map<Id,List<Employee_Work_Week__c>>();
    public static Map<Integer,String> cpfYearMap = new Map<Integer,String>{ 1 => 'firstyear', 2 => 'secondyear', 3 => 'thirdyear&singaporean' };
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
    
    public static void setupEmployeeWeekData(){
        for(Employee_Work_Week__c eww: [Select id,Employee__c ,Effective_Date__c,Monday__c,Tuesday__c,Wednesday__c,Thursday__c,Friday__c,Saturday__c,Sunday__c from Employee_Work_Week__c where Employee__c in : employeeRecords and Effective_Date__c!=null order by Effective_Date__c desc]){
            List<Employee_Work_Week__c> tempList = new List<Employee_Work_Week__c>();
            
            if(accToWorkWeekMap.containsKey(eww.Employee__c)){
                tempList.addAll(accToWorkWeekMap.get(eww.Employee__c));
            }
            tempList.add(eww);
            
            accToWorkWeekMap.put(eww.Employee__c,tempList);
        }
    }
    // Calculate CPF
    public static payout__c calculateEmployeeCPF(Account employee, payout__c payout){
        // calculate the date as start of month
        Date dt = employee != null ? employee.Issue_Date__c : null;
        if(dt != null || (employee != null && employee.ID_Type__c != null && employee.ID_Type__c.equalsignorecase('Citizen'))){
            Integer year = 3;
            if(!employee.ID_Type__c.equalsignorecase('Citizen') && dt != null){
                dt = date.newInstance(dt.Year(),dt.Month(),Date.DaysInMonth(dt.Year(),dt.Month()));
                Integer currYear = Integer.valueOf(payout.Year__c);
                Integer currMonth = monthMap.get(payout.Month__c);
                Date payoutDate = date.newInstance(currYear,currMonth,Date.DaysInMonth(currYear,currMonth));
                year = getCPFYearOfEmployee(employee, dt, payoutDate );
            }
            // Matching employee year with static string values
            if(cpfYearMap.containsKey(year)){
                if(cpfDetailsMap.containsKey(cpfYearMap.get(year))){
                    Map<Decimal,List<CPF_Category__c>> empYearData = cpfDetailsMap.get(cpfYearMap.get(year));
                    // Find data from age
                    List<CPF_Category__c> empAgeData = getCPFByAgeOfEmployee(employee,empYearData);
                    payout = getCPFCalculatedAmount(year, employee, empAgeData, payout );
                }
            }
        }
        return payout;
    }
    
    // Calculating CPF amount by employee
    public static payout__c getCPFCalculatedAmount(Integer year, Account emp, List<CPF_Category__c> cpfList, payout__c payout){
        if(payout != null){
            Decimal empSalary = payout.Salary__c;
            if(payout.Total_OW_Amount__c  != null && empSalary != null){
                empSalary += payout.Total_OW_Amount__c;
            }
            decimal totalWage = (empSalary!=null?empSalary:0) + (payout.Total_AW_Amount__c!=null?payout.Total_AW_Amount__c:0);
            
            String methodString = ':01';
            CPF_Category__c cpfCategoryRecord = New CPF_Category__c ();
            Decimal currentAmount = 0;
            for(CPF_Category__c cpfCat : cpfList){
                if(cpfCat.Min_Total_Wage__c < totalWage && cpfCat.Min_Total_Wage__c >= currentAmount ){
                    cpfCategoryRecord = cpfCat;
                    currentAmount = cpfCat.Min_Total_Wage__c;
                    // creating a comman method string and for dynamic use in future
                    if(cpfCat.Min_Total_Wage__c == 750){
                        methodString = ':04';
                    }else if(cpfCat.Min_Total_Wage__c == 500 && cpfCat.Max_Total_Wages__c == 750){
                        methodString = ':03';
                    }else if(cpfCat.Min_Total_Wage__c == 50 && cpfCat.Max_Total_Wages__c == 500){
                        methodString = ':02';
                    }
                }
            }
            system.debug('Method Execute "Year : m-Number"  *** '+year+''+methodString );
            system.debug('Method Execute "Age Fector "      *** '+cpfCategoryRecord.Min_Employee_Age__c+' To '+cpfCategoryRecord.Max_Employee_Age__c);
            system.debug('Method Execute "Salary Fector "   *** '+cpfCategoryRecord.Min_Total_Wage__c +' To '+cpfCategoryRecord.Max_Total_Wages__c );
            
            Decimal OW = payout.Salary__c != null ? payout.Salary__c : 0;
            
            //calculate payout salary fector
            Integer currYear = Integer.valueOf(payout.Year__c);
            Integer currMonth = monthMap.get(payout.Month__c);
            Date startMonthDate = date.newInstance(currYear,currMonth,1);
            Date lastMonthDate = null;
            
            
            if(emp.Joining_Date__c != null && emp.Joining_Date__c .Month() == currMonth && emp.Joining_Date__c .Year() == currYear){
                startMonthDate = emp.Joining_Date__c;
            }
            if(emp.Issue_Date__c != null && emp.Issue_Date__c.Month() == currMonth && emp.Issue_Date__c.Year() == currYear){
                startMonthDate = emp.Issue_Date__c > startMonthDate ? emp.Issue_Date__c : startMonthDate ;
            }
            if(emp.Last_Working_Date__c != null && emp.Last_Working_Date__c.Month() == currMonth && emp.Last_Working_Date__c.Year() == currYear){
                lastMonthDate = emp.Last_Working_Date__c;
            }else{
                lastMonthDate = date.newInstance(currYear,currMonth,Date.DaysInMonth(currYear,currMonth));
            }
            
            if(startMonthDate != null && lastMonthDate != null){
                List<Employee_Work_Week__c> employeeWeeks = new List<Employee_Work_Week__c>();
                if(accToWorkWeekMap.containsKey(emp.Id)){
                    for(Employee_Work_Week__c wk : accToWorkWeekMap.get(emp.Id)){
                        if(wk.Effective_Date__c <= lastMonthDate){
                            employeeWeeks.add(wk);
                        }
                    }
                }
                AureusHRUtility.workingDaysWrapper wd = AureusHRUtility.calcEmpWorkingDaysInaMonth(currYear,currMonth,startMonthDate,lastMonthDate,employeeWeeks);
                decimal workingDays = wd.workingDays;
                
                if(payout.Daily_Rate__c != null && payout.Daily_Rate__c>0 && workingDays != null && workingDays>0){
					OW = payout.Daily_Rate__c * workingDays;
                    //OW = OW.round(System.RoundingMode.CEILING);
                }else{
                    OW = (payout.Salary__c!=null?payout.Salary__c:0);
                }
                OW = OW.setScale(2,System.RoundingMode.CEILING);
                
                system.debug('Total Days ** '+startMonthDate.daysBetween(lastMonthDate));
                system.debug('Total working hours from '+startMonthDate+' to '+lastMonthDate+' ** '+workingDays);
                system.debug('Total Salary '+OW);
            }
            
            if(payout.Total_OW_Amount__c != null){
                OW += payout.Total_OW_Amount__c;
            }
            
            // Checking ceilling amount for payout
            if(cpfCategoryRecord.Capped_OW_Ceiling_Amount__c < OW){
                OW = cpfCategoryRecord.Capped_OW_Ceiling_Amount__c;
            } 
            Decimal AW = payout.Total_AW_Amount__c != null ? payout.Total_AW_Amount__c : 0;
            Decimal TW = OW+AW;
            // Calculate CPF Amount for both fields.
            if(methodString == ':02'){
                payout.Employer_CPF_Amount__c = getAmountByPercent(cpfCategoryRecord.Total_Contribution_Percent_of_TW__c,TW);
            }else if(methodString == ':03'){
                payout.Employee_CPF_Amount__c = ECMultipleofTWFixedAmount(
                    cpfCategoryRecord.TC_Multiple_of_TW_Fixed_Amount__c,TW,cpfCategoryRecord.Total_Contribution_Fixed_Amount__c);
                 
                payout.Employee_CPF_Amount__c = payout.Employee_CPF_Amount__c.round(System.RoundingMode.DOWN);
                
                decimal totalCPF = (getAmountByPercent(cpfCategoryRecord.Total_Contribution_Percent_of_TW__c,TW) + ECMultipleofTWFixedAmount(cpfCategoryRecord.TC_Multiple_of_TW_Fixed_Amount__c,TW,cpfCategoryRecord.Total_Contribution_Fixed_Amount__c));
                
                totalCPF = totalCPF.round(System.RoundingMode.HALF_UP);
                
                payout.Employer_CPF_Amount__c = totalCPF - payout.Employee_CPF_Amount__c;
            }else if(methodString == ':04'){
				payout.Employee_CPF_Amount__c = getAmountByPercent(
                                                 cpfCategoryRecord.Employee_Contribution_Percent_of_OW__c,OW) 
                                                 + getAmountByPercent(cpfCategoryRecord.Employee_Contribution_Percent_of_AW__c,AW
                                                 );
				payout.Employee_CPF_Amount__c = payout.Employee_CPF_Amount__c.round(System.RoundingMode.DOWN);
                
                decimal totalCPF = (getAmountByPercent(cpfCategoryRecord.Total_Contribution_Percent_of_OW__c,OW) + getAmountByPercent(cpfCategoryRecord.Total_Contribution_Percent_of_AW__c ,AW));
                totalCPF = totalCPF.round(System.RoundingMode.HALF_UP);
                    
                payout.Employer_CPF_Amount__c = totalCPF - payout.Employee_CPF_Amount__c;
            }
            
            payout.Employee_CPF_Amount__c = payout.Employee_CPF_Amount__c != null && payout.Employee_CPF_Amount__c > 0 ? payout.Employee_CPF_Amount__c.round() : 0;
            payout.Employer_CPF_Amount__c = payout.Employer_CPF_Amount__c != null && payout.Employer_CPF_Amount__c > 0 ? payout.Employer_CPF_Amount__c.round() : 0;
            
        }
        return payout;
    }
    
    public static decimal getAmountByPercent(Decimal percent, Decimal amount){
        
        Decimal value = 0;
        try{
            value = (amount*percent)/100;
        }catch(Exception e){}
        return value;
    }
    
    public static decimal ECMultipleofTWFixedAmount(Decimal multipleOf, Decimal tCAmountOfTW, Decimal fixedAmount){
        
        Decimal value = 0;
        try{
            value = multipleOf*(tCAmountOfTW - fixedAmount);
        }catch(Exception e){}
        return value;
    }
    
    // find year of employee
    public static List<CPF_Category__c> getCPFByAgeOfEmployee(Account emp, Map<Decimal,List<CPF_Category__c>> yearData){
        
        Decimal empAge = null;
        Decimal empAgeByAccount = 0;
        List<CPF_Category__c> returnValue = new List<CPF_Category__c>(); 
        if(emp.PersonBirthdate != null){
            Date personBirthdate = emp.PersonBirthdate;
            Date today = Date.Today(); 
            personBirthdate = personBirthdate.addYears(1);
            While(personBirthdate <= today){
                empAgeByAccount = empAgeByAccount + 1; 
                personBirthdate = personBirthdate.addYears(1);
            }
            personBirthdate = personBirthdate.addYears(-1);
            personBirthdate = personBirthdate.addMonths(1);
            While(personBirthdate <= today){
                empAgeByAccount = empAgeByAccount + 0.08; 
                personBirthdate = personBirthdate.addMonths(1);
            }
            personBirthdate = personBirthdate.addMonths(-1);
            if(personBirthdate < today && personBirthdate.Month() == today.Month() && personBirthdate.Day() == 1 ) empAgeByAccount = empAgeByAccount + 0.08; 
            
            for(Decimal age : yearData.keyset()){
                if(age >= empAgeByAccount && (empAge == null || age < empAge)){
                    returnValue = yearData.get(age);
                    empAge = age;
                }
            }
        }else{
            returnValue = yearData.get(55);
        }
        return returnValue;
    }
    
    // find year of employee
    public static Integer getCPFYearOfEmployee(Account emp, Date dt, Date today){
        if(dt != null){
            Integer days = dt.day();
            dt = days == 1 ? dt.addDays(-1) : dt.addDays(-(dt.day())).addMonths(1);
        }
        if(emp.ID_Type__c != null && emp.ID_Type__c.equalsignorecase('Citizen')){
            return 3;
        }else if(emp.ID_Type__c != null &&  emp.ID_Type__c.equalsignorecase('Permanent Resident')){
            
            Date thirdYear = date.newInstance(dt.Year()+2,dt.Month(),Date.DaysInMonth(dt.Year()+2,dt.Month()));
            Date secondYear = date.newInstance(dt.Year()+1,dt.Month(),Date.DaysInMonth(dt.Year()+1,dt.Month()));
            if(emp.Issue_Date__c == null) return 0;
            else if(thirdYear < today) return 3;
            else if(secondYear < today) return 2;
            else return 1;
        }else{
            return 0;
        }
    }
    // CPF Details
    public static Map<String,Map<Decimal,List<CPF_Category__c>>> getEmpCPFDetails(){
        
        Map<String,Map<Decimal,List<CPF_Category__c>>> cpfDetails = new Map<String,Map<Decimal,List<CPF_Category__c>>>();
        for(CPF_Category__c cpfCat : [SELECT Id, Name, Category__c, Min_Employee_Age__c, Max_Employee_Age__c, Min_Total_Wage__c,Max_Total_Wages__c,Total_Contribution_Percent_of_TW__c,TC_Multiple_of_TW_Fixed_Amount__c, Total_Contribution_Fixed_Amount__c, 
                                        EC_Multiple_of_TW_Fixed_Amount__c, Employee_Contribution_Fixed_Amount__c,Total_Contribution_Percent_of_OW__c,Total_Contribution_Percent_of_AW__c,Employee_Contribution_Percent_of_OW__c, Employee_Contribution_Percent_of_AW__c, Capped_OW_Ceiling_Amount__c
                                        FROM CPF_Category__c]){
                                        
            cpfCat.Category__c = cpfCat.Category__c != null ? cpfCat.Category__c.replaceAll(' ','').toLowerCase() : cpfCat.Category__c;
            // Adding year context to map
            if(!cpfDetails.containsKey(cpfCat.Category__c)){
                cpfDetails.put(cpfCat.Category__c, new Map<Decimal,List<CPF_Category__c>>());
            }
            // Adding age fector to map
            if(!cpfDetails.get(cpfCat.Category__c).containsKey(cpfCat.Max_Employee_Age__c)){
                cpfDetails.get(cpfCat.Category__c).put(cpfCat.Max_Employee_Age__c, new List<CPF_Category__c>());
            }
            // Adding salary fector to map
            cpfDetails.get(cpfCat.Category__c).get(cpfCat.Max_Employee_Age__c).add(cpfCat);
        }
        return cpfDetails;
    }
}