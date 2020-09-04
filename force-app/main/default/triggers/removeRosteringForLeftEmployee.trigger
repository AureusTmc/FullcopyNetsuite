trigger removeRosteringForLeftEmployee on Account (after update) {
    Map<Id,date> employeeLastWorkingMap = new Map<Id,date>();
    Date minLastDate;
    for(Account acc:Trigger.new){
        if(acc.Employee_Status__c=='Left' && acc.Employee_Status__c!=Trigger.oldMap.get(acc.Id).Employee_Status__c){
            Date dt = system.today();
            if(acc.Last_Working_Date__c!=null){
                dt = acc.Last_Working_Date__c;
            }
            employeeLastWorkingMap.put(acc.Id,dt);
            if(minLastDate!=null){
                if(minLastDate>dt){
                    minLastDate = dt;
                }
            }else{
                minLastDate = dt;
            }
        }
    }
    
    If(employeeLastWorkingMap.size()>0 && minLastDate!=null){
        List<Rostering__c> delRosteringList = new List<Rostering__c>();
        for(Rostering__c rost:[Select id,Employee__c,Effective_Date__c from Rostering__c where Employee__c in:employeeLastWorkingMap.keyset() and Effective_Date__c>=:minLastDate]){
            Date empLastWorkingDate = employeeLastWorkingMap.get(rost.Employee__c);
            If(rost.Effective_Date__c>empLastWorkingDate){
                delRosteringList.add(rost);
            }
        }
        if(delRosteringList.size()>0){
            delete delRosteringList;
        }
    }
}