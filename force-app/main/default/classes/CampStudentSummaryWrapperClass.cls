/***
* name: CampStudentEnrolSummaryCtrl
* author: jatin
* date: 9-Feb-2020
* description: This Controller will Show the details of Enrolment and update it.

* 
*/
public  class CampStudentSummaryWrapperClass {
    public CampDetailsForEnrolStudentController.AccountModal studentDetails{get;set;}
    public list<BillingSummary> listOfBillSummary{get;set;}
    public Decimal gstAmount{get;set;}
    public Decimal totalAmount{get;set;}
    public Decimal discountAmount{get;set;}
    public Decimal grossAmount{get;set;}
    public camp__c objCampClass{get;set;}
    public  Country__c objCountry{get;set;}
    public  Organisation__c organisationOfCentre{get;set;} //added by @nishi 24 Aug 2020,Organisation wise charge as per new logic
    public boolean isAmcClubMember{get;set;}
    public boolean isAlreadyStripCstmr{get;set;}
    public string stripeCstmrId{get;set;}
    public string cardNumber{get;set;}
    public string cardType{get;set;}
    public string cardImage{get;set;}
    public Account  existingStudentObj{get;set;}
    Public map<string,List<Camp_Day_Teachers__c>> mapOfCampDayTeachers{get;set;}
    //public Camp_Available_Package__c objCampPackage{get;set;}
    public map<id,Camp_Available_Package__c> mapOfCampPackage{get;set;}
    //public map<string,package> mapOfPackage{get;set;}
    //public List<Camp_Days__c> campDayList{get;set;}
    public map<string,List<StudentCampDays>> mapOfStudentCampDays{get;set;}
    public List<campStudentCampDays> listOfcampStudentCampDays{get;set;}
    
