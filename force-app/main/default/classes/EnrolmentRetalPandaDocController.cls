/*
    Name : EnrolmentRetalPandaDocController
    Date: 16-Jan-2020
    Description: this controller Create PandaDoc Dodument for get customer signature. 
  
 */
public with sharing class EnrolmentRetalPandaDocController {
    //Public Enrolment__c enrolmentObj{get;set;}
    public string sessionId{get;set;}
    public string personEmail{get;set;}
    public string aggrementId{get;set;}
    public string enrolmentId{get;set;}
    public string enrolmentType{get;set;}
    public boolean isSendDocument{get;set;}
    public Boolean isGetAggrementId{get;set;}
    
    public EnrolmentRetalPandaDocController() {
        enrolmentId = ApexPages.currentPage().getParameters().get('id');
        enrolmentType = ApexPages.currentPage().getParameters().get('type');
        personEmail = '';
        Enrolment__c objEnrolment = new Enrolment__c();
        if(String.isNotBlank(enrolmentId)){
            objEnrolment = [SELECT Id,Aggrement_Id__c,Parent__r.PersonEmail from Enrolment__c where Id=:enrolmentId];
            
            if(string.isNotBlank( objEnrolment.Aggrement_Id__c)){
                aggrementId = objEnrolment.Aggrement_Id__c;
            }
            if(string.isNotBlank(enrolmentType) && enrolmentType.equalsIgnoreCase('Client')){
                personEmail =  objEnrolment.Parent__r.PersonEmail;
            }else if(string.isNotBlank(enrolmentType) && enrolmentType.equalsIgnoreCase('Delivery_Person')){
                List<User> listOfPackerAndRemoverUser =  PianoRentalHelperController.getPackerAndRemoverUser();
                if(listOfPackerAndRemoverUser != null && listOfPackerAndRemoverUser.size()> 0 ){
                    personEmail = listOfPackerAndRemoverUser[0].email;
                }
            }
            if(string.isNotBlank(aggrementId) && string.isNotBlank(personEmail)){
                isGetAggrementId = false;
            }else{
                isGetAggrementId = true;
            }
        }
        
        isSendDocument = false;
    }

    // if both customer and packer signed aggrement then we update enrolment and Actual Delivery Date
    public PageReference  updateEnrolment(){
        string sendDocumentStatus = isSendDocumentAgreement(aggrementId);
        if(sendDocumentStatus.equalsIgnoreCase('document.completed')){ 
            // 10:Feb:2020 : jatin: for get extra stairs in aggrement doc.
            string extraStairs = viewDocumentDetails(aggrementId);   
            Enrolment__c objEnrolment = new Enrolment__c(id=enrolmentId,Actual_Delivery_Date_Time__c= system.now(),
            // 10:Feb:2020: jatin: added extra stairs
            Extra_Stairs__c = decimal.valueOf(string.isNotBlank(extraStairs)? extraStairs :'0')); 
            update objEnrolment;
            system.debug('objEnrolment'+objEnrolment);
        }
        return new PageReference('/'+enrolmentId);
    }

    // check document is sent, completed or view then we not create then we only create session other wise we call sendDoc function
    public void sendDocument(){
        if(String.isNotBlank(aggrementId) && String.isNotBlank(enrolmentId) ){
            isSendDocument = false;
            string sendDocumentStatus = isSendDocumentAgreement(aggrementId);
            system.debug('sendDocumentStatus'+sendDocumentStatus);
            if(sendDocumentStatus.equalsIgnoreCase('document.sent') || 
                sendDocumentStatus.equalsIgnoreCase('document.completed') ||
                sendDocumentStatus.equalsIgnoreCase('document.viewed')){
                      isSendDocument = true; 
                    }
            if(!isSendDocument)
                sendDocumentAgreement(aggrementId,enrolmentId);
        }

    }

    // create session for sign aggrement
    Public void createSession(){
        if(String.isNotBlank(aggrementId) && String.isNotBlank(personEmail)){
            sessionId = PianoRentalHelperController.createSession(aggrementId,personEmail);
            if(string.isNotBlank(sessionId)){
                isSendDocument = true; 
            }
        }
    }
   

    // Get basic data about a document such as name, status, and dates
    Public string  isSendDocumentAgreement(string aggrementId ){
        PandaDocUtility.Document document = new PandaDocUtility.Document();
        if( String.isNotBlank(aggrementId)){
            document = PandaDocUtility.viewDocument(aggrementId);
            return document.status;
        }
        return null;
    }

     //Move a document to sent status and send an optional email.
    Public void sendDocumentAgreement(string aggrementId, string enrolmentId){
         if( String.isNotBlank(aggrementId) && String.isNotBlank(enrolmentId)){
            map<string,PandaDocUtility.CreateDocument> mapOfsendDocument = PianoRentalHelperController.sendAgreement(new Map<String,string>{enrolmentId => aggrementId});
            if(mapOfsendDocument.containsKey(enrolmentId)){
                if(mapOfsendDocument.get(enrolmentId).status == 'document.sent'){
                    isSendDocument = true;
                }
            }
        }
    }

    //10-Feb-2020:jatin: get Document stairs field value 
    Public static string  viewDocumentDetails(string aggrementId){
        PandaDocUtility.Fields fieldsDetails; 
        if(String.isNotBlank(aggrementId)){
             fieldsDetails = PianoRentalHelperController.getDocumentStairs(aggrementId);
             System.debug('@@@sessionDetails'+aggrementId);
             if(String.isNotBlank(fieldsDetails.value)){
                return fieldsDetails.value;     
             }
         }
         return null;
    }
    
    
    
}