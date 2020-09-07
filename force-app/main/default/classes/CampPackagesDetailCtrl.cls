/**
 * name: CampPackagesDetailCtrl
 * date: 1-Feb-2020
 * Autho : jatin
 * desctiption: this controller show camp package details according to seleted camp Id
 * 
 */
public class CampPackagesDetailCtrl {
    Public String campId {get;set;} 
    public Account accountStudentObj{get;set;}
    public string stuPreExperience{get;set;}
    public string birthDate{get;set;}
    public boolean showDiscountAlert{get;set;}
    //Arpit/Junied 27-Aug-2020
    public boolean isOssia {get;set;}
    
    public CampPackagesDetailCtrl() {
        accountStudentObj = new Account();
        system.debug('is ossia -->'+ ApexPages.currentPage().getParameters().get('org'));
        //Arpit/Junied 27-Aug-2020
        isOssia = false;
        //Juneid 28 Aug 2020 Orgnization wise logic as per new Requierment
        if(String.isNotBlank(ApexPages.currentPage().getParameters().get('org'))){
            isOssia = ApexPages.currentPage().getParameters().get('org').equalsIgnoreCase('ossia') ? true : false;
        }
    }
    public Camp__c getCampDetails(){
        Camp__c campObj = new Camp__c ();
        system.debug('campId'+campId);
        showDiscountAlert = false;
        if(String.isNotBlank(campId)){
            List<Camp__c> listOfCamp = CampClassUtilityController.getCampList('',campId,'',new set<string>());
            if(listOfCamp != null && listOfCamp.size() > 0){
                campObj = listOfCamp[0];
                /*start : jatin: 4-mar-2020: When registerring for the camp, there should be a text above the packages for the early bird discount 
                                    then show alert. However, when the early bird discount does not apply, the text should not be appearing.*/
                if(system.today() >= campObj.Early_Bird_Start_Date__c && system.today() <= campObj.Early_Bird_End_Date__c 
                && campObj.Early_Bird_Discount__c != null &&  campObj.Early_Bird_Discount__c  > 0){
                    showDiscountAlert = true;
                } 
                /*end : jatin: 4-mar-2020: When registerring for the camp, there should be a text above the packages for the early bird discount 
                                    then show alert. However, when the early bird discount does not apply, the text should not be appearing.*/
            }
            
        }
        return campObj;
    }
    // get gender picklist
    public List<SelectOption> getAccoungGenderPicklist(){     
        return CampClassUtilityController.getPicklistValues('Account','Gender__c');
    }
   
}