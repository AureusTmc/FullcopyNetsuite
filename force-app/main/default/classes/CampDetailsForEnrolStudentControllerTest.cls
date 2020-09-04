/**
* Name: CampDetailsForEnrolStudentControllerTest
* Author: Jatin
* Date : 11-March-2020
* Description: this class Used to test CampDetailsForEnrolStudentControllerTest controller class
*/
@isTest
public class CampDetailsForEnrolStudentControllerTest {
    @testSetup
    private static void createData(){
        CampEnrolmentTestHelper.createCampData();
        
    }
    private static testMethod  void testCampStudentNotExist(){
        CampDetailsForEnrolStudentController objController = new CampDetailsForEnrolStudentController();
        CampDetailsForEnrolStudentController.AccountModal objAccModal = new CampDetailsForEnrolStudentController.AccountModal();
        list<Camp__c> lstCamp= [SELECT Id,Centre__c, Name FROM Camp__c];
        list<Camp_Available_Package__c> lstPackages = [SELECT Id, Name,No_of_days__c FROM Camp_Available_Package__c where Camp_Name__c =:lstCamp[0].id];
        
        list<Camp_Days__c>lstCampDays = [ SELECT Status__c, Camp_Name__c, Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c 
                                         FROM Camp_Days__c where Camp_Name__c =: lstCamp[0].id];
        objController.parentAcc = new Account(FirstName='Jatin',Lastname ='Motiyani Parent',PersonEmail ='test@tmc.com');
        List<CampDetailsForEnrolStudentController.StudentDetail> listOfStudentDetail = new List<CampDetailsForEnrolStudentController.StudentDetail>();
        
        CampDetailsForEnrolStudentController.StudentDetail objStudentDetail = new CampDetailsForEnrolStudentController.StudentDetail();
        List<CampDetailsForEnrolStudentController.student> listOfStudent = new List<CampDetailsForEnrolStudentController.Student>();
        
        CampDetailsForEnrolStudentController.student objStudentWrapper = new CampDetailsForEnrolStudentController.Student();
        objStudentWrapper.id = '1';
        objStudentWrapper.FirstName = 'Jatin';
        objStudentWrapper.LastName = 'Motiyani student 1';
        objStudentWrapper.FullName = 'Jatin Motiyani student 1';
        objStudentWrapper.BirthDate = '10/1/1996';
        objStudentWrapper.Gender = 'Male';
        objStudentWrapper.stuPreExperience ='No';
        objStudentWrapper.stuFoodAllergy = 'No';
        objStudentDetail.student = objStudentWrapper;
        objStudentDetail.packageId = lstPackages[0].id;
        objStudentDetail.selectedPackageName = lstPackages[0].Name;
        List<CampDetailsForEnrolStudentController.CampDays> listOfCampDays = new List<CampDetailsForEnrolStudentController.CampDays>();
        integer index =1; 
        List<String> campDates = new List<string>();
        for(Camp_Days__c objCamp_Days : lstCampDays) {
            CampDetailsForEnrolStudentController.CampDays objCampDays = new CampDetailsForEnrolStudentController.CampDays();
            objCampDays.campDay= string.ValueOf(index);
            objCampDays.campId = objCamp_Days.id;
            objCampDays.campDate = string.ValueOf(objCamp_Days.Dates_Of_The_Camp__c);
            listOfCampDays.add(objCampDays);
            index++;
            campDates.add(DateTime.newInstance(objCamp_Days.Dates_Of_The_Camp__c,objCamp_Days.Camp_Start_Time__c).format('MMM dd, yyyy'));
        }
        objStudentDetail.campDays = listOfCampDays;
        objStudentDetail.campDates = String.join(campDates,';');
        listOfStudentDetail.add(objStudentDetail);
        objController.isError = false;
        objController.errorMsg = '';
        objController.selectedPackageId  = lstPackages[0].id;
        objController.studentDetails =Json.serialize(listOfStudentDetail);
        objController.centerName = lstCamp[0].Centre__c;
        objController.getAccoungGenderPicklist();
        objController.fetchExistingStuDetail();
        system.assertEquals(true,String.isnotBlank(objController.accountModalDetails),'AccountModalDetails List is Empty');
      
    }
    
