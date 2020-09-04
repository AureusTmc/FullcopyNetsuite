/*
    Name          :    FifthBookingReminderBatch
    Date          :    11 March 2019
    Author        :    
    Description   :    This batch class is used for sending reminder email to parent for 5th booking. 
*/
global class FifthBookingReminderBatch implements Database.Batchable<sObject>,database.stateful{
    private Integer noOfDays;
    global DateTime startTime;
    global integer noOfRecords;
    global FifthBookingReminderBatch(Integer noOfDays){
        this.noOfDays = noOfDays;
        noOfRecords  = 0;
        startTime = system.now();
    } 
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        Date bookingDateToCheck= Date.today().addDays(noOfDays); 
        return Database.getQueryLocator([SELECT Id,Student__c,Student__r.parent__c,Student__r.personContactId,Student__r.parent__r.personContactId,
                                        Student__r.parent__r.Also_a_Student__c,Student__r.Also_a_Student__c
                                        FROM Booking__c WHERE Booking_Date__c =:bookingDateToCheck AND IS_fifth_Booking__c = TRUE
                                        AND RecordType.Name=: ConstantsClass.recordTypeLesson]);
    }
    global void execute(Database.BatchableContext BC,List<Booking__c> listOfBooking){
        noOfRecords += listOfBooking.size();
        Map<String,String> mapOfBookingWithContact = new Map<String,String>();
        List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE DeveloperName ='FifthBookingReminder'];
            
        for(Booking__c objBooking : listOfBooking){
            if(String.isNotBlank(objBooking.Student__r.Parent__c)){
                mapOfBookingWithContact.put(objBooking.Id,objBooking.Student__r.Parent__r.PersonContactId); 
            }else if(objBooking.Student__r.Also_a_Student__c){
               mapOfBookingWithContact.put(objBooking.Id,objBooking.Student__r.PersonContactId);
            }
        }
        if(mapOfBookingWithContact.size()> 0 && templateList.size() > 0){
            List<Messaging.SingleEmailMessage> listOfemail = new List<Messaging.SingleEmailMessage>();
            for(String bookingId : mapOfBookingWithContact.keySet()){
                String contactId = mapOfBookingWithContact.get(bookingId);
                Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateList[0].Id, contactId, bookingId);
                email.setTargetObjectId(contactId);
                email.saveAsActivity = true;
                //email.setWhatId(invoiceObj.Parent_Account__c);
                listOfemail.add(email); 
            } 
            if(listOfemail.size()>0){
                Messaging.sendEmail(listOfemail);   
            }
        }
    }
    global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Fifth Booking Reminder Batch',startTime,system.now(),noOfRecords);
    }
}