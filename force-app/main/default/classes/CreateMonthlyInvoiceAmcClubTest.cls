@isTest
public class CreateMonthlyInvoiceAmcClubTest {   
    @isTest
    public static void Test(){
        Country__c cntry = new Country__c();
        cntry.Name = 'SG';
        cntry.Country_Name__c ='Singapore';
        cntry.Currency_Code__c ='SGD';
        cntry.Tax_Rate__c = 7;
        cntry.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
        cntry.Stripe_Base_Url__c ='https://api.stripe.com';
        cntry.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
        cntry.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
        insert cntry;
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Name = ConstantsClass.centreNameForAmcClubInvoice;
        objCentr.Country__c = cntry.Id;
        Insert objCentr;
        
        Account obj1=new Account();
        obj1.LastName='American club';
        obj1.Membership_Type__c=ConstantsClass.amcClubMember;
        insert obj1;
       
        Account objAcc=new Account();
        objAcc.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        objAcc.Membership_Type__c=ConstantsClass.amcClubMember;
        objAcc.LastName='test cstmr';
        objAcc.Stripe_Customer_Id__c=NULL;
        objAcc.American_club__c=obj1.id;
        objAcc.Membership_Number__c= '90';
        insert objAcc;
        
        Invoice__c objInv=new Invoice__c();
        objInv.Parent_Account__c=objAcc.id;
        objInv.Status__c=ConstantsClass.dueStatus;
        objInv.Invoice_Date__c=Date.today();
        objInv.Due_Date__c=Date.today();
        insert objInv; 
        
        Invoice_Line_Item__c invObj=new Invoice_Line_Item__c();
        invObj.Invoice__c=objInv.id;
        invObj.Currency_Code__c='SGD';
        insert invObj;
        
        CreateMonthlyInvoiceAmcClubSchedular objCm =new CreateMonthlyInvoiceAmcClubSchedular();
        objCm.execute(null);
    }
}