    private static testMethod  void testCampStudentalreadyExist(){
        CampDetailsForEnrolStudentController objController = new CampDetailsForEnrolStudentController();
        CampDetailsForEnrolStudentController.AccountModal objAccModal = new CampDetailsForEnrolStudentController.AccountModal();
        list<Camp__c> lstCamp= [SELECT Id,Centre__c, Name FROM Camp__c];
        list<Camp_Available_Package__c> lstPackages = [SELECT Id, Name,No_of_days__c FROM Camp_Available_Package__c where Camp_Name__c =:lstCamp[0].id];
        
        list<Camp_Days__c>lstCampDays = [ SELECT Status__c, Camp_Name__c, Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c 
                                         FROM Camp_Days__c where Camp_Name__c =: lstCamp[0].id];
        
        List<Account> stuList = [SELECT Id,Name,Centre_Name__c,PersonEmail,Lastname,FirstName,PersonBirthdate,Gender__c 
                                 FROM Account 
                                 where recordtype.Name='Customer']; 
        Account objStudent = new Account(Parent__c = stuList[0].id,id=stuList[1].id);
        update objStudent;
        objController.parentAcc = new Account(FirstName=stuList[0].FirstName,Lastname =stuList[0].LastName,PersonEmail =stuList[0].PersonEmail);
        
       /* String str = '[{"student":{"id":0,"FirstName":"'+stuList[0].FirstName+'","LastName":"'+stuList[0].LastName+'","FullName":"'+stuList[0].Name+'","BirthDate":"'+stuList[0].PersonBirthdate.day()+'/'+stuList[0].PersonBirthdate.month()+'/'+stuList[0].PersonBirthdate.year()'","Gender":"'+stuList[0].Gender__c+'","stuPreExperience":"No","stuFoodAllergy":"No"},';
        str +='"packageId":"'+lstPackages[0].id+'","selectedPackageName":"'+lstPackages[0].Name+'","campDays":[';
        integer index =1; 
        String campDaystr='';
        List<String> campDates = new List<string>();
        
        for(Camp_Days__c objCamp_Days : lstCampDays) {
            campDaystr+='{"campId":"'+objCamp_Days.id+'","campDate":"'+objCamp_Days.Dates_Of_The_Camp__c+'","campDay":"'+index+'"},';
            index++;
            campDates.add(DateTime.newInstance(objCamp_Days.Dates_Of_The_Camp__c,objCamp_Days.Camp_Start_Time__c).format('MMM dd, yyyy'));
        }
        campDaystr =  campDaystr.removeEnd(',');
        
        str += campDaystr+']';
        str += ',"campDates":"'+ String.join(campDates,';') +'"}]';*/
        List<CampDetailsForEnrolStudentController.StudentDetail> listOfStudentDetail = new List<CampDetailsForEnrolStudentController.StudentDetail>();
        
        CampDetailsForEnrolStudentController.StudentDetail objStudentDetail = new CampDetailsForEnrolStudentController.StudentDetail();
        List<CampDetailsForEnrolStudentController.student> listOfStudent = new List<CampDetailsForEnrolStudentController.Student>();
        
        CampDetailsForEnrolStudentController.student objStudentWrapper = new CampDetailsForEnrolStudentController.Student();
        objStudentWrapper.id = '1';
        objStudentWrapper.FirstName = stuList[0].FirstName;
        objStudentWrapper.LastName = stuList[0].LastName;
        objStudentWrapper.FullName = stuList[0].Name;
        objStudentWrapper.BirthDate = stuList[0].PersonBirthdate.day()+'/'+stuList[0].PersonBirthdate.month()+'/'+stuList[0].PersonBirthdate.year();
        objStudentWrapper.Gender = stuList[0].Gender__c;
        objStudentWrapper.stuPreExperience ='No';
        objStudentWrapper.stuFoodAllergy = 'No';
        objStudentDetail.student = objStudentWrapper;
        objStudentDetail.packageId = lstPackages[0].id;
        objStudentDetail.selectedPackageName = lstPackages[0].Name;
        List<CampDetailsForEnrolStudentController.CampDays> listOfCampDays = new List<CampDetailsForEnrolStudentController.CampDays>();
        integer index =1; 
        List<String> campDates = new List<string>();
        for(Camp_Days__c objCamp_Days : lstCampDays) {
            CampDetailsForEnrolStudentController.CampDays objCampDays = new CampDetailsForEnrolStudentController.CampDays();
            objCampDays.campDay= string.ValueOf(index);
            objCampDays.campId = objCamp_Days.id;
            objCampDays.campDate = string.ValueOf(objCamp_Days.Dates_Of_The_Camp__c);
            listOfCampDays.add(objCampDays);
            index++;
            campDates.add(DateTime.newInstance(objCamp_Days.Dates_Of_The_Camp__c,objCamp_Days.Camp_Start_Time__c).format('MMM dd, yyyy'));
        }
        objStudentDetail.campDays = listOfCampDays;
        objStudentDetail.campDates = String.join(campDates,';');
        listOfStudentDetail.add(objStudentDetail);
        objController.isError = false;
        objController.errorMsg = '';
        objController.selectedPackageId  = lstPackages[0].id;
        objController.studentDetails =Json.serialize(listOfStudentDetail);
        objController.centerName = lstCamp[0].Centre__c;
        objController.getAccoungGenderPicklist();
        objController.fetchExistingStuDetail();
        system.assertEquals(true,String.isnotBlank(objController.accountModalDetails),'AccountModalDetails List is Empty');
      
    }
}