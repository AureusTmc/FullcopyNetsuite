global class TrialAttendedTaskBatch implements Database.Batchable<sObject>{
Private String Closed= ConstantsClass.ClosedStatus;
   // private String StatusNew = ConstantsClass.NewStatus;
    private string SalesRecordType=ConstantsClass.caseSalesEnqRecTypeName;
    
    global Database.QueryLocator start(Database.BatchableContext bc){ 
        set<string> CheckStatus= new set<string>();
        CheckStatus.add(Closed);
        Id recorId = Schema.SObjectType.case.getRecordTypeInfosByName().get(SalesRecordType).getRecordTypeId();
        String query = 'Select Id,OwnerId,ContactId,CreatedDate,Trial_Date__c,RecordTypeId From Case Where Status Not In :CheckStatus AND RecordTypeId=:recorId AND Stage__c=\'Trial Attended\' AND Trial_Date__c !=null and owner.type = \'user\'';
        return Database.getQueryLocator(query); 
    }
    global void execute (Database.BatchableContext bc ,List<sObject> recordsList){
        System.debug('Execute-------');
        List<Case> records = (List<Case>)recordsList;
        Date currentDate = System.today();
        List<Task> taskToBeCreated = new List<Task>();
        for(Case rec : records){
           Date trialDate=Date.newinstance(rec.Trial_Date__c.year(), rec.Trial_Date__c.month(), rec.Trial_Date__c.day());
            Integer daysBetween = trialDate.daysBetween(currentDate);
                Task tsk = new Task();
                    
                    if(daysBetween == 2){ 
                        
                        tsk.ownerId = rec.OwnerId;
                        tsk.Status = 'Open';
                        tsk.Priority = 'High';
                        tsk.Subject = 'Follow up (2) to book Enrolment';
                        tsk.ActivityDate = System.today();
                        tsk.WhoId=rec.ContactId;
                        tsk.WhatId=rec.Id;
                    }
            		 if(daysBetween == 4){ 
                        
                        tsk.ownerId = rec.OwnerId;
                        tsk.Status = 'Open';
                        tsk.Priority = 'High';
                        tsk.Subject = 'Follow up (4) to book Enrolment';
                        tsk.ActivityDate = System.today();
                        tsk.WhoId=rec.ContactId;
                        tsk.WhatId=rec.Id;
                    }
            
            		 if(daysBetween == 7){ 
                        
                        tsk.ownerId = rec.OwnerId;
                        tsk.Status = 'Open';
                        tsk.Priority = 'High';
                        tsk.Subject = 'Follow up (7) to book Enrolment';
                        tsk.ActivityDate = System.today();
                        tsk.WhoId=rec.ContactId;
                        tsk.WhatId=rec.Id;
                    }
            
            		 if(daysBetween == 10){ 
                        
                        tsk.ownerId = rec.OwnerId;
                        tsk.Status = 'Open';
                        tsk.Priority = 'High';
                        tsk.Subject = 'Follow up (10) to book Enrolment';
                        tsk.ActivityDate = System.today();
                        tsk.WhoId=rec.ContactId;
                        tsk.WhatId=rec.Id;
                    }
            
            		 if(daysBetween == 14){ 
                        
                        tsk.ownerId = rec.OwnerId;
                        tsk.Status = 'Open';
                        tsk.Priority = 'High';
                        tsk.Subject = 'Follow up (14) to book Enrolment';
                        tsk.ActivityDate = System.today();
                        tsk.WhoId=rec.ContactId;
                        tsk.WhatId=rec.Id;
                    }
            
            		 if(daysBetween == 30){ 
                        
                        tsk.ownerId = rec.OwnerId;
                        tsk.Status = 'Open';
                        tsk.Priority = 'High';
                        tsk.Subject = 'Final Follow up (30) to book Enrolment';
                        tsk.ActivityDate = System.today();
                        tsk.WhoId=rec.ContactId;
                        tsk.WhatId=rec.Id;
                    }
            
            		
            		
                
                if(!String.isBlank(tsk.Subject)){
                    taskToBeCreated.add(tsk);       
                }
        }
        if(!taskToBeCreated.isEmpty()){
            insert taskToBeCreated;
        }
    }
    global void finish(Database.BatchableContext bc){
        System.debug('----Finish');
    }
}