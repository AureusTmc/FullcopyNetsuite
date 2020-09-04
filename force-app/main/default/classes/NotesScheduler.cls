global class NotesScheduler implements Schedulable{
     /*
    Name        :        NotesScheduler
    Author      :        Ravi Gupta
    */
    /*This class  creates notes   for all the Bookings with Type 'Trial' ANd Enrolment Type is Trial and enrolment Stage Booked And Requested */
    global void execute(SchedulableContext sc) {
        BookingNotesBatch batch = new BookingNotesBatch();
        Database.executeBatch(batch);  
    }
}