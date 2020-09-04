/*
Name        :        TestUtil
Date        :        8 April 2019
Author      :        Karan Singh Soni
Remodified  :		 24 June 2019
Description :        It is the test factory class for test classes.
*/
@isTest
public class TestUtil{
    
    public static void init(){
        Account objAcc = createAccount('Center',false,true);
    }
    
    public static Account createAccount(String recTypeName,Boolean alsoStudnt,Boolean isDML){
        
        Account objAcc = new Account();
        string s=Schema.SObjectType.Account.getRecordTypeInfosByName().get(recTypeName).getRecordTypeId();
        
        if(s!=null){
            
            objAcc.RecordTypeId =s; 
            if(recTypeName=='Teacher'){
                
                objAcc.LastName='testTeacher';
                objAcc.Teacher_Bio__c='testbio';
                objAcc.CentreName_Cust__c='Aureus Eastpoint';
                objAcc.Status__c='Working';   
                objAcc.Major_Instruments_Disciplines__c='Piano';
                objAcc.Minor_Instruments_Disciplines__c='Piano';
            }
            if(recTypeName=='Customer'){
                
                objAcc.LastName='Teacher';
                objAcc.FirstName='test';
                objAcc.PersonEmail='testEmail@gmail.com';
                objAcc.Also_a_Student__c=alsoStudnt;
                objAcc.PersonMobilePhone='23456789';
            }
            if(recTypeName=='Centre'){
                
                objAcc.name='Aureus Eastpoint';
                objAcc.CentreName_Cust__c='Aureus Eastpoint'; 
                objAcc.Travel_Time__c=60.00;
                objAcc.Location__c='Aureus Eastpoint';
                //objAcc.PersonEmail='TestCentermail@gmail.com';
                objAcc.Center_Email__c='rajesh@techmatrixconsulting.com';
                //objAcc.PersonMobilePhone='1234';
            }
            // set values here
            if(isDml){
                insert objAcc;
            }
            
        }
        return objAcc;
    }
    public static list<Teacher_Working_Hour__c> createTeacher_Working_Hour(Id teacherId, Id centerId, Boolean isDml,boolean breakT,integer recordSize){
        list<Teacher_Working_Hour__c> listTwh=new List<Teacher_Working_Hour__c>();
        for(integer i=1;i<=recordSize;i++){
            Teacher_Working_Hour__c tw = new Teacher_Working_Hour__c();
            tw.Active__c = true;
            tw.Break_Time__c=breakT;
            tw.Teacher_Name__c=teacherId;
            tw.Center_Name__c=centerId;
            tw.Working_Day__c=i==1?'mon':i==2?'tue':i==3?'wed':i==4?'thu':i==5?'fri':i==6?'sat':'sun';
            tw.Start_Time__c=Time.newInstance(7,0,0,0);
            tw.End_Time__c=Time.newInstance(23,0,0,0);
            
            listTwh.add(tw);
        }
        
        if(isDml){
            insert listTwh;          
        }
        return listTwh;
        
    }
    
    public static Enrolment__c createEnrolment(Boolean isDML){
        
        Enrolment__c enrol=new Enrolment__c();
        enrol.Stage__c='requested';
        enrol.Type__c='trial';
        
        if(isDML){
            insert enrol;
        }
        
        return enrol;
    }
    public static void updateEnrolment(Id enrolId,Boolean isDML){
        
        Enrolment__c enrol=new Enrolment__c(id=enrolId);
        enrol.Stage__c='Cancelled';
        enrol.Type__c='trial';
        
        if(isDML){
            update enrol;
        }
        
    }
    public static Attachment createAttachment(Id accId, Boolean isDml){
        
        Attachment objAttach= new Attachment();
        Blob dat = Blob.valueOf('Test Blob');
        objAttach.Name='Profile Image';
        objAttach.ContentType='image/png';
        objAttach.ParentId=accId;
        objAttach.Body=dat;
        
        if(isDML){
            insert objAttach;
        }
        
        return objAttach;
    }
    public static Booking__c createBooking(Id teacherID,String recTypeName,String bookType,Boolean isDml){
        
        Booking__c objBook = new Booking__c();
        objBook.Teacher_Account__c=teacherId;
        objBook.RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(recTypeName).getRecordTypeId();
        objBook.Booking_Date__c=date.today().addDays(1);
        objBook.Start_Time__c=Time.newInstance(11,0,0,0);
        objBook.Type__c=bookType;
        objBook.Status__c='Pending';
        
        if(isDml){
            insert objBook;
        }
        return objBook;
        
    }
    
