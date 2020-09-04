/*
Name        :        InvoiceReminderSchedularTest
Date        :        2 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of InvoiceReminderSchedular.
*/
@isTest
public class InvoiceReminderSchedularTest {

    public static testmethod void invokeInvoiceReminderSchedular(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Invoice__C objINV=TestUtil.createInvoice(objCustmr.Id,False);
        objINV.Due_Date__c=Date.today().addDays(-3);
        objINV.Status__c='Due';
        insert objINV;
        InvoiceReminderSchedular objIRS=new InvoiceReminderSchedular();
        //string seh='0 0 23 *h * ?';
        //system.schedule('Test Status Check', seh,objIRS);
              
       // it will directly call schedular execute method to invoke batch class without cron expression
        objIRS.execute(null);
      
    }
}