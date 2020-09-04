trigger SubscriptionLineItemTrigger on Subscription_Line_Item__c (After Update) {
    
    Set<ID> subscriptionIDSet = new Set<ID>();
    Map<Id,Subscription_Line_Item__c> oldMap = trigger.oldMap;
    for(Subscription_Line_Item__c sli : Trigger.New){
        if(trigger.isUpdate && sli.Status__c != oldMap.get(sli.Id).Status__c /*&& sli.Status__c == ConstantsClass.statusInActive*/ ){
            if(String.isNotBlank(sli.Subscription__c)){
                subscriptionIDSet.add(sli.Subscription__c);
            }
        }
    }
    System.debug('subscriptionIDSet '+subscriptionIDSet);
    if(subscriptionIDSet.size() > 0){
        
        SubscriptionLineItemTriggerHelper.checkStatus(subscriptionIDSet);
    }
}