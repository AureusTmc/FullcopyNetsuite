public without sharing class EnrolmentThankyouCntrl {
    public Boolean isOssia{get;set;}//@Juneid 22 Aug 2020, For Checking ossia
    
    public EnrolmentThankyouCntrl(){
        isOssia = false;
        
        //String parId = ApexPages.currentPage().getParameters().get('id');
        //String status  = ApexPages.currentPage().getParameters().get('status');
        // isOssia = Boolean.valueOf((ApexPages.currentPage().getParameters().get('isOssia')));
        //added by nishi: 10-Sep-2020: for get ossia organisation parameter then we change colors
        if(String.isNotBlank(ApexPages.currentPage().getParameters().get('isOssia'))){
            isOssia =  Boolean.valueOf((ApexPages.currentPage().getParameters().get('isOssia')));
        }
    }
    
    public pagereference generateInvPdf(){
        /*  String invId = ApexPages.currentPage().getParameters().get('invId');  
if(String.isNotBlank(invId)){
Set<string> invIds = new Set<string>();
invIds.add(invId);
BillingUtility.addInvocieAttachment(invIds);    
}
*/
        Set<String> invIds = new Set<String>();
        Map<String, String> params  =  ApexPages.currentPage().getParameters(); 
        if(params != null && params.size() > 0){
            for(String strKey : params.keySet()){
                if(strKey.contains('inv'))
                    invIds.add(params.get(strKey));
            }
            
            if(invIds.size() > 0){
                updateInvoiceNumOnStripe(invIds);
                BillingUtility.addInvocieAttachment(invIds); 
                
                String prcType = ApexPages.currentPage().getParameters().get('type');
                if(prcType != 'Studio'){
                    return sendEmailWithPdf(invIds);
                }else{
                    String bookId = ApexPages.currentPage().getParameters().get('bookId');
                    if(String.isNotBlank(bookId))
                        sendEmailWithPdfOnStudio(bookId);
                }
            }
        }
        
        return null;
    }
    
    public void updateInvoiceNumOnStripe(Set<String> invIds){
        String stripeChargeId = ApexPages.currentPage().getParameters().get('scId'); 
        
        if(String.isNotBlank(stripeChargeId)){
            //commented by Rajesh, on 09th Sep 2019, to get stripe connection bases of contry 
            /* for(Invoice__c inv: [SELECT Id,Name FROM Invoice__c WHERE Id IN: invIds]){
invNumbers =+ inv.Name + ',';
}
if(invNumbers.endsWith(','))
invNumbers = invNumbers.substring(0, (invNumbers.length()-1));

//Update invoice number on Stripe
BillingUtility.updateCharge(stripeChargeId, invNumbers);
*/
            String invNumbers = '';
            List<Invoice__c> invList = [SELECT Id,Name,Center__r.Country__r.Stripe_Secret_Key__c,Center__r.Country__r.Stripe_Base_Url__c FROM Invoice__c WHERE Id IN: invIds];
            if(invList.size() > 0){
                for(Invoice__c inv: invList)
                    invNumbers =+ inv.Name + ',';
                
                if(invNumbers.endsWith(','))
                    invNumbers = invNumbers.substring(0, (invNumbers.length()-1));
                
                String baseUrl = invList.get(0).Center__r.Country__r.Stripe_Base_Url__c;
                String apiKey  = invList.get(0).Center__r.Country__r.Stripe_Secret_Key__c;
                BillingUtility.updateCharge(stripeChargeId, invNumbers, baseUrl, apiKey);
            }
        }
    }
    public pagereference sendEmailWithPdf(Set<String> invIds){
        //@Juneid 26 Aug 2020, Organizatuion wise Templates
        List<EmailTemplate> templateList =  new List<EmailTemplate>();
        if(isOssia){
            templateList =  [Select Id,name,developerName from EmailTemplate where developerName =:label.Ossia_Enrolment_Summary_Email limit 1];
        }else{
            templateList =  [Select Id,name,developerName from EmailTemplate where developerName =:Label.Enrolment_Summary_Email limit 1];
        }
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        
        if(invIds.size() > 0 && templateList.size() > 0){
            Map<String,OrgWideEmailAddress> mapOfOrgWide = new Map<String,OrgWideEmailAddress>();
            list<Attachment> invoiceSummarAttList = new List<Attachment>();
            
            List<Invoice__c> invList = [SELECT Id, Name, Parent_Account__c, Parent_Account__r.personContactId,Center__r.Location__c, 
                                        Parent_Account__r.Is_Club_Member__c, Parent_Account__r.Membership_Type__c, Parent_Account__r.American_club__r.PersonEmail, 
                                        (SELECT Id, Enrolment__c, Enrolment__r.Name, Subscription_Line_Item__r.Enrolment__c FROM Invoice_Line_Items__r)
                                        FROM Invoice__c WHERE Id IN:invIds AND Parent_Account__c != null];
            
            //Added by Rajesh: 27th June 2019, for concatenate enrolment number with the enrolment summary page
            Map<String, Set<String>> invEnrMap = new  Map<String, Set<String>>();
            for(Invoice__c inv: invList){
                Set<String> tempSet = new Set<String>();
                if(invEnrMap.containsKey(inv.Id))
                    tempSet  = invEnrMap.get(inv.Id);
                
                for(Invoice_Line_Item__c invLnItm: inv.Invoice_Line_Items__r)                  
                    tempSet.add(invLnItm.Enrolment__r.Name);
                
                invEnrMap.put(inv.Id, tempSet);
            } 
            
            //Added by Rajesh, 19th Aug 2019. To exclude invoice attachment in email for american club member 
            Boolean isClubMem   = False;   
            
            //Added by Rajesh, 11th June 2019, for check American club invoice to Club member
            String amcClubEmail = ''; 
            if(invList.size() > 0){
                //Added by Rajesh, 19th Aug 2019. To exclude invoice attachment in email for american club member 
                if(invList.get(0).Parent_Account__r.Is_Club_Member__c)
                    isClubMem = True;
                
                if(invList.get(0).Parent_Account__r.Is_Club_Member__c && invList.get(0).Parent_Account__r.Membership_Type__c == ConstantsClass.amcClubMember
                   &&
                   
                   String.isNotBlank(invList.get(0).Parent_Account__r.American_club__r.PersonEmail)){
                       amcClubEmail = invList.get(0).Parent_Account__r.American_club__r.PersonEmail;
                   }
            }
            
            for(OrgWideEmailAddress objAddress : [SELECT Address, DisplayName, Id FROM OrgWideEmailAddress]){
                mapOfOrgWide.put(objAddress.DisplayName,objAddress);
            }
            
            //Fetching parent related open case
            /* Map<Id, Case> accCaseMap = new Map<Id, Case>();
for(Invoice__c inv: invList)
accCaseMap.put(inv.Parent_Account__c, null);       

for(Case c : [SELECT Id, Status, AccountId FROM Case 
WHERE AccountId IN: accCaseMap.keySet() AND Status != 'Closed'AND
RecordType.Name = 'Sales Enquiry' ORDER BY CreatedDate DESC]){
if(accCaseMap.get(c.AccountId) == null)
accCaseMap.put(c.AccountId, c);   
}*/
            
            
            for(Invoice__c inv : invList){
                List<Messaging.EmailFileAttachment> email_attachments = new List<Messaging.EmailFileAttachment>();
                
                //Attaching Invoice pdf
                /*PageReference pdf = new pageReference('/apex/SubscriptionInvoicePdfClone?Id='+inv.Id);                
Messaging.EmailFileAttachment email_att = new Messaging.EmailFileAttachment();
if(!test.isRunningTest())
email_att.setBody(pdf.getContent());
else
email_att.setBody(blob.valueOf('TEST'));
email_att.setFileName('Invoice.pdf');
email_attachments.add(email_att);
*/                
                //Added by Rajesh: 27th June 2019, for concatenate enrolment number with the enrolment summary page
                String summFileName = '';
                
                for(String enrName: invEnrMap.get(inv.Id))
                    summFileName += (enrName + '_');                
                summFileName = summFileName+'EnrolmentSummary.pdf';
                
                //Attaching Enrolment Summar pdf                    
                PageReference pdf    = new pageReference('/apex/EnrolmentSummaryPdf?Id='+inv.Id); 
                Messaging.EmailFileAttachment email_att = new Messaging.EmailFileAttachment();
                
                //Added by Rajesh, 30th July 2019. For add invoice pdf in email
                PageReference invPdf = new pageReference('/apex/SubscriptionInvoicePdfClone?Id='+inv.Id);
                Messaging.EmailFileAttachment inv_att   = new Messaging.EmailFileAttachment();
                
                if(!test.isRunningTest()){
                    email_att.setBody(pdf.getContent());
                    
                    //Added by Rajesh, 30th July 2019. For add invoice pdf in email
                    inv_att.setBody(invPdf.getContent());
                    inv_att.setFileName(inv.Name+'.pdf');
                    
                    //Commented by Rajesh 24th Jun 2019, need to attach summary file with the parent record
                    //invoiceSummarAttList.add(fillAtt(pdf.getContent(), inv.Id));
                    invoiceSummarAttList.add(fillAtt(pdf.getContent(), inv.Parent_Account__c, summFileName));
                }else{
                    string blobstring='';
                    blobstring ='TEST';
                    blob blobtext =blob.valueOf(blobstring);
                    email_att.setBody(blobtext);
                }
                email_att.setFileName(summFileName);
                email_attachments.add(email_att);
                //Added by Rajesh, 30th July 2019. For add invoice pdf in email
                //Added by Rajesh, 19th Aug 2019. To exclude invoice attachment in email for american club member 
                if(!isClubMem)
                    email_attachments.add(inv_att);
                
                //Attaching Student Policy Form pdf
                /* pdf = new pageReference('/apex/StudentPolicyFormPdf?Id='+inv.Id);                
email_att = new Messaging.EmailFileAttachment();
if(!test.isRunningTest())
email_att.setBody(pdf.getContent());
else
email_att.setBody(blob.valueOf('TEST'));

email_att.setFileName('StudentPolicy.pdf');
email_attachments.add(email_att);
*/
                Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(templateList[0].Id, inv.Parent_Account__r.personContactId, inv.Id);
                //new Messaging.SingleEmailMessage();
                if( String.isNotBlank(inv.Center__r.Location__c) && mapOfOrgWide.containsKey(inv.Center__r.Location__c)){
                    mail.setOrgWideEmailAddressId(mapOfOrgWide.get(inv.Center__r.Location__c).Id);
                }
                mail.setTargetObjectId(inv.Parent_Account__r.personContactId);
                mail.saveAsActivity = true;
                mail.setWhatId(inv.Id);
                // if(accCaseMap.containsKey(inv.Parent_Account__c))
                //  mail.setWhatId(accCaseMap.get(inv.Parent_Account__c).Id); 
                mail.setTemplateId(templateList[0].Id);
                
                //Added by Rajesh, 11th June 2019, for check American club invoice to Club member
                if(String.isNotBlank(amcClubEmail))
                    mail.setCCAddresses( new String[]{amcClubEmail});
                
                if(email_attachments.size()  > 0)
                    mail.setFileAttachments(email_attachments);
                emailList.add(mail); 
            }
            
            if(emailList.size() > 0){
                if(!test.isRunningTest())
                    Messaging.sendEmail(emailList);
               
                if(invoiceSummarAttList.size() > 0)
                    insert invoiceSummarAttList;
                
                pagereference pg = new pagereference(Label.Enrolment_completed_url);
                return pg;
            }
        }
        
        return null;
    }
    
    //Send email code for the studiorental process
    public void sendEmailWithPdfOnStudio(String bookId){
        //@Juneid 26 Aug 2020, Organizatuion wise Templates
        List<EmailTemplate> templateList =  new List<EmailTemplate>();
        if(isOssia){
            templateList =  [Select Id,name,developerName from EmailTemplate where developerName =:Label.Ossia_Studio_Booking_Confirmation limit 1];
        }else{
            templateList =  [Select Id,name,developerName from EmailTemplate where developerName =:Label.Studio_Booking_Confirmation_Email limit 1];
        }
        //List<EmailTemplate> templateList =  [Select Id,name,developerName from EmailTemplate where developerName =:Label.Studio_Booking_Confirmation_Email limit 1];
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        
        if(String.isNotBlank(bookId) && templateList.size() > 0){
            Map<String,OrgWideEmailAddress> mapOfOrgWide = new Map<String,OrgWideEmailAddress>();
            
            //updated by Rajesh, 30th July 2019. For add invoice pdf in email, In this soql fetching invoice field
            List<Booking__c> bookList = [SELECT Id, Name, Parent__c, Parent__r.personContactId, Center__r.Location__c, Studio_Booking_Invoice_Number__c, Studio_Booking_Invoice_Number__r.Name
                                         FROM Booking__c WHERE Id =:bookId AND Parent__c != null];
            
            for(OrgWideEmailAddress objAddress : [SELECT Address, DisplayName, Id FROM OrgWideEmailAddress]){
                mapOfOrgWide.put(objAddress.DisplayName,objAddress);
            }
            
            for(Booking__c book : bookList){
                
                Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(templateList[0].Id, book.Parent__r.personContactId, book.Id);
                //new Messaging.SingleEmailMessage();
                if( String.isNotBlank(book.Center__r.Location__c) && mapOfOrgWide.containsKey(book.Center__r.Location__c)){
                    mail.setOrgWideEmailAddressId(mapOfOrgWide.get(book.Center__r.Location__c).Id);
                }
                
                //Added by Rajesh, 30th July 2019. For add invoice pdf in email
                List<Messaging.EmailFileAttachment> email_attachments = new List<Messaging.EmailFileAttachment>();
                PageReference invPdf = new pageReference('/apex/SubscriptionInvoicePdfClone?Id='+book.Studio_Booking_Invoice_Number__c); 
                Messaging.EmailFileAttachment inv_att   = new Messaging.EmailFileAttachment();
                if(!test.isRunningTest()){
                    inv_att.setBody(invPdf.getContent());
                    inv_att.setFileName(book.Studio_Booking_Invoice_Number__r.Name+'.pdf');
                }else{
                    string blobsting  = '';
                    blobsting  = 'Test';
                    Blob blobtext =blob.valueOf('TEST');
                    inv_att.setBody(blobtext);
                }
                email_attachments.add(inv_att); 
                
                mail.setTargetObjectId(book.Parent__r.personContactId);
                mail.saveAsActivity = true;
                mail.setWhatId(book.Id);
                mail.setTemplateId(templateList[0].Id);
                
                //Added by Rajesh, 30th July 2019. For attaching invoice pdf in email
                if(email_attachments.size()  > 0)
                    mail.setFileAttachments(email_attachments);
                emailList.add(mail); 
            }
            
            if(emailList.size() > 0){
                if(!test.isRunningTest())
                    Messaging.sendEmail(emailList);
                
                
            }
        }
    }
    
    public static Attachment fillAtt(Blob body, String parId, String fileName){
        Attachment att = new Attachment();
        att.Name       = fileName;
        att.parentId   = parId;
        att.body       = body;
        return att;
    }
    
    
}