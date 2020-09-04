public class SendMobileNotificationBatch  implements Database.Batchable<MobileNotificationWrapper>, Database.Stateful, Database.AllowsCallouts{
    List<MobileNotificationWrapper> notificationsToSend;
    
    public SendMobileNotificationBatch(List<MobileNotificationWrapper> notificationsToSend){
        this.notificationsToSend = notificationsToSend;
    }
    
    public Iterable<MobileNotificationWrapper> start(Database.BatchableContext BC){
        return notificationsToSend;
    }
    
    public void execute(Database.BatchableContext BC, List<MobileNotificationWrapper> notifications){
        List<Mobile_Notification__c> logs = new List<Mobile_Notification__c>();
        
        for(MobileNotificationWrapper notification : notifications) {
            Mobile_Notification__c log = FirebaseNotificationHelper.sendNotificationBatch(notification.customerId, notification.to, notification.title, notification.body);
            if(log !=null) logs.add(log);
        }
        
        if(logs.size() > 0 ) {
            try {
                insert logs;
            }catch(Exception e) {
                System.debug(e);
            }
        }
    }
    
    
    public void finish(Database.BatchableContext BC){
        
    }
}