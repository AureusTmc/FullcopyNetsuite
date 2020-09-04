trigger UpdateEnrolmentNo on Enrolment__c (after insert, after delete,after undelete,after update) {
    
    if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUndelete){
            UpdateEnrolmentNoCLass.updatetotalEnrolment(Trigger.New);
        }
        if(Trigger.isDelete){
            UpdateEnrolmentNoCLass.updatetotalEnrolment(Trigger.Old);
        } 
        if(Trigger.isUpdate){
            List<Enrolment__c> enrList= new List<Enrolment__c>();
            for(Enrolment__c enrObj:Trigger.New){
                if (Trigger.oldmap.get(enrObj.Id).Type__c != enrObj.Type__c || Trigger.oldmap.get(enrObj.Id).Stage__c != enrObj.Stage__c 
                                                             || Trigger.oldmap.get(enrObj.Id).Package_Process_Status__c != enrObj.Package_Process_Status__c ||
                                                             Trigger.oldmap.get(enrObj.Id).Package_Process_Type__c != enrObj.Package_Process_Type__c) 
                {
                    enrList.add(enrObj);
                                                                        
                }
                //system.debug('---enrList'+enrList);
                if(enrList.size()>0){
                   // system.debug('enrList'+enrList);
                   UpdateEnrolmentNoCLass.updatetotalEnrolment(enrList); 
                }
                
            }
          
        } 
    } 

}