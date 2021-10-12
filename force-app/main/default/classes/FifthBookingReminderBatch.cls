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
                                        Student__r.parent__r.Also_a_Student__c,Student__r.Also_a_Student__c,
                                        Teacher_Account__r.Engagement_Type__c,Center__r.Organisation__r.Name // added by nishi: 12-Oct-2020
                                        FROM Booking__c WHERE Booking_Date__c =:bookingDateToCheck 
                                        AND IS_fifth_Booking__c = TRUE
                                        AND RecordType.Name=: ConstantsClass.recordTypeLesson]);
    }
    global void execute(Database.BatchableContext BC,List<Booking__c> listOfBooking){
        noOfRecords += listOfBooking.size();
        Map<String,String> mapOfBookingWithContact = new Map<String,String>();
        Map<String,String> mapOfOssiaBookingWithContact = new Map<String,String>();
        map<string,EmailTemplate> templatemap= new map<string,EmailTemplate>();
        //added by nishi: 12-Oct-2020:start: for send email according to organisation
        for(EmailTemplate objEmailTemplate :[Select Id,DeveloperName from EmailTemplate 
									where DeveloperName = 'FifthBookingReminder' 
									or DeveloperName = 'Ossia_FifthBookingReminder' 
									]){
										templatemap.put(objEmailTemplate.DeveloperName,objEmailTemplate);
									}
        //List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE DeveloperName ='FifthBookingReminder'];
       //added by nishi: 12-Oct-2020:end: for send email according to organisation     
        for(Booking__c objBooking : listOfBooking){
            //boolean isReminderFifthlessonBooking = true;
            //added by nishi: 12-Oct-2020:start: for send email according to organisation
            if(string.isnotBlank(objBooking.Center__r.Organisation__r.Name) && objBooking.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                if(string.isNotBlank(objBooking.Teacher_Account__r.Engagement_Type__c) && ConstantsClass.teacherPartTimeEngagementStatus.contains(objBooking.Teacher_Account__r.Engagement_Type__c)){
                   // isReminderFifthlessonBooking= false;
                }
                else{
                    if(String.isNotBlank(objBooking.Student__r.Parent__c)){
                        mapOfOssiaBookingWithContact.put(objBooking.Id,objBooking.Student__r.Parent__r.PersonContactId); 
                    }else if(objBooking.Student__r.Also_a_Student__c){
                        mapOfOssiaBookingWithContact.put(objBooking.Id,objBooking.Student__r.PersonContactId);
                    }
                }
            }else{
            //added by nishi: 12-Oct-2020:end: for send email according to organisation    
                if(String.isNotBlank(objBooking.Student__r.Parent__c)){
                    mapOfBookingWithContact.put(objBooking.Id,objBooking.Student__r.Parent__r.PersonContactId); 
                }else if(objBooking.Student__r.Also_a_Student__c){
                    mapOfBookingWithContact.put(objBooking.Id,objBooking.Student__r.PersonContactId);
                }
            }
        }
        if(mapOfBookingWithContact.size()> 0 && templatemap.size() > 0){
            List<Messaging.SingleEmailMessage> listOfemail = new List<Messaging.SingleEmailMessage>();
            for(String bookingId : mapOfBookingWithContact.keySet()){
                if(templateMap.containsKey('FifthBookingReminder')){
                    String contactId = mapOfBookingWithContact.get(bookingId);
                    Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templatemap.get('FifthBookingReminder').Id, contactId, bookingId);
                    email.setTargetObjectId(contactId);
                    email.saveAsActivity = true;
                    //email.setWhatId(invoiceObj.Parent_Account__c);
                    listOfemail.add(email); 
                }
            } 
            if(listOfemail.size()>0){
                Messaging.sendEmail(listOfemail,False);   
            }
        }
        //added by nishi: 12-Oct-2020:start: for send email according to ossia organisation
        if(mapOfOssiaBookingWithContact.size()> 0 && templatemap.size() > 0){
            List<Messaging.SingleEmailMessage> listOfemail = new List<Messaging.SingleEmailMessage>();
            for(String bookingId : mapOfOssiaBookingWithContact.keySet()){
                if(templateMap.containsKey('Ossia_FifthBookingReminder')){
                    String contactId = mapOfOssiaBookingWithContact.get(bookingId);
                    Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templatemap.get('Ossia_FifthBookingReminder').Id, contactId, bookingId);
                    email.setTargetObjectId(contactId);
                    email.saveAsActivity = true;
                    //email.setWhatId(invoiceObj.Parent_Account__c);
                    listOfemail.add(email); 
                }
            } 
            if(listOfemail.size()>0){
                Messaging.sendEmail(listOfemail,False);   
            }
        }
        //added by nishi: 12-Oct-2020:start: for send email according to ossia organisation
    }
    global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Fifth Booking Reminder Batch',startTime,system.now(),noOfRecords);
    }
}