public with sharing class SendReEnrolmentConfirmationctrl {
    public Account parentAcc{get;set;}
    public Boolean isOssiaOrg{get;set;}
    public boolean isError{get;set;}
    public boolean isSucess{get;set;}
    public string  errorMsg{get;set;}
    public SendReEnrolmentConfirmationctrl(ApexPages.StandardController sc){
        isOssiaOrg = false;
        isError = false;
        isSucess = false;
        parentAcc = (Account)sc.getRecord();
        parentAcc = [SELECT Id,Parent__c,Centre_Name__r.Organisation__r.Name,Centre_Name__r.Location__c,PersonContactId, Centre_Name__c,Stripe_Customer_Id__c,PersonEmail FROM Account WHERE Id=: parentAcc.id];
        if(string.isNotBlank(parentAcc.Centre_Name__c) && string.isNotBlank(parentAcc.Centre_Name__r.Organisation__c) 
            && System.Label.Ossia_Organisation_Name == parentAcc.Centre_Name__r.Organisation__r.Name){
            isOssiaOrg= true;
        }
    }
    public void redirectToEnrolmentlink(){
        isError = false;
        errorMsg ='';
        isSucess = false;
        try{
            if(string.isNotBlank(parentAcc.Parent__c)){
                parentAcc = [SELECT Id,Parent__c,Centre_Name__r.Organisation__r.Name,Centre_Name__r.Location__c,PersonContactId, Centre_Name__c,Stripe_Customer_Id__c,PersonEmail
                             FROM Account WHERE Id=: parentAcc.Parent__c];
            }
            Set<String> paymentFailedEmails=new Set<string>{'Ossia_Re_Enrolment_Confirmation','Re_Enrolment_Confirmation'};
            Map<String,EmailTemplate> mapOfEmailTemplate = new Map<String,EmailTemplate>();
            List<Mobile_Notification__c> listOfMobileNotification = new List<Mobile_Notification__c>();
            // we get templete according to organisation
            Set<string> availabletime =new Set<string>() ;
            Set<string>  availableMakeupTimeSlot =new Set<string>() ;
            for(EmailTemplate objEmailTemplate: [SELECT Id, Name,DeveloperName 
                                                FROM EmailTemplate 
                                                WHERE DeveloperName In:paymentFailedEmails]){
                                                    mapOfEmailTemplate.put(objEmailTemplate.DeveloperName,objEmailTemplate);
                                                }
            List<Messaging.SingleEmailMessage> sendSingleEmailMessage = new List<Messaging.SingleEmailMessage>(); 
            string templatename ='';
            if(isOssiaOrg){
                templatename = 'Ossia_Re_Enrolment_Confirmation';
            }else{
                templatename = 'Re_Enrolment_Confirmation';
            }
            Messaging.SingleEmailMessage objSingleEmailMessage = getParentEmailInformation(mapOfEmailTemplate,parentAcc,templatename);
            if(objSingleEmailMessage != null)
                sendSingleEmailMessage.add(objSingleEmailMessage);
        
            if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
                Messaging.sendEmail(sendSingleEmailMessage);
            }    
            isSucess = true;
            errorMsg ='Re-enrollment link with all enrolment details successfully sent to parent!..';
        }catch(exception e){
            isError = true;
            errorMsg =e.getMessage();
        }  
    }

    // we get templete according to Enrolment organisation
    public static Messaging.SingleEmailMessage getParentEmailInformation(Map<String,EmailTemplate> mapOfEmailTemplate,Account parentAcc,string templatename){
        Messaging.SingleEmailMessage objsendSingleEmailMessage = new Messaging.SingleEmailMessage();
        if(mapOfEmailTemplate != null && mapOfEmailTemplate.size() > 0 ){
            string centerId,personContactId;
            if(parentAcc.id != null && parentAcc.Centre_Name__r != null &&
                string.isNotBlank(parentAcc.Centre_Name__r.Location__c) ){
                centerId = parentAcc.Centre_Name__r.Location__c;
            }
            if(parentAcc.id  != null && string.isNotBlank(parentAcc.PersonContactId)){
                personContactId = parentAcc.PersonContactId;
            }
            if(mapOfEmailTemplate.containsKey(templatename)){
                objsendSingleEmailMessage = AureusUtility.getSingleEmailMessage(mapOfEmailTemplate.get(templatename).Id,personContactId,parentAcc.id,centerId);
            }
        
        }
        return objsendSingleEmailMessage;
    }
}
