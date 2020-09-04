// @Ravi ....trigger actually update total deposit on enrolment of invoice line item amount  when there is changes in status  of invoice
public class UpdateEnrolmentDepositClass {

    public static void updateDeposit(List<Invoice__c> invList){
        List<Enrolment__c> enrolList = new List<Enrolment__c>();
        set<Id> idsenrol = new set<Id>();
        /* for(Invoice__c invLine:invList){
            if(invLine.Id != null){
                ids.add(invLine.Id);
            }
        }*/
        for(Invoice__c invListing :[select Id,(select Id,Enrolment__c from Invoice_Line_Items__r) from Invoice__c where Id in:invList]){
            for(Invoice_Line_Item__c invLine:invListing.Invoice_Line_Items__r){
                if(invLine.Enrolment__c != null){
                    idsenrol.add(invLine.Enrolment__c);
                }
            }
        } 
        system.debug('idsenrol'+idsenrol);
        List<Enrolment__c> enrolMentList = [Select Id,Total_Deposit_Value__c,(select Amount__c from Invoice_Line_Items__r where  (Invoice__r.Status__c !='Void' and Invoice__r.Status__c !='Cancelled') AND Is_Deposit__c =true) from Enrolment__c where Id in:idsenrol];
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
}