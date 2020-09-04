public class LiveChatTranscriptTriggerHelper {
    public static void assignAccountToCase(list<LiveChatTranscript> triggerNew, map<Id, LiveChatTranscript> chatOldMap){
        Set<String> setEmails = new Set<String>();
        Map<Id,LiveChatTranscript> mapIdToLiveChatTranscript = new Map<Id,LiveChatTranscript>([SELECT Id,Country__c,Contact.Email,Contact.FirstName,Contact.LastName,Status FROM LiveChatTranscript WHERE Id IN : triggerNew]);
        Map<String,Account> mapEmailToAccountId = new Map<String,Account>();
        List<Account> listAccountToInsert = new List<Account>();
        List<LiveChatTranscript> listChatTranscriptToUpdate = new List<LiveChatTranscript>();
        List<Case> listCaseToUpdate = new List<Case>();
        
        for(LiveChatTranscript lct : mapIdToLiveChatTranscript.Values()){
            if(lct.Status != chatOldMap.get(lct.Id).Status && lct.Status == 'Completed' && mapIdToLiveChatTranscript.get(lct.Id).Contact.Email != NULL)  
                setEmails.add(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email);
        }
        
        Id recordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        
        if(setEmails.size() > 0) {
            for(Account acc : [SELECT Id,PersonEmail FROM Account WHERE RecordTypeId = :recordTypeId AND PersonEmail IN :setEmails]) {
                mapEmailToAccountId.put(acc.PersonEmail,acc);    
            }       
        }
  
        for(LiveChatTranscript lct : triggerNew) {
            if(lct.Status != chatOldMap.get(lct.Id).Status && lct.Status == 'Completed' && mapIdToLiveChatTranscript.containsKey(lct.Id) && mapIdToLiveChatTranscript.get(lct.Id).Contact.Email != NULL) {
                if(!mapEmailToAccountId.containsKey(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email)) {
                    Account acc = new Account();
                    acc.recordTypeId = recordTypeId;
                    acc.FirstName = mapIdToLiveChatTranscript.get(lct.Id).Contact.FirstName;
                    acc.lastName = mapIdToLiveChatTranscript.get(lct.Id).Contact.LastName;
                    acc.PersonEmail = mapIdToLiveChatTranscript.get(lct.Id).Contact.Email;
                    mapEmailToAccountId.put(acc.PersonEmail,acc);
                    listAccountToInsert.add(acc);
                }
            }           
        } 
        
        if(listAccountToInsert.size() > 0)
            insert listAccountToInsert;
        
        for(LiveChatTranscript lct : triggerNew) {
            if(lct.Status != chatOldMap.get(lct.Id).Status && lct.Status == 'Completed'){
                LiveChatTranscript lct1 = new LiveChatTranscript();
                lct1.Id = lct.Id;
                lct1.AccountId = mapEmailToAccountId.get(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email).Id;
                listChatTranscriptToUpdate.add(lct1);
                
                Case cas = new Case();
                cas.Id = lct.CaseId;
                cas.AccountId = mapEmailToAccountId.get(mapIdToLiveChatTranscript.get(lct.Id).Contact.Email).Id;
                cas.Country_PI__c = mapIdToLiveChatTranscript.get(lct.Id).Country__c;
                listCaseToUpdate.add(cas);    
            }
        }
        
        if(listChatTranscriptToUpdate.size() > 0)
            update listChatTranscriptToUpdate;
        
        if(listCaseToUpdate.size() > 0)
            update listCaseToUpdate;
    }
}