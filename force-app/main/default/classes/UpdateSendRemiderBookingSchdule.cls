global class UpdateSendRemiderBookingSchdule implements Schedulable{
	// Added By Ravi on 20 june 2020 ...it basically update reschedulebooking checkbox  
    global void execute(SchedulableContext sc) {
        UpdateSendRemiderBookingBatch b = new UpdateSendRemiderBookingBatch();
        Database.executeBatch(b);
    }
}