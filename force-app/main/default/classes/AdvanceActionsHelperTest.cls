/*
Name        :        AdvanceActionsHelperTest
Date        :        
Author      :        
Description :        
*/
@istest
public class AdvanceActionsHelperTest {
    Public Static testMethod void invokeAdvanceActionsHelper(){
        
        Country__c country = new Country__c();
        country.Name = 'SG';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        Account objTechr=TestUtil.createAccount('Teacher',False,True);
        Account objCntr=TestUtil.createAccount('Centre',False,FALSE);
        objCntr.Country__c = country.Id;
        INSERT objCntr;
        Account objCustmr=TestUtil.createAccount('Customer',False,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        insert objCustmr;
        
        
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objOldPack=testUtil.createPackage(objProg.id,objCntr.id,'30',true);        
        Package__c objNewPack=testUtil.createPackage(objProg.id,objCntr.id,'60',False);    
        objNewPack.Package_Fee__c=15.00;
        objNewPack.Active__c=true;
        objNewPack.Unit_Fee__c=15.00;
        objNewPack.Registration_Fee__c=18.00;
        objNewPack.Deposit_Fee__c=18.00;
        insert objNewPack;
        
        Package__c objMakeup = testUtil.createPackage(objProg.id,objCntr.id,'60',False); 
        objMakeup.Type__c = 'Makeup';
        objMakeup.Active__c=true;
        insert objMakeup;
        
        Package__c objMakeup2 = testUtil.createPackage(objProg.id,objCntr.id,'30',False); 
        objMakeup2.Type__c = 'Makeup';
        objMakeup2.Active__c=true;
        insert objMakeup2;
        
        Enrolment__c objEnrl=TestUtil.createEnrolment(objCntr.id,objTechr.id,objCustmr.id,objOldPack.id,FALSE);
        objEnrl.effective_date__c = System.today();
        INSERT objEnrl;
        Enrolment__c objEnrl2=TestUtil.createEnrolment(objCntr.id,objTechr.id,objCustmr.id,objOldPack.id,FALSE);
        objEnrl2.effective_date__c = System.today().adddays(10);
        objEnrl2.new_package_Id__c = objMakeup2.Id;
        INSERT objEnrl2;
        
        Booking__c objBook=TestUtil.createBooking(objTechr.Id,'Lesson','Regular',False);
        objBook.Enrolment__c=objEnrl.Id;
        objBook.Booking_Date__c=Date.today().adddays(10);
        objBook.Package__c = objOldPack.Id;
        insert objBook;
        
        Booking__c objBook2=TestUtil.createBooking(objTechr.Id,'Lesson','Make-up',False);
        objBook2.Enrolment__c=objEnrl.Id;
        objBook2.status__c = 'Scheduled';
        objBook2.Booking_Date__c=date.newInstance(2019, 10, 29);
        objBook2.Package__c = objMakeup2.Id;
        insert objBook2;
        
        Booking__c objBook3=TestUtil.createBooking(objTechr.Id,'Lesson','Regular',False);
        objBook3.Enrolment__c=objEnrl2.Id;
        objBook3.Booking_Date__c=Date.today().adddays(10);
        objBook3.Package__c = objOldPack.Id;
        insert objBook3;
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c=date.newInstance(2019, 10, 29), Center__c=objCntr.id, End_Time__c=time.newInstance(10, 0, 0, 0), Enrolment__c=objEnrl.id,
                                                              Package__c=objOldPack.id, Start_Time__c= time.newInstance(10, 30, 0, 0), Student__c=objCustmr.id, Teacher_Account__c=objTechr.id, Remarks__c='40',
                                                              IsActive__c=FALSE ,Parent__c=objCustmr.id, Booking__c = objBook2.Id);
        insert objFifthLesson;
        
        
        
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.id, FALSE);
        objSubs.Center__c= objCntr.Id;
        insert objSubs;
        Subscription_Line_Item__c objSLI=TestUtil.createSubscriptionLineItem(objSubs.id,false);
        objSLI.Enrolment__c=objEnrl.Id;
        insert objSLI;
        
        AdvanceActionsHelper.convertToDate(String.valueOf(System.today()));
        AdvanceActionsHelper.convertToDateForUpgrade('10/10/2019');
        AdvanceActionsHelper.fetchEnrolmentDetailsFromBooking(objBook.Id);
        AdvanceActionsHelper.fetchNextBillDateFromEnrolment(objEnrl);
        AdvanceActionsHelper.fetchCountryFromEnrolment(objEnrl);
        AdvanceActionsHelper.getDateTimeFromString('10:00 AM');
        AdvanceActionsHelper.getDepositFromFile(objEnrl.Id);
        AdvanceActionsHelper.getPackageDetailsUpgradeDowngrade(objOldPack.Id, objNewPack.Id);
        AdvanceActionsHelper.processFutureBookings(objEnrl2, 'downgrade');
        Set<string> makeupSet = AdvanceActionsHelper.processFutureFifthLessons(objEnrl, 'upgrade');
        AdvanceActionsHelper.fetchAllBooking(new Set<String>{objBook.Id});
        AdvanceActionsHelper.getOldNewPackage(objOldPack.Id, objNewPack.Id);
        objBook2.Make_up_Utilize_Bookings__c =objBook.Id+'-45;';
        update objBook2;
        objBook.Available_Make_up_Units__c =15;
        update objBook;
        AdvanceActionsHelper.AddFifthMakeupMinutesToParent(objCntr.Id, 60, 30, Time.newInstance(10, 0, 0, 0), Time.newInstance(10, 30, 0, 0), new Set<String>{objBook2.Id});
        AdvanceActionsHelper.deleteFutureFifthLessons(objEnrl);
    }
}