    public CampStudentSummaryWrapperClass( CampDetailsForEnrolStudentController.AccountModal studentDetails){
        this.studentDetails = studentDetails;
        set<string> selectedDates = new set<string>();
        listOfBillSummary = new list<BillingSummary>();
        objCountry =  new Country__c();
        organisationOfCentre = new Organisation__c();//added by @nishi 24 Aug 2020,Organisation wise charge as per new logic
        totalAmount = 0;
        gstAmount =0;
        discountAmount = 0;
        grossAmount =0;
        isAmcClubMember = false;
        isAlreadyStripCstmr = false;
        stripeCstmrId ='';
        mapOfStudentCampDays = new map<string,List<StudentCampDays>>();
        listOfcampStudentCampDays = new List<campStudentCampDays>();
        mapOfCampPackage = new map<id,Camp_Available_Package__c>();
        mapOfCampDayTeachers = new  map<string,List<Camp_Day_Teachers__c>>();
        // get all selected camp days ids 
        for(string studentId: studentDetails.mapOfSelectedDates.keySet()){
            if(studentDetails.mapOfSelectedDates.containsKey(studentId))
                selectedDates.addAll(studentDetails.mapOfSelectedDates.get(studentId));
        }
        system.debug('!!'+studentDetails.centerId);
        system.debug('!!'+studentDetails.selectedCampId);
        system.debug('!!'+studentDetails.mapOfSelectedPackages);
        system.debug('!!'+selectedDates);
        List<camp__c> ListOfCamp = CampClassUtilityController.getCampList(studentDetails.centerId,studentDetails.selectedCampId,
                                                                          new set<string>(studentDetails.mapOfSelectedPackages.values()),selectedDates);
         system.debug('!!'+ListOfCamp);
        // get camp class selected days for show billing summary 
        if(ListOfCamp != null && ListOfCamp.size() > 0){
            // 14-feb-2020:jatin:check early bird start and date is exist and discount amount is greater then 0 
            // user enrol in middel of this early dates then give discount other wise not  
            objCampClass =ListOfCamp[0];
           
            
            map<Id,Camp_Days__c> mapofcampDay =((objCampClass.Camp_Days__r != null && objCampClass.Camp_Days__r.size() > 0 ) 
                                                ? new map<Id,Camp_Days__c>(objCampClass.Camp_Days__r) 
                                                : new map<Id,Camp_Days__c>());
            /* commented by jatin: 13-feb : show one package not a days calculation
for(Camp_Days__c campDayObj : objCampClass.Camp_Days__r){
listOfBillSummary.add(new BillingSummary(objCampClass.Camp_Available_Packages__r[0].Package__r.package_Fee__c,
'Camp Day - '+dateTime.newInstance(campDayObj.Dates_Of_The_Camp__c, campDayObj.Camp_Start_Time__c).format('dd MMM, yyyy')
)); 
}*/
            mapOfCampDayTeachers = CampClassUtilityController.getCampDaysTeachers(new Set<Id>(mapofcampDay.keySet()));
            if(string.isNotBlank(objCampClass.Centre__r.id) && objCampClass.Centre__r.Country__c != null && string.isNotBlank(objCampClass.Centre__r.Country__r.id)){
                objCountry = objCampClass.Centre__r.Country__r;
            }
            //start:added by @nishi 24 Aug 2020,Organisation wise charge as per new logic
            if(string.isNotBlank(objCampClass.Centre__r.id) && objCampClass.Centre__r.Organisation__c != null
             && string.isNotBlank(objCampClass.Centre__r.Organisation__r.id)){
                organisationOfCentre = objCampClass.Centre__r.Organisation__r;
            }
            //end:added by @nishi 24 Aug 2020,Organisation wise charge as per new logic
             system.debug('!!'+objCampClass.Camp_Available_Packages__r);
            mapOfCampPackage =((objCampClass.Camp_Available_Packages__r != null && objCampClass.Camp_Available_Packages__r.size() > 0 )
                                                                    ? new map<Id,Camp_Available_Package__c>(objCampClass.Camp_Available_Packages__r) 
                                                                    : new map<id,Camp_Available_Package__c>());
            if(studentDetails.listOfStudentDetails != null && studentDetails.listOfStudentDetails.size() > 0 ){
                List<StudentCampDays> listOfCampDays = new List<StudentCampDays>(); 
                listOfBillSummary = createBillingSummary( studentDetails,mapOfCampPackage,objCampClass);
                mapOfStudentCampDays = getMapOfStudentSelectedCampDayes(studentDetails,mapofcampDay);
                system.debug('@@mapOfStudentCampDays'+mapOfStudentCampDays);
                 
                // addby jatin: 21-feb-2020: for manage package details in table
                if(mapOfStudentCampDays != null && mapOfStudentCampDays.size() > 0){
                    for(string studentTempId :  studentDetails.mapOfStudentAccount.keySet()){
                        if(string.isnotBlank(studentTempId) && mapOfStudentCampDays.containsKey(studentTempId)){
                            system.debug('@@mapOfStudentCampDays'+mapOfStudentCampDays.get(studentTempId));
                            listOfcampStudentCampDays.add(new campStudentCampDays(studentDetails.mapOfStudentAccount.get(studentTempId),mapOfStudentCampDays.get(studentTempId)));
                        }
                    }
                }
            }
        }
        
        // mange billing summary accoding to selected dates
        if(listOfBillSummary != NULL && listOfBillSummary.size() != 0){
            for(BillingSummary objBillingSummary : listOfBillSummary){
                grossAmount += objBillingSummary.amount;
            }
            // 13-feb-2020:jatin:check early bird start and date is exist and discount amount is greater then 0 
            // user enrol in middel of this early dates then give discount other wise not  
            /*commented by jatin:14-Feb-2020: for this field change now we use this fields to camp object perviously we use this field to camp package object
if(system.today() >= objCampPackage.Early_Bird_Start_Date__c && system.today() <= objCampPackage.Early_Bird_End_Date__c 
&& objCampPackage.Early_Bird_Discount__c != null &&  objCampPackage.Early_Bird_Discount__c  > 0){
discountAmount = grossAmount *(objCampPackage.Early_Bird_Discount__c / 100);
} */
            if(system.today() >= objCampClass.Early_Bird_Start_Date__c && system.today() <= objCampClass.Early_Bird_End_Date__c 
                && objCampClass.Early_Bird_Discount__c != null &&  objCampClass.Early_Bird_Discount__c  > 0
                && grossAmount != null && grossAmount >0){
                    discountAmount = grossAmount * (objCampClass.Early_Bird_Discount__c / 100);
                } 
            if(grossAmount > 0 && discountAmount >0){
                grossAmount =  grossAmount - discountAmount;
            }
            if(grossAmount > 0 && objCountry != null && string.isNotBlank(objCountry.id) && objCountry.Tax_Rate__c > 0){
                gstAmount = grossAmount  * (objCampClass.Centre__r.Country__r.Tax_Rate__c / 100);
            }
        }
        
        if(grossAmount > 0 && gstAmount > 0 ){
            totalAmount = BillingUtility.roundOffAmount(grossAmount + gstAmount);
        }
        if(discountAmount > 0){
            discountAmount = -(BillingUtility.roundOffAmount(discountAmount));
        } 
        if(grossAmount > 0){
            grossAmount = (BillingUtility.roundOffAmount(grossAmount));
        } 
        if(gstAmount > 0){
            gstAmount = BillingUtility.roundOffAmount(gstAmount);
        } 
        // if person is already exist then we get all detials 
        if(string.isNotBlank(studentDetails.parentAccDetails.PersonEmail)){
            List<Account> existingParentList = [SELECT Id, Is_Club_Member__c, Membership_Type__c,Stripe_Customer_Id__c, Card_Number__c, Card_Type__c, Card_Image__c 
                                                FROM Account WHERE 
                                                PersonEmail =: studentDetails.parentAccDetails.PersonEmail];
            if(existingParentList != null && existingParentList.size() > 0){
                existingStudentObj = existingParentList[0];
                if(existingStudentObj.Is_Club_Member__c && existingStudentObj.Membership_Type__c == ConstantsClass.amcClubMember)
                    isAmcClubMember = true;
                if(string.isNotBlank(existingStudentObj.Stripe_Customer_Id__c))
                    stripeCstmrId = existingStudentObj.Stripe_Customer_Id__c;
                if(string.isNotBlank(existingStudentObj.Card_Number__c))
                    cardNumber    = existingStudentObj.Card_Number__c;
                if(string.isNotBlank(existingStudentObj.Card_Type__c))
                    cardType      = existingStudentObj.Card_Type__c;            
                if(string.isNotBlank(existingStudentObj.Card_Image__c))
                    cardImage     = existingStudentObj.Card_Image__c;   
            }
        }
        if(string.isNotBlank(stripeCstmrId) && string.isNotBlank(cardNumber) && string.isNotBlank(cardType) && string.isNotBlank(cardImage)){
            isAlreadyStripCstmr = true;
        }
    }
    // jatin: 21-feb-2020: start :  manage billing amount for per  student selected package fee
    public list<BillingSummary>  createBillingSummary(CampDetailsForEnrolStudentController.AccountModal studentDetails, map<id,Camp_Available_Package__c> mapOfCampPackage,camp__c objCampClass){
        list<BillingSummary> listOfBillSummary = new list<BillingSummary>();
        for(CampDetailsForEnrolStudentController.StudentDetail objStudentDetail :  studentDetails.listOfStudentDetails){
            string studentName = objStudentDetail.student.FirstName+' '+objStudentDetail.student.LastName;
            // jatin: 21-feb-2020: start :  manage billing amount for per  student selected package fee
            if(mapOfCampPackage != null && mapOfCampPackage.size() > 0 ){
                if(mapOfCampPackage.containsKey(objStudentDetail.packageId)){
                    Camp_Available_Package__c objCampPackage = mapOfCampPackage.get(objStudentDetail.packageId);
                    if(system.today() >= objCampClass.Early_Bird_Start_Date__c && system.today() <= objCampClass.Early_Bird_End_Date__c 
                        && objCampClass.Early_Bird_Discount__c != null &&  objCampClass.Early_Bird_Discount__c  > 0){
                            Decimal discountPackageFeeAmount = objCampPackage.Package__r.package_Fee__c * (objCampClass.Early_Bird_Discount__c / 100);
                            listOfBillSummary.add(new BillingSummary(objCampPackage.Package__r.package_Fee__c,objCampPackage.Package__r.name,studentName,objStudentDetail.student.id,objCampPackage.Package__r.id,discountPackageFeeAmount)); 
                        }else{
                            listOfBillSummary.add(new BillingSummary(objCampPackage.Package__r.package_Fee__c,objCampPackage.Package__r.name,studentName,objStudentDetail.student.id,objCampPackage.Package__r.id,0)); 
                        }
                }
            }
        }
        return listOfBillSummary;
    }
    
