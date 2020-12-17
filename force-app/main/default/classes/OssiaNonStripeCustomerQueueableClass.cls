public class OssiaNonStripeCustomerQueueableClass implements Queueable{
	Set<string>setOfInvIds;
    public OssiaNonStripeCustomerQueueableClass(Set<string> setOfInvIds) {
        this.setOfInvIds = setOfInvIds;
    }
    public void execute(QueueableContext context) {
        BillingUtility.EmailsForOssiaNonStripeCustomers(setOfInvIds);
    }
}