@isTest
public class FifthLessonPageForPortalControllerTest{
    @isTest static void fetchFifthLessonRecord(){
        
        //Booking Parent
        String customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        String lessonRecordTypeId = Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        String centreRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId();
        Account parentRecord = new Account();
        parentRecord.firstname = 'Parent';
        parentRecord.lastname = 'Test';
        parentRecord.Available_Make_up_Units__c = 50;
        parentRecord.recordtypeid = customerRecordTypeId;
        insert parentRecord;
        
        //Booking student
        Account studentRecord = new Account();
        studentRecord.firstname = 'Student';
        studentRecord.lastname = 'Test';
        studentRecord.Available_Make_up_Units__c = 50;
        studentRecord.recordtypeid = customerRecordTypeId;
        studentRecord.parent__c = parentRecord.id;
        insert studentRecord;
        
        //insert country
        Country__c countryRecord = new Country__c();
        countryRecord.Name = 'SG';
        countryRecord.Country_Name__c = 'Singapore';
        countryRecord.Currency_Code__c = 'SGD';
        countryRecord.Tax_Rate__c = 7.00;        
        insert countryRecord;
        
        //insert Centre
        Account centerRecord = new Account();
        centerRecord.Name = 'Aureus 112 Katong';
        //centerRecord.lastname = '112 Katong';
        centerRecord.location__c = 'Aureus 112 Katong';
        centerRecord.country__c = countryRecord.id;
        centerRecord.recordtypeid = centreRecordTypeId;
        insert centerRecord;        
                
        //insert package
        Package__c packageRecord = new Package__c();
        packageRecord.Name = 'Piano Lessons 4x30 min';
        packageRecord.recordtypeid = lessonRecordTypeId;
        packageRecord.location__c = centerRecord.id;
        packageRecord.unit_fee__c = 300.00;
        insert packageRecord;
        
        //insert enrollment;
        Enrolment__c enrolmentRecord = new Enrolment__c();
        enrolmentRecord.name = 'ENR-1000';
        enrolmentRecord.Center__c = centerRecord.id;
        enrolmentRecord.package__c = packageRecord.id;
        insert enrolmentRecord;
        
        Fifth_Lesson__c fifthLesson = new Fifth_Lesson__c();        
        fifthLesson.booking_date__c = Date.newInstance(2019, 12, 29);
        fifthLesson.Start_Time__c = time.newInstance(07, 00, 0,0);
        fifthLesson.End_Time__c = time.newInstance(07, 30, 0,0);        
        fifthLesson.student__c = studentRecord.id;
        fifthLesson.center__c = centerRecord.id;
        fifthLesson.parent__c = parentRecord.id;
        fifthLesson.package__c = packageRecord.id;
        fifthLesson.Enrolment__c = enrolmentRecord.id;
        fifthLesson.IsActive__c = TRUE;
        insert fifthLesson;
        ApexPages.currentPage().getParameters().put('id',fifthLesson.id);
        FifthLessonPageForPortalController fifthLessonPage = new FifthLessonPageForPortalController();        
        fifthLessonPage.type = 'placeholder';        
        fifthLessonPage.fifthLessonId = fifthLesson.id; 
        fifthLessonPage.createBookingRecord();
        
        FifthLessonPageForPortalController fifthLessonPageMakeUp = new FifthLessonPageForPortalController();
        fifthLessonPageMakeUp.type = 'makeup';        
        fifthLessonPageMakeUp.fifthLessonId = fifthLesson.id; 
        fifthLessonPageMakeUp.createBookingRecord();
        
        FifthLessonPageForPortalController fifthLessonPageAdHoc = new FifthLessonPageForPortalController();         
        fifthLessonPageAdHoc.type = 'adhoc';
        fifthLessonPageAdHoc.fifthLessonId = fifthLesson.id; 
        fifthLessonPageAdHoc.createBookingRecord();
        
        ApexPages.currentPage().getParameters().put('id','');
        FifthLessonPageForPortalController fifthLessonPageWithBlankId = new FifthLessonPageForPortalController();
    }
    
}