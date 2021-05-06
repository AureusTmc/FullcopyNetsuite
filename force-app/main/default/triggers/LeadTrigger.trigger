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
            List<Lead> rentalLeadList = new List<Lead>();//added by 6-May-2021:start: Nishi: On the bases of UTM Campaign parameters, We will identify the customer for the Instrument Rental Enquiry process.
            Set<String> sourceSet = new Set<String>{'Website','Facebook'};
                
            for(Lead l: Trigger.new){
                if(String.isNotBlank(l.LeadSource) && String.isNotBlank(l.Email) && sourceSet.contains(l.LeadSource) && l.Center__c != null){
                    //added by 6-May-2021:start: Nishi: On the bases of UTM Campaign parameters, We will identify the customer for the Instrument Rental Enquiry process.
                    if(string.isnotBlank( l.UTM_Campaign__c) && (l.UTM_Campaign__c.containsIgnoreCase('Rental')  
                    || l.UTM_Campaign__c.containsIgnoreCase('Purchase'))){
                        rentalLeadList.add(l);
                    }else{
                    //6-May-2021: Nishi:end: On the bases of UTM Campaign parameters, We will identify the customer for the Instrument Rental Enquiry process.
                        webLeadList.add(l);
                    }
                }
            }
            
            if(webLeadList != null && webLeadList.size() > 0)
                LeadTriggerHelper.automateWebLeadProcess(webLeadList,true);
             //added by 6-May-2021:start: Nishi: On the bases of UTM Campaign parameters, We will identify the customer for the Instrument Rental Enquiry process and create  Instrument Rental  case records.
            if(rentalLeadList != null && rentalLeadList.size() > 0)
                LeadTriggerHelper.automateWebLeadProcess(rentalLeadList,false);
            //added by 6-May-2021:start: Nishi: On the bases of UTM Campaign parameters, We will identify the customer for the Instrument Rental Enquiry process and create  Instrument Rental  case records.
            
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