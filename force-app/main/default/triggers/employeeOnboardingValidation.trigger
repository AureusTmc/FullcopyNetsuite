trigger employeeOnboardingValidation on Account (before update) {
    string employeeRecordTypeId = schema.SObjectType.Account.getRecordTypeInfosByName().get('Employee').getRecordTypeId();
    Set<Id> accIds = new Set<Id>();
    for(Account acc:Trigger.new){
        if(acc.recordTypeId==employeeRecordTypeId){
            If(acc.Onboarding_Stage__c!=null && acc.Onboarding_Stage__c!=Trigger.oldMap.get(acc.Id).Onboarding_Stage__c){
                accIds.add(acc.Id);
            }        
        }
    }
    
    If(accIds.size()>0){
    
        Map<Id,List<Checklist_Item__c>> accToChecklistMap = new Map<Id,List<Checklist_Item__c>>();
        
        for(Checklist_Item__c ci : [Select id,Employee__c from Checklist_Item__c where Employee__c in:accIds and Due_Date__c<:system.today() and Completed__c=False and Type__c='Onboarding Process']){
            List<Checklist_Item__c> tempList = new List<Checklist_Item__c>();
            if(accToChecklistMap.containsKey(ci.Employee__c)){
                tempList.addAll(accToChecklistMap.get(ci.Employee__c));
            }
            tempList.add(ci);
            accToChecklistMap.put(ci.Employee__c,tempList);
        }
    
        Map<Id,List<Employee_Document__c>> accToEmpDocMap = new Map<Id,List<Employee_Document__c>>();
        for(Employee_Document__c empDoc: [Select id,name,Stage__c,Required__c,Uploaded__c,Employee__c from Employee_Document__c where Employee__c=:accIds and Required__c=true and Uploaded__c=false]){
            List<Employee_Document__c> tempList = new List<Employee_Document__c>();
            if(accToEmpDocMap.containsKey(empDoc.Employee__c)){
                tempList.addAll(accToEmpDocMap.get(empDoc.Employee__c));
            }
            tempList.add(empDoc);
            
            accToEmpDocMap.put(empDoc.Employee__c,tempList);
        }
        
        if(accToEmpDocMap.size()>0){
            for(Account acc:Trigger.new){
                if(acc.recordTypeId==employeeRecordTypeId){
                    if(accToChecklistMap.containsKey(acc.Id)){
                        acc.addError('Please complete the overdue checklist item.');
                        continue;
                    }
                    if(accToEmpDocMap.containsKey(acc.Id)){
                        Set<string> stagesToCheck = new Set<string>();
                        
                        Switch on acc.Onboarding_Stage__c{
                            when 'In Process'{
                                stagesToCheck.add('In Process');
                            }
                            when 'LO Signed'{
                                stagesToCheck.add('In Process');
                                stagesToCheck.add('LO Signed');
                            }
                            when 'Contract Signed'{
                                stagesToCheck.add('In Process');
                                stagesToCheck.add('LO Signed');
                                stagesToCheck.add('Contract Signed');
                            }
                            when 'Joining'{
                                stagesToCheck.add('In Process');
                                stagesToCheck.add('LO Signed');
                                stagesToCheck.add('Contract Signed');
                                stagesToCheck.add('Joining');
                            }
                            when 'Completed'{
                                stagesToCheck.add('In Process');
                                stagesToCheck.add('LO Signed');
                                stagesToCheck.add('Contract Signed');
                                stagesToCheck.add('Joining');
                                stagesToCheck.add('Completed');
                            }
                        }
                        
                        for(Employee_Document__c ed: accToEmpDocMap.get(acc.Id)){
                            if(stagesToCheck.contains(ed.stage__c)){
                                acc.addError('Please upload the required documents before moving to next stage.');
                                break;
                            }
                        }
                    }                    
                }
            }
        }
    }
}