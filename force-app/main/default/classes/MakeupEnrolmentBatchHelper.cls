public with sharing class MakeupEnrolmentBatchHelper {
    public static Map<String,set<String>> getMultipleTeacherWorkingHourTimeSlotList( map<string,set<String>> mapofCenterIds ,map<string,set<String>> mapofTeacherLessondays,
        set<string> listOfTeacherWithDuration,date startdate){
        return new Map<String,set<String>>();
    }
     // we get templete according to Enrolment organisation
     public static Messaging.SingleEmailMessage getEmailInformation(Map<String,EmailTemplate> mapOfEmailTemplate,Enrolment__c objPreferredEnrolment){
        Messaging.SingleEmailMessage objsendSingleEmailMessage = new Messaging.SingleEmailMessage();
        if(mapOfEmailTemplate != null && mapOfEmailTemplate.size() > 0 ){
            string centerId,personContactId;
            if(objPreferredEnrolment.Parent__c != null && objPreferredEnrolment.Parent__r.Centre_Name__r != null &&
                string.isNotBlank(objPreferredEnrolment.Parent__r.Centre_Name__r.Location__c) ){
                centerId = objPreferredEnrolment.Parent__r.Centre_Name__r.Location__c;
            }
            if(objPreferredEnrolment.Parent__c != null && string.isNotBlank(objPreferredEnrolment.Parent__r.PersonContactId)){
                personContactId = objPreferredEnrolment.Parent__r.PersonContactId;
            }
            if(objPreferredEnrolment.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                if(mapOfEmailTemplate.containsKey('Ossia_Waitlist_Enrolment_Time_Available')){
                    objsendSingleEmailMessage = AureusUtility.getSingleEmailMessage(mapOfEmailTemplate.get('Ossia_Waitlist_Enrolment_Time_Available').Id,personContactId,objPreferredEnrolment.id,centerId);
                }
            }else{
                if(mapOfEmailTemplate.containsKey('Waitlist_Enrolment_Time_Available')){
                    objsendSingleEmailMessage = AureusUtility.getSingleEmailMessage(mapOfEmailTemplate.get('Waitlist_Enrolment_Time_Available').Id,personContactId,objPreferredEnrolment.id,centerId);
                }   
            }
        }
        return objsendSingleEmailMessage;
    }
    public static set<String> getFormatedTimeSlotList(DateTime startTime, DateTime endTime){
        set<String> timeSlots = new set<String>();
        if(startTime < endTime){
            while(startTime <= endTime){
                timeSlots.add(startTime.format('h:mm a'));
                startTime = startTime.addMinutes(15);
            }
        }
        return timeSlots;
    } 

    public static Mobile_Notification__c getMobileNotificationMsg(Enrolment__c objEnrolment,string availabletime,string bookingdate){
        String  title =  'Make-Up Credit Available before/after Your Bookings ';
        String  bodymsg = 'You will be use your make-up credits before/after you regular bookings. Make-up times are : '
                         +availabletime + ' of ' + bookingdate +
                        '! Please use our app to book a make-up lesson and use your make-up credits. If you\'re having trouble finding any available times, contact our team as we are happy to help!';
        String to = objEnrolment.Parent__r.FCM_Token__c;
        return FirebaseNotificationHelper.sendNotificationBatch(objEnrolment.Parent__c, to, title, bodymsg);
        
    }
}