    public static Qualification__c createQualification(Id teachId,String progName,string qual,Boolean isDml){
        Qualification__c quali = new Qualification__c();
        quali.Teacher__c=teachId;
        quali.Programme_Name__c=progName;
        quali.Qualification__c=qual;
        
        if(isDml)
            insert quali;
        return quali;  
    }
    
    public static Program__C createProgram(string isActive, string slcdinstrument, boolean IsDml){
        Program__c prog =new Program__C();
        prog.Name='testProg';
        prog.Status__c=isActive;
        prog.Instrument__c=slcdinstrument;
        prog.Billing__c='Monthly';
        prog.Scheduling__c='Monthly';
        if(isDml)
            insert prog;
        
        return prog;
    }
    
    public static Package__c createPackage(Id progId, Id centrId,String Duration,Boolean isDml){
        Package__c pack=new Package__c();
        pack.Name='Piano';
        pack.Program__c=progId;
        pack.Location__c=centrId;
        pack.Duration__c=Duration;
        pack.Package_Fee__c=05.00;
        pack.Active__c=true;
        pack.Unit_Fee__c=05.00;
        pack.Registration_Fee__c=08.00;
        pack.Deposit_Fee__c=08.00;
        
        if(isDml){
            insert pack; 
        }
        return pack;
    }    
    public static Resource__c createResource(Id centrId,string studID,id packId,Boolean isDml){
        Resource__c objRes=new Resource__c();
        objRes.Name='TestResource';
        objRes.Studio_Id__c=studId;
        objRes.Center__c=centrId;
        objRes.Capacity__c=60;
        objRes.Type__c='ABRSM';
        objRes.Status__c='Available';
        
        objRes.Package__c=packId;
        
        if(isDml){
            insert objRes; 
        }
        return objRes;
    }    
    public static list<Resource_Working_Hour__c> createResource_Working_Hour(Id centerId,id resID, Boolean isDml,boolean isactive,integer recordSize){
        list<Resource_Working_Hour__c> listobjRWh=new List<Resource_Working_Hour__c>();
        for(integer i=1;i<=recordSize;i++){
            Resource_Working_Hour__c objRWh = new Resource_Working_Hour__c();
            objRWh.Active__c =isactive;
            objRWh.Center_Name__c=centerId;
            objRWh.Working_Day__c=i==1?'mon':i==2?'tue':i==3?'wed':i==4?'thu':i==5?'fri':i==6?'sat':'sun';
            objRWh.Start_Time__c=Time.newInstance(9,0,0,0);
            objRWh.End_Time__c=Time.newInstance(23,0,0,0);
            objRWh.Resource_Name__c=resID;
            listobjRWh.add(objRWh);
        }
        
        if(isDml){
            
            insert listobjRWh;          
        }
        
        return listobjRWh;
        
    }
    public static Booking__c createStudioBooking(id ResId,Id cntrId,string sType,Boolean isDml){
        Booking__c objBook=new Booking__c();
        objBook.Resource__c=resId;
        objBook.Center__c=cntrId;
        objBook.Booking_Date__c=date.today().addDays(1);
        
        objBook.Start_Time__c=Time.newInstance(11,0,0,0);
        objbook.End_Time__c=Time.newInstance(12,0,0,0);
        
        
        
        if(isDml){
            
            insert objBook;
            //system.debug('center'+[select Resource__r.Center__c from Booking__c where id=:objBook.id].resource__r.Center__c);
        }
        return objBook;
    }
    
