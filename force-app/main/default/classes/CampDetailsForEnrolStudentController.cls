/****
* name : CampDetailsForEnrolStudentController
* Date : 12-Feb-2020
* author : jatin
* description: for  camp enrol student details
* 
*/
public  class CampDetailsForEnrolStudentController {
    // public String stuPreExperience{get;set;}
    public string studentDetails{get;set;}
    public Account parentAcc{get;set;}
    //public Account studentAcc{get;set;}
    // public Boolean isParAlsoAStudent{get;set;}
    public Boolean isError{get;set;}
    public String  errorMsg{get;set;}
    //public string birthDate{get;set;}
    public Boolean isAureusAtHome{get;set;}
    public Integer travelDuration{get;set;}
    public String selCountryCode{get;set;}
    public string accountModalDetails{get;set;}
    //public String  selectedDates{get;set;}
    public String selectedPackageId{get;set;}
    public String selectedCampId{get;set;}
    public string centerId{get;set;}
    public string centerName{get;set;}
    public string phoneNumber{get;set;}
   //@ Juneid 28 Aug 2020, Checking for Ossia Orgnization 
    Public Boolean isOssia{get;set;}
    public CampDetailsForEnrolStudentController() {
        parentAcc  = new Account();
        // studentAcc = new Account();
        accountModalDetails = '';
        
        isOssia =  false;
        //Juneid 28 Aug 2020 Orgnization wise logic as per new Requierment
        if(String.isNotBlank(ApexPages.currentPage().getParameters().get('org'))){
            isOssia = ApexPages.currentPage().getParameters().get('org').equalsIgnoreCase('ossia') ? true : false;
        }
    }
    
    
    // get gender picklist
    public List<SelectOption> getAccoungGenderPicklist(){     
        return CampClassUtilityController.getPicklistValues('Account','Gender__c');
    }
    
    public void fetchExistingStuDetail(){
        
        List<StudentDetail> listOfStudentDetials = (List<StudentDetail>) System.JSON.deserialize(studentDetails, List<StudentDetail>.class);
        
                /* set<String> existingStuList = new set<String>();
        //if(studentAcc.Gender__c != null && studentAcc.PersonBirthdate != null && parentAcc.PersonEmail != null){
        if(parentAcc.PersonEmail != null){
        List<Account> stuList = [SELECT Id,Name,PersonBirthdate,Gender__c FROM Account WHERE Parent__r.PersonEmail =: parentAcc.PersonEmail]; 
        if(stuList.size() > 0){
        for(Account ac: stuList){
        for(StudentDetail objStudentDetail :  listOfStudentDetials){
        if(objStudentDetail.student.BirthDate)
        existingStuList.add(ac.Id);
        }
        }
        }
        
        }*/
                /*studentAcc.PersonBirthdate = date.newInstance(integer.valueOf(objStudentDetail .student.BirthDate.split('/')[2]),
        integer.valueOf(objStudentDetail .student.BirthDate.split('/')[1]),
        integer.valueOf(objStudentDetail .student.BirthDate.split('/')[0])));*/
        system.debug('listOfStudentDetials'+listOfStudentDetials);
        parentAcc.phone =  phoneNumber;
        
        accountModalDetails = JSON.serialize(new AccountModal(parentAcc,selCountryCode,isAureusAtHome,travelDuration,selectedCampId,centerId,listOfStudentDetials));
        /*accountModalDetails = JSON.serialize(new AccountModal(studentAcc,parentAcc,existingStuList,selCountryCode,isAureusAtHome
,travelDuration,selectedDates.split(','),selectedPackageId,selectedCampId,
isParAlsoAStudent,centerId,stuPreExperience));*/
    }
    
