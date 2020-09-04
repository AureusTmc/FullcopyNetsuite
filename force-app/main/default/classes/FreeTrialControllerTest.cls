/*
Name        :        FreeTrialControllerTest
Date        :        21 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of FreeTrialController.
*/

@isTest
public class FreeTrialControllerTest {
    
   
    
    public static testMethod void createFreeTrialController(){
        // Create country 
        Country__c counryObj = new Country__c(Country_Name__c='Singapore',Name='SG',Tax_Rate__c=7.00);
        insert counryObj;
        
         // create a new account with center record type
        Account objCenter=TestUtil.createAccount('Centre',false,False);
        objCenter.Name='Aureus 112 Katong';
        objCenter.Country__c =counryObj.Id;
        insert objCenter;
        
        /* Account objCenterNew=TestUtil.createAccount('Centre',false,False);
        objCenterNew.Name='Aureus Forum';
        objCenter.Country__c =counryObj.Id;
        insert objCenterNew;*/
        
        // creating pagereference with page which is to be load
        PageReference pageRef = Page.freetrialprocess; 
        
        //Test.setCurrentPage(pageRef); //setting that page as current page 
        //ApexPages.currentPage().getParameters().put('cntId',objCenter.id); // passing current page id of center
        
        //creating teacher obj for linking with teacherWorkingHour
        Account objTeacher=TestUtil.createAccount('Teacher',false,true);
        Account objCustm=TestUtil.createAccount('Customer',false,true);
        List <Teacher_Working_Hour__c> objTWh=TestUtil.createTeacher_Working_Hour(objTeacher.id,objCenter.id,true,False,7);
        Attachment objAttach=TestUtil.createAttachment(objTeacher.id,true);
        Booking__c objBook=TestUtil.createBooking(objTeacher.id,'Lesson','Regular',true);
        Qualification__c qual=TestUtil.createQualification(objTeacher.id,'testProgram','Degree',true);
        
        FreeTrialController ftc=new FreeTrialController();
        
        ftc.getCenters();
        ftc.slcdCenter=objCenter.id;
        ftc.getInstrument();
        ftc.getAddr();
        ftc.checkAtHome();
        ftc.slcdInstrument='Piano';  
  	    ftc.fetchTimeSlot();
        ftc.slcdSlot='23:00';
		       
        ftc.refreshSlotsAndTchr();
        ftc.slcdTechr=objTeacher.id;
        ftc.refreshTeacherOnSelectSlot();
        ftc.validateSlcdSlotInFuture();
        
        ftc.parModel.lastName='TestLastName';
        ftc.parentAcc.PersonEmail='testEmail@gmail.com';
        ftc.isParAlsoAStudent=true;
        ftc.iWantReceivedLatestNew=true;
        ftc.slcdInstrument='Piano';  
        ftc.slcdCenter=objCenter.id;
        Program__c objProg =TestUtil.createProgram('Active', ftc.slcdInstrument, true);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCenter.id,'Trial', false);
        //system.debug('objPack.Location__r.Country__r.Country_Name__c'+objPack.Location__r.Country__r.Country_Name__c);
       // objPack.Country_Sharing__c=objPack.Location__r.Country__r.Country_Name__c;
       	ObjPack.Location__c=ftc.slcdCenter;
        objPack.Active__c = True;
        objPack.Duration__c = '30';
        objPack.Type__c = 'Trial';
        insert objPack;
        
        ftc.fetchSummaryDetails();
  
        ftc.saveData();
        
    }
}