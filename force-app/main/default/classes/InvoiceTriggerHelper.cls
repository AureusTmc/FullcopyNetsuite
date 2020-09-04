/*
Name        :    InvoiceTriggerHelper
Date        :    4/02/2019
Description :    Helper Class For Invoice Trigger 
*/
public class InvoiceTriggerHelper{
    
    /*
This method takes the set of Id's of the Invoices
and calculate the Admin fees according to percentage of admin fees of subtraction of discount amount from the grand total.
and update the invoice.
*/
    public static void getAdminFees(Set<String> invoiceSet){
        List<Invoice__c> listOfInvoices = new List<Invoice__c>();
        
        if(invoiceSet.size() > 0){
            List<Invoice__c> invoices = [SELECT Id, Admin_Fees__c, Gross_Total__c, Discount_Amount__c, Parent_Account__c, Parent_Account__r.Admin_Fees__c, Parent_Account__r.Admin_Fees_Required__c FROM Invoice__c WHERE Id IN :invoiceSet];
            Decimal dc = 0;
            if(invoices.size() > 0){
                for(Invoice__c invoiceObj : invoices){
                    dc = 0;
                    if(invoiceObj.Parent_Account__r.Admin_Fees_Required__c && String.isNotBlank(invoiceObj.Parent_Account__r.Admin_Fees__c)){
                        dc = ((invoiceObj.Gross_Total__c - invoiceObj.Discount_Amount__c) * Integer.valueOf(invoiceObj.Parent_Account__r.Admin_Fees__c)) / 100;
                        invoiceObj.Admin_Fees__c = BillingUtility.roundOffAmount(dc);
                        listOfInvoices.add(invoiceObj);
                    }
                }
                if(listOfInvoices.size() > 0){
                    update listOfInvoices;
                }
                
            }
        }
    }
    
    /*
This method takes the set of Id's of the Invoices where the total amount of invoice is less than 0
and create a task for the financial User(Baljit). Because it is a refund case.    
*/
    
    public static void createRefundTask(Set<String> invoiceSet){
        List<Task> taskList = new List<Task>();
        System.debug('invoiceSet'+invoiceSet);
        for(String invoiceId : invoiceSet){
            taskList.add(new Task(WhatId = invoiceId, 
                                  Priority = 'Normal', 
                                  Status = 'Open', 
                                  ActivityDate = System.today(), 
                                  OwnerId = Label.Financial_User));
        }
        
        if(taskList.size() > 0){
            insert taskList;
        }
        
    }
    
    
    //Insert the Invoice With the name = New Invoice Name 
    Public static void fillInvoiceName(List<Invoice__c> invoiceList){
        for(Invoice__c invoiceObj : invoiceList){
            invoiceObj.Name = 'New Invoice Name';
        }
    }
    
