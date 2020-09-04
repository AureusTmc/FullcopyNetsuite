global class MakeupCreditExpNotificationSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new MakeupCreditExpirationNotificationBatch(30),99);
        Database.executeBatch(new MakeupCreditExpirationNotificationBatch(14),99);
        Database.executeBatch(new MakeupCreditExpirationNotificationBatch(7),99);
    }
}