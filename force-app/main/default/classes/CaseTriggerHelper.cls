public class CaseTriggerHelper {
    private static string custRec=ConstantsClass.customerRecTypeName;
    Private static String CentreRec = ConstantsClass.centerRecTypeName;
    //@Ravi, This process is used to update Service Request Cases with the Location, Center and Contact if Person Account exist
    // else create person account and update the same 
    @future
    public static void UpdateCase(set<Id> CaseId){

        
        List<EmailMessage> messages= [select id, ParentId, FromName, FromAddress, ToAddress from EmailMessage where ParentId IN: CaseId];
        list<Case> CaseListing = new list<Case>([Select Id, OwnerId,IsDeleted, CaseNumber, ContactId, AccountId, AssetId, SourceId, BusinessHoursId, ParentId, SuppliedName, SuppliedEmail, SuppliedPhone, SuppliedCompany, Type, RecordTypeId, Status, Reason, Origin, Subject, Priority, Description From Case where id in :CaseId]);
        set<string> ids = new set<string>();
        List<Case> caseList= new List<Case>();
        List<EmailMessage> emailList= new List<EmailMessage>();
        List<Account> accnt= new List<Account>();
        List<Account> accntUpdate= new List<Account>();
        map<string,Account> maptoAccount= new map<string,account>();
        
        for(Case cs:CaseListing){
            if(cs.SuppliedEmail != null){
                ids.add(cs.SuppliedEmail);   
            }
        }
        Id customerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(custRec).getRecordTypeId();
        list<Account> acc=[Select id,Name,Location__c,(Select id From Contacts),PersonEmail From Account where RecordTypeId =:customerId and PersonEmail in :ids];
        if(acc.size()>0){
            String QueIds;
            String CustomersId;
            string centerLocation;
            if(messages.size()>0){
                Id centerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(CentreRec).getRecordTypeId();
                List<Account> center = [Select id,Name,Location__c,Center_Email__c From Account where RecordTypeId =:centerId and Center_Email__c =:messages[0].ToAddress limit 1];
                
                if(center.size()>0){
                    CustomersId=center[0].id;
                    centerLocation = center[0].Location__c;
                }
                
            }
            map<string,Account> mapToAccnt = new map<string,Account>();
            for(Account getAcc:acc){
                mapToAccnt.put(getAcc.PersonEmail,getAcc);
            }
            set<id> caseidSet= new set<id>();
            // Changes on 4th Oct by Ravi as Updated Account with center and Location
            for(Account accObjNew:acc){
                Account accObj = new Account();
                accObj.Id=accObjNew.Id;
                accObj.Location__c=centerLocation;
                accObj.Centre_Name__c=CustomersId;
                accntUpdate.add(accObj);
            }
            for(Case caseobj:CaseListing){
                Case caseRec = new Case();
                caseRec.id=caseobj.id;
                caseRec.ContactId=mapToAccnt.get(caseobj.SuppliedEmail).Contacts[0].id;
                caseRec.Location__c=centerLocation;
                caseRec.Centre_Name__c=CustomersId;
                caseidSet.add(caseRec.id);
                caseList.add(caseRec);
            }
            update caseList;
            if(accntUpdate.size()>0){
                update accntUpdate;
            }
            
        }else{
            for(Case cs:CaseListing){
                String[] SuppName=String.isNotBlank(cs.SuppliedName)?cs.SuppliedName.split(' ',2):new List<String>();
                
                if(SuppName.size()==2){
                    Account ac= new Account(FirstName=SuppName[0],LastName=SuppName[1],PersonEmail=cs.SuppliedEmail,RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get(custRec).getRecordTypeId(),OwnerId=UserInfo.getUserId());
                    maptoAccount.put(ac.PersonEmail,ac);
                    accnt.add(ac);
                }
            }
            if(accnt.size()!=null){
                insert accnt;
            }
            map<string,Contact> mapAccToContact = new map<string,Contact>();
            for(Contact getCon:[Select Email,id from Contact where AccountId in : accnt]){
                mapAccToContact.put(getCon.Email,getCon);
            }
            for(Case casobj:CaseListing){
                if(maptoAccount.containsKey(casobj.SuppliedEmail)){
                    
                    String QueIds;
                    String CustomersId;
                    string centerLocation;
                    if(messages.size()>0){
                        Id centerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(CentreRec).getRecordTypeId();
                        List<Account> center = [Select id,Name,Location__c,Center_Email__c From Account where RecordTypeId =:centerId and Center_Email__c =:messages[0].ToAddress limit 1];
                        if(center.size()>0){
                            CustomersId=center[0].id;
                            centerLocation = center[0].Location__c; 
                        }
                        
                    }
                    Case cscObj = new Case();
                    cscObj.id=casobj.id;
                    cscObj.AccountId=maptoAccount.get(casobj.SuppliedEmail).id;
                    cscObj.ContactId=mapAccToContact.get(casobj.SuppliedEmail).id;
                    //cscObj.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
                    cscObj.Location__c=centerLocation;
                    cscObj.Centre_Name__c=CustomersId;
                    caseList.add(cscObj);
                     // Changes on 4th Oct by Ravi as Updated Account with center and Location
                    for(Account accObj:accnt){
                        accObj.Location__c=centerLocation;
                        accObj.Centre_Name__c=CustomersId;
                        accntUpdate.add(accObj);
                    }
                }
                
            }
            if(accntUpdate.size()>0){
                update accntUpdate;
            }
            if(caseList!=null){
                update caseList;   
            }
        }
    }
    
    //@Rajesh(Date 19-04-2019), Populate Booking Id on Case
    @future
    public static void updateBookingIdInCase(Map<Id, Id> caseEnrMap){
        //Filling Enromlent Booking map
        Map<Id, Id>   enrTrialbookMap = new Map<Id, Id>();
        String bookLessRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();    
        for(Booking__c book : [SELECT Id, Name, Enrolment__c FROM Booking__c 
                               WHERE Enrolment__c IN: caseEnrMap.values() AND 
                               Type__c =: ConstantsClass.typeTrial AND RecordTypeId=:bookLessRecId]){
                                   if(!enrTrialbookMap.containsKey(book.Enrolment__c))
                                       enrTrialbookMap.put(book.Enrolment__c, book.Id);
                               }
        
        List<Case> cupdList = new List<Case>();
        for(Id caseId : caseEnrMap.keySet()){
            if(enrTrialbookMap.containsKey(caseEnrMap.get(caseId))){
                cupdList.add(new Case(Id = caseId, Booking__c = enrTrialbookMap.get(caseEnrMap.get(caseId))));
            }
        }
        if(cupdList.size() > 0)
            update cupdList;
        //if(enrTrialbookMap.containsKey(enrol.Id))
        //  salesEnqCase.Booking__c = enrTrialbookMap.get(enrol.Id);
    }
    
    
    //@Rajesh (Date 6-4-2019), This process is used to update contactId with the Parent contactId
    public static void updateContact(List<case> caseList){
        Map<Id, Account> accMap = new Map<Id, Account>();
        for(Case c: caseList){
            if(c.AccountId != null && c.ContactId == null)
                accMap.put(c.AccountId, null);
        }
        if(accMap.size() > 0){
            accMap = new Map<Id, Account>([Select Id, PersonContactId From Account Where Id IN: accMap.keySet()]);
            for(Case c: caseList){
                if(c.AccountId != null && c.ContactId == null && accMap.get(c.AccountId) != null)
                    c.ContactId = accMap.get(c.AccountId).PersonContactId;
            }
        }
    }
    //@Rajesh (Date 3-4-2019), This process is used to update Lead and Opportunity and Enrolment as lost when case Lost
    //Commented by Rajesh on (17-06-2020), need to build this functionality from enrolment as per discussion with Ashish or Alex
  /*  public static void processOnCaseLost(List<case> caseList, Map<Id, Case> caseOldMap){
        Id recorTypeId = Schema.SObjectType.case.getRecordTypeInfosByName().get(ConstantsClass.caseSalesEnqRecTypeName).getRecordTypeId();
        
        List<Lead> leadUpdList       = new List<Lead>();
        List<Opportunity> oppUpdList = new List<Opportunity>();
        List<Enrolment__c> enrUpdList= new List<Enrolment__c>();
        for(Case cs: caseList){
            if(cs.RecordTypeId == recorTypeId && cs.Stage__c == ConstantsClass.caseLost && cs.Stage__c != caseOldMap.get(cs.Id).Stage__c){
                
                if(cs.Lead__c != null)
                    leadUpdList.add(new Lead(Id = cs.Lead__c , Status = ConstantsClass.caseLost));  
                
                if(cs.Opportunity__c != null)
                    oppUpdList.add(new Opportunity(Id = cs.Opportunity__c, StageName = 'Closed Lost'));
                
                if(cs.Enrolment__c != null)
                    enrUpdList.add(new Enrolment__c(Id = cs.Enrolment__c, Stage__c = ConstantsClass.caseLost));      
            }
        }
        
        if(leadUpdList.size() > 0)
            update leadUpdList;
        
        if(oppUpdList.size() > 0)
            update oppUpdList;
        
        if(enrUpdList.size() > 0)
            update enrUpdList;   
    }*/
    
    
    //@Nishi (Date 22-7-2019), This process is used to Change Case status Notification.
    public static void processChangeCase(Map<String,String> changeStatusMap){
        List<MobileNotificationWrapper> notifications = new List<MobileNotificationWrapper>();
        
        Map<String,String> parentTokens = new Map<String,String>();
        
        for(Account acc: [SELECT id,FCM_Token__c from Account where Id in:changeStatusMap.values() AND FCM_Token__c !=null]){
            parentTokens.put(acc.id,acc.FCM_Token__c );
        }
        
        for(Case caseObj : [SELECT id,Status,CaseNumber,AccountId FROM Case WHERE id in: changeStatusMap.keyset()]){
            try{
            if(parentTokens.containsKey(caseObj.AccountId)){
                String to = parentTokens.get(caseObj.AccountId);
                String title = 'Ticket #'+caseObj.CaseNumber+' has been updated!';
                String bodymsg = 'Please note your ticket '+ caseObj.CaseNumber +' has been updated. Please check your email for our reply or check your tickets page for more information.';
                notifications.add(new MobileNotificationWrapper(caseObj.AccountId, to, title, bodymsg));
            }
            }catch(Exception e){}
        }
        if(notifications.size() > 0 && !System.isBatch() && !System.isFuture()) {
            Database.executeBatch(new SendMobileNotificationBatch(notifications),90);
        }
    }
}