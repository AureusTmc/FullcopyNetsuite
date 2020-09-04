global class BookingFileDeleteBatchScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        BookingFileDeleteBatch batchCls = new BookingFileDeleteBatch();
        Database.executeBatch(batchCls);
    }
}