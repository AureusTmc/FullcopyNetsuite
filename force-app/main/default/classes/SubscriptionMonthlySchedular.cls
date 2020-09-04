global class SubscriptionMonthlySchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new SubscriptionMonthlyInvoiceBatch(), 50);
    }
}