    public static Enrolment__c createEnrolment(string cntrId,string tchrId,String custmrId,String packId,boolean isDml){
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(11,0,0,0));
        Enrolment__c objEnrol = new Enrolment__c();
        objEnrol.Center__c=cntrId;
        objEnrol.Teacher__c=tchrId;
        objEnrol.Package__c=packId;
        objEnrol.Student__c=custmrId;
        objEnrol.Parent__c=custmrId; 
        objEnrol.Trial_Date__c=date.today().addDays(1);
        objEnrol.Trial_Start_Time__c=Time.newInstance(11,0,0,0);
        objEnrol.Lesson_Start_time__c=Time.newInstance(11,0,0,0);
        objEnrol.Lessons_Start_Date__c=date.today().addDays(1);
        objEnrol.Lesson_Day__c = 'Wednesday';
        objEnrol.Type__c='Regular';
        if(isDml)
            insert objEnrol;
        return objEnrol;
    }
    public Static School__c createSchool(Boolean isDml){
        School__c objSch=new School__c();
        objSch.Name='TestSchool';
        if(isDml)
            insert objSch;
        return objSch;
        
    }
    
    public static Lead createLead(string Locatn,string leadsrc,string email,id cntrId,boolean isDml){
        lead objLead=new lead();
        objLead.LastName='leadLastName';
		objLead.Location__c=Locatn;
		objLead.LeadSource=leadsrc;
        objLead.Email=email;
        objLead.Center__c=cntrId;
        if(isDml)
            insert objLead;
        return objLead;
    }
    
    public static invoice__c createInvoice(String prntCustrID,Boolean IsDml){
        invoice__c objINV=new invoice__c();
        objINV.Parent_Account__c=prntCustrID;
        objINV.Invoice_Date__c=date.today();
        objINV.Due_Date__c=date.today().addDays(30);
        objINV.Center__c= TestUtil.createAccount('Centre',False,true).id;
        if(isDml)
            insert objINV;
        return objINV;
        
    }
    
    public static Invoice_Line_Item__c createInvLineItem(String invId,boolean IsDml){
        Invoice_Line_Item__c objInvLineItm = new Invoice_Line_Item__c();
        objInvLineItm.Invoice__c=invId;
        objInvlineItm.Amount__c=20;
        objInvlineItm.Currency_Code__c = 'SGD';
        if(IsDml)
            insert objInvlineItm;
        return objInvLineItm;
    }
    public static Subscription__C createSubscription(string custmrId,Boolean isDml){
        Subscription__C objSubs=new Subscription__C();
        objSubs.Parent__c=custmrId;
        if(isDml)
            insert objSubs;
        return objSubs;
        
    }
    
    public static Subscription_Line_Item__c createSubscriptionLineItem(string subscriptId,Boolean isDml){
	Subscription_Line_Item__C objSLI=new Subscription_Line_Item__C();
    objSLI.Subscription__c=subscriptId;
    return objSLI;    
    }
    public static list<Center_Working_Hours__c> createCenter_Working_Hours(Id centerId, Boolean isDml,integer recordSize){
        list<Center_Working_Hours__c> listCwh=new List<Center_Working_Hours__c>();
        for(integer i=1;i<=recordSize;i++){
            Center_Working_Hours__c cw = new Center_Working_Hours__c();
            cw.Active__c = true;
            cw.Center_Name__c=centerId;
            cw.Working_Day__c=i==1?'mon':i==2?'tue':i==3?'wed':i==4?'thu':i==5?'fri':i==6?'sat':'sun';
            cw.Start_Time_1st_Shift__c=Time.newInstance(7,0,0,0);
            cw.End_Time_1st_Shift__c=Time.newInstance(12,0,0,0);
            cw.Start_Time_2nd_Shift__c=Time.newInstance(13,0,0,0);
            cw.End_Time_2nd_Shift__c=Time.newInstance(23,0,0,0);
            
            listCwh.add(cw);
        }
        
        if(isDml){
            insert listCwh;          
        }
        return listCwh;
        
    }
    
    public static list<Resource_Working_Hour__c> createResource_Working_Hour(Id centerId,Id resId ,Boolean isDml,integer recordSize){
        list<Resource_Working_Hour__c> listRwh=new List<Resource_Working_Hour__c>();
        for(integer i=1;i<=recordSize;i++){
            Resource_Working_Hour__c rw = new Resource_Working_Hour__c();
            rw.Active__c = true;
            rw.Center_Name__c=centerId;
            rw.Resource_Name__c=resId;
            rw.Working_Day__c=i==1?'mon':i==2?'tue':i==3?'wed':i==4?'thu':i==5?'fri':i==6?'sat':'sun';
            rw.Start_Time__c=Time.newInstance(7,0,0,0);
            rw.End_Time__c=Time.newInstance(23,0,0,0);
            listRwh.add(rw);
        }
        
        if(isDml){
            insert listRwh;          
        }
        return listRwh;
        
    }
    public static user createUser(Boolean isDml){
        user objUser=new user();
        objUser.LastName='CenterUserTest';
        objUser.Username='Centerusermail@gmail.com';
        objUser.Email='Centerusermail@gmail.com';
        objUser.Alias='Center';
		objuser.CommunityNickname='centerUserCommunityNickname';
		objUser.TimeZoneSidKey='Asia/Singapore';    
        objUser.LocaleSidKey='en_SG';
        objUser.EmailEncodingKey='UTF-8';
        objUser.ProfileId=Userinfo.getProfileId();
		objUser.LanguageLocaleKey='en_US';
        if(isDml)
        insert objUser;
        
        return objUser;
    }
    
    public static Centre_Users__c createCentreUser(Boolean isDML){
        Centre_Users__c cntrUsr = new Centre_Users__c();
        cntrUsr.Designation__c='Centre Admin';
        cntrUsr.Centre_Name__c = TestUtil.createAccount('Centre', false, true).id;
        if(isDML)
            insert cntrUsr;
            
        return cntrUsr;
        
    }
    public static Case createCase(Boolean isDml){
        Case objCase= new Case();
        objCase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId();
        Account objCust =  Testutil.createAccount('Customer',true, false);
        objCust.personEmail = 'test@xml.com'+System.now().getTime();
        insert objCust;
        objCase.AccountId= objCust.id;
        objCase.ContactId=new Contact().id;
        objCase.Status='New';
        objCase.Origin='Email';
        objCase.SuppliedEmail='testEmail@gmail.com';
        system.debug('objcase.AccountId'+objcase.AccountId);
        if(isDml)
            insert objCase;
        return objCase;
    }
    //@Added on 24 June 2019 Karan
    //Creating payment object
    public static Payment__c createPayment( Id prntId, Boolean isDml){
        Payment__c objpay = new Payment__c();
        objPay.Parent_Account__c = prntId;
        objPay.Transaction_ID__c = 'ch_1ElCr3Jja9IPifcSADDUXp23';
        objPay.Payment_Amount__c = 0;
        if(isDml)
            insert objPay;
        return objPay;
    }
    
    public static Map<String,String> createData(){
        Country__c countryObj = new Country__c();
        countryObj.Name='SG';
        countryObj.Country_Name__c='Singapore';
        countryObj.Tax_Rate__c=7.00;
        insert countryObj;
        
        Map<String,String> createdDataMap= new Map<String,String>();
        Account objCustmr=createAccount('Customer',true,true);
        createdDataMap.put('objCustmr',objCustmr.id);
        
        Account objCentr=createAccount('Centre',false,false);
        objCentr.Country__c=countryObj.Id;
        objCentr.Centre_Status__c='Active';
        insert objCentr;
        createdDataMap.put('objCentr',objCentr.id);
        
        Account objTchr=createAccount('Teacher',false,true);
        createdDataMap.put('objTchr',objTchr.id);
        
        List<Teacher_working_Hour__c> listTwh=createTeacher_Working_Hour(objTchr.Id, objCentr.Id,true,false,7);
        
        
        Program__C objProg=createProgram('Active','Piano',true);
        createdDataMap.put('objProg',objProg.id);
        
        Package__c objPack=createPackage(objProg.id,objCentr.id,'60',true);
        createdDataMap.put('objPack',objPack.id);
        
        Enrolment__c objEnrol=createEnrolment(objCentr.Id,objTchr.Id,objCustmr.id,objPack.Id,true);
        createdDataMap.put('objEnrol',objEnrol.id);
        
        School__c objSch=createSchool(True);
        createdDataMap.put('objSch',objSch.id);
        
        Booking__C objBook=createBooking(objTchr.Id,'Lesson','Regular',True);
        createdDataMap.put('objBook',objBook.id);
            
        return createdDataMap;
        
    }
    
    
}