    public map<string,List<StudentCampDays>> getMapOfStudentSelectedCampDayes(CampDetailsForEnrolStudentController.AccountModal studentDetails,map<Id,Camp_Days__c> mapofcampDay){
        map<string,List<StudentCampDays>> mapOfStudentCampDays = new map<string,List<StudentCampDays>>();
        List<StudentCampDays> listOfCampDays = new List<StudentCampDays>();
        for(CampDetailsForEnrolStudentController.StudentDetail objStudentDetail :  studentDetails.listOfStudentDetails){
            // jatin: 21-feb-2020: start :  manage campDays per  student to dates
            if(objStudentDetail.campDays != null && objStudentDetail.campDays.size() > 0 ){
                for(CampDetailsForEnrolStudentController.CampDays objCampDay : objStudentDetail.campDays){
                    if(mapofcampDay != null && mapofcampDay.size() > 0 && mapofcampDay.containsKey(objCampDay.campId)){
                        listOfCampDays = new List<StudentCampDays>();
                        if(string.isNotBlank(objStudentDetail.student.Id)){
                            system.debug('@@objStudentDetail.student.FullName'+objStudentDetail.student.Id);
                            if(mapOfStudentCampDays.containsKey(objStudentDetail.student.Id)){
                                listOfCampDays = mapOfStudentCampDays.get(objStudentDetail.student.Id);
                            }
                            Camp_Days__c objCampDays = mapofcampDay.get(objCampDay.campId);
                            listOfCampDays.add(new StudentCampDays(objCampDay.campDay,objCampDays));
                            mapOfStudentCampDays.put(objStudentDetail.student.Id,listOfCampDays);
                        }
                    }
                }
            }
        }
        return mapOfStudentCampDays;
    }
    
