trigger CaseTrigger on Case (Before Insert, After Insert, After Update) {
    
    if(trigger.isBefore){
        
        if(trigger.isInsert){
            //@Rajesh (Date 6-4-2019), This process is used to update contactId with the Parent contactId
            CaseTriggerHelper.updateContact(Trigger.new);            
        }
    }else if(trigger.isAfter){
        //Added by Ravi
        if(trigger.isInsert){
            set<id> ids = new set<id>();
            Id recorId = Schema.SObjectType.case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId();
            list<Case> CaseList =new list<Case>();
            for(Case cs: trigger.new){
                if(cs.RecordTypeId ==recorId && cs.Origin=='Email'){
                    CaseList.add(cs);
                    ids.add(cs.id);
                }
            }
            if(! CaseList.isEmpty()){
                CaseTriggerHelper.UpdateCase(ids);
            }
        }
        
        if(trigger.isUpdate){
            //@Rajesh (Date 3-4-2019), This process is used to update Lead and Opportunity and Enrolment as lost when case Lost
            //Commented by Rajesh on (17-06-2020), need to build this functionality from enrolment as per discussion with Ashish or Alex
            //CaseTriggerHelper.processOnCaseLost(Trigger.new, Trigger.oldMap);     
        }
        
        //@populate booking id in the trial case enrolment
        Map<Id, Id> caseEnrMap = new Map<Id, Id>();
        Map<String,String> changeStatusMap = new Map<String,String>();
        Firebase_Settings__c settings = Firebase_Settings__c.getValues('setting');
        // added by nishi: 28-Apr-2021:start:  To add sales enquiry  or Instrument Rental Enquiry recordtype condition
        set<string> caseRecordtypeIds = new Set<string>();
        caseRecordtypeIds.add(Schema.SObjectType.Case.getRecordTypeInfosByName().get(ConstantsClass.caseSalesEnqRecTypeName).getRecordTypeId());
        caseRecordtypeIds.add(Schema.SObjectType.Case.getRecordTypeInfosByName().get(ConstantsClass.InstrumentRentalEnquiryRecordType).getRecordTypeId());
        // added by nishi: 28-Apr-2021:end:  To add sales enquiry  or Instrument Rental Enquiry recordtype condition
        for(Case c : Trigger.new){
             //if(c.Enrolment__c != null && (Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(c.Id).Enrolment__c != c.Enrolment__C)))
             //Added by Rajesh on 21st Oct 2019, To add sales enquiry recordtype condition
             if(c.Enrolment__c != null && c.Booking__c == null && caseRecordtypeIds.contains( c.RecordTypeId) && c.Status != ConstantsClass.ClosedStatus &&  //commented by nishi: 28-apr-2021 : c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(ConstantsClass.caseSalesEnqRecTypeName).getRecordTypeId()
               (Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(c.Id).Enrolment__c != c.Enrolment__C))){
                 caseEnrMap.put(c.Id, c.Enrolment__c);
             }
                
             if((c.Status != null && Trigger.isUpdate && Trigger.oldMap.get(c.Id).Status != c.Status) && c.Origin =='App' && settings.Enable_Notifications__c)
                changeStatusMap.put(c.Id, c.AccountId);    
        }
        if(caseEnrMap.size() > 0)
            CaseTriggerHelper.updateBookingIdInCase(caseEnrMap);
        system.debug('@@changeStatusMap'+changeStatusMap);
        if(changeStatusMap.size() >0){
            CaseTriggerHelper.processChangeCase(changeStatusMap);
        }    
    }    
}