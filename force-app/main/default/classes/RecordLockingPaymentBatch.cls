/*
        Name        :    RecordLockingPaymentBatch
        Date        :    24-Sep-2020
        Author      :   nishi jain
        Description :    This batch class is used to all sucesse payment records as locked that belongs to the previous calendar month 
        
*/
global class RecordLockingPaymentBatch  implements Database.Batchable<sObject>,database.stateful{
    global Date startDate;
    global Date endDate;
    global integer noOfRecords;
    
    public RecordLockingPaymentBatch(Date startDate,date endDate){
        noOfRecords  = 0;
        this.endDate = endDate;
        this.startDate = startDate;
    } 
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator([SELECT Id, Name,Locked__c
                                            FROM Payment__c 
                                            WHERE Payment_Date__c >=: startDate 
                                            AND Payment_Date__c <=: endDate 
                                            AND Payment_Status__c =: ConstantsClass.successStatus
                                        	AND Locked__c = false ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Payment__c> paymentList){
        noOfRecords += paymentList.size();
        system.debug('paymentList'+paymentList);
        if(paymentList != null && paymentList.size()  > 0){
            for(Payment__c objPayment : paymentList){
                objPayment.Locked__c = true;
            }
            update paymentList;
        }
    }

    global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Payment Record Locking Batch',system.now(),system.now(),noOfRecords);
         Database.executeBatch(new RecordLockingInvoiceBatch(startDate,endDate),99);
    }
    
}