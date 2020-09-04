global class TaskScheduler implements Schedulable{
     /*
    Name        :        TaskScheduler
    Author      :        Ravi Gupta
    */
    /*This class  creates task  for all the case with stage equialent to enquiry and  enquiry date not blank in gap of 1,2,7,10 */
    global void execute(SchedulableContext sc) {
        CaseTaskBatch batch = new CaseTaskBatch();
        Database.executeBatch(batch);  
    }
}