    public class AccountModal{
        public Account parentAccDetails{get;set;}
        public List<String>  existingStudentList{get;set;}
        public String countryCode{get;set;}
        public Boolean isAureusAtHome{get;set;}
        public Integer travelDuration{get;set;}
        //public Boolean isParAlsoAStudent{get;set;}
        public string centerId{get;set;}
        public String selectedCampId{get;set;}
        public map<string,string> mapOfSelectedPackages{get;set;}
        public  map<String,Set<String>> mapOfSelectedDates{get;set;}
        //public String selectedPackageId{get;set;}
        //public string stuPreExperience{get;set;}
        public List<StudentDetail> listOfStudentDetails{get;set;}
        public map<string,Account> mapOfStudentAccount{get;set;}
        /*public AccountModal(Account>  studentAcc,Account parentAcc,Set<String>  existingStuList,
string countryCode,Boolean isAureusAtHome,Integer travelDuration,
List<String> selectedDates,String selectedPackageId,String selectedCampId,Boolean isParAlsoAStudent,
string centerId,string stuPreExperience){
studentAccDetails =studentAcc;
parentAccDetails = parentAcc;
existingStudentList = new List<string>(existingStuList);
this.countryCode = countryCode;
this.isAureusAtHome = isAureusAtHome;
this.travelDuration = travelDuration;
this.isParAlsoAStudent = isParAlsoAStudent;
this.centerId =centerId;
this.selectedCampId = selectedCampId;
this.selectedPackageId =selectedPackageId;
this.selectedDates = selectedDates;
this.stuPreExperience = stuPreExperience;
}*/
        public AccountModal(Account parentAcc, string countryCode,Boolean isAureusAtHome,Integer travelDuration,String selectedCampId,string centerId,List<StudentDetail> listOfStudentDetails){
            parentAccDetails = parentAcc;
            // existingStudentList = new List<string>(existingStuList);
            this.countryCode = countryCode;
            this.isAureusAtHome = isAureusAtHome;
            this.travelDuration = travelDuration;
            this.centerId =centerId;
            this.selectedCampId = selectedCampId;
            this.listOfStudentDetails =listOfStudentDetails;
            mapOfStudentAccount = new map<string,Account>();
            mapOfSelectedPackages = new map<string,string>();
            mapOfSelectedDates= new map<String,Set<String>>();
           
            if(listOfStudentDetails != null && listOfStudentDetails.size() > 0){
                for(StudentDetail objStudentDetail :  listOfStudentDetails){
                    date birthdate =date.newInstance(integer.valueOf(objStudentDetail .student.BirthDate.split('/')[2]),
                                                     integer.valueOf(objStudentDetail .student.BirthDate.split('/')[1]),
                                                     integer.valueOf(objStudentDetail .student.BirthDate.split('/')[0]));
                    mapOfStudentAccount.put(objStudentDetail.student.id,new Account(FirstName = objStudentDetail .student.FirstName,
                                                         LastName = objStudentDetail .student.LastName,
                                                         Gender__c = objStudentDetail .student.Gender,
                                                         PersonBirthdate = birthdate,
                                                         Food_Allergy__c = objStudentDetail.student.stuFoodAllergy));
                    if(string.isNotBlank(objStudentDetail.packageId)){
                        system.debug('objStudentDetail.packageId'+objStudentDetail.packageId);
                        mapOfSelectedPackages.put(objStudentDetail.student.id,objStudentDetail.packageId);
                    }
                    if(objStudentDetail.campDays != null && objStudentDetail.campDays.size() > 0){
                        set<String> selectedDates = new set<String>();
                        for(CampDays objCampDays:objStudentDetail.campDays){
                            selectedDates = new set<String>();
                            if(mapOfSelectedDates.containsKey(objStudentDetail.student.id)){
                                selectedDates = mapOfSelectedDates.get(objStudentDetail.student.id);
                            }
                            selectedDates.add(objCampDays.campId);
                            mapOfSelectedDates.put(objStudentDetail.student.id,selectedDates);
                        }
                    }    
                }
            }
            existingStudentList = new list<String>();
            //if(studentAcc.Gender__c != null && studentAcc.PersonBirthdate != null && parentAcc.PersonEmail != null){
            if(parentAcc.PersonEmail != null){
                List<Account> stuList = [SELECT Id,Name,PersonBirthdate,Gender__c FROM Account WHERE Parent__r.PersonEmail =: parentAcc.PersonEmail]; 
                System.debug('studList = '+stuList );
                System.debug('parent Email = '+parentAcc.PersonEmail);
                if(stuList.size() > 0){
                    for(Account ac: stuList){
                        for(account objstudent :  mapOfStudentAccount.values()){
                            if(string.valueOf(objstudent.PersonBirthdate).equalsIgnoreCase(string.valueOf(ac.PersonBirthdate)) && objstudent.Gender__c.equalsIgnoreCase(ac.Gender__c)){
                                existingStudentList.add(ac.Id);
                            }
                        }
                    }
                }
            }
        }
        public AccountModal(){
            //studentAccDetails =new Account();
            parentAccDetails =new Account();
            existingStudentList = new List<String> ();
            listOfStudentDetails = new List<StudentDetail>();
            mapOfStudentAccount = new map<string,Account>();
            mapOfSelectedPackages = new map<string,string>();
            mapOfSelectedDates= new map<String,Set<String>>();
        }
    }
    
    public class StudentDetail{
        public Student student{get;set;} 
        public String packageId{get;set;}
        public String selectedPackageName{get;set;}
        public List<CampDays> campDays{get;set;}
        public string campDates{get;set;}
    }
     
    public class Student {
        public string id{get;set;}
        public String FirstName{get;set;}
        public String LastName{get;set;}
        public string FullName{get;set;}
        public String BirthDate{get;set;}
        public String Gender{get;set;}
        public String stuPreExperience{get;set;}
        public String stuFoodAllergy{get;set;}
    }
    
    public class CampDays {
        public String campId{get;set;}
        public String campDate{get;set;}
        public String campDay{get;set;}
        
    }
    
}