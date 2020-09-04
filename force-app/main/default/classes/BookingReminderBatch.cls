/*
        Name        :    BookingReminderBatch 
        Date        :    02/08/2019
        Author      :  
        Description :    This batch class is used to send reminder if booking date is equals to TOMORROW and booking status is 'Scheduled' .
        
*/
global class BookingReminderBatch implements Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    global Database.QueryLocator start(Database.BatchableContext BC){
        system.debug('asd');
        return Database.getQueryLocator([SELECT id,Enrolment__r.Stage__c, Booking_Date__c,Instrument__c, Student__r.Name,Cancellation_Reason__c,  start_time__c, Parent__c,
                                        Parent__r.FCM_Token__c,Teacher_Account__r.name
                                        FROM booking__c
                                        WHERE Enrolment__r.Stage__c ='Enrolled' 
                                        AND Parent__r.FCM_Token__c !=null 
                                        AND Status__c ='Scheduled' 
                                        AND Booking_Date__c = TOMORROW 
                                        AND Parent__r.Booking_Reminded_Notification__c = true]);
    }
    
    global void execute(Database.BatchableContext BC, List<booking__c> bookingList){
       system.debug('bookingList'+bookingList);
       List<Mobile_Notification__c> listOfMobileNotification = new List<Mobile_Notification__c>();
        for(booking__c bookingObj: bookingList){
                Datetime StartTime = Datetime.newInstance(Date.today(), bookingObj.start_time__c);
                 DateTime BookingDate = DateTime.newInstance(bookingObj.Booking_Date__c.year(), bookingObj.Booking_Date__c.month(),bookingObj.Booking_Date__c.day());
                 
                 String instrument = String.IsNotBlank(bookingObj.instrument__c) ? bookingObj.instrument__c :'Make-up';
                 String  title =  'Lesson Reminder  – '+instrument +' Lesson on '+BookingDate.format('dd, MMM') +' '+ StartTime.format('h:mm a');
                 String  bodymsg = 'Hey there '+ bookingObj.Student__r.Name + '\'s ! This is a friendly reminder that you have a '+ instrument  +'  lesson on '
                                 +BookingDate.format('dd, MMM') +' '+ StartTime.format('h:mm a')+
                                 '. If you need to cancel or reschedule, you can go to the lesson detail page!';
                 String to = bookingObj.Parent__r.FCM_Token__c;
                 Mobile_Notification__c log = FirebaseNotificationHelper.sendNotificationBatch(bookingObj.Parent__c, to, title, bodymsg);
                  if(log != null)
                        listOfMobileNotification.add(log); 
        }
        if(listOfMobileNotification.size() > 0 && listOfMobileNotification!= Null){
            insert listOfMobileNotification;
        }
        
    }
    global void finish(Database.BatchableContext BC){
       
    }
    
    
}