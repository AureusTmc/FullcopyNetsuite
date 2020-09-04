global class BusyBookingSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new BusyBookingBatch());
    }
}