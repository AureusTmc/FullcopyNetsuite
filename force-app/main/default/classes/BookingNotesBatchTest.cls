@isTest
public class BookingNotesBatchTest {

    static testMethod Void invokeBatch(){
        
        Country__c objCountry = createCountryRecord ('Singapore','SGD',true);
        
        
        
         Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Country__c = objCountry.Id;
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        
        insert objENrol;
        
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        ObjBook.Enrolment__c=objEnrol.id;
        objBook.Center__c=objCentr.Id;
        objBook.Booking_Date__c=System.today();
        
        insert objBook;
        NotesScheduler objTaskSchd= new NotesScheduler();
            objTaskSchd.execute(Null);
    }
    
    public static Country__c createCountryRecord(String countryName,string currencyCode,Boolean isCreate){
        Country__c country = new Country__c();
        country.Name = currencyCode;
        country.Country_Name__c = countryName;
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = currencyCode;
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        if(isCreate){
            insert country;
        }
        return country;
    }
}