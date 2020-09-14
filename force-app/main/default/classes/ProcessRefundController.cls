/*
  Name    :   ProcessRefundController
  Date    :   06/18/2019
  Author    :  Arpit vijayvergiya
  Description :  This controller is used for initiate refund with stripe
*/
public class ProcessRefundController {
  @AuraEnabled
    public static void initRefund(String recId){
        Boolean isSuccess = FALSE;
        string stripe_Base_Url,stripe_Secret_Key;
        Payment__c objPay = [SELECT Id,Payment_Amount__c,Transaction_Id__c,Payment_Status__c,Parent_Account__r.Country_PI__pc,Refund_Id__c,
                             Parent_Account__r.Centre_Name__r.Country__r.Stripe_Base_Url__c, Parent_Account__r.Centre_Name__r.Country__r.Id, 
                             Parent_Account__r.Centre_Name__r.Country__r.Stripe_Secret_Key__c, Invoice__c ,
                             //commented by @nishi 10 sep 2020,Organisation wise charge as per new logic
                             Parent_Account__r.Centre_Name__r.Organisation__r.name,Payment_Date__c,
                             Parent_Account__r.Centre_Name__r.Organisation__r.Stripe_Base_Url__c, Parent_Account__r.Centre_Name__r.Organisation__r.Stripe_Secret_Key__c
                             FROM Payment__c 
                             WHERE Id=:recId LIMIT 1];
        
        /*if(String.isNotBlank(objPay.Parent_Account__r.Centre_Name__r.Country__r.Id) && String.isNotBlank(objPay.Parent_Account__r.Centre_Name__r.Country__r.Stripe_Base_Url__c) && 
           String.isNotBlank(objPay.Parent_Account__r.Centre_Name__r.Country__r.Stripe_Secret_Key__c)){
             stripe_Base_Url = objPay.Parent_Account__r.Centre_Name__r.Country__r.Stripe_Base_Url__c;
             stripe_Secret_Key = objPay.Parent_Account__r.Centre_Name__r.Country__r.Stripe_Secret_Key__c;
            isSuccess = TRUE;
        }*/
         //system.debug('@@@objPay.Parent_Account__r.Country_PI__pc'+objPay.Parent_Account__r.Country_PI__pc);
        /* start:commented by @nishi 10 sep 2020,Organisation wise charge as per new logic
        if(string.isNotBlank(objPay.Parent_Account__r.Country_PI__pc)){
           List<Country__c> listOfCountry = [SELECT Country_Name__c, Currency_Code__c, Stripe_Base_Url__c, Stripe_Publishable_Key__c, Stripe_Secret_Key__c, Tax_Rate__c, 
                                    Student_Policies_Template_Id__c, Folder__c, Currency_Code_PI__c, Ref_No__c, Id, Name 
                                    FROM Country__c 
                                    Where Country_Name__c =:objPay.Parent_Account__r.Country_PI__pc];
                                    system.debug('@@@listOfCountry =='+listOfCountry);
          if(listOfCountry != null && listOfCountry.size() >0){
            if(string.isNotBlank( listOfCountry[0].Stripe_Base_Url__c) && string.isNotBlank( listOfCountry[0].Stripe_Secret_Key__c) ){
              stripe_Base_Url  = listOfCountry[0].Stripe_Base_Url__c;
              stripe_Secret_Key = listOfCountry[0].Stripe_Secret_Key__c;
              isSuccess = TRUE;
            }
          }
        } */

        if(string.isNotBlank(objPay.Parent_Account__c) && string.isNotBlank(objPay.Parent_Account__r.Centre_Name__c) && string.isNotBlank(objPay.Parent_Account__r.Centre_Name__r.Organisation__c)
        && string.isNotBlank(objPay.Parent_Account__r.Centre_Name__r.Organisation__c)){
            if(string.isNotBlank( objPay.Parent_Account__r.Centre_Name__r.Organisation__r.Stripe_Base_Url__c) && string.isNotBlank(  objPay.Parent_Account__r.Centre_Name__r.Organisation__r.Stripe_Secret_Key__c) ){
                stripe_Base_Url  =  objPay.Parent_Account__r.Centre_Name__r.Organisation__r.Stripe_Base_Url__c;
                stripe_Secret_Key =  objPay.Parent_Account__r.Centre_Name__r.Organisation__r.Stripe_Secret_Key__c;
                isSuccess = TRUE;
            }
        }
        //end:commented by @nishi 10 sep 2020,Organisation wise charge as per new logic
        system.debug('@@@stripe_Base_Url'+stripe_Base_Url);
        system.debug('@@@stripe_Secret_Key'+stripe_Secret_Key);
        if(objPay.Payment_Amount__c <= 0 && String.isNotBlank(objPay.Transaction_Id__c) && isSuccess){
          BillingUtility.StripeRefund  refundObj = BillingUtility.createRefundForCharge(objPay.Transaction_Id__c,
                                                                  (-1*BillingUtility.roundOffAmount(objPay.Payment_Amount__c)),
                                                                  stripe_Base_Url, 
                                                                  stripe_Secret_Key
                                                                );
            System.debug('@@@@refundObj'+refundObj);
            if(refundObj.statusCode == 200 && refundObj.status == 'succeeded'){
              objPay.Refund_Id__c = refundObj.id;
              //added by nishi: 10-Sep-2020:Payment date for Pending payments should be updated to the date of application in the subsequent invoice. Same should also be changed at the time of Refunds
              objPay.Payment_Date__c = System.today();
              objPay.Payment_Status__c = ConstantsClass.paymentSuccessStatus;
              update objPay;
              system.debug('@@@objPay'+objPay);
             SageIntacctIntegrationUtility.refundPayment(objPay.id);	 
             if(String.isNotBlank(objPay.Invoice__c)){
              	Invoice__c invoice = new Invoice__c(Id=objPay.Invoice__c);
                invoice.Status__c = ConstantsClass.dueStatus;
                update invoice;
                system.debug('@@@invoice'+invoice);
              }
            }else{
                throw new AuraHandledException('Refund Failed');
            }
        }else{
            throw new AuraHandledException('Refund Failed');
        }
        
      
    }
}