/*
  Name	:	AccountTriggerHelper
  Author:  Rajesh
  Date	 : 20th July 2019
  Description : This triggerHelper is used to create case when person account sync with Pardot 
 */
public class AccountTriggerHelper {
	
    public static void createCaseForPIsyncAccounts(List<Account> filtrAccList){
        List<Case>   caseAccList  = new List<Case>();
        List<Account> updAccList  = new List<Account>();
        Map<String, Id> accLocMap = new Map<String, Id>();
        //Added by Rajesh on 30th Oct 2019, Add code as per discussion with Prashant. To solve duplicate insertion case(sales enquiry) record
        Map<Id, Case> accCaseMap  = new Map<Id, Case>();
        List<Case>   caseUpdateList = new List<Case>();
        
        for(Account acc: filtrAccList){
            accLocMap.put(acc.Location_PI__pc, null);
            //Added by Rajesh on 30th Oct 2019, Add code as per discussion with Prashant. To solve duplicate insertion case(sales enquiry) record
            accCaseMap.put(acc.Id, null); 
        }
        
        if(accLocMap.size() > 0){
        	for(Account acc: [SELECT Id, Name, Location__c FROM Account WHERE Location__c IN: accLocMap.keySet() AND RecordType.Name = 'Centre'])
        		accLocMap.put(acc.Location__c, acc.Id);
        }    
        
        String salesRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        //Added by Rajesh on 30th Oct 2019, Add code as per discussion with Prashant. To solve duplicate insertion case(sales enquiry) record
        for(Case c : [SELECT Id, Status, AccountId FROM Case 
                      WHERE AccountId IN: accCaseMap.keySet() AND Status !=: ConstantsClass.ClosedStatus AND CreatedDate = Today AND
                      RecordType.Name =: ConstantsClass.caseSalesEnqRecTypeName AND CreatedBy.Name Like '%Aureusacademy Site Guest User%' ORDER BY CreatedDate DESC]){
            if(accCaseMap.get(c.AccountId) == null)
                accCaseMap.put(c.AccountId, c);          
        }
        
        for(Account ac: filtrAccList){
            updAccList.add(new Account(Id = ac.Id, PI_to_SF_Sync__pc = 'False',PI_Data_Sync__pc='False'));
            if(accCaseMap.get(ac.Id) != null){
            	Case cs 	= accCaseMap.get(ac.Id);
                cs.Form_Name__c  = ac.Form_Name_PI__pc;
                //Added by Rajesh on 5th Aug 2020. As per discussion with Prashant and Gandi
                cs.UTM_Campaign__c  = ac.UTM_Campaign__pc;
                cs.UTM_Content__c   = ac.UTM_Content__pc;
                cs.UTM_Medium__c    = ac.UTM_Medium__pc;
                cs.UTM_Source__c    = ac.UTM_Source__pc;
                cs.UTM_Term__c      = ac.UTM_Term__pc;       
                cs.Pardot_Source__c = ac.Pardot_Source__pc;
                cs.UTM_Adgroup__c	= ac.UTM_Adgroup__pc;
                caseUpdateList.add(cs);
            }else{
                Case cs 	= fillCase(salesRecId, ac);
            	if(String.isNotBlank(ac.Location_PI__pc) && accLocMap.containsKey(ac.Location_PI__pc))
                	cs.Centre_Name__c = accLocMap.get(ac.Location_PI__pc);
            
                caseAccList.add(cs);
            }
        }
        
        if(caseAccList.size() > 0){
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            Database.insert(caseAccList, dmo);
        }
        //Added by Rajesh on 30th Oct 2019, Add code as per discussion with Prashant. To solve duplicate insertion case(sales enquiry) record
        if(caseUpdateList.size() > 0)
            update caseUpdateList;
        
        if(updAccList.size() > 0)
            update updAccList;
    }
    
    public static Case fillCase(String recId, Account ac){
        Case cas = new Case(RecordTypeId = recId);
        cas.AccountId 	 = ac.Id;
        cas.Subject		  = 'Sales Enquiry';
        cas.Origin  	  = 'Web';
        cas.Status  	  = 'New';
        cas.Priority	  = 'High';
        cas.Location__c   = ac.Location_PI__pc;
		cas.Country_PI__c = ac.Country_PI__pc;
		cas.Form_Name__c  = ac.Form_Name_PI__pc;
        cas.Instrument__c = ac.Instrument_PI__pc;
        cas.Description   = ac.Description_PI__pc;
        //Added by Rajesh on 1st July 2020. As per discussion with Gandi and Anuj 
        cas.UTM_Campaign__c = ac.UTM_Campaign__pc;
		cas.UTM_Content__c  = ac.UTM_Content__pc;
        cas.UTM_Medium__c = ac.UTM_Medium__pc;
        cas.UTM_Source__c = ac.UTM_Source__pc;
        cas.UTM_Term__c   = ac.UTM_Term__pc;        
         //Added by Rajesh on 20th July 2020. As per discussion with Prashant and Gandi
        cas.Pardot_Source__c = ac.Pardot_Source__pc;
        cas.UTM_Adgroup__c= ac.UTM_Adgroup__pc;
        return cas;
    }
    //@Juneid 12 Aug 2020, Updating Contacts with referal code
    public static void contactRefrelCodeUpdate (List<Account> accontsContaintRferal){
        List<Contact> contactToUpdate = new List<Contact>();
        for(Account accObj : accontsContaintRferal){
            Contact refConObj = new Contact(Id = accObj.PersonContactId, Unique_Referral_Code__c = accObj.Unique_Referral_Code__c);
            contactToUpdate.add(refConObj);
        }
        if(!contactToUpdate.isEmpty())
            UPDATE contactToUpdate;
    }
}