public class MobileNotificationWrapper {
    public String customerId;
    public String to;
    public String title;
    public String body;
    
    public MobileNotificationWrapper(String customerId, String to, String title, String body){
        this.customerId = customerId;
        this.to = to;
        this.title = title;
        this.body = body;
    }
        
    void execute(Database.BatchableContext BC, List<MobileNotificationWrapper> notifications) {}
}