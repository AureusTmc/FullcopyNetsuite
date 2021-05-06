public class LeadTriggerHelper {
	
    //Populate Center on the bases of location Selected
    public static void populateCenter(List<Lead> webLeadList){
        Set<String> locationSet = new Set<String>();
        for(Lead l: webLeadList){
            
            if(String.isBlank(l.Location__c) && String.isNotBlank(l.Preferred_Session__c)){
                String locationStr;
                if(l.Preferred_Session__c.contains('Katong'))
                	locationStr = 'Aureus 112 Katong';
				else if(l.Preferred_Session__c.contains('AMK'))
                	locationStr = 'Aureus AMK Hub';   
                else if(l.Preferred_Session__c.contains('Eastpoint'))
                	locationStr = 'Aureus Eastpoint Mall';  
                else if(l.Preferred_Session__c.contains('Forum'))
                	locationStr = 'Aureus Forum';
				else if(l.Preferred_Session__c.contains('Northpoint'))
                	locationStr = 'Aureus Northpoint';   
                else if(l.Preferred_Session__c.contains('Rochester'))
                	locationStr = 'Aureus Rochester';  
			    else if(l.Preferred_Session__c.contains('Suntec'))
                	locationStr = 'Aureus Suntec';
				else if(l.Preferred_Session__c.contains('Westgate'))
                	locationStr = 'Aureus Westgate';   
                else if(l.Preferred_Session__c.contains('United Square'))
                	locationStr = 'Aureus United Square';  
                else if(l.Preferred_Session__c.contains('Pianos'))
                	locationStr = 'Aureus Pianos';   
                else if(l.Preferred_Session__c.contains('Home'))
                	locationStr = 'Aureus @ Home'; 
                
                if(String.isNotBlank(locationStr))
                	l.Location__c = locationStr;
            }
            
             //Added by Rajesh: 28th June 2019, set location and centre default in Interested case
            if(String.isNotBlank(l.Interested_In__c))
                	l.Location__c  = 'Aureus Pianos'; 
            
            if(String.isNotBlank(l.Location__c))
                locationSet.add(l.Location__c);
        }
        
        if(locationSet.size() > 0){
            Map<String, Id> accLocMap = new Map<String, Id>();
            for(Account acc: [SELECT Id, Name, Location__c FROM Account WHERE Location__c IN: locationSet AND RecordType.Name = 'Centre'])
                accLocMap.put(acc.Location__c, acc.Id);
            
            for(Lead l: webLeadList){
                if(String.isNotBlank(l.Location__c) && accLocMap.containsKey(l.Location__c))
                    l.Center__c = accLocMap.get(l.Location__c);
            }
        }
    }
    
    public static void automateWebLeadProcess(List<Lead> webLeadList,Boolean isCreateSalesEnquiery){//commented by nishi: 6-may-2021:for  we create salesenquiery or instrument rental records (List<Lead> webLeadList){
        Map<String, Id> accEmailMap = new Map<String, Id>();
        
        for(Lead l: webLeadList)
            accEmailMap.put(l.Email.toLowerCase(), null);
        
        if(accEmailMap.size() > 0){
            for(Account acc: [SELECT Id, Name, PersonEmail FROM Account WHERE PersonEmail IN: accEmailMap.keySet()])
                accEmailMap.put(acc.PersonEmail.toLowerCase(), acc.Id);
        	
            List<Account> parAccList = new List<Account>();
            List<Case>   caseAccList = new List<Case>();
                    
            
            String cstmrRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();
            
            //added and commented by nishi: 28-apr-2021:start: according to isCreateSalesEnquiery we create salesenquiery or instrument rental records
            //String salesRecId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
            String caseRecName =isCreateSalesEnquiery ? ConstantsClass.caseSalesEnqRecTypeName  :ConstantsClass.InstrumentRentalEnquiryRecordType; 
            //added and commented by nishi: 28-apr-2021:end: according to isCreateSalesEnquiery we create salesenquiery or instrument rental records
            for(Lead l: webLeadList){
                Account parentAcc = new Account();
                
                if(accEmailMap.get(l.Email.toLowerCase()) != null){
                    parentAcc.Id 		 = accEmailMap.get(l.Email.toLowerCase());
                    parentAcc.Lead__c    = l.Id;
                }else{
                	parentAcc = fillParentAccount(cstmrRecId, l);  
                }
                parAccList.add(parentAcc);
                
                
                Case cs = fillCase(caseRecName, l);
                //added  by nishi: 28-apr-2021:start according to isCreateSalesEnquiery we added stage and type values for instrument rental records
                cs.stage__c = isCreateSalesEnquiery ? ''  :'Piano Rental Enquiry';
                cs.Type = isCreateSalesEnquiery ? ''  :'Instrument Rental Enquiry';
                //added  by nishi: 28-apr-2021:end according to isCreateSalesEnquiery we added stage and type values for instrument rental records
                cs.Account 	 = parentAcc;
                caseAccList.add(cs);
            }
            
            if(parAccList.size() > 0){
                upsert parAccList;
                
                if(caseAccList.size() > 0){
                    for(Case c: caseAccList)
                        c.AccountId = c.Account.Id;
                    
                    
                    Database.DMLOptions dmo = new Database.DMLOptions();
                    dmo.assignmentRuleHeader.useDefaultRule = true;
                    Database.insert(caseAccList, dmo);
                    //insert caseAccList;
            	}
            }
        }
    }
    
    public static Account fillParentAccount(String recId, Lead l){
        // Added LeadSource,UTM_Campaign__pc,Country_PI__pc on 30 sept 2020..By Ravi as per discussion with prashant sir
        Account acc = new Account(RecordTypeId = recId, Lead__c = l.Id, FirstName = l.FirstName, LastName = l.Lastname, PersonEmail = l.Email,
                                  PersonMobilePhone = l.MobilePhone, Phone = l.Phone, Instrument__c = l.Instrument__c, Location__c = l.Location__c,
                                 AccountSource=l.LeadSource,UTM_Campaign__pc=l.UTM_Campaign__c,Country_PI__pc=l.Country_PI__c,Pardot_Source__pc=l.Pardot_Source__c);	 
        
        return acc;
    }
    
    public static Case fillCase(String caseRecName, Lead l){
        String recId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(caseRecName).getRecordTypeId();
        Case cas = new Case(RecordTypeId = recId);
        cas.Subject		  = caseRecName;//commented by nishi: 6-May-2021: As per discussion with rajesh we add subject according to record type 'Sales Enquiry';
        cas.Lead__c   	  = l.Id;
        cas.Centre_Name__c= l.Center__c;
        cas.Location__c   = l.Location__c;
        cas.First_Name__c = l.FirstName;
        cas.Last_Name__c  = l.LastName;
        cas.Email__c	  = l.Email;
        cas.Student_Gender__c = l.Student_Gender__c;
        cas.Mobile__c	  = l.MobilePhone;
        cas.Instrument__c = l.Instrument__c;
        cas.Origin  	  = (l.LeadSource != null && l.LeadSource.equalsIgnoreCase('Facebook')) ? 'Facebook' : 'Web';
        cas.Status  	  = 'New';
        cas.Priority	  = 'High';
        cas.Student_First_Name__c = l.Student_First_Name__c;
        cas.Student_Last_Name__c  = l.Student_Last_Name__c;
        cas.Birthdate__c = l.Birthdate__c;
        
        //Added by Rajesh: 28th June 2019, set case interested field with Lead interested field
        cas.Interested_In__c = l.Interested_In__c;
        //Added by Rajesh: 13th Aug 2020, Set for facebook lead
        cas.Pardot_Source__c = l.Pardot_Source__c;
        cas.UTM_Campaign__c = l.UTM_Campaign__c;
        cas.Country_PI__c=l.Country_PI__c;// added By Ravi on 5th oct 2020 as discussed with prashant sir 
        return cas;
    }
    
   /* public static void processEnrolments(List<Lead> cnvrtdLeadList){
        //try{
            
            
            List<Account> insStuList = new List<Account>();
            List<Opportunity> oppList = new List<Opportunity>();
            
            Id stuRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Student').getRecordTypeId();
            for(Lead l: cnvrtdLeadList){
                if(l.convertedOpportunityId != null && l.Type__c != null){
                    System.debug('@@@@@@@'+l.convertedAccountId);
                    Account accNew = new Account(Parent__c = l.convertedAccountId, RecordTypeId = stuRecordTypeId);
                    accNew.FirstName = l.Student_First_Name__c;
                    accNew.LastName = l.Student_Last_Name__c;       
                    accNew.PersonBirthdate = l.Birthdate__c;
                    accNew.Gender__c      = l.Gender__c;
                    accNew.Nationality__c = l.Nationality__c;
                    accNew.BillingStreet  = l.Street;
                    accNew.BillingCity    = l.City;
                    accNew.BillingCountry = l.Country;
                    accNew.BillingPostalCode = l.PostalCode;
                    accNew.BillingState   = l.State;
                   // accNew.BillingAddress = l.Address;
                    insStuList.add(accNew);
                    
                    Id oppRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(l.Type__c).getRecordTypeId();
                    Opportunity opp =  new Opportunity(Id = l.convertedOpportunityId, RecordTypeId = oppRecTypeId);
                    //opp.Account     =  l.convertedAccount;
                    //opp.Parent__c   =  l.convertedAccountId;
                    opp.Parent_Email__c    =  l.Email;
                   // opp.Name      =  String.isNotBlank(accNew.FirstName) ? accNew.FirstName : ''; 
                   // opp.Name      += accNew.LastName;
                    oppList.add(opp);
                }  
            }
            
            if(insStuList.size() > 0){
                insert insStuList;
               
                update oppList;
                
            }
    }*/
}