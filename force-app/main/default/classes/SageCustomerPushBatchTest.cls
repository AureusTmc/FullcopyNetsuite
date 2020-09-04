/*
 * By Shalini Singh
 */
@istest
public class SageCustomerPushBatchTest {
    
     @isTest
    public static void test2(){
        //Invoice__c inv = SageIntacctIntegrationUtility.createInvoice(new SageIntacctIntegrationUtility.sessionWrapper(),new Invoice__c());
        Account acc=new Account();
        acc.LastName='XYZ';
        acc.RecordTypeId=schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();
        acc.MovedToSage__c=false;
        insert acc;
        Account acc2= new Account();
        acc2.LastName='PQR';
        insert acc2;
        
        Invoice__c inv = new Invoice__c();
        inv.Total_Invoice_Amount__c = 100;
        inv.Parent_Account__c = acc.id;
        inv.Status__c ='Due';
        insert inv;
        
        set<String> accidSet=new Set<String>();
        accidSet.add(acc.id);
        accidSet.add(acc2.id);
  
        Test.startTest();
        SageCustomerPushBatch obj = new SageCustomerPushBatch(accidSet);
        SageCustomerPushBatch obj1 = new SageCustomerPushBatch();
        ID batchprocessid = Database.executeBatch(obj);
        ID batchprocessid1 = Database.executeBatch(obj1);
        test.stopTest();
    }
  
   
}