/*
    Name : EnrolmentWaitlistingSchedular
    date: 3-Feb-2021
    Author :  Nishi Jain
    Description:
    1.	 A scheduled process will run for all Waiting enrolments and check for the availability of the preferred time slot for the enrolment duration.
    2.	If a timeslot is found then an email notification will be send to Centre Admin and Customer to perform the necessary action. 
	test class:WaitingEnrolmentsBatchtest
*/
global class EnrolmentWaitlistingSchedular implements Schedulable {
    global void execute (SchedulableContext ctx) {
        Database.executeBatch(new WaitingEnrolmentsBatch(integer.valueOf(label.Waiting_Enrolment_Notification_Days)),99);
    }
}