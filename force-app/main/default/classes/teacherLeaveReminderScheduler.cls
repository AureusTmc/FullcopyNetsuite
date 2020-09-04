global class teacherLeaveReminderScheduler implements Schedulable{
     /*
    Name        :        teacherLeaveReminderScheduler
    Author      :        Ravi Gupta
    */
    /*This class basically calls the batch and send email to parent 7 days before to the actual leave of teacher*/
    global void execute(SchedulableContext sc) {
        TeacherLeaveReminder batch = new TeacherLeaveReminder();
        Database.executeBatch(batch);  
    }
}