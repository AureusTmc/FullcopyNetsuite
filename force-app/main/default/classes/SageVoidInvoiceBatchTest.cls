@isTest
public class SageVoidInvoiceBatchTest {

    @isTest
      public static void test1(){  
        Test.startTest();
        SageCustomerPushBatch obj = new SageCustomerPushBatch();
        ID batchprocessid = Database.executeBatch(obj);
        test.stopTest();
    }
    
     @isTest
    public static void test2(){
        Sage_Intacct_Credentials__c sic = new Sage_Intacct_Credentials__c();
        sic.Name='test';
        sic.Endpoint__c='https://api.intacct.com/ia/xml/xmlgw.phtml';
        insert sic;
        
        Account acc=new Account();
        acc.LastName='XYZ';
        insert acc;
        Invoice__c inv=new Invoice__c();
        inv.Parent_Account__c=acc.id;
        inv.SageInvoiceKey__c='xyz';
        inv.Status__c='Void';
        inv.Invoice_Date__c = system.today();
        inv.Invoice_Void_Date__c = system.today();
        insert inv;
        
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
        
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        
        Package__c objPack=TestUtil.createPackage(objProg.id,Centre.id,'60',true);
        objPack.Type_of_package__c='Normal';
        objPack.Type__c='Individual';
        objPack.Sage_Revenue_Template__c='svt';
        update objPack;
        
        Invoice_Line_Item__c ili = new Invoice_Line_Item__c(); 
        ili.Amount__c = 20;
        ili.Invoice__c = inv.Id;
        ili.Package__c=objPack.id;
        ili.GST_Amount__c=10;
        ili.Discount_Amount__c=5;
        ili.Currency_Code__c = 'SGD';
        insert ili;
        
        set<String> invidSet=new Set<String>();
        invidSet.add(inv.id);
        
        Test.startTest();
        SageVoidInvoiceBatch obj = new SageVoidInvoiceBatch(invidSet);
        
        SageVoidInvoiceBatch obj1 = new SageVoidInvoiceBatch();
        
        SageVoidInvoiceBatch svib = new SageVoidInvoiceBatch();
        svib.execute(null);
        
        test.stopTest();
    } 
}