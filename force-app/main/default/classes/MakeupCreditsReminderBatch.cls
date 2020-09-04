/*
    Name          :    MakeupCreditsReminderBatch
    Date          :    11 March 2019
    Author        :    
    Description   :    This batch class is used for sending reminder email to parent to utilize makeup credits. 
*/
global class MakeupCreditsReminderBatch implements Database.Batchable<sObject>,database.stateful{
    private Integer noOfDays;
    global DateTime startTime;
    global integer noOfRecords;
    global MakeupCreditsReminderBatch (Integer noOfDays){
        this.noOfDays = noOfDays;
        noOfRecords  = 0;
        startTime = system.now();
    } 
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        Date bookingDateToCheck= Date.today().addDays(noOfDays); 
        return Database.getQueryLocator([SELECT Id,Student__c,Student__r.parent__c,Student__r.personContactId,Student__r.parent__r.personContactId,
                                        Student__r.parent__r.Also_a_Student__c,Student__r.Also_a_Student__c,Available_Make_up_Units__c,
                                         Center__r.Location__c
                                        FROM Booking__c WHERE Make_up_Expiry_Date__c =: bookingDateToCheck AND 
                                        (Available_Make_up_Units__c!= NULL OR Available_Make_up_Units__c != 0)
                                        AND RecordType.Name=: ConstantsClass.recordTypeLesson]);
    }
    global void execute(Database.BatchableContext BC,List<Booking__c> listOfBooking){
        noOfRecords += listOfBooking.size();
        if(noOfDays == -1){
            List<Booking__c>  listOfBookingToUpdate = new List<Booking__c>();
            Set<String> setOfStudents = new Set<String>();
            for(Booking__c objBooking : listOfBooking){
                objBooking.Available_Make_up_Units__c = 0;
                listOfBookingToUpdate.add(objBooking);
                /*if(String.isNotBlank(objBooking.Student__c)){
                    setOfStudents.add(objBooking.Student__c); 
                }*/
            }
            if(listOfBookingToUpdate.size() > 0){
                UPDATE listOfBookingToUpdate;    
            }
            /*if(setOfStudents.size() > 0){
                BillingUtility.rollUpMakeupCredits(setOfStudents);
                // call recalculation logic here
            }*/
        }else{
            //Map<String,String> mapOfBookingWithContact = new Map<String,String>();
            //List<EmailTemplate> templateList = [SELECT Id FROM EmailTemplate WHERE DeveloperName ='Make_credits_reminder'];
                
            /*for(Booking__c objBooking : listOfBooking){
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
                    Messaging.SingleEmailMessage email = AureusUtility.getSingleEmailMessage(templateList[0].Id,contactId,
                                                                                            bookingId,);
                    //Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateList[0].Id, contactId, bookingId);
                    //email.setTargetObjectId(contactId);
                    //email.saveAsActivity = true;
                    listOfemail.add(email); 
                } 
                if(listOfemail.size()>0){
                    Messaging.sendEmail(listOfemail);   
                }
            }*/
        }
    }
    global void finish(Database.BatchableContext BC){
        String name = 'Make up credits reminder batch before '+noOfDays+' Days.';
        BillingUtility.createBatchLog(name ,startTime,system.now(),noOfRecords);
    }
}