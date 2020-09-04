/*
        Name        :    CreateMonthlyInvoiceAmcClubBatch
        Date        :    06/29/2019
        Author      :    Rajesh
        Description :    This batch class is used for create consolidated invoice for the American club members
*/
global class CreateMonthlyInvoiceAmcClubBatch implements Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{    
	
	global Invoice__c consolidatedInv;    
    global Set<String> invSet; 
    global CreateMonthlyInvoiceAmcClubBatch(){
    	consolidatedInv = new Invoice__c();
        invSet 		    = new Set<String>();
        
        //Inserting consolidated invoice
        List<Account> amcCluList =  [SELECT Id,Name FROM Account WHERE Name =:constantsClass.amcClubMember  AND Membership_Type__c =: ConstantsClass.amcClubMember LIMIT 1]; 
        if(amcCluList.size() > 0){
            consolidatedInv = BillingUtility.fillInvoice(null, amcCluList.get(0).Id, ConstantsClass.dueStatus);
            consolidatedInv.Due_Date__c = System.today().addDays(14);
            
            List<Account> pianoCentreList =  [SELECT Id,Name FROM Account WHERE Name =: ConstantsClass.centreNameForAmcClubInvoice AND RecordType.Name =: ConstantsClass.centerRecTypeName LIMIT 1]; 
            if(pianoCentreList.size() > 0)
                consolidatedInv.Center__c = pianoCentreList.get(0).Id;
            
            insert consolidatedInv;
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        //Updated by Rajesh, 9th sept, 2019. Change condition Last_Month to This_Month, As per discussion with Ashish 
        return Database.getQueryLocator([Select Id,Name,Parent_Account__c,Parent_Account__r.PersonContactId, 
                                         		(SELECT Id, Invoice__c, Amount__c, GST_Amount__c, Booking__c, Discount_Amount__c, Enrolment__c, Is_Deposit__c,
                                                 Month__c, Package__c, Remarks__c, Subscription_Line_Item__c, Teacher_Id__c, Field_1__c
                                                 FROM Invoice_Line_Items__r)
                                         FROM Invoice__c 
                                         WHERE Parent_Account__r.Stripe_Customer_Id__c = NULL AND Invoice_Date__c = THIS_MONTH
                                         AND Parent_Account__r.Is_Club_Member__c = true AND Parent_Account__r.Membership_Type__c =: ConstantsClass.amcClubMember 
                                         AND Status__c=:ConstantsClass.dueStatus]);
    }

    global void execute(Database.BatchableContext BC, List<Invoice__c> amcInvoices){
        List<Invoice__c> invList  = new List<Invoice__c>();
        List<Invoice_Line_Item__c> insInvLnItms = new List<Invoice_Line_Item__c>();
        if(consolidatedInv.Id != null){
            String remarks = 'American club invoice consolidation process - '+System.now();
            for(Invoice__c inv: amcInvoices){
                invSet.add(inv.Id);
                invList.add(new Invoice__c(Id = inv.Id,  Status__c ='void', Remarks__c = remarks));
                
                for(Invoice_Line_Item__c invLnItm : inv.Invoice_Line_Items__r){
                   // invLnItm.Invoice__c = consolidatedInv.Id;
                    Invoice_Line_Item__c clonedLnItem = invLnItm.clone(false, false, false, false);
                    clonedLnItem.Invoice__c = consolidatedInv.Id;
                    insInvLnItms.add(clonedLnItem);
                }
            }
        }
        
        if(invList.size() > 0)
            update invList;
        
        if(insInvLnItms.size() > 0)
            insert insInvLnItms;
    }

    global void finish(Database.BatchableContext BC){
        if(consolidatedInv.Id!=null){
        	SageIntacctIntegrationUtility.americanClubInvoice(consolidatedInv.Id);
        }
        
        if(invSet.size() > 0){
            Database.executeBatch(new SageVoidInvoiceBatch(invSet),Integer.valueOf(label.SageBatchSize));
        }
        
        List<Invoice__c> invoiceList = [SELECT Id,Name,Total_Amount__c,Parent_Account__c,Parent_Account__r.personContactId, status__c FROM Invoice__c WHERE Id =: consolidatedInv.Id];
        BillingUtility.createInvoiceAttachment(invoiceList);
    }
}