global class TrialAttendedTaskScheduler implements Schedulable{
    /*
    Name        :        TaskScheduler
    Author      :        Ravi Gupta
    */
    /*This class  creates task  for all the case with stage equialent to Task Attended and  trial date not blank in gap of 2,4,7,10,14 */
	global void execute(SchedulableContext sc) {
        TrialAttendedTaskBatch batch = new TrialAttendedTaskBatch();
        Database.executeBatch(batch);  
    }
}