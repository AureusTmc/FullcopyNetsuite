trigger RevenueCommissionTrigger on Revenue_Commission__c (after insert, after update) {
    Set<Id> empIds = new Set<Id>();
    Set<string> monthSet = new Set<string>();
    Set<string> yearSet = new Set<string>();
    
    for(Revenue_Commission__c rc:Trigger.New){
        if((Trigger.isInsert && (rc.Individual_Revenue__c>0 || rc.Group_Revenue__c>0)) || (Trigger.isUpdate && (rc.Individual_Revenue__c!=trigger.oldMap.get(rc.Id).Individual_Revenue__c || rc.Group_Revenue__c!=Trigger.oldMap.get(rc.Id).Group_Revenue__c))){
            empIds.add(rc.Employee__c);
            monthSet.add(rc.month__c);
            yearSet.add(rc.Year__c);
        }
    }
    
    Map<string,Id> payitemMasterMap = new Map<string,Id>();
    for(Payitem_Master__c pm: [Select id,Name from Payitem_Master__c where Active__c=true and Name in (:AureusHRUtility.individualCommission,:AureusHRUtility.groupCommission)]){
        payitemMasterMap.put(pm.Name,pm.Id);
    }
    
    Map<Id,Account> employeeMap = new Map<Id, Account>([Select id,Individual_Commission__c,Group_Commission__c from Account where Id in:empids and Payout_Type__c='Commission']);
    
    Map<string,Payout__c> payoutMap = new Map<string,Payout__c>();
    for(Payout__c py:[Select Id,Employee_Name__c,Month__c,Year__c,(Select id,Payitem__r.Name,Type__c,Value__c,Amount__c from Payitems__r where System_Generated__c=true and Payitem__r.Name in (:AureusHRUtility.individualCommission,:AureusHRUtility.groupCommission) limit 2) from Payout__c where Employee_Name__c in:empIds and Month__c in:monthSet and Year__c in:yearSet]){
        payoutMap.put((py.Employee_Name__c+'-'+py.Month__c+'-'+py.Year__c),py);
    }
    
    List<PayItem__c> payitemList = new List<PayItem__c>();
    
    for(Revenue_Commission__c rc:Trigger.New){
        if(employeeMap.containsKey(rc.Employee__c) && payoutMap.containsKey(rc.Employee__c+'-'+rc.Month__c+'-'+rc.Year__c)){
            Payout__c payout = payoutMap.get(rc.Employee__c+'-'+rc.Month__c+'-'+rc.Year__c);
            Account employee = employeeMap.get(rc.Employee__c);
            
            PayItem__c individualPayitem = new PayItem__c();
            PayItem__c groupPayitem = new PayItem__c();
            
            if(payout.Payitems__r.size()>0){
                for(PayItem__c pi:payout.Payitems__r){
                    if(pi.Payitem__r.Name==AureusHRUtility.individualCommission){
                        individualPayitem.Id = pi.Id;
                    }else if(pi.Payitem__r.Name==AureusHRUtility.groupCommission){
                        groupPayitem.Id = pi.Id; 
                    }
                }
            }
            
            if(payitemMasterMap.containsKey(AureusHRUtility.individualCommission) && employee.Individual_Commission__c>0 && rc.Individual_Revenue__c>0){
                individualPayitem.Value__c = rc.Individual_Revenue__c*employee.Individual_Commission__c/100.00;
                individualPayitem.Type__c = 'Amount'; 
                individualPayitem.Notes__c = employee.Individual_Commission__c+'% of '+rc.Individual_Revenue__c;
                
                if(individualPayitem.Id==null){
                    individualPayitem.Payitem__c = payitemMasterMap.get(AureusHRUtility.individualCommission);
                    individualPayitem.Payout__c = payout.Id;
                    individualPayitem.System_Generated__c = true;
                }
                payitemList.add(individualPayitem);
            }else{
                if(individualPayitem.Id!=null){
                    individualPayitem.Value__c = 0;
                    individualPayitem.Type__c = 'Amount';
                    payitemList.add(individualPayitem);
                }
            }
            
            if(payitemMasterMap.containsKey(AureusHRUtility.groupCommission) && employee.Group_Commission__c>0 && rc.Group_Revenue__c>0){
                groupPayitem.Value__c = rc.Group_Revenue__c*employee.Group_Commission__c/100.00;
                groupPayitem.Type__c = 'Amount';
                groupPayitem.Notes__c = employee.Group_Commission__c+'% of '+rc.Group_Revenue__c;
                
                if(groupPayitem.Id==null){
                    groupPayitem.Payitem__c = payitemMasterMap.get(AureusHRUtility.groupCommission);
                    groupPayitem.Payout__c = payout.Id;
                    groupPayitem.System_Generated__c = true;
                }
                payitemList.add(groupPayitem);
            }else{
                if(groupPayitem.Id!=null){
                    groupPayitem.Value__c = 0;
                    groupPayitem.Type__c = 'Amount';
                    payitemList.add(groupPayitem);
                }
            }
        }
    }
    
    If(payitemList.size()>0){
        upsert payitemList;
    }
}