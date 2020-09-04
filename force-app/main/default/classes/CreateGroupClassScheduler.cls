global class CreateGroupClassScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        CreateGroupClassBatch b = new CreateGroupClassBatch(); 
        database.executebatch(b,100);
    }
}