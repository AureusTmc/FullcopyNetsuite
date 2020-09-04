global class TrialNoShowTaskBatch implements Database.Batchable<sObject>{
    Private String Closed= ConstantsClass.ClosedStatus;
    //private String StatusNew = ConstantsClass.NewStatus;
    private string SalesRecordType=ConstantsClass.caseSalesEnqRecTypeName;
    
    global Database.QueryLocator start(Database.BatchableContext bc){ 
        set<string> CheckStatus= new set<string>();
        CheckStatus.add(Closed);
        Id recorId = Schema.SObjectType.case.getRecordTypeInfosByName().get(SalesRecordType).getRecordTypeId();
        String query = 'Select Id,OwnerId,ContactId,Trial_No_Show_Date__c From Case Where Status Not In :CheckStatus AND RecordTypeId=:recorId AND Stage__c=\'Trial No Show\' AND Trial_No_Show_Date__c !=null and owner.type = \'user\'';
        return Database.getQueryLocator(query); 
    }
    global void execute (Database.BatchableContext bc ,List<sObject> recordsList){
        System.debug('Execute-------');
        List<Case> records = (List<Case>)recordsList;
        Date currentDate = System.today();
        List<Task> taskToBeCreated = new List<Task>();
        for(Case rec : records){
           // Date enquiryDate=Date.newinstance(rec.Enquiry_Date__c.year(), rec.Enquiry_Date__c.month(), rec.Enquiry_Date__c.day());
            Integer daysBetween = rec.Trial_No_Show_Date__c.daysBetween(currentDate);
            System.debug('====>'+daysBetween);
                Task tsk = new Task();
                    /*For Sales Enquiry talk Case  we need to create tasks for the time gap of 1 ,7days,5days*/
                    /*Before 2 week task*/
                    
                    if(daysBetween == 2){
                        tsk.ownerId = rec.OwnerId;
                        tsk.Status = 'Open';
                        tsk.Priority = 'High';
                        tsk.Subject = 'Follow up (2) to confirm new trial';
                        tsk.ActivityDate = System.today();
                        tsk.WhoId=rec.ContactId;
                        tsk.WhatId=rec.Id;
                    }
            		else if(daysBetween == 4){  
                        tsk.ownerId = rec.OwnerId;
                        tsk.Status = 'Open';
                        tsk.Priority = 'High';
                        tsk.Subject = 'Follow up (4) to confirm new trial';
                        tsk.ActivityDate = System.today();
                        tsk.WhoId=rec.ContactId;
                        tsk.WhatId=rec.Id;
                    }
            		 else if(daysBetween == 7){
                        tsk.ownerId = rec.OwnerId;
                        tsk.Status = 'Open';
                        tsk.Priority = 'High';
                        tsk.Subject = 'Follow up (7) to confirm new trial';
                        tsk.ActivityDate = System.today();
                        tsk.WhoId=rec.ContactId;
                        tsk.WhatId=rec.Id;
                    }
            		 else if(daysBetween == 10){ 
                        tsk.ownerId = rec.OwnerId;
                        tsk.Status = 'Open';
                        tsk.Priority = 'High';
                        tsk.Subject = 'Follow up (10) to confirm new trial';
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