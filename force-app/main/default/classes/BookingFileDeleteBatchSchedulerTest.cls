@isTest
public class BookingFileDeleteBatchSchedulerTest {
	public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    static testmethod void testScheduledJob() {
    	String jobId = System.schedule('Delete attachments from Booking when Booking date exceed 5 days',
            						CRON_EXP, new BookingFileDeleteBatchScheduler()); 
    }
}