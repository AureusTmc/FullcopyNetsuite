global class PayrollBatchScheduler implements Schedulable {
   global void execute(SchedulableContext sc) {
      createEmployeePayoutBatch batch = new createEmployeePayoutBatch();
      Database.executeBatch(batch);
   }   
}