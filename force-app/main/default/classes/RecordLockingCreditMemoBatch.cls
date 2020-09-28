/*
        Name        :    RecordLockingCreditMemoBatch
        Date        :    24-Sep-2020
        Author      :   nishi jain
        Description :    This batch class is used to all success credit memo  records as locked that belongs to the previous calendar month  and its line items
        
*/
global class RecordLockingCreditMemoBatch  implements Database.Batchable<sObject>,database.stateful{
    global Date startDate;
    global Date endDate;
    global integer noOfRecords;
    
    public RecordLockingCreditMemoBatch(Date startDate,date endDate){
        noOfRecords  = 0;
        this.endDate = endDate;
        this.startDate = startDate;
    } 
    global Database.QueryLocator start(Database.BatchableContext BC){
        Set<string> creditmemoStatus = new Set<String>{'Customer No Response',ConstantsClass.creditMemoSuccessStatus};
    
        return Database.getQueryLocator([SELECT Id, Name,Locked__c,
                                         (SELECT Id, Locked__c
                                          FROM Credit_memo_line_items__r
                                          Where Locked__c = false
                                          //   Month__c >=: startDate 
                                          // AND Month__c <=: endDate
                                         ) 
                                         FROM Credit_Memo__c 
                                         WHERE Credit_Memo_Date__c >=: startDate 
                                         AND Credit_Memo_Date__c <=: endDate 
                                         and Locked__c = false
                                         AND Status__c In:creditmemoStatus]);
    }
    
    global void execute(Database.BatchableContext BC, List<Credit_Memo__c> creditMemoList){
        noOfRecords += creditMemoList.size();
        List<Credit_memo_line_item__c> listOfCreditmemolineitem = new  List<Credit_memo_line_item__c>();
        if(creditMemoList != null && creditMemoList.size()  > 0){
            for(Credit_Memo__c objCreditMemo  : creditMemoList){
                objCreditMemo.Locked__c = true;
                if(objCreditMemo.Credit_memo_line_items__r != null && objCreditMemo.Credit_memo_line_items__r.size() >0){
                    for(Credit_memo_line_item__c objCreditmemolineitem :  objCreditMemo.Credit_memo_line_items__r){
                        objCreditmemolineitem.Locked__c = true;
                        listOfCreditmemolineitem.add(objCreditmemolineitem);
                    }
                } 
            }
            update creditMemoList;
            if(listOfCreditmemolineitem != null && listOfCreditmemolineitem.size() > 0){
                update listOfCreditmemolineitem;
            }
        }
    }

    global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Credit Memo Record Locking Batch',system.now(),system.now(),noOfRecords);
    }
    
}