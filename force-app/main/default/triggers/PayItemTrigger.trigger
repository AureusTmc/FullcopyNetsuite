trigger PayItemTrigger on PayItem__c (after insert, after update) {
    // setup payout calculation
    if(trigger.isAfter){
        Set<Id> payoutIdset = new Set<Id>();
        Map<Id, PayItem__c> oldmap = trigger.oldMap;
        for(PayItem__c py: Trigger.New){
            if((trigger.isInsert || (oldmap != null && py.Amount__c != oldmap.get(py.Id).Amount__c)) && py.Payout__c != null){
                payoutIdset.add(py.Payout__c );
            }
        }   
        if(!payoutIdset.isEmpty()) AureusHRUtility.calculatePayout(payoutIdset);
    }
}