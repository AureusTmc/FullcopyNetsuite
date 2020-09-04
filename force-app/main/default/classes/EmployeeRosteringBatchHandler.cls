public class EmployeeRosteringBatchHandler{
public static Integer setupRosteringForMonths = 3;
public static List<Rostering__c> existingRosteringToDeleteList = new List<Rostering__c>();
public static Date startDate = Date.today();
   
    public static void generateRostering(List<SObject> records, Integer forMonths, Date sDate){
        setupRosteringForMonths = forMonths != null ? forMonths : setupRosteringForMonths ;
        startDate = sDate != null ? sDate : startDate ;
        
        List<Account> accountList = (List<Account>) records;
        
        // Comman list for delete existing record
        existingRosteringToDeleteList = new List<Rostering__c>();
        
        Map<Id,List<Employee_Work_Week__c>> employeeWorkWeekMap = getWorkWeekByAccount(records);
        // setup date data with date range define month
        Date endDate = startdate.addMonths(setupRosteringForMonths);
        Map<Id,Map<Date, Rostering__c>> existingRosteringMap = getExistingRosteringByAccountWithDateRange(accountList, startDate, endDate);
        
        List<Rostering__c> rosteringList = new List<Rostering__c> ();
        for(Account emp: accountList){
            // getting employee work week records.
            List<Employee_Work_Week__c> workWeekList = new List<Employee_Work_Week__c>();
            if(employeeWorkWeekMap.containsKey(emp.Id)){
                workWeekList = employeeWorkWeekMap.get(emp.Id);
            }
            if(workWeekList.isEmpty() && existingRosteringMap.containsKey(emp.Id)){
                List<Rostering__c> existingRosteringList = existingRosteringMap.get(emp.Id).values();
                if(!existingRosteringList.isEmpty()) existingRosteringToDeleteList.addAll(existingRosteringList);
            }
            
            Date lastWeekFrom = startDate;
            Date lastWeekTo = startDate.addDays(7);
            Employee_Work_Week__c  lasteww = getemployeeWorkWeekByDateRange(workWeekList, lastWeekFrom, lastWeekTo);
            // procesing week data by week
            startDate = lastWeekTo;
            
            if(!workWeekList.isEmpty()){
                while(startDate < endDate) {
                    Date weekFrom = startDate;
                    Date weekTo = weekFrom.addDays(7);
                    Employee_Work_Week__c  eww = getemployeeWorkWeekByDateRange(workWeekList, weekFrom, weekTo);
                    
                    // Checking date for work week 
                    if(eww.Effective_Date__c > lastWeekFrom && eww.Effective_Date__c < lastWeekTo && eww.Effective_Date__c != lastWeekFrom){
                        lastWeekTo = eww.Effective_Date__c;
                        startDate = eww.Effective_Date__c;
                    }
                    
                    List<Rostering__c> rosteringListtoCreateList = getGenerateRosteringBetweenDateRange(lasteww, lastWeekFrom, lastWeekTo, emp.Main_Centre__c, existingRosteringMap, emp.Id);
                    if(rosteringListtoCreateList  != null && !rosteringListtoCreateList.isEmpty()) rosteringList.addAll(rosteringListtoCreateList);
                    
                    lastWeekFrom = startDate;
                    startDate = startDate.addDays(7);
                    
                    lastWeekTo = lastWeekFrom.addDays(7);
                    lasteww = eww;
                    // Lets create rostering for last week in date range.
                    if(endDate <= lastWeekTo){
                        lastWeekTo = endDate ;
                        rosteringListtoCreateList = getGenerateRosteringBetweenDateRange(lasteww, lastWeekFrom, lastWeekTo, emp.Main_Centre__c, existingRosteringMap, emp.Id);
                        if(!rosteringListtoCreateList.isEmpty()) rosteringList.addAll(rosteringListtoCreateList);
                    }
                }
            }
        }
        if(!rosteringList.isEmpty()){
            for(Rostering__c rs:rosteringList){
                If(rs.centre__c==null){
                    system.debug('Test===='+rs);
                }
            }
            upsert rosteringList;
        }
        if(!existingRosteringToDeleteList.isEmpty()){
            delete existingRosteringToDeleteList;
        }
    }
    
    
    /* Comman method of batch class */
    
    public static Employee_Work_Week__c getemployeeWorkWeekByDateRange(List<Employee_Work_Week__c> workWeekList, Date fromDate, date toDate){
        Employee_Work_Week__c  workWeek = new Employee_Work_Week__c();
        Date processedEffectivedate = null;
        Date workWeekEffective_Date = null;
        for(Employee_Work_Week__c eww: workWeekList){
            if(fromDate >= eww.Effective_Date__c && (eww.Effective_Date__c > processedEffectivedate || processedEffectivedate == null) ){
                processedEffectivedate = eww.Effective_Date__c;
                workWeek = eww;
            }
        }
        if(workWeekEffective_Date  != null) workWeek.Effective_Date__c = workWeekEffective_Date  ;
        return workWeek;
    }
    
    public static List<Rostering__c> getGenerateRosteringBetweenDateRange(Employee_Work_Week__c workWeek, Date startDate, date endDate, Id centreId, Map<Id,Map<Date, Rostering__c>> existingRosteringMap, Id empId){
        List<Rostering__c> rosteringList = new List<Rostering__c>();
        Map<Date, Rostering__c> existingRosteringByDateMap = new Map<Date, Rostering__c>();
        if(existingRosteringMap.containsKey(empId)){
            existingRosteringByDateMap = existingRosteringMap.get(empId);
        }
        while(startDate < endDate) {
            Datetime dt = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            String dayOfWeek = dt.format('EEEE');
            
            Rostering__c rosteringCopy = new Rostering__c (
                Additional_Work_Day__c = false,
                Effective_Date__c = startDate,
                Employee__c = empId,
                Shift__c = 'Opening Hours',
                Centre__c  = centreId,
                Work_Day__c = ''
            );
            
            if(dayOfWeek.equalsignorecase('Monday')){
                rosteringCopy.Work_Day__c = workWeek.Monday__c;
                rosteringCopy.Notes__c = workWeek.Monday_Note__c;
                rosteringCopy.Shift__c = workWeek.Monday_Shift__c;
                rosteringCopy.Centre__c = workWeek.Monday_Centre__c;
            }else if(dayOfWeek.equalsignorecase('Saturday')){
                rosteringCopy.Work_Day__c = workWeek.Saturday__c;
                rosteringCopy.Notes__c = workWeek.Saturday_Note__c;
                rosteringCopy.Shift__c = workWeek.Saturday_Shift__c;
                rosteringCopy.Centre__c = workWeek.Saturday_Centre__c;
            }else if(dayOfWeek.equalsignorecase('Sunday')){
                rosteringCopy.Work_Day__c = workWeek.Sunday__c;
                rosteringCopy.Notes__c = workWeek.Sunday_Note__c;
                rosteringCopy.Shift__c = workWeek.Sunday_Shift__c;
                rosteringCopy.Centre__c = workWeek.Sunday_Centre__c;
            }else if(dayOfWeek.equalsignorecase('Friday')){
                rosteringCopy.Work_Day__c = workWeek.Friday__c;
                rosteringCopy.Notes__c = workWeek.Friday_Note__c;
                rosteringCopy.Shift__c = workWeek.Friday_Shift__c;
                rosteringCopy.Centre__c = workWeek.Friday_Centre__c;
            }else if(dayOfWeek.equalsignorecase('Thursday')){
                rosteringCopy.Work_Day__c = workWeek.Thursday__c;
                rosteringCopy.Notes__c = workWeek.Thursday_Note__c;
                rosteringCopy.Shift__c = workWeek.Thursday_Shift__c;
                rosteringCopy.Centre__c = workWeek.Thursday_Centre__c;
            }else if(dayOfWeek.equalsignorecase('Tuesday')){
                rosteringCopy.Work_Day__c = workWeek.Tuesday__c;
                rosteringCopy.Notes__c = workWeek.Tuesday_Note__c;
                rosteringCopy.Shift__c = workWeek.Tuesday_Shift__c;
                rosteringCopy.Centre__c = workWeek.Tuesday_Centre__c;
            }else if(dayOfWeek.equalsignorecase('Wednesday')){
                rosteringCopy.Work_Day__c = workWeek.Wednesday__c;
                rosteringCopy.Notes__c = workWeek.Wednesday_Note__c;
                rosteringCopy.Shift__c = workWeek.Wednesday_Shift__c;
                rosteringCopy.Centre__c = workWeek.Wednesday_Centre__c;
            }
            
            if(String.isNotBlank(rosteringCopy.Centre__c) && String.isNotBlank(rosteringCopy.Work_Day__c) && !rosteringCopy.Work_Day__c.equalsignorecase('Rest Day') && !existingRosteringByDateMap.containsKey(rosteringCopy.Effective_Date__c)){
                rosteringList.add(rosteringCopy);
            }else if(String.isNotBlank(rosteringCopy.Centre__c) && String.isNotBlank(rosteringCopy.Work_Day__c) && !rosteringCopy.Work_Day__c.equalsignorecase('Rest Day') && existingRosteringByDateMap.containsKey(rosteringCopy.Effective_Date__c)){
                Rostering__c r = existingRosteringByDateMap.get(rosteringCopy.Effective_Date__c);
                if(r.Work_Day__c != rosteringCopy.Work_Day__c || r.Shift__c != rosteringCopy.Shift__c || r.Centre__c != rosteringCopy.Centre__c){
                    rosteringCopy.Work_Day__c = r.Work_Day__c;
                    rosteringCopy.Id = r.Id;
                    rosteringList.add(rosteringCopy);
                }
            }else if((String.isBlank(rosteringCopy.Work_Day__c) || rosteringCopy.Work_Day__c.equalsignorecase('Rest Day')) && existingRosteringByDateMap.containsKey(rosteringCopy.Effective_Date__c)){
                existingRosteringToDeleteList.add(existingRosteringByDateMap.get(rosteringCopy.Effective_Date__c));
            }
            startDate = startDate.addDays(1);
        }
        return rosteringList;
    }
     
    // Method used to delete all existing rostering record related to employee and not as additional work day
    public static Map<Id,Map<Date, Rostering__c>> getExistingRosteringByAccountWithDateRange(List<Account> accountList, Date startDate, Date endDate){
        Map<Id,Map<Date, Rostering__c>> existingReosteringMap = new Map<Id,Map<Date, Rostering__c>>();
        List<Rostering__c> existingRosteringList = [SELECT Id, Employee__c, Work_Day__c ,Shift__c,Centre__c, Effective_Date__c FROM Rostering__c WHERE Employee__c IN: accountList AND Effective_Date__c > =: startDate AND Effective_Date__c <=: endDate AND Additional_Work_Day__c = false];
        
        // Map data with existing ..
        for(Rostering__c rost: existingRosteringList){
            // adding data as main content "Employee"
            if(!existingReosteringMap.containsKey(rost.Employee__c)){
                existingReosteringMap.put(rost.Employee__c, new Map<Date, Rostering__c>());
            }
            // exist date and its rostering records
            if(!existingReosteringMap.get(rost.Employee__c).containsKey(rost.Effective_Date__c)){
                existingReosteringMap.get(rost.Employee__c).put(rost.Effective_Date__c, rost);
            }
        }
        return existingReosteringMap;
    } 
    
    // this method used for setup week data with account
    public static Map<Id,List<Employee_Work_Week__c>> getWorkWeekByAccount(List<Account> employeeList){
        Map<Id,List<Employee_Work_Week__c>> employeeWorkWeekMap = new Map<Id,List<Employee_Work_Week__c>>();
        // No records needed after define date in 'setupRosteringForMonths'
        //Date startDate = Date.today();
        Date endDate = startdate.addMonths(setupRosteringForMonths);
        for(Employee_Work_Week__c eww: [SELECT Id, Name, Employee__c, Effective_Date__c, Monday__c, Tuesday__c, Wednesday__c, Thursday__c, Friday__c, Saturday__c, Working_Days_in_a_Week__c, Sunday__c, Monday_Note__c, Saturday_Note__c, Thursday_Note__c, Sunday_Note__c, Tuesday_Note__c, Wednesday_Note__c, Friday_Note__c, Wednesday_Shift__c, Tuesday_Shift__c, Friday_Shift__c, Thursday_Shift__c, Sunday_Shift__c, Monday_Shift__c, Saturday_Shift__c, Monday_Centre__c, Saturday_Centre__c, Sunday_Centre__c, Thursday_Centre__c, Tuesday_Centre__c, Friday_Centre__c, Wednesday_Centre__c FROM Employee_Work_Week__c WHERE Employee__c IN: employeeList AND Effective_Date__c <=: endDate ORDER By Effective_Date__c ASC]){
            if(!employeeWorkWeekMap.containsKey(eww.Employee__c)){
                employeeWorkWeekMap.put(eww.Employee__c, new List<Employee_Work_Week__c >());
            }
            employeeWorkWeekMap.get(eww.Employee__c).add(eww);
        }
        return employeeWorkWeekMap;
    }
}