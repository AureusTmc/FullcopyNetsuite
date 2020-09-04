/*
        Name        :    NoLessonThisWeekNotificationBatch 
        Date        :    06/Aug/2019
        Author      :  
        Description :    This batch class is used to send reminder for No Lesson in this week.

      
*/
global class NoLessonThisWeekNotificationBatch implements Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    global Database.QueryLocator start(Database.BatchableContext BC){
         return Database.getQueryLocator([SELECT id,Enrolment__r.Stage__c, Booking_Date__c,Instrument__c, Student__r.Name,Cancellation_Reason__c,  start_time__c, Parent__c,
                                               Parent__r.FCM_Token__c,Teacher_Account__r.name
                                               FROM Booking__c
                                               WHERE Enrolment__r.Stage__c ='Enrolled' 
                                               AND Status__c =:ConstantsClass.statusCanceled   
                                               AND Booking_Date__c = THIS_WEEK
                                               AND Cancellation_Reason__c = 'Teacher MC' 
                                               AND Parent__r.FCM_Token__c !=null]);
    }
    
     global void execute(Database.BatchableContext BC, List<Booking__c> BookingList){
       List<Mobile_Notification__c> listOfMobileNotification = new List<Mobile_Notification__c>();
        for(booking__c bookingObj: BookingList){
                Datetime StartTime = Datetime.newInstance(Date.today(), bookingObj.start_time__c);
                 DateTime BookingDate = DateTime.newInstance(bookingObj.Booking_Date__c.year(), bookingObj.Booking_Date__c.month(),bookingObj.Booking_Date__c.day());
            String instrument = String.IsNotBlank(bookingObj.instrument__c) ? bookingObj.instrument__c :'Make-up';
                      
            String  title =  'Reminder – No Lesson on '+BookingDate.format('dd, MMM') +' '+ StartTime.format('h:mm a') +' for '+bookingObj.Student__r.Name;
                 String  bodymsg = 'This is a reminder that there is no '+ instrument +'  lesson for '+bookingObj.Student__r.Name + '\'s  on '+
                                 +BookingDate.format('dd, MMM') +' '+ StartTime.format('h:mm a')+
                                 ' as teacher '+bookingObj.Teacher_Account__r.name+ ' is on leave';
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