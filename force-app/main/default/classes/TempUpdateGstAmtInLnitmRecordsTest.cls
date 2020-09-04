//temprary test class for the TempUpdateGstAmtInLnitmRecords controller, after work done we will delete controller or test class both
@isTest
public class TempUpdateGstAmtInLnitmRecordsTest {
    
    public static testMethod void testMethod1(){
		Country__c country = new Country__c(); 
        country.Name = 'SG'; 
        country.Country_Name__c = 'Singapore'; 
        country.Tax_Rate__c = 7.0; 
        country.Currency_Code__c = 'SGD'; 
        country.Student_Policies_Template_Id__c = 'test'; 
        country.Stripe_Base_Url__c = 'www.test.com'; 
        country.Stripe_Publishable_Key__c = 'ABC'; 
        country.Stripe_Secret_Key__c = 'deede'; 
        insert country;

        Firebase_Settings__c settings = New Firebase_Settings__c(name= 'setting',API_Key__c='Key=AAAAnpwAoa0:APA91bED0q97GSDONF-R-KvOr3ZPQM3Iid5O6Lq00ysF7XvZYwFZ8y2U6kF_loirGYtoNF6rgQPSTQFtYisty4GB_6w5xFf9cXDTRI8eXSulk6KX8cFjCgDEvf7KjnH4tu27V65Y0WEN',
                                                                 Endpoint__c='https://fcm.googleapis.com/fcm/send',Enable_Logs__c=true,Enable_Notifications__c = true);
        insert settings;
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Stage__c = 'Enrolled';
        insert objENrol;
        
        Invoice__c objinvoice = testUtility.createInvoice(objcustmr.id, false);
        objInvoice.Center__c = objCentr.Id;
        objInvoice.Parent_Account__c=objcustmr.id;
        objInvoice.invoice_date__c = system.today();
        insert objInvoice;
        
        Invoice_Line_Item__c objInvLneItm=TestUtil.createInvLineItem(objinvoice.id,false);
        objInvLneItm.Amount__c=30;
        objInvLneItm.Enrolment__c = objENrol.Id;
        insert objInvLneItm;
        
        test.startTest();
        	database.executeBatch(new TempUpdateGstAmtInLnitmRecords());
        test.stopTest();
    }
}