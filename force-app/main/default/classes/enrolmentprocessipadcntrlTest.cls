@isTest
public class enrolmentprocessipadcntrlTest {
    
    
    testMethod static void enrolmentprocessipadcntrlMethodTwo(){
        Country__c countryObj = new Country__c();
        countryObj.Name='SG';
        countryObj.Country_Name__c='Singapore';
        countryObj.Tax_Rate__c=7.00;
        insert countryObj;
        Organisation__c organisation = new Organisation__c(
            Name = 'Aureus Academy Singapore',
            Bank_Account_Number__c = '647743343001',
            Bank_Name__c = 'OVERSEA-CHINESE BANKING CORP GROUP',
            Branch_Code__c = '001',
            CPF_Advice_Code__c = '01',
            CPF_Payment_Type__c = 'PTE',
            Country__c =countryObj.Id,
            Sage_Company__c = 'AGP');
        insert organisation;
        Account objCentr=TestUtil.createAccount('Centre',False,false);
        objCentr.Country__c=countryObj.Id;
        objCentr.Centre_Status__c='Active';
        objCentr.Organisation__c = organisation.Id;
        insert objCentr;
        
       /* Centre_Users__c cenUserObj = new Centre_Users__c();
        cenUserObj.User_Name__c=UserInfo.getUserId();
        cenUserObj.Centre_Name__c=objCentr.Id;
        */
        
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.PersonEmail='xytestz@gmail.com';
        insert objCustmr; 
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        
        List<Teacher_Working_Hour__c> teachObj=TestUtil.createTeacher_Working_Hour(objTechr.Id,objCentr.Id,true,false,7);
        
        String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',false);  
        objPack.RecordtypeId=pkgLessRecId;
        objPack.Type_of_package__c='Normal';
        objPack.Type__c='Individual';
        objPack.Location__c=objCentr.Id;
        insert objPack;
        
        List<Enrolment__c> enrolObjList = new List<Enrolment__c>(); 

        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Pending Enrolment';
        objEnrol.Lessons_Start_Date__c = System.today().addDays(20);
        enrolObjList.add(objEnrol);
        
        Enrolment__c objENrol1=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol1.Type__c='Trial';
        objENrol1.Stage__c='Attended';
        enrolObjList.add(objENrol1);
        insert enrolObjList; 
        
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        ObjBook.Enrolment__c=objENrol1.id;
        objBook.Center__c=objCentr.Id;
        objBook.Start_Time__c=Time.newInstance(10,0,0,0);
        objBook.End_Time__c=Time.newInstance(11,0,0,0);
        objBook.Booking_Date__c=System.today().addDays(2);        
        insert objBook; 
        
                
        ApexPages.currentPage().getParameters().put('enr1',objENrol.Id);
         ApexPages.currentPage().getParameters().put('currentOrg',organisation.Id);
         ApexPages.currentPage().getParameters().put('defaultOrg','Aureus');
        EnrolmentProcessIpadCntrl EnrolmentProcessObj = new EnrolmentProcessIpadCntrl();
        
        try{
        EnrolmentProcessObj.sendEmail();
        }catch(exception e){
            
        }
        EnrolmentProcessObj.saveStudentAndSendEmail();
        
        EnrolmentProcessObj.redirectOnSrch();
        EnrolmentProcessObj.addFreshEnrolment();
       	 
        EnrolmentProcessObj.selectedIndex = 1;
        EnrolmentProcessObj.refreshSlots();
        EnrolmentProcessObj.assignSlots();
        EnrolmentProcessObj.fetchTchrs();
        EnrolmentProcessObj.fetchPkgPlans();  
        EnrolmentProcessObj.studentWrapList.get(0).lesson.selectedPlan = objEnrol.Package__c;
        EnrolmentProcessObj.studentWrapList.get(0).lesson.selectedTeacher = objTechr.Id;
        EnrolmentProcessObj.studentWrapList.get(0).lesson.selectedLsnType = 'Group';
        EnrolmentProcessObj.fetchTSlots();
        EnrolmentProcessObj.showSlcdEnrolment();
        EnrolmentProcessObj.saveAndNextProcess();
        EnrolmentProcessObj.deleteEnrolment(); 
        EnrolmentProcessIpadCntrl.LessonWrapper lsnWrapObj = new EnrolmentProcessIpadCntrl.LessonWrapper();
       // EnrolmentProcessIpadCntrl.fillBook(lsnWrapObj, recTypeId, enrl, status, bookDate);
        EnrolmentProcessObj.slcdLessonType();
        EnrolmentProcessObj.slcdLsnType = 'Group';
      EnrolmentProcessObj.slcdLessonType();
    }
    
    
    
}