global class MakeupCreditsReminderSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        //Database.executeBatch(new MakeupCreditsReminderBatch(7));
        //Database.executeBatch(new MakeupCreditsReminderBatch(7));
        //Database.executeBatch(new MakeupCreditsReminderBatch(30));
        //-1 is used for expiry
        Database.executeBatch(new MakeupCreditsReminderBatch(-1));
    }
}