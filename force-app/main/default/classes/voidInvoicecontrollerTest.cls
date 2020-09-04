/*
    Name            :   voidInvoicecontrollerTest
    Date            :   22 May 2019
    Author          :   Karan Singh Soni
    Description     :   This test class is used for void and delete process of invoice.
*/
@isTest
public class voidInvoicecontrollerTest {
    public static TestMethod void invokevoidInvoicecontroller(){
        Invoice__c objInv = new Invoice__c();
        objInv.Parent_Account__c=TestUtil.createAccount('Customer', True, True).id;
        insert objInv;
        
        VoidInvoiceController.processInvoice(objInv.Id, 'void','Test');
    }
    public static TestMethod void invokevoidInvoicecontroller2(){
        Invoice__c objInv = new Invoice__c();
        objInv.Parent_Account__c=TestUtil.createAccount('Customer', True, True).id;
        insert objInv;
        
        VoidInvoiceController.processInvoice(objInv.Id, 'delete','');
    }
}