global class FifthBookingNotificationSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new FifthBookingNotificationBatch(),99);
    }
}