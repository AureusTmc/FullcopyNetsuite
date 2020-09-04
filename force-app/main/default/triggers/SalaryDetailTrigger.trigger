trigger SalaryDetailTrigger on Salary_Detail__c (before insert, before update) {
    
    Set<Id> empIds = new Set<Id>();
    Set<Id> salDetIds = new Set<Id>();
    Set<Date> effDateSet = new Set<Date>();
    for(Salary_Detail__c sd: Trigger.New){
        if(sd.Effective_Date__c!=null && (Trigger.isInsert || sd.Effective_Date__c!=Trigger.oldMap.get(sd.Id).Effective_Date__c)){
            empIds.add(sd.Employee_Name__c);
            //System.debug(sd.Id);
            If(sd.Id!=null){
                salDetIds.add(sd.Id);
            }
            effDateSet.add(sd.Effective_Date__c);
        }    
    }
    //System.debug(empIds+''+salDetIds+''+effDateSet);
    
    If(empIds.size()>0){
        Map<Id,List<Salary_Detail__c>> empToSalaryMap = new Map<Id,List<Salary_Detail__c>>(); 
        for(Salary_Detail__c sd: [Select id,Employee_Name__c,Effective_Date__c from Salary_Detail__c where Employee_Name__c in:empIds and Id not in :salDetIds and Effective_Date__c in:effDateSet]){
            List<Salary_Detail__c> tempList = new List<Salary_Detail__c>();
            If(empToSalaryMap.containsKey(sd.Employee_Name__c)){
                tempList.addAll(empToSalaryMap.get(sd.Employee_Name__c));
            }
            tempList.add(sd);
            empToSalaryMap.put(sd.Employee_Name__c,tempList);
        }
        
        If(empToSalaryMap.size()>0){
            for(Salary_Detail__c sd: Trigger.New){
                if(empToSalaryMap.containsKey(sd.Employee_Name__c)){
                    for(Salary_Detail__c existingSD : empToSalaryMap.get(sd.Employee_Name__c)){
                        If(sd.Effective_Date__c==existingSD.Effective_Date__c){
                            sd.addError('Another salary detail with same effective date already present.');
                        }
                    }
                }
            }
        }
    }

    /*if(trigger.isAfter){
        if(trigger.isInsert){
            new SalaryDetailTriggerHandler().afterInsertContext();
        }else if(trigger.isUpdate){
            new SalaryDetailTriggerHandler().afterUpdateContext();
        }else if(trigger.isDelete){
            new SalaryDetailTriggerHandler().afterDeleteContext();
        }else if(trigger.isUnDelete){
            new SalaryDetailTriggerHandler().afterUnDeleteContext();
        }
    }*/
}