public with sharing class searchFreeInstrumentRentalCtrl {
    public Account parentAcc{get;set;}
    public Boolean isOssiaOrg{get;set;}
    public boolean isError{get;set;}
    public boolean isSucess{get;set;}
    public string  errorMsg{get;set;}
    public Boolean isAllowedPermissionToThisUser{get;set;}
    public searchFreeInstrumentRentalCtrl(ApexPages.StandardController sc){
        isAllowedPermissionToThisUser = FeatureManagement.checkPermission('Free_Promotional_Instrument_Rental') ? true : false;
        isOssiaOrg = false;
        isError = false;
        isSucess = false;
        parentAcc = (Account)sc.getRecord();
        parentAcc = [SELECT Id,Parent__c,Centre_Name__r.Organisation__r.Name,Centre_Name__r.Location__c,PersonContactId, Centre_Name__c,Stripe_Customer_Id__c,PersonEmail FROM Account WHERE Id=: parentAcc.id];
        if(string.isNotBlank(parentAcc.Centre_Name__c) && string.isNotBlank(parentAcc.Centre_Name__r.Organisation__c) 
            && System.Label.Ossia_Organisation_Name == parentAcc.Centre_Name__r.Organisation__r.Name){
            isOssiaOrg= true;
        }
    }
    public PageReference redirectToParentAccount(){
       return new Pagereference('/'+parentAcc.id);
    }
    public PageReference redirectToPianoRentallink(){
        isError = false;
        errorMsg ='';
        isSucess = false;
        if(string.isNotBlank(parentAcc.id)){
            map<Id,Enrolment__c> regularEnrolmentList = new map<Id,Enrolment__c>();
            map<Id,Enrolment__c> rentalEnrolmentList = new map<Id,Enrolment__c>();
            Map<string,string> retailPromotionEnrolmentPackageIds = new Map<string,string>(); // added  by nishi: 13-Feb-2021: New Requirement Retail promotion for Piano rental: get selected package is promotional rental package
            Set<String> setOfAccIds = new Set<String>();
            for(Account objAcc : [SELECT Id,Parent__c, Also_A_Student__c FROM Account WHERE Id =: parentAcc.id OR 
                                Parent__c = : parentAcc.id ]){
                if(String.isBlank(objAcc.Parent__c)){
                    setOfAccIds.add(objAcc.Id);
                }else{
                    setOfAccIds.add(objAcc.Parent__c);
                }
            }
          
            for(Enrolment__c enr : [SELECT Id, Name, Center__c, Center__r.Name, Teacher__c,Teacher__r.Engagement_Type__c, Teacher__r.Name, Package__r.Name, Lesson_Day__c,  Parent__r.Name,
                                            Lesson_Start_time__c, Lessons_Start_Date__c, Student__r.Name, Student__r.FirstName, Student__r.LastName, Parent__c, Parent__r.FirstName, Parent__r.LastName, 
                                            Package__c, Package__r.Package_Fee__c, Package__r.Deposit_Fee__c, Package__r.Registration_Fee__c, Package__r.Unit_Fee__c,Referral_code_used__c,//Package__r.Facility_Fee__c,
                                            Package__r.Is_Promotion_Discount__c, Package__r.Promotion_Discount__c, Package__r.Promotion_period_In_months__c,Referred_by__c,Referred_by__r.name,Referee_discount_amount__c,Referrer_discount_amount__c,Center__r.Location__c, 
                                            Package__r.Type_of_package__c,Enrolment__c.Referred_by__r.personContactId, Package__r.Registration_Discount_Active__c, Package__r.Registration_Discount_Value__c, CreatedDate,Instrument__c, 
                                            Package__r.of_Units__c, Package__r.Package_after_Promotion__c, Package__r.Duration__c, Center__r.Country__c, Package__r.Type__c, Type__c, Class__c,
                                            Package__r.Rent_Free_Period__c,Package__r.Is_Rent_Free_Instrument_available__c, // added by nishi: 13-Feb-2021: Retail promotion for Piano rental : get instrument Retail promotion details  
                                            Package__r.Complimentary_Credit_Mins__c,Package__r.Complimentary_End_Date__c,Package__r.Complimentary_Start_Date__c,Package__r.Is_Complimentary_Credit_Available__c,// added by nishi 24-Feb-2021: Creating Complimentary Lessons: check if the package has any active complementary credit then the applicable complementary credit will be assigned.
                                            Center__r.Country__r.Name, Center__r.Country__r.Country_Name__c, Center__r.Country__r.Tax_Rate__c, Center__r.Organisation__c,Center__r.Organisation__r.name,
                                            Recordtype.name,Related_Lesson_Enrolment__c,Stage__c,
                                            (SELECT Id, Subscription__c, Enrolment__c FROM Subscription_Line_Items__r) 
                                            FROM Enrolment__c 
                                            WHERE Parent__c IN: setOfAccIds
                                            Or Student__c IN:setOfAccIds]){
                                                system.debug('enr.Stage__c'+enr.Stage__c);
                                                system.debug('enr.Package__r'+enr.Package__r);
                if(enr.Stage__c ==ConstantsClass.enroledStatus && String.isNotBlank(enr.Package__c)){
                    if(string.isnotblank(enr.Package__r.Rent_Free_Period__c) && enr.Package__r.Is_Rent_Free_Instrument_available__c){
                        regularEnrolmentList.put(enr.id,enr);
                        retailPromotionEnrolmentPackageIds.put(enr.id,enr.Package__c+'-'+enr.Package__r.Rent_Free_Period__c+'-'+enr.Instrument__c);
                    }
                }else if(enr.Recordtype.name == 'Instrument Rental' && String.isNotBlank(enr.Related_Lesson_Enrolment__c)){
                    rentalEnrolmentList.put(enr.id,enr);
                }
            }
            system.debug('regularEnrolmentList'+regularEnrolmentList);
            system.debug('retailPromotionEnrolmentPackageIds'+retailPromotionEnrolmentPackageIds);
            system.debug('rentalEnrolmentList'+rentalEnrolmentList);
            if(regularEnrolmentList != null && regularEnrolmentList.size()> 0){
                if(rentalEnrolmentList != null && rentalEnrolmentList.size()>0){
                    for(Enrolment__c objEnr : rentalEnrolmentList.values()){
                        if(regularEnrolmentList.containsKey(objEnr.Related_Lesson_Enrolment__c)){
                            retailPromotionEnrolmentPackageIds.remove(objEnr.Related_Lesson_Enrolment__c);
                        }
                    }
                }
                system.debug('retailPromotionEnrolmentPackageIds'+retailPromotionEnrolmentPackageIds);
                if(retailPromotionEnrolmentPackageIds != null && retailPromotionEnrolmentPackageIds.size() > 0){
                    isSucess = true;
                    PageReference pageRef = new PageReference('/apex/SearchInstrumentRental_Ipad2?&isOssia='+isOssiaOrg);
                    // added  by nishi: 13-Feb-2021: New Requirement Retail promotion for Piano rental: Once the payment is completed for these specific instruments -> New Dynamic Public Page where parents can decide if they would like to take up the rental
                    string retailPromotionEnrolmentId ='';
                    decimal packageTime = 0 ;
                    // 15-Feb-2021: Nishi: If we enroll two enrolment at the same time, then we considered that enrollment is the maximum time for free rental.
                    for(string enrolmentId : retailPromotionEnrolmentPackageIds.keyset()){
                        decimal enrolmentFreeRentalTime = decimal.valueof(retailPromotionEnrolmentPackageIds.get(enrolmentId).split('-')[1].trim());
                        if(packageTime < enrolmentFreeRentalTime){
                            packageTime = enrolmentFreeRentalTime;
                            retailPromotionEnrolmentId = enrolmentId;
                        }
                    } 
                    if(string.isnotBlank(retailPromotionEnrolmentId) && retailPromotionEnrolmentPackageIds.containsKey(retailPromotionEnrolmentId)){
                        pageRef.getParameters().put('enrolment', retailPromotionEnrolmentId);
                        pageRef.getParameters().put('package',retailPromotionEnrolmentPackageIds.get(retailPromotionEnrolmentId).split('-')[0].trim());
                        pageRef.getParameters().put('instrumentName',retailPromotionEnrolmentPackageIds.get(retailPromotionEnrolmentId).split('-')[2].trim());
                    }
                    pageRef.getParameters().put('AureusNewEnolment', 'true');
                    pageRef.getParameters().put('parentId', String.valueOf(parentAcc.Id));
                    return pageRef.setRedirect(true);
                }else{
                    isError = true;        
                    errorMsg ='Parent have already used Promotional Rental for all new enrollments!..';
                }
            }else{
                isError = true;        
                errorMsg ='No Enrolment Found for Promotional Rental!..';
            }                                    
        }
        return null;
    }

   
}
