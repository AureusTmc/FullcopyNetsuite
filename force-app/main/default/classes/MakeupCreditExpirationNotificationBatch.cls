/*
        Name        :    MakeupCreditExpirationMobileNotificationBatch 
        Date        :    02/Aug/2019
        Author      :  
        Description :    This batch class is used to send reminder if Booking Status = Canceled and Check Make-Up Expiration Date and Check Make-up Duration
      
*/
global class MakeupCreditExpirationNotificationBatch implements Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    private Integer noOfDays;
    public MakeupCreditExpirationNotificationBatch(Integer days){
        noOfDays = days;
    } 
    global Database.QueryLocator start(Database.BatchableContext BC){
        Date preDate = system.today().addDays(noOfDays);
        system.debug('preDate'+preDate);
        return Database.getQueryLocator([SELECT id,Enrolment__r.Stage__c, Booking_Date__c,Instrument__c, Student__r.Name,Cancellation_Reason__c,  start_time__c, Parent__c,
                                        Parent__r.FCM_Token__c,Teacher_Account__r.name
                                        FROM booking__c
                                         WHERE Make_up_Expiry_Date__c =:preDate and Status__c =: ConstantsClass.statusCanceled  
                                         and Available_Make_up_Units__c > 0 
                                         AND Parent__r.FCM_Token__c !=null]);
    }
    
    global void execute(Database.BatchableContext BC, List<booking__c> bookingList){
       system.debug('bookingList'+bookingList);
       List<Mobile_Notification__c> listOfMobileNotification = new List<Mobile_Notification__c>();
        for(booking__c bookingObj: bookingList){
                Datetime StartTime = Datetime.newInstance(Date.today(), bookingObj.start_time__c);
                 DateTime BookingDate = DateTime.newInstance(bookingObj.Booking_Date__c.year(), bookingObj.Booking_Date__c.month(),bookingObj.Booking_Date__c.day());
                 system.debug('@@bookingObj'+bookingObj);
                 String instrument = String.IsNotBlank(bookingObj.instrument__c) ? bookingObj.instrument__c :'Make-up';
                 String  title =  'Make-Up Credit Expiring in '+noOfDays +' of days';
                 String  bodymsg = 'Your make-up credit is expiring in '
                                  +noOfDays+ ' of days' +
                                 '! Please use our app to book a make-up lesson and use your make-up credits. If you\'re having trouble finding any available times, contact our team as we are happy to help!';
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
        //BillingUtility.createBatchLog('Invoice Reminder Batch',startTime,system.now(),noOfRecords);
    }
    
}