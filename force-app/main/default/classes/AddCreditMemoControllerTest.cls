/*
Name        :        AddCreditMemoControllerTest
Date        :        28 Sep 2020
Author      :        Karan Singh Soni
Apex Class :        AddCreditMemoController
*/
@isTest
public class AddCreditMemoControllerTest {
    
    //_________________________________________________________________  Test Setup ___________________________________________________________________
    @testSetup
    public static void createTestData(){  
        Country__c country = new Country__c(); 
        country.Name = 'IN';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD'; 
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com'; 
        country.Stripe_Publishable_Key__c = 'ABC'; 
        country.Stripe_Secret_Key__c = 'deede'; 
        insert country;
        
        Organisation__c org = new Organisation__c();
        org.Name = 'Aureus Academy Singapore';
        org.Sage_Company__c = 'AGP';
        org.Bank_Account_Number__c = 'er45678i';
        org.Bank_Name__c = 'test bank';
        org.Branch_Code__c = '56789';
        org.UEN__c = 'test';
        org.CPF_Advice_Code__c = 'test code';
        org.CPF_Payment_Type__c = 'test';
        org.Country__c = country.id;
        org.Stripe_Base_Url__c = 'sdsd';
        org.Stripe_Secret_Key__c = 'sdsd';
        insert org;
        
        Account objCentr=TestUtil.createAccount('Centre',False,FALSE);
        objCentr.Country__c = country.Id;
        objCentr.Organisation__c = org.id;
        INSERT objCentr;
        
        Account objCustmr = testUtil.createAccount('Customer',true,False); 
        objcustmr.Admin_Fees_Required__c=true;
        objcustmr.Admin_Fees__c='3';
        insert objcustmr;
        
        Invoice__c objinvoice = testUtility.createInvoice(objcustmr.id, false);
        objInvoice.Center__c = objCentr.Id;
        objInvoice.Parent_Account__c=objcustmr.id;
        insert objInvoice;
        
        Invoice_Line_Item__c objInvLneItm=TestUtil.createInvLineItem(objinvoice.id,True);
        objInvLneItm.Amount__c=30;
        objInvLneItm.GST_Amount__c = 2;
        update objInvLneItm;
        
         Payment__c objPay = TestUtil.createPayment(objCustmr.Id, FALSE);
        objPay.Payment_Status__c = 'Pending';
        objPay.Payment_Amount__c = 1000;
        objPay.Payment_Date__c= date.today();
        objPay.Invoice__c = objinvoice.id;
        objPay.Transaction_ID__c = 'sfsd';
        INSERT objPay;
    }
    
    public static testMethod void testCreditMemoCreation(){
        
        List<Invoice__c> listInvoice = [ SELECT Id  FROM Invoice__c LIMIT 1];
        if( listInvoice.size() == 0 ){
            return;
        }
        AddCreditMemoController.getCreditMemoDetails( listInvoice[0].Id );
        
        Credit_Memo__c objCreditMem = new Credit_Memo__c( From_Invoice__c = listInvoice[0].Id );
        insert objCreditMem;
        
        AddCreditMemoController.creditMemoWrap creditMemo = AddCreditMemoController.getCreditMemoDetails( listInvoice[0].Id );
        AddCreditMemoController.getCreditMemoDetails( objCreditMem.Id );
        
        AddCreditMemoController.createCreditMemo( JSON.serialize( creditMemo, true), 'Credit Memo (Future Adj)', 'Testing Remarks' );
        AddCreditMemoController.createCreditMemo( JSON.serialize( creditMemo, true), 'Credit Memo (Invoice Cancellation)', 'Testing Remarks' );
        AddCreditMemoController.createCreditMemo( JSON.serialize( creditMemo, true), 'Refund Memo', 'Testing Remarks' );
        
        //for covering the exception part 
         AddCreditMemoController.createCreditMemo( 'JSON.serialize( creditMemo, true)', 'Refund Memo', 'Testing Remarks' );
    }
}