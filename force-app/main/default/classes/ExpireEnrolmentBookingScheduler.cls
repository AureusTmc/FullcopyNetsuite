global class ExpireEnrolmentBookingScheduler implements Schedulable {
    
         /*
    Name        :        ExpireEnrolmentBookingScheduler
    Author      :        Ravi Gupta
    */
    /*This class   */
    global void execute(SchedulableContext sc) {
        ExpireEnrolmentBooking batch = new ExpireEnrolmentBooking();
        Database.executeBatch(batch);  
    }


}