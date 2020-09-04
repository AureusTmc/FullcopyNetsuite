global class TempUpdateGstAmtInLnitmRecords implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext bc){ 
        //
        String query = 'SELECT id,name,invoice_date__c,Amount__c,Discount_Amount__c,Is_Deposit__c,Field_1__c'+ 
                                     ' FROM invoice_Line_item__c '+
                                     ' WHERE invoice__r.Center__r.Country__r.name = \'SG\' '+
                                     ' AND Is_Deposit__c = False AND Amount__c != null '+
                                     ' AND invoice_date__c >= 2019-07-01 order by Id';
        return Database.getQueryLocator(query); 
    }
    global void execute (Database.BatchableContext bc ,List<invoice_Line_item__c> invList){
        Decimal tempGstPrcntg = 7;
        for(invoice_Line_item__c invLnItm: invList){
            Decimal tempTotAmt = invLnItm.Amount__c; 
            tempTotAmt = invLnItm.Discount_Amount__c > 0 ? (tempTotAmt-invLnItm.Discount_Amount__c): tempTotAmt; 
            invLnItm.GST_Amount__c = BillingUtility.roundOffAmount(tempTotAmt != 0 ? ((tempTotAmt * tempGstPrcntg) / 100):0);
            invLnItm.Field_1__c = invLnItm.Field_1__c +'-- updated Gst Amount on '+System.today()+'.';
        }
        
        update invList;
    }
    global void finish(Database.BatchableContext bc){
        System.debug('----Finish');
    }
}