    public CampStudentSummaryWrapperClass(){
        existingStudentObj = new Account();
        objCampClass = new camp__c();
        listOfBillSummary = new list<BillingSummary>();
        isAmcClubMember = false;
        isAlreadyStripCstmr = false;
        // objCampPackage =  new Camp_Available_Package__c();
        mapOfCampPackage = new map<id,Camp_Available_Package__c>();
        // campDayList = new List<Camp_Days__c>();
        mapOfStudentCampDays = new map<string,List<StudentCampDays>>();
        listOfcampStudentCampDays = new List<campStudentCampDays>();
        totalAmount = 0;
        gstAmount =0;
        discountAmount = 0;
        grossAmount =0;
        mapOfCampDayTeachers = new  map<string,List<Camp_Day_Teachers__c>>();
    }
    
    public class BillingSummary{
        public string studentName{get;set;}
        public string studentTempId{get;set;}
        public Decimal amount{get;set;}
        public String packageName{get;set;}
        public string packageId{get;set;}
        public Decimal netAmount{get;set;}
        public Decimal discountAmount{get;set;}
        public Decimal netDiscountAmount{get;set;}
        public BillingSummary(Decimal amount,String packageName,string studentName,string studentTempId,string packageId,decimal discountAmount){
            this.amount = amount;
            this.packageName = packageName;
            this.netAmount = BillingUtility.roundOffAmount(amount);
            this.studentName = studentName;
            this.packageId = packageId;
            this.discountAmount =  -BillingUtility.roundOffAmount(discountAmount);
            this.netDiscountAmount = discountAmount;
            this.studentTempId = studentTempId;
        }
    }
    // 21-feb-2020:jatin:manage per student camp days details  
    public class campStudentCampDays{
        public Account studentDetail{get;set;}
        public List<StudentCampDays> listOfCampDays{get;set;}
        public campStudentCampDays(Account studentDetail,List<StudentCampDays> listOfCampDays){
            this.studentDetail = studentDetail;
            this.listOfCampDays = new List<StudentCampDays>();
            if(listOfCampDays != null && listOfCampDays.size()>0)
                this.listOfCampDays.addAll(listOfCampDays);
        }
        public campStudentCampDays(){
            studentDetail = new Account();
            listOfCampDays = new List<StudentCampDays>();
        }
    }
    
    // 21-feb-2020:jatin: for manege students selected camp day 
    public class StudentCampDays {
        public String campId{get;set;}
        public string campStartTime{get;set;}
        public date campdate{get;set;}
        public String campDay{get;set;}
        public string campEndTime{get;set;}
        public Camp_Days__c objCampDays{get;set;}
        public StudentCampDays(string campDay,Camp_Days__c objCampDays){
            this.campId = objCampDays.id;
            campStartTime = datetime.newInstance(objCampDays.Dates_Of_The_Camp__c, objCampDays.Camp_Start_Time__c).format('hh:mm aa');
            campEndTime = datetime.newInstance(objCampDays.Dates_Of_The_Camp__c, objCampDays.Camp_End_Time__c).format('hh:mm aa');
            this.campdate = objCampDays.Dates_Of_The_Camp__c;
            this.campDay = campDay;
            this.objCampDays = objCampDays;
        }
    }
}