    //@Nishi (Date 26-7-2019), This process is used to proces Status invoice Notification.
    public static void procesStatusInvoice(Map<String,String> mapOfStatusInvoice){
        List<MobileNotificationWrapper> notifications = new List<MobileNotificationWrapper>();
        Map<String,String> parentTokens = new Map<String,String>();
        
        for(Account acc: [SELECT id,FCM_Token__c from Account 
                          where Id in: mapOfStatusInvoice.values() 
                          and Invoice_Paid_Notification__c = true AND FCM_Token__c !=null]){
                              parentTokens.put(acc.id,acc.FCM_Token__c );
                          }
        
        for(Invoice__c  invoiceObj : [SELECT id,Name,Parent_Account__c,Card_Type__c FROM Invoice__c  WHERE id in: mapOfStatusInvoice.keyset()]){
            try{
                if(parentTokens.containsKey(invoiceObj.Parent_Account__c)){
                    String to = parentTokens.get(invoiceObj.Parent_Account__c);
                    String title = invoiceObj.Name+' Paid';
                    String bodymsg = 'Please note '+invoiceObj.Name+' has been paid using '+invoiceObj.Card_Type__c+'. Click here to view the payment details.';
                    notifications.add(new MobileNotificationWrapper(invoiceObj.Parent_Account__c, to, title, bodymsg));
                }
            }catch(Exception e){}
        }
        if(notifications.size() > 0 && !System.isBatch() && !System.isFuture()) {
            Database.executeBatch(new SendMobileNotificationBatch(notifications),90);
        }
        
    }
    //@zakir  dated 22-10-2019, it is used to update the fields "Internal ref no SG" "Internal ref no HK" in Invoice Obj and "Ref No" field in Country Onj .
    public static void updateReferenceNo(list<Invoice__c> Invoice){
        List<Invoice__c> updInvList = new List<Invoice__c>();
        Map<Id,Country__c> mapCountryWithId = new Map<Id,Country__c>();
        
        for(Invoice__c inv: [SELECT Id, Name, Center__r.Country__c, Center__r.Country__r.Name, Center__r.Country__r.Ref_No__c 
                             FROM Invoice__c 
                             WHERE Id IN:Invoice AND Center__r.Country__c != null]){
                                 
            Country__c ci = new Country__c(Id = inv.Center__r.Country__c, Ref_No__c = inv.Center__r.Country__r.Ref_No__c);
            if(mapCountryWithId.containsKey(inv.Center__r.Country__c))
                ci = mapCountryWithId.get(inv.Center__r.Country__c);
                                 
            ci.Ref_No__c = ci.Ref_No__c!=null?(ci.Ref_No__c+1):1;
            mapCountryWithId.put(ci.Id, ci);
                                 
            String textNum = '';
            for(Integer i=String.valueOf(ci.Ref_No__c).length(); i < 5 ; i++)                     
                textNum += '0';
            textNum = textNum + ci.Ref_No__c;
                                 
        	if(inv.Center__r.Country__r.Name=='SG')
                textNum = 'SG-'+textNum;
            else if(inv.Center__r.Country__r.Name=='HK')
                textNum = 'HK-'+textNum;
            
            inv.Internal_Ref_No__c= textNum;
            updInvList.add(inv);                     
        }
            
        if(updInvList.size() > 0)
            update updInvList;
        
        if(mapCountryWithId.size() > 0) 
             update mapCountryWithId.values();
        /*set<id> centerIds = new set<id>(); 
        set<id> countryIds = new set<id>();
        List<Country__c> countryList = new List<Country__c>();
        
        for(Invoice__c inc : Invoice ){
            if(inc.Center__c!=null)
                centerIds.add(inc.Center__c);
        }
        System.debug('====centerIds===>>>'+centerIds);
        map<id,id> mapacctocountry = new map<id,id>();
        for(Account acnt : [Select id, Country__c from Account where Id in:centerIds]){
            if(acnt.Country__c!=null)
                mapacctocountry.put(acnt.id,acnt.Country__c);
            countryIds.add(acnt.Country__c);
        }
        map<id,Country__c> mapCountryWithId = new map<id,Country__c>([select id,Name, Ref_No__c from Country__c where id In: countryIds]);
        
        System.debug('====countryIds===>>>'+countryIds);
       List<Invoice__c> listInvoiceUpdate = new List<Invoice__c>();
        for(Invoice__c inv : Invoice){
            if(mapacctocountry.containskey(inv.Center__c)){
                Country__c ci = mapCountryWithId.get(mapacctocountry.get(inv.Center__c));
                ci.Ref_No__c = ci.Ref_No__c!=null?(ci.Ref_No__c+1):1;
                
                mapCountryWithId.put(mapacctocountry.get(inv.Center__c),ci);
                if(ci.Name=='HK'){
                    Invoice__c invv = new Invoice__c();
                    invv.Id = inv.Id;
                    invv.Internal_Ref_No_HK__c = ci.Ref_No__c;
                    listInvoiceUpdate.add(invv);
                }
                else if(ci.Name=='SG'){
                    Invoice__c invv = new Invoice__c();
                    invv.Id = inv.Id;
                    invv.Internal_Ref_No_SG__c = ci.Ref_No__c;
                    listInvoiceUpdate.add(invv);
                }
            }
        }
        if(listInvoiceUpdate.size() > 0) update listInvoiceUpdate ;
        
        if(mapCountryWithId.size() > 0) update mapCountryWithId.values();
        */
    }
}