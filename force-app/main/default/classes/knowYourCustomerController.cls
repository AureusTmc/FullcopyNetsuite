public without sharing class knowYourCustomerController{
    String id;
    public String parentPhoneNumber{get;set;}
    public Boolean isError{get;set;}
    public String  errorMsg{get;set;}
    //public String test{get;set;}
    public String parentid{get;set;}      
    public StudentWrapper studentWrap{get;set;}
    public List<StudentWrapper> studentWrapList{get;set;}
    //public List<parentStudentWrapper> parentStudentWrapperList{get;set;}
    public parentStudentWrapper parentStudentWrap{get;set;}
    public knowYourCustomerController(){        
        studentWrapList = new List<StudentWrapper>();
        //getStudentdateofbirth = new map<String,String>();
        //parentStudentWrapperList = new List<parentStudentWrapper>();        
        parentStudentWrap = new parentStudentWrapper();
        id = ApexPages.currentPage().getParameters().get('id');
        String parentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();                 
        //String studentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.studentRecTypeName).getRecordTypeId();         
        if(String.isNotBlank(id)){
            List<Account> parentAccDetail = [select id,firstname,lastname,personemail,personmobilephone,phone,gender__c,nationality__c,BillingStreet,BillingCity,BillingPostalCode,BillingCountryCode,customer_password__c from account where id =: id AND recordtypeid =: parentRecordTypeId];
            if(parentAccDetail.size() > 0){
                    Account parentAcc = parentAccDetail.get(0);
                    if(String.isNotBlank(parentAcc.customer_password__c)){
                        errorMsg = 'The validity of your Unique Link has been expired!';
                        isError = true;        
                    }else{
                        parentStudentWrap = new parentStudentWrapper(parentAcc.firstname,parentAcc.lastname,parentAcc.phone,parentAcc.gender__c,parentAcc.nationality__c,parentAcc.BillingStreet,parentAcc.BillingCity,parentAcc.BillingPostalCode,parentAcc.BillingCountryCode,parentAcc.personemail,'','','');
                        parentid = parentAcc.id;
                        system.debug('###'+parentAcc);
                        parentStudentWrap.parentDetail =  parentAcc;           
                        List<Account> studentAccDetail = [select id,firstname,lastname,personbirthdate,gender__c,nationality__c,school__c from account where parent__c =: parentAcc.id AND recordtypeid =: parentRecordTypeId];                
                        if(studentAccDetail.size() > 0){                
                            for(Account aObj : studentAccDetail){
                                studentWrap = new StudentWrapper();
                                //Date stuBirth = aObj.personbirthdate != null ? aObj.personbirthdate : null;
                                if(aObj.personbirthdate != null){
                                    Date stuBirth = aObj.personbirthdate;
                                    studentWrap.stuAccWrap = new parentStudentWrapper(aObj.firstname,aObj.lastname,'',aObj.gender__c,aObj.nationality__c,'','','','','',aObj.id,stuBirth.day()+'/'+stuBirth.month()+'/'+stuBirth.year(),aObj.school__c);
                                }else{
                                    studentWrap.stuAccWrap = new parentStudentWrapper(aObj.firstname,aObj.lastname,'',aObj.gender__c,aObj.nationality__c,'','','','','',aObj.id,'',aObj.school__c);
                                }
                                
                                //parentStudentWrap.studentDetail.add(aObj);
                                //System.debug('###'+stuBirth.day()+'/'+stuBirth.month()+'/'+stuBirth.year());
                                //getStudentdateofbirth.put(aObj.id,stuBirth.day()+'/'+stuBirth.month()+'/'+stuBirth.year());
                                studentWrapList.add(studentWrap);
                                system.debug('!!!!'+studentWrap);
                            }
                            system.debug('****'+studentWrapList);
                            system.debug('****'+studentWrapList.size());
                        }
                        //parentStudentWrapperList.add(parentStudentWrap);
                    }    
            }else{
                errorMsg = 'Customer Account details not found! Please contact your Center Admin for login assistance.';
                isError = true;
            }
        }else{
            errorMsg = 'Customer Account details not found! Please contact your Center Admin for login assistance.';
            isError = true;
        }
        //System.debug('@@@'+parentStudentWrapperList);
        
    }
    public List<SelectOption> getAccoungGenderPicklist(){     
        return getPicklistValues('Account','Gender__c');
    }
    public List<SelectOption> getAccoungNationalityPicklist(){     
        return getPicklistValues('Account','Nationality__c');
    }
    public List<SelectOption> getAccoungBillCntryPicklist(){     
        return getPicklistValues('Account','BillingCountryCode');
    }
    public List<SelectOption> getSchoolPicklist(){     
        List<SelectOption> lstPickvals = new List<SelectOption>();        
        lstPickvals.add(new SelectOption('', '--None--'));
        
        School__c otherSch;
        for(School__c sch : [SELECT Id, Name FROM School__c ORDER BY Name  LIMIT 999]){
            if(sch.Name != 'Other')
              lstPickvals.add(new SelectOption(sch.Id, sch.Name));
            else
                otherSch = sch;
        }
        if(otherSch != null)
            lstPickvals.add(new SelectOption(otherSch.Id, otherSch.Name));
        
        return lstPickvals;
    }
    private static List<SelectOption> getPicklistValues(String ObjectApi_name,String Field_name){ 
        List<SelectOption> lstPickvals = new List<SelectOption>();        
        lstPickvals.add(new SelectOption('', '--None--'));
        
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);//From the Object Api name retrieving the SObject
        Sobject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> field_map    = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> pick_list_values   = field_map.get(Field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        
        for(Schema.PicklistEntry a : pick_list_values){ //for all values in the picklist list
            lstPickvals.add(new SelectOption(a.getValue(), a.getLabel()));
        }
        return lstPickvals;
    }
    public void updateDetail(){     
        system.debug('parent phone number = '+parentPhoneNumber); 
        try{
            Account parentaccDetail = new Account();
            //Code for update parent detail
            Account updateparentacc = new Account(id=parentid);
            updateparentacc.firstname = parentStudentWrap.firstname;
            updateparentacc.lastname = parentStudentWrap.lastName;
            updateparentacc.phone = parentPhoneNumber;
            updateparentacc.gender__c = parentStudentWrap.gender;
            updateparentacc.nationality__c = parentStudentWrap.Nationality;
            updateparentacc.BillingStreet = parentStudentWrap.Address;
            updateparentacc.BillingCity = parentStudentWrap.City;
            updateparentacc.BillingPostalCode = parentStudentWrap.BillingPostalCode;
            updateparentacc.BillingCountryCode = parentStudentWrap.BillingCountryCode;
            updateparentacc.updated_personal_details__c = true;
            update updateparentacc;
            //code for update student detail
            List<Account> studentListForUpdate = new List<Account>();
            for(StudentWrapper sWrap : studentWrapList){
                Account stuObj = new Account(id=sWrap.stuAccWrap.studentid);
                stuObj.firstname = sWrap.stuAccWrap.firstname;
                stuObj.lastname = sWrap.stuAccWrap.lastname;
                stuObj.personbirthdate = Date.parse(sWrap.stuAccWrap.studentdateofbirth);
                stuObj.gender__c = sWrap.stuAccWrap.gender;
                stuObj.Nationality__c = sWrap.stuAccWrap.Nationality;
                stuObj.school__c = sWrap.stuAccWrap.studentschool;
                //stuObj.updated_personal_details__c = true;
                studentListForUpdate.add(stuObj);            
            }
            if(studentListForUpdate.size() > 0){
                update studentListForUpdate;
            }
        }catch(Exception e){} 
    }
    
    public void fetchFullAddress(){
        string postalCode = Apexpages.currentPage().getParameters().get('postalCode');
        parentStudentWrap.Address = '';
        parentStudentWrap.BillingCountryCode = '';
        parentStudentWrap.City = '';
        if(String.isNotBlank(postalCode)){
            for(Postal_code__c code : [SELECT Id, Name, BuildingNo__c, Country__r.Name, Country__r.Country_Name__c, Street_Name__c, Building_Name__c 
                                       FROM Postal_code__c 
                                       WHERE Name =: postalCode LIMIT 1]){
                if(String.isNotBlank(id)){
                    parentStudentWrap.Address = (String.isNotBlank(code.BuildingNo__c)) ? code.BuildingNo__c + ', ': '';
                    parentStudentWrap.Address += (String.isNotBlank(code.Building_Name__c)) ? code.Building_Name__c + ', ': '';
                    parentStudentWrap.Address += (String.isNotBlank(code.Street_Name__c)) ? code.Street_Name__c: '';
                   // enrolDetails.parent.country = code.Country__c;
                    parentStudentWrap.BillingCountryCode = code.Country__r.Name;
                    parentStudentWrap.City = code.Building_Name__c;
                    parentStudentWrap.BillingPostalCode = code.Name;
                    
                }
            }
        }    
    }
    
    public class parentStudentWrapper{
        public String firstName{get;set;}
        public String lastName{get;set;}
        public String Phone{get;set;}
        public String gender{get;set;}
        public String Nationality{get;set;}
        public String Address{get;set;}
        public String City{get;set;}
        public String BillingPostalCode{get;set;}
        public String BillingCountryCode{get;set;}
        public String parentemail{get;set;}
        
        public String studentid{get;set;}
        public String studentdateofbirth{get;set;}
        public String studentschool{get;set;}
        public Account parentDetail{get;set;}        
        
        //public List<Account> studentDetail{get;set;}
        public parentStudentWrapper(){}
        public parentStudentWrapper(String firstName,String lastname,String Phone,String gender,String Nationality,String Address,String City,String BillingPostalCode,String BillingCountryCode,String parentemail,String studentid,String studentdateofbirth,String studentschool){
            this.firstName = firstName;
            this.lastName = lastName;
            this.Phone = Phone;
            this.gender = gender;
            this.Nationality = Nationality;
            this.Address = Address;
            this.City = City;
            this.BillingPostalCode = BillingPostalCode;
            this.BillingCountryCode = BillingCountryCode;
            this.parentemail = parentemail;
            this.studentid = studentid;
            this.studentdateofbirth = studentdateofbirth;
            this.studentschool = studentschool;
            //studentDetail = new List<Account>();            
        }
    }
    public class StudentWrapper{
        public parentStudentWrapper stuAccWrap{get;set;}
        public StudentWrapper(){
            stuAccWrap = new parentStudentWrapper();            
        }
    }
}