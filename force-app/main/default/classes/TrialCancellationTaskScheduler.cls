global class TrialCancellationTaskScheduler implements Schedulable{
    /*
    Name        :        TaskScheduler
    Author      :        Ravi Gupta
    */
    /*This class  creates task  for all the case with stage equialent to Trial Cancelled and  Trial cancel date not blank in gap of 2,4,7,10 */
      global void execute(SchedulableContext sc) {
        TrialCancellationTaskBatch batch = new TrialCancellationTaskBatch();
        Database.executeBatch(batch);  
    }

}