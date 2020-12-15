global class BatchClsToUpdateAccConOnChatCase implements  Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        integer minutes = integer.valueof(label.CaseCreatedTime);
        datetime nowSubtractTwoMins = system.now().addminutes(-minutes);
        return Database.getQueryLocator('Select ContactEmail,CaseNumber,Contact.FirstName,Contact.LastName,Contact.Name,Email__c,AccountId,ContactId,SuppliedName,Origin,Location__c from Case where createddate >=:nowSubtractTwoMins and Origin=\'Chat\'');
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
        // added by nishi: 7-Dec-2020: for update centername according to location picklist value 
        Set<string> locationList = new Set<string>();
        for(case cse:Caselist){
            if(string.isNotBlank(cse.Location__c)){
                locationList.add(cse.Location__c);
            }
        }
        Id centerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
        Map<string,Account> mapofCenter = new Map<string,Account>();
        Map<string,Account> mapofCaseCenter = new Map<string,Account>();
        for(Account objCenter: [Select id,Name,Location__c,Center_Email__c,Organisation__c,country__r.name,Organisation__r.name
                                From Account
                                where RecordTypeId =:centerId]){
                                    mapofCenter.put(objCenter.Location__c,objCenter); 
                                    if(locationList.contains(objCenter.Location__c)){
                                        mapofCaseCenter.put(objCenter.Location__c,objCenter);   
                                    }
                                }
        Map<string,Account> mapofCaseLocation = new Map<string,Account>();
        Map<string,String> mapofAccountLocation = new Map<string,String>();
        for(case cse:Caselist){
            system.debug(cse.ContactEmail+';'+cse.AccountId+';'+cse.CaseNumber);
            if(string.isNotBlank(cse.Email__c) && string.isBlank(cse.AccountId) && string.isblank(cse.ContactId)){
                system.debug(cse.Email__c);
                mapOfEmailWithName.put(cse.Email__c,cse.SuppliedName);   
                if(string.isNotBlank(cse.Location__c) && mapofCaseCenter.containsKey(cse.Location__c)){
                    mapofAccountLocation.put(cse.Email__c,mapofCaseCenter.get(cse.Location__c).id);
                }
            }
            if(string.isNotBlank(cse.ContactEmail) && string.isBlank(cse.AccountId)){
                mapOfEmailWithName.put(cse.ContactEmail,cse.Contact.Name); 
                mapOfCaseIdWithCountry.put(cse.id,null);
                if(string.isNotBlank(cse.Location__c) && mapofCaseCenter.containsKey(cse.Location__c)){
                    mapofAccountLocation.put(cse.ContactEmail,mapofCaseCenter.get(cse.Location__c).id);
                }
            }
        }
        system.debug('mapOfEmailWithName'+mapOfEmailWithName);
        system.debug('mapofAccountLocation'+mapofAccountLocation);
        for(LiveChatTranscript chat : [SELECT Id,Country__c,caseid FROM LiveChatTranscript WHERE caseid IN : mapOfCaseIdWithCountry.keyset()]){
            if(string.isNotBlank(chat.Country__c))
                mapOfCaseIdWithCountry.put(chat.caseid,chat.Country__c);  
        } 
        for( Account acc : [Select id,Name,Location__c,Organisation_Sharing__c,(Select id From Contacts),PersonEmail 
                            From Account 
                            where RecordTypeId =:customerId 
                            and PersonEmail in :mapOfEmailWithName.keyset()]){
            system.debug('acc-->'+acc);
            if(string.isNotBlank(acc.Location__c)){
                if(mapofAccountLocation.containsKey(acc.PersonEmail) && mapofCenter.get(acc.Location__c).id == mapofAccountLocation.get(acc.PersonEmail)){                                
                    mapOfEmailWithAccount.put(acc.PersonEmail,acc);
                }else{
                    if(acc.Organisation_Sharing__c == mapofCenter.get(acc.Location__c).Organisation__r.name ){
                        if(!mapOfEmailWithAccount.containsKey(acc.PersonEmail))
                            mapOfEmailWithAccount.put(acc.PersonEmail,acc);
                    }
                }
            }else{
                if(!mapOfEmailWithAccount.containsKey(acc.PersonEmail))
                    mapOfEmailWithAccount.put(acc.PersonEmail,acc);
            }
        }
        system.debug('mapOfEmailWithAccount'+mapOfEmailWithAccount);
        for(case cse:Caselist){
            if(string.isNotBlank(cse.Email__c) && string.isBlank(cse.AccountId) && string.isblank(cse.ContactId)){
                if(mapOfEmailWithAccount.containskey(cse.Email__c)) {
                    Case casetoupdate = new Case();
                    casetoupdate.id = cse.id;
                    casetoupdate.AccountId = mapOfEmailWithAccount.get(cse.Email__c).Id;
                    if(mapOfEmailWithAccount.get(cse.Email__c).contacts != null && mapOfEmailWithAccount.get(cse.Email__c).contacts.size() > 0){
                        casetoupdate.ContactId = mapOfEmailWithAccount.get(cse.Email__c).Contacts[0].Id;  
                    }
                    if(string.isNotBlank(cse.Location__c) && mapofCenter.containsKey(cse.Location__c)){
                        casetoupdate.Centre_Name__c =  mapofCenter.get(cse.Location__c).id;
                    }
                    caseListToUpdate.add(casetoupdate);  
                }
                else{
                    string name = mapOfEmailWithName.get(cse.Email__c); 
                    String[] SuppName=name.split(' ',2);
                    
                    if(SuppName.size()==2){
                        Account ac= new Account(FirstName=SuppName[0],LastName=SuppName[1],PersonEmail=cse.Email__c,RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get(custRec).getRecordTypeId(),OwnerId=UserInfo.getUserId());
                        string useremail=cse.Email__c+'.';
                        if(mapofCaseCenter.containskey(cse.Location__c)){
                            Account objCenter=mapofCaseCenter.get(cse.Location__c);
                            string CustomersId = mapofCaseCenter.get(cse.Location__c).id;
                            if(String.isNotBlank(CustomersId)){
                                if(objCenter.Organisation__r.name == Label.Ossia_Organisation_Name){
                                    useremail +='ossia'+objCenter.country__r.name; 
                                }else{
                                    useremail += 'aureus'+objCenter.country__r.name;
                                }
                                
                                ac.User_Email__c=useremail;
                            }
                            ac.Centre_Name__c = CustomersId;
                        }
                        ac.Location__c=cse.Location__c;
                        mapOfEmailWithAccount.put(ac.PersonEmail,ac);
                        accountListToUpdate.add(ac);
                    }
                    if(SuppName.size()==1){
                        Account ac= new Account(FirstName=SuppName[0],LastName=SuppName[0],PersonEmail=cse.Email__c,RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get(custRec).getRecordTypeId(),OwnerId=UserInfo.getUserId());
                        string useremail=cse.Email__c+'.';
                        if(mapofCaseCenter.containskey(cse.id)){
                            Account objCenter= mapofCaseCenter.get(cse.Location__c);
                            string CustomersId = mapofCaseCenter.get(cse.Location__c).id;
                            if(String.isNotBlank(CustomersId)){
                                if(objCenter.Organisation__r.name == Label.Ossia_Organisation_Name){
                                    useremail +='ossia'+objCenter.country__r.name; 
                                }else{
                                    useremail += 'aureus'+objCenter.country__r.name;
                                }
                                ac.Centre_Name__c = CustomersId;
                                ac.User_Email__c=useremail;
                            }
                        }
                        ac.Location__c=cse.Location__c;
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
                    if(string.isNotBlank(cse.Location__c) && mapofCaseCenter.containsKey(cse.Location__c)){
                        casetoupdate.Centre_Name__c =  mapofCaseCenter.get(cse.Location__c).id;
                    }
                    // casetoupdate.ContactId = mapOfEmailWithAccount.get(cse.Email__c).Contacts[0].Id; 
                    if(mapOfCaseIdWithCountry.containskey(cse.id)) casetoupdate.Country_PI__c=mapOfCaseIdWithCountry.get(cse.id); 
                    caseListToUpdate.add(casetoupdate);    
                }
                else{
                    string name = mapOfEmailWithName.get(cse.ContactEmail); 
                    String[] SuppName=name.split(' ',2);
                    
                    if(SuppName.size()==2){
                        Account ac= new Account(FirstName=SuppName[0],LastName=SuppName[1],PersonEmail=cse.ContactEmail,RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get(custRec).getRecordTypeId(),OwnerId=UserInfo.getUserId());
                        string useremail=cse.ContactEmail+'.';
                        if(mapofCaseCenter.containskey(cse.Location__c)){
                            Account objCenter= mapofCaseCenter.get(cse.Location__c);
                            string CustomersId = objCenter.id;
                            if(String.isNotBlank(CustomersId)){
                                if(objCenter.Organisation__r.name == Label.Ossia_Organisation_Name){
                                    useremail +='ossia'+objCenter.country__r.name; 
                                }else{
                                    useremail += 'aureus'+objCenter.country__r.name;
                                }
                                ac.Centre_Name__c = CustomersId;
                                ac.User_Email__c=useremail;
                            }
                        }
                        ac.Location__c=cse.Location__c;
                        mapOfEmailWithAccount.put(ac.PersonEmail,ac);
                        accountListToUpdate.add(ac);
                    }
                    if(SuppName.size()==1){
                        Account ac= new Account(FirstName=SuppName[0],LastName=SuppName[0],PersonEmail=cse.ContactEmail,RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get(custRec).getRecordTypeId(),OwnerId=UserInfo.getUserId());
                        string useremail=cse.ContactEmail+'.';
                        if(mapofCaseCenter.containskey(cse.Location__c)){
                            Account objCenter= mapofCaseCenter.get(cse.Location__c);
                            string CustomersId = objCenter.id;
                            if(String.isNotBlank(CustomersId)){
                                if(objCenter.Organisation__r.name == Label.Ossia_Organisation_Name){
                                    useremail +='ossia'+objCenter.country__r.name; 
                                }else{
                                    useremail += 'aureus'+objCenter.country__r.name;
                                }
                                ac.Centre_Name__c = CustomersId;
                                ac.User_Email__c=useremail;
                            }
                        }
                        ac.Location__c=cse.Location__c;
                        mapOfEmailWithAccount.put(ac.PersonEmail,ac);
                        accountListToUpdate.add(ac);
                    }
                }   
            }
            
        }
        system.debug('accountListToUpdate'+accountListToUpdate);
        system.debug('caseListToUpdate'+caseListToUpdate);
        if(accountListToUpdate.size()>0) insert accountListToUpdate;
        if(caseListToUpdate.size()>0) update caseListToUpdate;
        for( Account acc : [Select id,Name,Location__c,(Select id From Contacts),PersonEmail From Account where RecordTypeId =:customerId and id in :accountListToUpdate]){
            if(string.isNotBlank(acc.Location__c)){
                if(mapofAccountLocation.containsKey(acc.PersonEmail) && mapofCenter.get(acc.Location__c).id == mapofAccountLocation.get(acc.PersonEmail)){                                
                    mapOfEmailWithAccount.put(acc.PersonEmail,acc);
                }else{
                    if(acc.Organisation_Sharing__c == mapofCenter.get(acc.Location__c).Organisation__r.name ){
                        if(!mapOfEmailWithAccount.containsKey(acc.PersonEmail))
                            mapOfEmailWithAccount.put(acc.PersonEmail,acc);
                    }
                }
            }else{
                if(!mapOfEmailWithAccount.containsKey(acc.PersonEmail))
                    mapOfEmailWithAccount.put(acc.PersonEmail,acc);
            }
        }
        
        for(case cse:Caselist){
            if(string.isNotBlank(cse.Email__c) && string.isBlank(cse.AccountId) && string.isblank(cse.ContactId)){
                if(mapOfEmailWithAccount.containskey(cse.Email__c)) {
                    Case casetoupdate = new Case();
                    casetoupdate.id = cse.id;
                    casetoupdate.AccountId = mapOfEmailWithAccount.get(cse.Email__c).Id;
                    if(mapOfEmailWithAccount.get(cse.Email__c).contacts != null && mapOfEmailWithAccount.get(cse.Email__c).contacts.size() > 0){
                        casetoupdate.ContactId = mapOfEmailWithAccount.get(cse.Email__c).contacts[0].Id;  
                    }
                    if(string.isNotBlank(cse.Location__c) && mapofCenter.containsKey(cse.Location__c)){
                        casetoupdate.Centre_Name__c =  mapofCenter.get(cse.Location__c).id;
                    }
                    caseListToUpdatewithnewAccounnts.add(casetoupdate);  
                }
                
            }
            if(string.isNotBlank(cse.ContactEmail) && string.isBlank(cse.AccountId)){
                if(mapOfEmailWithAccount.containskey(cse.ContactEmail)) {
                    Case casetoupdate = new Case();
                    casetoupdate.id = cse.id;
                    casetoupdate.AccountId = mapOfEmailWithAccount.get(cse.ContactEmail).Id;
                    if(string.isNotBlank(cse.Location__c) && mapofCenter.containsKey(cse.Location__c)){
                        casetoupdate.Centre_Name__c =  mapofCenter.get(cse.Location__c).id;
                    }
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