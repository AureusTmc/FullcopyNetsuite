global class TrialNoShowTaskScheduler implements Schedulable{
    /*
    Name        :        TaskScheduler
    Author      :        Ravi Gupta
    */
    /*This class  creates task  for all the case with stage equialent to No show stage and  trial  no show date not blank in gap of 2,4,7,10 */
    global void execute(SchedulableContext sc){
        TrialNoShowTaskBatch batch = new TrialNoShowTaskBatch();
        Database.executeBatch(batch);
    }

}