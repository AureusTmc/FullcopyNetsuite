@isTest
public class TempCreateFifthLessonRecordsTest {
    
	testMethod static void testMethod1(){
    
        Country__c country = new Country__c(); 
        country.Name = 'SGD'; 
        country.Country_Name__c = 'India'; 
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
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,true);
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        objBook.Enrolment__c=objEnrol.id;
        objBook.Status__c='Pending';
        insert objBook;
        
        //objBook.Status__c='Canceled';
        objBook.Is_fifth_booking__c=true;
        objbook.Booking_Date__c=Date.newInstance(2020, 01, 31);
        objBook.Available_Make_up_Units__c=30;
        objBook.Type__c='Busy';
        objBook.Category__c='Placeholder';
        objBook.Status__c  = 'Scheduled';
        update objBook;
        
        test.startTest();
        	database.executeBatch(new TempCreateFifthLessonRecords ());
        test.stopTest();
    }
}