/*
Name        :        FifthLessonReminderBatch
Date        :        24 Septmber 2019
Author      :        
Description :        It is FifthLessonReminderBatch class which send emails to the customer before 10 and fifteen days.
*/
global class FifthLessonReminderBatch implements Database.Batchable<sObject>, database.stateful{
    
    global Date BookingDate;
    global Integer numberOfDays;
    global DateTime startTime;
     global integer noOfRecords;
    //global List <EmailTemplate> emailTemplateList; ////commented by nishi: 12-Oct-2020:start: for send email according to organisation
    global map<string,EmailTemplate> emailTemplatemap;
    public FifthLessonReminderBatch (Date callingDate, Integer numberOfDays){
        //emailTemplateList = new  List<EmailTemplate>();//commented by nishi: 12-Oct-2020:start: for send email according to organisation
        emailTemplatemap = new map<string,EmailTemplate>();
        //String emailTemplateName;//commented by nishi: 12-Oct-2020:start: for send email according to organisation
        Set<string> emailTemplateNames = new Set<string>();
        noOfRecords  = 0;
        startTime = system.now();

        if(callingDate != NULL && numberOfDays != NULL && numberOfDays > 0){
            BookingDate = callingDate.addDays(numberOfDays);
            this.numberOfDays = numberOfDays;
            //added by nishi: 12-Oct-2020:start: for send email according to organisation
            if(numberOfDays == 10){
                //emailTemplateName = 'FifthLessonReminderFor10Days';
                emailTemplateNames.add('Ossia_FifthLessonReminderFor10Days');
                emailTemplateNames.add('FifthLessonReminderFor10Days');
            }else if(numberOfDays == 15){
                //emailTemplateName = 'FifthLessonReminderFor15Days';
                emailTemplateNames.add('Ossia_FifthLessonReminderFor15Days');
                emailTemplateNames.add('FifthLessonReminderFor15Days');
            }
            //added by nishi: 12-Oct-2020:end: for send email according to organisation
        }
        //added by nishi: 12-Oct-2020:start: for send email according to organisation
        if(emailTemplateNames != null && emailTemplateNames.size() > 0){
            for(EmailTemplate objEmailTemplate :[Select Id,developername from EmailTemplate 
                                                     where developername in:emailTemplateNames]){
                emailTemplatemap.put(objEmailTemplate.developername,objEmailTemplate);
            }
        }
        /*if(String.isNotBlank(emailTemplateName)){
            emailTemplateList = [SELECT Id, name FROM EmailTemplate WHERE developername = :emailTemplateName];
        }*/
        //added by nishi: 12-Oct-2020:end: for send email according to organisation
        
    }
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator([SELECT Id,Booking_Date__c,Parent__r.Available_Make_up_Units__c, Duration__c, 
                                        Parent__r.PersonContactId,Enrolment__c ,Enrolment__r.Center__r.Location__c ,
                                        // added by nishi: 7-Sep-2020:for check organisation is ossia then we get makeup mins on enrolment and teacher type is part-time then we not send reminder 
                                        Enrolment__r.Available_Make_up_Mins__c,Enrolment__r.Center__r.Organisation__r.Name,Enrolment__r.teacher__r.Engagement_Type__c
                                        FROM Fifth_Lesson__c 
                                        WHERE Booking_Date__c = :BookingDate 
                                        AND IsActive__c = TRUE 
                                        AND Enrolment__c != NULL
                                        ]);
    }
    global void execute(Database.BatchableContext bc,List <Fifth_Lesson__c> FifthLessonReminderList){

        noOfRecords  += FifthLessonReminderList.size();
        List <Messaging.SingleEmailMessage> singleEmailList = new  List <Messaging.SingleEmailMessage>();
        if(emailTemplatemap != null && emailTemplatemap.size() > 0){
        //if(emailTemplateList.size() > 0){
            
            for(Fifth_Lesson__c fl : FifthLessonReminderList){
                 //start: added by nishi: 7-Sep-2020:for check organisation is ossia then we get makeup mins on enrolment and teacher type is part-time then we not send reminder 
                 Boolean isSendNotification = true;
                 Boolean isOssiaOrganisation = false;
                Decimal availableMakeupUnits = 0;
                system.debug('fl.Enrolment__r.Center__r.Organisation__r.Name'+fl.Enrolment__r.Center__r.Organisation__r.Name);
                if(string.isNotBlank(fl.Enrolment__c) && string.isNotBlank(fl.Enrolment__r.Center__c) && string.isNotBlank(fl.Enrolment__r.Center__r.Organisation__c)
                 && string.isNotBlank(fl.Enrolment__r.Center__r.Organisation__r.Name) && fl.Enrolment__r.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                    availableMakeupUnits = fl.Enrolment__r.Available_Make_up_Mins__c != null ? fl.Enrolment__r.Available_Make_up_Mins__c : 0;
                    isOssiaOrganisation = true;
                    if(string.isNotBlank(fl.Enrolment__c) && string.isNotBlank(fl.Enrolment__r.teacher__c) &&  string.isNotBlank(fl.Enrolment__r.teacher__r.Engagement_Type__c) && 
                        fl.Enrolment__r.Teacher__r.Engagement_Type__c.equalsIgnoreCase('Part-Time') ){
                            isSendNotification = false;        
                    }
                }else{
                    availableMakeupUnits = fl.Parent__r.Available_Make_up_Units__c != null ? fl.Parent__r.Available_Make_up_Units__c : 0;
                }
                 //end : added by nishi: 7-Sep-2020:for check organisation is ossia then we get makeup mins on enrolment and teacher type is part-time then we not send reminder 
                                       
                Decimal duration = fl.Duration__c != null ? fl.Duration__c : 0;
                system.debug('!!duration'+duration);
                 system.debug('!!availableMakeupUnits'+availableMakeupUnits);
                 system.debug('fl.Parent__r.PersonContactId'+fl.Parent__r.PersonContactId);
                // 19-mar-2020:jatin: for check Available_Make_up_Units__c is less then then fifth_lesson_ Package_duration 
                //then we send email otherwise not
                if(duration > availableMakeupUnits && isSendNotification){
                    //added by nishi: 12-Oct-2020:start: for send email according to organisation
                   if(isOssiaOrganisation){
                        if(numberOfDays == 10 &&emailTemplatemap.containskey('Ossia_FifthLessonReminderFor10Days')){
                                Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(emailTemplatemap.get('Ossia_FifthLessonReminderFor10Days').Id,fl.Parent__r.PersonContactId,fl.Enrolment__c,fl.Enrolment__r.Center__r.Location__c);
                                singleEmailList.add(mail);
                            
                        }else if(numberOfDays == 15 && emailTemplatemap.containskey('Ossia_FifthLessonReminderFor15Days')){
                            system.debug('isOssiaOrganisation'+isOssiaOrganisation);
                            Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(emailTemplatemap.get('Ossia_FifthLessonReminderFor15Days').Id,fl.Parent__r.PersonContactId,fl.Enrolment__c,fl.Enrolment__r.Center__r.Location__c);
                            singleEmailList.add(mail);
                        }
                   }else{
                        if(numberOfDays == 10 && emailTemplatemap.containskey('FifthLessonReminderFor10Days')){
                            Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(emailTemplatemap.get('FifthLessonReminderFor10Days').Id,fl.Parent__r.PersonContactId,fl.Enrolment__c,fl.Enrolment__r.Center__r.Location__c);
                            singleEmailList.add(mail);
                            
                        }else if(numberOfDays == 15  && emailTemplatemap.containskey('FifthLessonReminderFor15Days')){
                                Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(emailTemplatemap.get('FifthLessonReminderFor15Days').Id,fl.Parent__r.PersonContactId,fl.Enrolment__c,fl.Enrolment__r.Center__r.Location__c);
                                singleEmailList.add(mail);
                            
                        }
                   }
                //    Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(emailTemplateList[0].Id,fl.Parent__r.PersonContactId,fl.Enrolment__c,fl.Enrolment__r.Center__r.Location__c);
                //    singleEmailList.add(mail);
                //added by nishi: 12-Oct-2020:end: for send email according to organisation
                    system.debug('!!Send email  ---  fl.Duration__c--'+fl.Duration__c);
                    system.debug('!!Send email  ----- fl.Parent__r.Available_Make_up_Units__c--'+fl.Parent__r.Available_Make_up_Units__c);
                }
            } 
        }
        system.debug('!!singleEmailList'+singleEmailList);
        if(singleEmailList.size()>0){
            system.debug('!!singleEmailList'+singleEmailList);
            Messaging.sendEmail(singleEmailList,FALSE);   
        }   
    }
    global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Fifth Lesson Reminder',startTime,system.now(),noOfRecords);
     }
    
}