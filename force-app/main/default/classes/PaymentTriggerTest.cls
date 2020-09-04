/*
Name        :        PaymentTriggerTest
Date        :        24 June 2019
Author      :        Karan Singh Soni
Description :        It is the test class for PaymentTrigger and handler.
*/
@isTest
public class PaymentTriggerTest {
    public static testMethod void invokePaymentTrigger(){
        Payment__c objpay = TestUtil.createPayment(testUtil.createAccount('Customer', true, true).Id, False);
        objPay.RecordTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsDepositRecordType).getRecordTypeId();
        objPay.Invoice__c = TestUtil.createInvoice(objpay.Parent_Account__c, True).Id;
        insert objPay;
        update objPay;
        delete objPay;
    }
    // @jatin  10/29/2019, cover the work due to stripe payout log 
    public static testMethod void invokePaymentTrigger_RollUpStripePayoutFees(){
        String paymentTransactionRcTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByDeveloperName().get('Payment_Transaction').getRecordTypeId();
        String refundPaymentRcTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByDeveloperName().get('Refund').getRecordTypeId();
        
        Account acc = TestUtil.createAccount('Customer',TRUE,FALSE);
        insert acc;
        
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
        Organisation__c org = new Organisation__c(
            Name = 'Test Org',
            Bank_Account_Number__c = '123456789',
            Bank_Name__c = 'Test Bank Name',
            Branch_Code__c = '001',
            Country__c = country.Id
        );
        insert org;
        
        Stripe_Payout_Log__c payoutObj = new Stripe_Payout_Log__c(Organisation__c = org.Id);
        insert payoutObj;
        
        List<Payment__c> paymentList = new List<Payment__c>();
        
        //add payment records
        paymentList.add(new Payment__c(RecordTypeId = paymentTransactionRcTypeId, Parent_Account__c = acc.Id, Transaction_ID__c = 'po_1F7B21Jja9IPifcSMtoJfYU9'));
        paymentList.add(new Payment__c(RecordTypeId = refundPaymentRcTypeId, Parent_Account__c = acc.Id, Transaction_ID__c = 'po_1F7B21Jja9IPifcSMtoJfYU8'));
        
        insert paymentList;
        paymentList[0].Stripe_fees__c =0;
        paymentList[0].Stripe_Payout_Id__c = payoutObj.Id;
        update paymentList;
        
    }
}