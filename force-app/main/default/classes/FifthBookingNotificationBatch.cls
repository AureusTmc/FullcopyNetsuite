/*
Name          :    FifthBookingNotificationBatch
Date          :    2 Dec 2019
Author        :    
Description   :    This batch class is used for sending reminder Mobile Notification to parent for 5th booking. 
*/
global class FifthBookingNotificationBatch implements Database.Batchable<sObject>,Database.AllowsCallouts{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id,start_time__c,Booking_Date__c,Package__r.Instrument__c,Student__r.Name,Parent__r.FCM_Token__c,Parent__c FROM Fifth_Lesson__c 
                                         WHERE Booking_Date__c = THIS_MONTH and 
                                         Parent__r.FCM_Token__c != null and 
                                         IsActive__c = true]);
    }
    
    global void execute(Database.BatchableContext BC,List<Fifth_Lesson__c> listOfBooking){
        List<Mobile_Notification__c> listOfMobileNotification = new List<Mobile_Notification__c>();
        for(Fifth_Lesson__c bookingObj: listOfBooking){
            Datetime StartTime = Datetime.newInstance(Date.today(), bookingObj.start_time__c);
            DateTime BookingDate = DateTime.newInstance(bookingObj.Booking_Date__c.year(), bookingObj.Booking_Date__c.month(),bookingObj.Booking_Date__c.day());
            String instrument = String.IsNotBlank(bookingObj.Package__r.Instrument__c) ? bookingObj.Package__r.Instrument__c :'Make-up';
            String  title =  'Action Required  – '+instrument +' Lesson on '+BookingDate.format('EEEE') +' '+ StartTime.format('h:mm a');
            String  bodymsg = 'You have an action required for the 5th lesson this month on ' + BookingDate.format('dd, MMM') +' '+ StartTime.format('h:mm a') 
                + ' for ' + + bookingObj.Student__r.Name + '. Please go to the lesson page to select one of the options.';
            String to = bookingObj.Parent__r.FCM_Token__c;
            Mobile_Notification__c log = FirebaseNotificationHelper.sendNotificationBatch(bookingObj.Parent__c, to, title, bodymsg);
            if(log != null)
                listOfMobileNotification.add(log); 
        }
        if(listOfMobileNotification.size() >0 ){
            insert listOfMobileNotification;
        }
    }
    
    global void finish(Database.BatchableContext BC){}
}