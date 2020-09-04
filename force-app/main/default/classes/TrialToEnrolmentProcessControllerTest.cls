/*
Name        :        TrialToEnrolmentProcessControllerTest
Date        :        21 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of TrialToEnrolmentProcessController.
*/

@isTest
public class TrialToEnrolmentProcessControllerTest {

    public static testMethod void invokeTrialToEnrolmentProcessController(){
        Map<string,string> entrdDataMap=TestUtil.createData();
        ApexPages.currentPage().getParameters().put('id',entrdDataMap.get('objBook'));
        
        //fetching previous created dummy booking obj and making changes on that according to condition
        Booking__C objBook=[select id,Type__c from Booking__c WHERE Id =:entrdDataMap.get('objBook')];
        objBook.Type__c='Trial';
        objBook.Enrolment__c=entrdDataMap.get('objEnrol');
        update objBook;
        
        Account objCentr=new Account();
        objCentr.id=entrdDataMap.get('objCentr');
        objCentr.Name='Aureus 112 Katong';
        objCentr.CentreName_Cust__c='Aureus Academy - 112 Katong';
        update objcentr;
        
        Program__C objProgram= new Program__C();
        objProgram.Id=entrdDataMap.get('objProg');
        objProgram.Billing__c='Monthly';
        update objProgram; 
            
            
        Package__c objPack= new Package__c();
        objPack.Id=entrdDataMap.get('objPack');
        objPack.Duration__c='30';
        objpack.Type__c='Individual';
        objPack.RecordTypeId=Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        update objpack;
        
         Booking__C objBookForTeachr=TestUtil.createBooking(entrdDataMap.get('objTchr'),'Lesson','Regular',True);
        TrialToEnrolmentProcessController objTEP= new TrialToEnrolmentProcessController();
        objTEP.lessonWrap.selectedTeacher=entrdDataMap.get('objTchr');
        objTEp.getSchoolPicklist();
        objTEp.saveStuAndLessonOnGrid();
        objTEp.completeEnrolment();
        boolean sentEmail=TrialToEnrolmentProcessController.sendEmail('testSubject TrialToEnrolmentProcessControllerTest','testbody TrialToEnrolmentProcessControllerTest',entrdDataMap.get('objCustmr'));
        
        
    }
}