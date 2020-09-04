trigger SubscriptionTrigger on Subscription__c (Before Insert) {
    if(Trigger.isBefore && Trigger.isInsert){
        for(Subscription__c subscription : Trigger.new){
            subscription.Name = 'New Subscription Name';
        }
    }
}