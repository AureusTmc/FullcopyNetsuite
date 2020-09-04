trigger LeadTrigger on Lead (before insert, after insert) {
    
    //On insert
    if(Trigger.isInsert){
        if(Trigger.isBefore){
            //Center lookup population process
            LeadTriggerHelper.populateCenter(Trigger.new);
        }
        
        // Web to lead automation sales process
        if(Trigger.isAfter){
            List<Lead> webLeadList = new List<Lead>();
            Set<String> sourceSet = new Set<String>{'Website','Facebook'};
                
            for(Lead l: Trigger.new){
                if(String.isNotBlank(l.LeadSource) && String.isNotBlank(l.Email) && sourceSet.contains(l.LeadSource) && l.Center__c != null)
                    webLeadList.add(l);
            }
            
            if(webLeadList.size() > 0)
                LeadTriggerHelper.automateWebLeadProcess(webLeadList);
        }
	}
    
    
    //After udpate
    /*if(Trigger.isUpdate){
        List<Lead> convertdLeadList = new List<Lead>();
        
        for(Lead l: Trigger.new){
            if(l.IsConverted && !(Trigger.oldMap.get(l.Id).IsConverted))
            	convertdLeadList.add(l);                
        }
        
        if(convertdLeadList.size() > 0)
            LeadTriggerHelper.processEnrolments(convertdLeadList);
    }*/
}