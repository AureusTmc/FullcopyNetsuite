global class InvoiceReminderSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new InvoiceReminderBatch(3),99);
        Database.executeBatch(new InvoiceReminderBatch(5),99);
        Database.executeBatch(new InvoiceReminderBatch(7),99);
    }
}