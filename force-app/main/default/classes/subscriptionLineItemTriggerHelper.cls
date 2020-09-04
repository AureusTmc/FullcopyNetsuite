public class subscriptionLineItemTriggerHelper{
    
    public static void checkStatus(Set<ID> subscriptionIDSet){
        Map<String, List<Subscription_Line_Item__c>> mapOfSubLineItem = new Map<String,List<Subscription_Line_Item__c>>();
        List<Subscription__c> listOfSubsToUpd = new List<Subscription__c>();
       for(Subscription_Line_Item__c objSubLineItem : [SELECT Id,Subscription__c FROM Subscription_Line_Item__c WHERE Subscription__c IN:subscriptionIDSet 
                                                        AND Status__c !=: ConstantsClass.statusInActive]){
            List<Subscription_Line_Item__c> listOfLineItems = mapOfSubLineItem.containsKey(objSubLineItem.Subscription__c) ? 
                                                                mapOfSubLineItem.get(objSubLineItem.Subscription__c) : new List<Subscription_Line_Item__c>();    
            listOfLineItems.add(objSubLineItem);
            mapOfSubLineItem.put(objSubLineItem.Subscription__c,listOfLineItems);    
        }
        System.debug('subscriptionIDSet'+subscriptionIDSet);
        System.debug('mapOfSubLineItem'+mapOfSubLineItem);
        for(String subsId : subscriptionIDSet){
            if(!mapOfSubLineItem.containsKey(subsId)){
                listOfSubsToUpd.add(new Subscription__c(Id= subsId,Status__c = ConstantsClass.statusInActive));        
            }else{
                listOfSubsToUpd.add(new Subscription__c(Id= subsId,Status__c = ConstantsClass.activeStatus));        
            }
        }
        if(listOfSubsToUpd.size() > 0){
            UPDATE listOfSubsToUpd;
        }
        
    }
}