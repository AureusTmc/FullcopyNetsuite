global class BookingReminderSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new BookingReminderBatch());
    }
}