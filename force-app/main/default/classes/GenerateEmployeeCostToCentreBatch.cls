global class GenerateEmployeeCostToCentreBatch implements Database.Batchable<sObject>, Database.Stateful{
    global Set<Id> accountIdSet = new Set<Id>();
    global Date batchProcessDate = system.today();
    global String mString;
    global String yString;
    global GenerateEmployeeCostToCentreBatch(){
        
    }
    
    global GenerateEmployeeCostToCentreBatch(Set<Id> accountIdSet){
        this.accountIdSet = accountIdSet;
    }
    global GenerateEmployeeCostToCentreBatch(Set<Id> accountIdSet, Date batchProcessDate ){
        this.accountIdSet = accountIdSet;
        this.batchProcessDate = batchProcessDate;    
    }
    
    global GenerateEmployeeCostToCentreBatch(Date batchProcessDate ){
        this.batchProcessDate = batchProcessDate ;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id FROM Account WHERE RecordType.Name IN (\'Employee\',\'Teacher\') ';
        if(accountIdSet != null && !accountIdSet.isEmpty()) query += ' AND Id IN : accountIdSet ';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Date startDate = date.newInstance(batchProcessDate.Year(),batchProcessDate.month(),1); 
        Date endDate = date.newInstance(batchProcessDate.Year(),batchProcessDate.month(),Date.DaysInMonth(batchProcessDate.Year(),batchProcessDate.month()));

        
        List<Account> accountList = (List<Account>) scope;
        
        system.debug('batchProcessDate==='+batchProcessDate);
        system.debug('accountList=='+accountList);
        
        // A wrapper class to combine cost data with employee or teacher
        Map<Id, CostCentre> costCentreMap = new Map<Id, CostCentre>();
        for(Payout__c pay : [SELECT Id, Employee_Name__c,Payout_Date__c,Month__c,Year__c  FROM Payout__c WHERE Employee_Name__c IN : accountList and Calendar_Month(Payout_Date__c)=:batchProcessDate.month() and Calendar_Year(Payout_Date__c)=:batchProcessDate.year()]){
            costCentreMap.put(pay.Employee_Name__c  , new CostCentre(pay));
            If(mstring==null || ystring==null){
                mString = pay.Month__c;
                ystring = pay.Year__c;
            }
        }
        
        // Employee Rostering
        for(Rostering__c rost : [SELECT Id, Name, Employee__c, Effective_Date__c, Centre__c, Additional_Work_Day__c, Shift__c, Notes__c, PayItem__c, Work_Day__c FROM Rostering__c WHERE Employee__c IN : accountList AND Effective_Date__c >=: startDate AND Effective_Date__c  <=: endDate]){
            if(costCentreMap.containsKey(rost.Employee__c)){
                CostCentre cost = costCentreMap.get(rost.Employee__c);
                
                // working time calculate
                Decimal workTime = 0;
                if(rost.Work_Day__c.equalsignorecase('Full Day')){
                    workTime = 1.00;
                }else if(rost.Work_Day__c.equalsignorecase('Half Day')){
                    workTime = 0.50;
                }
                cost.totalWorking += workTime;
                
                if(!cost.workingByCenreMap.containsKey(rost.Centre__c)) cost.workingByCenreMap.put(rost.Centre__c, 0.00);
                Decimal centreTime = cost.workingByCenreMap.get(rost.Centre__c);
                centreTime += workTime;
                cost.workingByCenreMap.put(rost.Centre__c, centreTime );
                
                costCentreMap.put(rost.Employee__c, cost );
            }
        }
        
        // Teacher_Working_Hour__c  
        for(Teacher_Working_Hour__c  twh : [SELECT Id, Teacher_Name__c, Working_Day__c, Active__c, Start_Time__c, End_Time__c, Remarks__c, Break_Time__c, Centre__c, Center_Name__c FROM Teacher_Working_Hour__c WHERE Teacher_Name__c IN : accountList AND Active__c = true AND Break_Time__c = false]){
            if(costCentreMap.containsKey(twh.Teacher_Name__c)){
                CostCentre cost = costCentreMap.get(twh.Teacher_Name__c);
                
                Decimal tWorkingTime = getTeacherWorkingTimeForMonth(twh);
                cost.totalWorking += tWorkingTime;
                system.debug('tWorkingTime  *** '+tWorkingTime );
                if(!cost.workingByCenreMap.containsKey(twh.Center_Name__c)) cost.workingByCenreMap.put(twh.Center_Name__c , 0.00);
                Decimal centreTime = cost.workingByCenreMap.get(twh.Center_Name__c);
                centreTime += tWorkingTime;
                cost.workingByCenreMap.put(twh.Center_Name__c, centreTime );
                
                costCentreMap.put(twh.Teacher_Name__c, cost );
            }
        }
        Map<String, Employee_Cost_Centre__c> existingCostCentreMap = getExistingEmployeeCostCentre();
        List<Employee_Cost_Centre__c> employeeCostCentreList = new List<Employee_Cost_Centre__c>();
        // setup cost centre data
        for(Id accountId : costCentreMap.keyset()){
            CostCentre cost = costCentreMap.get(accountId);
            for(Id centreId : cost.workingByCenreMap.keyset()){
                system.debug(cost.totalWorking + ' **** '+cost.workingByCenreMap.get(centreId));
                if(cost.totalWorking > 0 && cost.workingByCenreMap.get(centreId) > 0){
                    Decimal ctc = (cost.workingByCenreMap.get(centreId) * 100 )/cost.totalWorking ;
                    
                    Employee_Cost_Centre__c ecc = new Employee_Cost_Centre__c(
                        Centre__c = centreId,
                        Cost_to_Centre__c = ctc,
                        Employee__c = accountId,
                        Month__c = cost.payout.Month__c,
                        Year__c = cost.payout.Year__c,
                        Payout__c = cost.payout.Id
                    );
                    String key = ecc.Employee__c+''+ecc.Centre__c+''+ecc.Payout__c;
                    if(existingCostCentreMap.containsKey(key)){
                        ecc.Id = existingCostCentreMap.get(key).Id;
                        existingCostCentreMap.remove(key);
                    }
                    employeeCostCentreList.add(ecc);
                }
            }
            
        }
        if(!employeeCostCentreList.isEmpty()){
            upsert employeeCostCentreList;
        }
        // delete existing cost centre
        if(existingCostCentreMap != null && !existingCostCentreMap.values().isEmpty()){
            delete existingCostCentreMap.values();
        }
    }
    
    global Map<String, Employee_Cost_Centre__c> getExistingEmployeeCostCentre(){
        Map<String, Employee_Cost_Centre__c> eccMap = new Map<String, Employee_Cost_Centre__c>();
        for(Employee_Cost_Centre__c ecc : [SELECT Id, Year__c, Month__c, Payout__c, Cost_to_Centre__c, Centre__c, Employee__c, Name FROM Employee_Cost_Centre__c WHERE Year__c = : yString AND Month__c = : mString AND Employee__c IN: accountIdSet]){
            String key = ecc.Employee__c+''+ecc.Centre__c+''+ecc.Payout__c;
            eccMap.put(key, ecc);
        }
        return eccMap;
    }
    
    global Decimal getTeacherWorkingTimeForMonth(Teacher_Working_Hour__c  twh ){
        Decimal workingTimeMonth = 0;
        Decimal workingTimeDay = (twh.End_Time__c.hour() - twh.Start_Time__c.hour()) * 60;
        
        Date startDate = date.newInstance(batchProcessDate.Year(),batchProcessDate.month(),1); 
        Date endDate = date.newInstance(batchProcessDate.Year(),batchProcessDate.month(),Date.DaysInMonth(batchProcessDate.Year(),batchProcessDate.month()));
        
        workingTimeDay += twh.End_Time__c.minute() - twh.Start_Time__c.minute();
        system.debug('workingTimeDay  *** '+workingTimeDay  );
        system.debug('twh.Working_Day__c *** '+twh.Working_Day__c);
        system.debug('startDate *** '+startDate );
        system.debug('endDate *** '+endDate);
        //if(workingTimeDay < 0) workingTimeDay = workingTimeDay * -1;
        if(workingTimeDay > 0 && twh.Working_Day__c != null){
            while(startDate <= endDate){
                system.debug('startDate **'+startDate );
                DateTime dt = (DateTime) startDate ;
                String day = dt.format('EEE');
                if(day.equalsignorecase(twh.Working_Day__c)){
                    workingTimeMonth += workingTimeDay;
                    startDate = startDate.addDays(7);
                }else{
                    startDate = startDate.addDays(1);
                }
            }
        }
        system.debug('workingTimeMonth *** '+workingTimeMonth );
        return workingTimeMonth ;
    }
    
    global void finish(Database.BatchableContext BC){}
    
    global class CostCentre{
        global Payout__c payout ;
        global Decimal totalWorking ;
        global Map<Id, Decimal> workingByCenreMap ;
        
        global CostCentre(Payout__c payout){
            this.payout = payout;
            this.workingByCenreMap = new Map<Id, Decimal>();
            this.totalWorking = 0.00;
        }
    }
}