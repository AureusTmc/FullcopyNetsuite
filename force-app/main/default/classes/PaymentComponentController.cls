/*
*      Name        :    PaymentComponentController
*      Date        :    22 Aug 2020
*      Description :    This Controlleris used to manage Paymen credit and use with paymentComponent.
*/
public class PaymentComponentController {
    
    
    //@Juneid 22 Aug 2020, Method for get the Ccredit amount of Parent
    @AuraEnabled
    public static Decimal getCurrentCredit(String recordId){
        if(String.isNotBlank(recordId)){
            List<Invoice__c> invoiceList = [SELECT Id, Total_Amount__c,Parent_Account__c,Parent_Account__r.Total_Payment_Credit_Available__c, Total_Invoice_Amount__c FROM Invoice__c WHERE Id =:recordId];
            if(!invoiceList.isEmpty())
                return invoiceList[0].Parent_Account__r.Total_Payment_Credit_Available__c;
            
            return null;
        }
        return null;
        
    }    
    //@Juneid 21 Aug 2020, This method is used to manage Payment as credit calculation on invoice
    @AuraEnabled
    public static void createPayment( String selectedMethod, String recordId, String transacId, Boolean isCreditAmnt, Decimal currentCreditAmounts){
        system.debug('method call-->'+selectedMethod+ recordId+transacId);
        if( String.isNotBlank(selectedMethod) && String.isNotBlank(recordId) && String.isNotBlank(transacId)){  
            List<Payment__c> paymentsToUpsert  = new List<Payment__c>();//To update and create paymet of crdit
            //Getting recordtype Id
            String payCredRecId  =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
            String paySuccesRecId  =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment Transaction').getRecordTypeId();
            
            
            //Fetching current invoice Values
            List<Invoice__c> invoiceList = [SELECT Id, Total_Amount__c,Parent_Account__c,Parent_Account__r.Total_Payment_Credit_Available__c, Total_Invoice_Amount__c FROM Invoice__c WHERE Id =:recordId];
            system.debug('invoiceList--->'+invoiceList);
            if(invoiceList.size() > 0 ){
                for(Payment__c pay: [SELECT Id, Name, Parent_Account__c,Invoice__c, Payment_Amount__c, Payment_Status__c FROM Payment__c where  Parent_Account__c =:invoiceList[0].Parent_Account__c AND RecordType.Name = 'Payment As Credit' AND Payment_Status__c = 'Pending' AND Payment_Amount__c > 0 ORDER BY Payment_Amount__c]){
                    system.debug('pay---->'+pay);
                    if(isCreditAmnt){
                        system.debug('in credit amnt -->'+pay);
                        //Checking if Cutomer have full or more than amout of invoice 
                        if(invoiceList[0].Total_Amount__c <=invoiceList[0].Parent_Account__r.Total_Payment_Credit_Available__c){
                            system.debug('in if');
                            pay.Payment_Amount__c = invoiceList[0].Total_Amount__c;
                            pay.Payment_Status__c = 'Success';
                            pay.Method_of_Payment__c = selectedMethod;
                            pay.Payment_Date__c = system.today();
                            pay.Invoice__c = invoiceList[0].Id;
                            pay.Transaction_ID__c = transacId;
                            pay.RecordTypeId =  paySuccesRecId;
                            paymentsToUpsert.add(pay);
                            
                        }else{//If payment is less than invoice than manage payment
                            system.debug('in else');
                            Decimal diffrenceAmount =  invoiceList[0].Total_Amount__c - currentCreditAmounts;
                            //Decimal actualPayCredit = pay.Payment_Amount__c;
                            pay.Payment_Status__c = 'Success';
                            pay.Payment_Amount__c = currentCreditAmounts;
                            pay.Transaction_ID__c = transacId;
                            pay.RecordTypeId =  paySuccesRecId;
                             pay.Invoice__c = invoiceList[0].Id;
                            paymentsToUpsert.add(pay);   
                            
                            //Create new payment credit for remaning amount
                            Payment__c payCrd = new Payment__c();
                             pay.Invoice__c = invoiceList[0].Id;
                            payCrd.RecordTypeId = payCredRecId;
                            payCrd.Payment_Amount__c = diffrenceAmount;
                            payCrd.Payment_Status__c = 'Pending';
                            payCrd.Parent_Account__c = invoiceList[0].Parent_Account__c;
                            paymentsToUpsert.add(payCrd);  
                        }
                    }else{//If customer dont want to pay with credit amount 
                        pay.Payment_Amount__c = invoiceList[0].Total_Amount__c;
                        pay.Payment_Status__c = 'Success';
                        pay.Method_of_Payment__c = selectedMethod;
                        pay.Payment_Date__c = system.today();
                        pay.Invoice__c = invoiceList[0].Id;
                        pay.Transaction_ID__c = transacId;
                        pay.RecordTypeId =  paySuccesRecId;
                        paymentsToUpsert.add(pay);
                    }
                    if(paymentsToUpsert.size() > 0)
                        UPSERT paymentsToUpsert;
                    
                    system.debug('paymentsToUpsert-->'+paymentsToUpsert);
                }
            }
        }
    }
    
}