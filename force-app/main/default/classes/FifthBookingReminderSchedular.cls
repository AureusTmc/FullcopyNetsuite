global class FifthBookingReminderSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new FifthBookingReminderBatch(10),99);
    }
}