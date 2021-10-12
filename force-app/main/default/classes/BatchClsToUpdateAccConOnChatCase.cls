global class BatchClsToUpdateAccConOnChatCase implements  Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        integer minutes = integer.valueof(label.CaseCreatedTime);
        datetime nowSubtractTwoMins = system.now().addminutes(-minutes);
        return Database.getQueryLocator('Select ContactEmail,CaseNumber,Contact.FirstName,Contact.LastName,Contact.Name,Email__c,AccountId,ContactId,SuppliedName,Origin from Case where createddate >=:nowSubtractTwoMins and Origin=\'Chat\'');
    }
    
    global void execute(Database.BatchableContext BC, List<Case> Caselist){
        map<string,string> mapOfEmailWithName = new map<string,string>();
         map<string,string> mapOfCaseIdWithCountry = new map<string,string>();
        map<string,Account> mapOfEmailWithAccount = new map<string,Account>();
        map<string,contact> mapOfEmailWithcontact = new map<string,contact>();
        list<case> caseListToUpdate = new list<case>();
        list<case> caseListToUpdatewithnewAccounnts = new list<case>();
        list<account> accountListToUpdate = new list<account>();
        string custRec=ConstantsClass.customerRecTypeName;
        Id customerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(custRec).getRecordTypeId();
        for(case cse:Caselist){
            system.debug(cse.ContactEmail+';'+cse.AccountId+';'+cse.CaseNumber);
            if(string.isNotBlank(cse.Email__c) && string.isBlank(cse.AccountId) && string.isblank(cse.ContactId)){
                system.debug(cse.Email__c);
                mapOfEmailWithName.put(cse.Email__c,cse.SuppliedName);   
            }
            if(string.isNotBlank(cse.ContactEmail) && string.isBlank(cse.AccountId)){
                mapOfEmailWithName.put(cse.ContactEmail,cse.Contact.Name); 
                mapOfCaseIdWithCountry.put(cse.id,null);
                system.debug(cse.ContactEmail);
            }
        }
        for(LiveChatTranscript chat : [SELECT Id,Country__c,caseid FROM LiveChatTranscript WHERE caseid IN : mapOfCaseIdWithCountry.keyset()]){
            if(string.isNotBlank(chat.Country__c))
             mapOfCaseIdWithCountry.put(chat.caseid,chat.Country__c);  
        } 
        for( Account acc : [Select id,Name,Location__c,(Select id From Contacts),PersonEmail From Account where RecordTypeId =:customerId and PersonEmail in :mapOfEmailWithName.keyset()]){
            system.debug('acc-->'+acc);
            mapOfEmailWithAccount.put(acc.PersonEmail,acc);
        }
        for(case cse:Caselist){
            if(string.isNotBlank(cse.Email__c) && string.isBlank(cse.AccountId) && string.isblank(cse.ContactId)){
                if(mapOfEmailWithAccount.containskey(cse.Email__c)) {
                    Case casetoupdate = new Case();
                    casetoupdate.id = cse.id;
                    casetoupdate.AccountId = mapOfEmailWithAccount.get(cse.Email__c).Id;
                    if(mapOfEmailWithAccount.get(cse.Email__c).Contacts != null && mapOfEmailWithAccount.get(cse.Email__c).Contacts.size() > 0 && string.isNotBlank(mapOfEmailWithAccount.get(cse.Email__c).Contacts[0].id)){
                        casetoupdate.ContactId =  mapOfEmailWithAccount.get(cse.Email__c).Contacts[0].Id;  
                    }
                    caseListToUpdate.add(casetoupdate);  
                }
                else{
                    string name = mapOfEmailWithName.get(cse.Email__c); 
                    String[] SuppName=name.split(' ',2);
                    
                    if(SuppName.size()==2){
                        Account ac= new Account(FirstName=SuppName[0],LastName=SuppName[1],PersonEmail=cse.Email__c,RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get(custRec).getRecordTypeId(),OwnerId=UserInfo.getUserId());
                        mapOfEmailWithAccount.put(ac.PersonEmail,ac);
                        accountListToUpdate.add(ac);
                    }
                    if(SuppName.size()==1){
                        Account ac= new Account(FirstName=SuppName[0],LastName=SuppName[0],PersonEmail=cse.Email__c,RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get(custRec).getRecordTypeId(),OwnerId=UserInfo.getUserId());
                        mapOfEmailWithAccount.put(ac.PersonEmail,ac);
                        accountListToUpdate.add(ac);
                    }
                }
            }
            if(string.isNotBlank(cse.ContactEmail) && string.isBlank(cse.AccountId)){
                if(mapOfEmailWithAccount.containskey(cse.ContactEmail)) {
                    Case casetoupdate = new Case();
                    casetoupdate.id = cse.id;
                    casetoupdate.AccountId = mapOfEmailWithAccount.get(cse.ContactEmail).Id;
                    // casetoupdate.ContactId = mapOfEmailWithAccount.get(cse.Email__c).Contacts[0].Id; 
                    if(mapOfCaseIdWithCountry.containskey(cse.id)) casetoupdate.Country_PI__c=mapOfCaseIdWithCountry.get(cse.id); 
                    caseListToUpdate.add(casetoupdate);    
                }
                else{
                    string name = mapOfEmailWithName.get(cse.ContactEmail); 
                    String[] SuppName=name.split(' ',2);
                    
                    if(SuppName.size()==2){
                        Account ac= new Account(FirstName=SuppName[0],LastName=SuppName[1],PersonEmail=cse.ContactEmail,RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get(custRec).getRecordTypeId(),OwnerId=UserInfo.getUserId());
                        mapOfEmailWithAccount.put(ac.PersonEmail,ac);
                        accountListToUpdate.add(ac);
                    }
                    if(SuppName.size()==1){
                        Account ac= new Account(FirstName=SuppName[0],LastName=SuppName[0],PersonEmail=cse.ContactEmail,RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get(custRec).getRecordTypeId(),OwnerId=UserInfo.getUserId());
                        mapOfEmailWithAccount.put(ac.PersonEmail,ac);
                        accountListToUpdate.add(ac);
                    }
                }   
            }
            
        }
        if(accountListToUpdate.size()>0) insert accountListToUpdate;
        if(caseListToUpdate.size()>0) update caseListToUpdate;
        for( Account acc : [Select id,Name,Location__c,(Select id From Contacts),PersonEmail From Account where RecordTypeId =:customerId and id in :accountListToUpdate]){
            system.debug('acc-->'+acc);
            mapOfEmailWithAccount.put(acc.PersonEmail,acc);
        }
        
        for(case cse:Caselist){
            if(string.isNotBlank(cse.Email__c) && string.isBlank(cse.AccountId) && string.isblank(cse.ContactId)){
                if(mapOfEmailWithAccount.containskey(cse.Email__c)) {
                    Case casetoupdate = new Case();
                    casetoupdate.id = cse.id;
                    casetoupdate.AccountId = mapOfEmailWithAccount.get(cse.Email__c).Id;
                    if(mapOfEmailWithAccount.get(cse.Email__c).Contacts != null && mapOfEmailWithAccount.get(cse.Email__c).Contacts.size() > 0 && string.isNotBlank(mapOfEmailWithAccount.get(cse.Email__c).Contacts[0].id)){
                        casetoupdate.ContactId = mapOfEmailWithAccount.get(cse.Email__c).contacts[0].Id;  
                    }
                    caseListToUpdatewithnewAccounnts.add(casetoupdate);  
                }
                
            }
            if(string.isNotBlank(cse.ContactEmail) && string.isBlank(cse.AccountId)){
                if(mapOfEmailWithAccount.containskey(cse.ContactEmail)) {
                    Case casetoupdate = new Case();
                    casetoupdate.id = cse.id;
                    casetoupdate.AccountId = mapOfEmailWithAccount.get(cse.ContactEmail).Id;
                    // casetoupdate.ContactId = mapOfEmailWithAccount.get(cse.Email__c).Contacts[0].Id;  
                     if(mapOfCaseIdWithCountry.containskey(cse.id)) casetoupdate.Country_PI__c=mapOfCaseIdWithCountry.get(cse.id);
                    caseListToUpdatewithnewAccounnts.add(casetoupdate);    
                }
                
            }
            
        }
        if(caseListToUpdatewithnewAccounnts.size()>0) update caseListToUpdatewithnewAccounnts;
    }
    global void finish(Database.BatchableContext BC){
    }
    
}