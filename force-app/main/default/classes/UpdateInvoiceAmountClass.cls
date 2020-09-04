public class UpdateInvoiceAmountClass {
	
    public static void sumInvoiceLineAmount(List<Invoice_Line_Item__c> invList){
        // This trigger is updating the total Deposit Value on enrolment with the sum of amount on Invoice line item when isdeposit is true and status not = to (void,Cancelled)
        List<Enrolment__c> enrolList = new List<Enrolment__c>();
        set<Id> enrolId = new set<Id>();
        for(Invoice_Line_Item__c invObj:[select Id,Is_Deposit__c,Invoice__r.Status__c,Name,Invoice__c,Enrolment__c from Invoice_Line_Item__c where id in:invList]){
            if(invObj.Enrolment__c != null){
               enrolId.add(invObj.Enrolment__c); 
            }
        }
        system.debug('enrolId'+enrolId);
        List<Enrolment__c> enrolMentList = [Select Id,Total_Deposit_Value__c,(select Amount__c from Invoice_Line_Items__r where  (Invoice__r.Status__c !='Void' and Invoice__r.Status__c !='Cancelled') AND Is_Deposit__c =true) from Enrolment__c where Id in:enrolId];
        if(enrolMentList.size()>0){
            for(Enrolment__c enrObj:enrolMentList){
                system.debug('enrObj'+enrObj);
                decimal val =0;
                for(Invoice_Line_Item__c InvLineObj:enrObj.Invoice_Line_Items__r){
                    val += InvLineObj.Amount__c == null ? 0 :InvLineObj.Amount__c;
                }
                enrObj.Total_Deposit_Value__c=val;
                enrolList.add(enrObj);
            }
        }
        system.debug('enrolList'+enrolList);
        if(enrolList.size()>0){
            Update enrolList;
        }
        
        
    }
    
    public static void deleteInvoiceLineAmount(list<Invoice_Line_Item__c> invList){
          // This trigger is reducing  the total Deposit Value on enrolment with the  amount on Invoice line item when isdeposit is true and status not = to (void,Cancelled)
        List<Enrolment__c> enrolList = new List<Enrolment__c>();
        
        set<Id> enrolId = new set<Id>();
        for(Invoice_Line_Item__c inlineObj:invList){
            if(inlineObj.Enrolment__c != null){
                enrolId.add(inlineObj.Enrolment__c);
            }
        }
        system.debug('enrolIddelete'+enrolId);
        List<Enrolment__c> enrolMentList = [Select Id,Total_Deposit_Value__c,(select Amount__c from Invoice_Line_Items__r where  (Invoice__r.Status__c !='Void' and Invoice__r.Status__c !='Cancelled') AND Is_Deposit__c =true) from Enrolment__c where Id in:enrolId];
        if(enrolMentList.size()>0){
            for(Enrolment__c enrObj:enrolMentList){
                decimal val =0;
                for(Invoice_Line_Item__c InvLineObj:enrObj.Invoice_Line_Items__r){
                    val += InvLineObj.Amount__c == null ? 0 :InvLineObj.Amount__c;
                    //val += InvLineObj.Amount__c == null ? 0 :InvLineObj.Amount__c;
                   // enrObj.Total_Deposit_Value__c -=invList[0].Amount__c== null? 0 : invList[0].Amount__c;
                }
                enrObj.Total_Deposit_Value__c=val;
                enrolList.add(enrObj);
            }
        }
        system.debug('enrolListdelete'+enrolList);
        if(enrolList.size()>0){
            Update enrolList;
        }
    }
}