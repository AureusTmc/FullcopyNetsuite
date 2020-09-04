/*
    Name    :       SagePaymentPushBatchTest
    Date    :       18 JULY 2019    
    author  :       karan singh soni
*/
@isTest
public class SagePaymentPushBatchTest {
    public static testMethod Void invokeSagePaymentPushBatch(){
        Firebase_Settings__c fs = new Firebase_Settings__c();
        fs.Name = 'setting';
        insert fs;
        
        Sage_Intacct_Credentials__c sic = new Sage_Intacct_Credentials__c();
        sic.Name='test';
        sic.Endpoint__c='https://api.intacct.com/ia/xml/xmlgw.phtml';
        insert sic;
        
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
        
        Account cust = TestUtil.createAccount('Customer',TRUE,TRUE);
        
        Invoice__c objInv = TestUtil.createInvoice(cust.id,TRUE);
        objInv.Center__c = Centre.id;
        objInv.SageInvoiceKey__c='xyz';
        objInv.MovedToSage__c=false;
        objInv.Admin_Fees__c=10;
        objInv.Invoice_Date__c = system.today();
        update objInv;
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,Centre.id,'60',true);
        objPack.Type_of_package__c='Promo';
        objPack.Type__c='Individual';
        objPack.Sage_Revenue_Template__c='svt';
        update objPack;
        
        Invoice_Line_Item__c ili = TestUtil.createInvLineItem(objInv.id, TRUE);
        ili.Package__c=objPack.id;
        ili.Amount__c = 120;
        ili.GST_Amount__c=10;
        ili.Discount_Amount__c=5;
        update ili;
        
        Payment__c pay = new Payment__c();
        pay.Invoice__c = objInv.Id;
        pay.Parent_Account__c = cust.id;
        pay.Payment_Status__c ='Success';
        pay.Payment_Amount__c = 105;
        pay.MovedToSage__c = false;
        pay.Payment_Date__c = system.today();
        insert pay;
        
        Payment__c pay1 = new Payment__c();
        pay1.Invoice__c = objInv.Id;
        pay1.Parent_Account__c = cust.id;
        pay1.Payment_Status__c ='Success';
        pay1.Payment_Amount__c = -5;
        pay1.Parent_Payment__c = pay.Id;
        pay1.MovedToSage__c = false;
        pay1.Payment_Date__c = system.today();
        insert pay1;
        
        //database.executeBatch(new SagePaymentPushBatch());
        database.executeBatch(new SagePaymentPushBatch('Payment',new set< String >{pay.Id}));
        database.executeBatch(new SagePaymentPushBatch('Payment',new set< String >{pay1.Id}));
        
        database.executeBatch(new SagePaymentPushBatch( 'Invoice',new set< String >{objInv.Id}));
        
        objInv.MovedToSage__c = true;
        objInv.SageInvoiceKey__c = 'TestKey';
        objInv.Status__c = 'Paid';
        update objInv;
        
        pay.MovedToSage__c=true;
        update pay;
        pay1.MovedToSage__c = true;
        update pay1;
        
        database.executeBatch(new SageApplyARPaymentBatch(new set<string>{objInv.Id}));
        
        SchedulableContext sc;
        SageApplyARPaymentBatch SB = new SageApplyARPaymentBatch();
        sb.execute(sc);
        
        SagePaymentPushBatch sp = new SagePaymentPushBatch();
        sp.execute(sc);
    }
}