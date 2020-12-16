public class LiveChatTranscriptTriggerHelper {
    public static void assignAccountToCase(list<LiveChatTranscript> triggerNew, map<Id, LiveChatTranscript> chatOldMap){
        Map<String,string> mapOfEmails = new Map<String,string>();
        Map<Id,LiveChatTranscript> mapIdToLiveChatTranscript = new Map<Id,LiveChatTranscript>([SELECT Id,Country__c,Contact.Location_PI__c, Contact.Email,Contact.FirstName,Contact.LastName,Status FROM LiveChatTranscript WHERE Id IN : triggerNew]);
        Map<String,Account> mapEmailToAccountId = new Map<String,Account>();
        List<Account> listAccountToUpsert = new List<Account>();
        List<LiveChatTranscript> listChatTranscriptToUpdate = new List<LiveChatTranscript>();
        List<Case> listCaseToUpdate = new List<Case>();
        
        for(LiveChatTranscript lct : mapIdToLiveChatTranscript.Values()){
            if(lct.Status != chatOldMap.get(lct.Id).Status && lct.Status == 'Completed' && lct.Contact.Email != NULL)  
                mapOfEmails.put(lct.Contact.Email,lct.Contact.Location_PI__c);
        }
        system.debug('mapOfEmails'+mapOfEmails);
        Id recordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        Id centerId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
        Map<string,Account> mapofCenter = new Map<string,Account>();
        for(Account objCenter: [Select id,Name,Location__c,Center_Email__c,Organisation__c,country__r.name,Organisation__r.name
                                        From Account
                                        where RecordTypeId =:centerId
                                        and Location__c in:mapOfEmails.values()]){
                mapofCenter.put(objCenter.Location__c,objCenter);    
            }
        if(mapOfEmails.size() > 0) {
        for(Account acc : [SELECT Id,PersonEmail,Location_PI__pc,Country__c,Organisation_Sharing__c FROM Account WHERE RecordTypeId = :recordTypeId AND PersonEmail IN :mapOfEmails.keySet()]) {
                if(mapOfEmails.containsKey(acc.PersonEmail)){
                    if(string.isNotBlank(acc.Location_PI__pc)){
                        if(mapOfEmails.get(acc.PersonEmail) == acc.Location_PI__pc){
                            mapEmailToAccountId.put(acc.PersonEmail,acc); 
                        }else{
                            if(acc.Organisation_Sharing__c == mapofCenter.get(acc.Location_PI__pc).Organisation__r.name ){
                                if(!mapEmailToAccountId.containsKey(acc.PersonEmail))
                                    mapEmailToAccountId.put(acc.PersonEmail,acc); 
                            }
                        }
                    }else{
                        if(!mapEmailToAccountId.containsKey(acc.PersonEmail))
                            mapEmailToAccountId.put(acc.PersonEmail,acc);  
                    }
                }
            }     
            system.debug('mapEmailToAccountId'+mapEmailToAccountId);  
        }
       
        for(LiveChatTranscript lct : triggerNew) {
            if(lct.Status != chatOldMap.get(lct.Id).Status && lct.Status == 'Completed' && mapIdToLiveChatTranscript.containsKey(lct.Id) 
            && mapIdToLiveChatTranscript.get(lct.Id).Contact.Email != NULL) {
                if(!mapEmailToAccountId.containsKey(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email)) {
                    Account acc = new Account();
                    acc.recordTypeId = recordTypeId;
                    acc.FirstName = mapIdToLiveChatTranscript.get(lct.Id).Contact.FirstName;
                    acc.lastName = mapIdToLiveChatTranscript.get(lct.Id).Contact.LastName;
                    acc.PersonEmail = mapIdToLiveChatTranscript.get(lct.Id).Contact.Email;
                    if(mapOfEmails.containsKey(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email) 
                    && mapofCenter.containskey(mapOfEmails.get(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email)) ){
                        Account objCenter= mapofCenter.get(mapOfEmails.get(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email));
                        string CustomersId = mapofCenter.get(mapOfEmails.get(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email)).id;
                        string useremail=mapIdToLiveChatTranscript.get(lct.Id).Contact.Email+'.';
                        if(String.isNotBlank(CustomersId)){
                            if(objCenter.Organisation__r.name == Label.Ossia_Organisation_Name){
                                useremail +='ossia'+objCenter.country__r.name; 
                            }else{
                                useremail += 'aureus'+objCenter.country__r.name;
                            }
                            
                            acc.User_Email__c=useremail;
                        }
                        acc.Centre_Name__c = CustomersId;
                        acc.Location__c=acc.Location_PI__pc;
                    }
                    mapEmailToAccountId.put(acc.PersonEmail,acc);
                    listAccountToUpsert.add(acc);
                }else{
                    Account acc =  mapEmailToAccountId.get(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email);
                    if(string.isBlank(acc.Centre_Name__c) && string.isNotBlank(acc.Location_PI__pc) && mapofCenter.containskey(acc.Location_PI__pc)){
                        Account objCenter=mapofCenter.get(acc.Location_PI__pc);
                        string CustomersId = mapofCenter.get(acc.Location_PI__pc).id;
                        string useremail=mapIdToLiveChatTranscript.get(lct.Id).Contact.Email+'.';
                        if(String.isNotBlank(CustomersId)){
                            if(objCenter.Organisation__r.name == Label.Ossia_Organisation_Name){
                                useremail +='ossia'+objCenter.country__r.name; 
                            }else{
                                useremail += 'aureus'+objCenter.country__r.name;
                            }
                            
                            acc.User_Email__c=useremail;
                        }
                        acc.Centre_Name__c = CustomersId;
                        acc.Location__c=acc.Location_PI__pc;
                        mapEmailToAccountId.put(acc.PersonEmail,acc);
                        listAccountToUpsert.add(acc);
                    }
                }
            }           
        } 
        
        system.debug('listAccountToUpsert'+listAccountToUpsert);  
        if(listAccountToUpsert.size() > 0)
            upsert listAccountToUpsert;
        map<string,Account> mapOfEmailWithAccount = new map<string,Account>();
        
        for( Account acc : [Select id,Name,Location__c,(Select id From Contacts),PersonEmail From Account where RecordTypeId =:recordTypeId 
                            and id in :listAccountToUpsert]){
            system.debug('acc-->'+acc);
            if(mapEmailToAccountId.containsKey(acc.PersonEmail)&& mapofCenter.containsKey(acc.Location__c)){ 
                mapOfEmailWithAccount.put(acc.PersonEmail,acc);
            }
        }
        system.debug('mapOfEmailWithAccount'+mapOfEmailWithAccount);  
        for(LiveChatTranscript lct : triggerNew) {
            if(lct.Status != chatOldMap.get(lct.Id).Status && lct.Status == 'Completed'){
                LiveChatTranscript lct1 = new LiveChatTranscript();
                lct1.Id = lct.Id;
                lct1.AccountId = mapOfEmailWithAccount.get(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email).Id;
                listChatTranscriptToUpdate.add(lct1);
                
                Case cas = new Case();
                cas.Id = lct.CaseId;
                cas.AccountId = mapOfEmailWithAccount.get(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email).Id;
                cas.Country_PI__c = mapIdToLiveChatTranscript.get(lct.Id).Country__c;
                if(mapOfEmailWithAccount.get(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email).contacts != null && mapOfEmailWithAccount.get(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email).contacts.size() > 0){
                    cas.ContactId = mapOfEmailWithAccount.get(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email).Contacts[0].Id;  
                }
                cas.Centre_Name__c =  mapOfEmailWithAccount.get(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email).Centre_Name__c;
                listCaseToUpdate.add(cas);    
            }
        }
        system.debug('listChatTranscriptToUpdate'+listChatTranscriptToUpdate); 
        system.debug('listCaseToUpdate'+listCaseToUpdate); 
        if(listChatTranscriptToUpdate.size() > 0)
            update listChatTranscriptToUpdate;
        
        if(listCaseToUpdate.size() > 0)
            update listCaseToUpdate;
    }
}