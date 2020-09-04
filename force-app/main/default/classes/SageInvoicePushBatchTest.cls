/*
    Name    :       SageInvoicePushBatchTest
    Date    :       18 JULY 2019    
    author  :       karan singh soni
*/
@isTest
public class SageInvoicePushBatchTest {

    public static testMethod void invokeSageInvoicePushBatch(){
        Sage_Intacct_Credentials__c sic = new Sage_Intacct_Credentials__c();
        sic.Name='test';
        sic.Endpoint__c='https://api.intacct.com/ia/xml/xmlgw.phtml';
        insert sic;
        
        Account acc2= new Account();
        acc2.LastName='PQR';
        insert acc2;
        
        Country__c country = new Country__c();
        country.Name = 'IN';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'INR';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        country.Currency_Code_PI__c='SGD';
        insert country;
        
        Organisation__c org = new Organisation__c();
        org.Country__c = country.id;
        insert org;
        
        Account Centre = TestUtil.createAccount('Centre',TRUE,TRUE);
        Centre.Country__c=country.id;
        centre.Organisation__c=org.id;
        update Centre;
        
        Invoice__c objInv = TestUtil.createInvoice(acc2.id,TRUE);
        objInv.Center__c = Centre.id;
        objInv.MovedToSage__c=false;
        objInv.Admin_Fees__c=10;
        update objInv;
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,Centre.id,'60',true);
        objPack.Type_of_package__c='Promo';
        objPack.Type__c='Individual';
        objPack.Sage_Revenue_Template__c='svt';
        update objPack;
        
        Invoice_Line_Item__c ili = TestUtil.createInvLineItem(objInv.id, TRUE);
        ili.Package__c=objPack.id;
        ili.GST_Amount__c=10;
        ili.Discount_Amount__c=5;
        update ili;
        
        database.executeBatch(new SageInvoicePushBatch (new set<String>{'asdas'}));
        database.executeBatch(new SageInvoicePushBatch ());
    }
}