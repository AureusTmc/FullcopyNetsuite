// @Ravi...... trigger actually update total deposit on enrolment of invoice line item amount  when there is changes in status  of invoice
trigger UpdateEnrolmentDeposit on Invoice__c (after insert,after Update) {
    if(Trigger.isAfter){
        /* if(trigger.isInsert || trigger.isUndelete){
            UpdateEnrolmentDepositClass.updateDeposit(trigger.new);
        }*/
        
        if(Trigger.isUpdate){
            List<Invoice__c> invList= new List<Invoice__c>();
            for(Invoice__c invObj:Trigger.New){
                if (Trigger.oldmap.get(invObj.Id).Status__c != invObj.Status__c) 
                {
                    invList.add(invObj); 
                }
                system.debug('---invList'+invList);
                if(invList.size()>0){
                    // system.debug('enrList'+enrList);
                    UpdateEnrolmentDepositClass.updateDeposit(invList); 
                }
                
            }
            
        } 
    }
       

}