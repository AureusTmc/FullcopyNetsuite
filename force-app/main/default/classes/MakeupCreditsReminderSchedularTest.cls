/*
Name        :        MakeupCreditsReminderSchedularTest
Date        :        4 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of MakeupCreditsReminderSchedular.
*/
@isTest
public class MakeupCreditsReminderSchedularTest {
    public static testmethod void invokeMakeupCreditsReminderSchedular(){
        Account objteachr=TestUtil.createAccount('Teacher',false,true);
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Booking__c objBook = TestUtil.createBooking(objteachr.id, 'Lesson','Regular',false);
        objBook.Make_up_Expiry_Date__c=date.today().addDays(-1);
        objbook.Available_Make_up_Units__c=30;
        objBook.Student__c=objCustmr.id;
        insert objBook;
        MakeupCreditsReminderSchedular objMakeCredit = new MakeupCreditsReminderSchedular();
        //every day at 23:00
        //string seh='0 0 23 * * ?';
        //system.schedule('Test Status Check',seh,objMakeCredit);
        
        //
         objMakeCredit.execute(Null);     
        MakeupCreditsReminderBatch batchObj = new MakeupCreditsReminderBatch(-1);
		Database.executeBatch(batchObj);
    }
}