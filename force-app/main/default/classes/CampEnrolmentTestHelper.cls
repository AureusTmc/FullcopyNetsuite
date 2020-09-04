/**
* Name: CampEnrolmentTestHelper
* Author: Jatin
* Date : 11-March-2020
* Description: this helper class Used to help in all camp test classes
*/
public class CampEnrolmentTestHelper {
     
    public static void createCampData(){
        
        //Create Country Records
        Country__c objCountry = AureusCalendarControllerTestHelper.createCountryRecord ('Singapore','SGD',true);
        
        // Create 2 Centre
        List<Account> ListCentre = new List<Account>();
        ListCentre.add(AureusCalendarControllerTestHelper.createCentre('Aureus Northpoint', objCountry.Id,FALSE));
        ListCentre.add(AureusCalendarControllerTestHelper.createCentre('Aureus AMK Hub', objCountry.Id,FALSE));
        insert ListCentre; 
        
        // Add Customers
        List<Account> listOfCustomerAccount = new List<Account> ();
        listOfCustomerAccount.add(TestUtil.createAccount('Customer',True,false));
        listOfCustomerAccount.add(TestUtil.createAccount('Customer',false,false));
        
        listOfCustomerAccount[0].Centre_Name__c = ListCentre[0].Id;
        listOfCustomerAccount[0].PersonEmail = 'test1@tmc.com';
        listOfCustomerAccount[0].PersonBirthdate=date.newInstance(1995, 01, 01);
        listOfCustomerAccount[0].Gender__c ='Male';
        listOfCustomerAccount[1].Centre_Name__c = ListCentre[1].Id;
        listOfCustomerAccount[1].PersonEmail = 'test2@tmc.com';
        listOfCustomerAccount[1].PersonBirthdate=date.newInstance(1995, 01, 01);
        listOfCustomerAccount[1].Gender__c ='Male';
        insert listOfCustomerAccount;
        
        // Create Program 
        Program__c objProg=TestUtil.createProgram('Active','Piano',true);
        
        // Create Package 
        List<Package__c> listOfPackage =new List<Package__c>();
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[0].id,'30','Camp',False)); 
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[1].id,'60','Camp',False));
        insert listOfPackage;
        
         // Create  Teachers 
        List<Account> ListOfTeacherAccount = new List<Account>();
        ListOfTeacherAccount.add(testUtil.createAccount('Teacher',false,False));
        ListOfTeacherAccount.add(testUtil.createAccount('Teacher',false,False));
        ListOfTeacherAccount.add(testUtil.createAccount('Teacher',false,False));
        Insert ListOfTeacherAccount; 
        
         // Create Teacher Working Hours 
        List <Teacher_Working_Hour__c> listOfTeacherWorkingHours = new List <Teacher_Working_Hour__c>();
        listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(ListOfTeacherAccount[0].id,ListCentre[0].Id,True,False,7));
        listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(ListOfTeacherAccount[1].id,ListCentre[1].Id,True,False,7));
       
        //Create Camp
        list<Camp__c> lstCamps = new list<Camp__c>();
        lstCamps.add(createCamps('Test Camp1',ListCentre[0].id,10,'Draft',system.today(),system.today().addmonths(1)));
        lstCamps.add(createCamps('Test Camp2',ListCentre[1].id,10,ConstantsClass.campActiveStatus,system.today().addmonths(-1),system.today()));
        lstCamps.add(createCamps('Test Camp3',ListCentre[1].id,10,ConstantsClass.campActiveStatus,system.today().addmonths(1),system.today().addmonths(2)));
        insert lstCamps;
        
        //Create CampDays
        list<Camp_Days__c> lstCampDays = new list<Camp_Days__c>();
        lstCampDays.add(createCampDays(ConstantsClass.campDaysActiveStatus,lstCamps[0].id,date.newInstance(system.today().year(), system.today().month(), 18),Time.newInstance(11, 00, 00,00), Time.newInstance(14, 00, 00,00)));
        lstCampDays.add(createCampDays(ConstantsClass.campDaysActiveStatus,lstCamps[0].id,date.newInstance(system.today().year(), system.today().month(), 19),Time.newInstance(11, 00, 00,00), Time.newInstance(14, 00, 00,00)));
        lstCampDays.add(createCampDays(ConstantsClass.campDaysActiveStatus,lstCamps[1].id,date.newInstance(system.today().addMonths(1).year(), system.today().addMonths(1).month(), 10),Time.newInstance(11, 00, 00,00), Time.newInstance(14, 00, 00,00)));
        lstCampDays.add(createCampDays(ConstantsClass.campDaysActiveStatus,lstCamps[1].id,date.newInstance(system.today().addMonths(1).year(), system.today().addMonths(1).month(), 11),Time.newInstance(11, 00, 00,00), Time.newInstance(11, 30, 00,00)));
        lstCampDays.add(createCampDays(ConstantsClass.campDaysActiveStatus,lstCamps[2].id,date.newInstance(system.today().addMonths(2).year(), system.today().addMonths(2).month(), 12),Time.newInstance(13, 00, 00,00), Time.newInstance(14, 00, 00,00)));
        lstCampDays.add(createCampDays(ConstantsClass.campDaysActiveStatus,lstCamps[2].id,date.newInstance(system.today().addMonths(2).year(), system.today().addMonths(2).month(), 15),Time.newInstance(13, 00, 00,00), Time.newInstance(14, 00, 00,00)));
        insert lstCampDays;
        
       
        list<Camp_Day_Teachers__c> lstCampDayTeachers = new list<Camp_Day_Teachers__c>();
        lstCampDayTeachers.add(createCampDayTeacher(lstCampDays[0].id,ListOfTeacherAccount[0].id, Time.newInstance(11, 00, 00,00), Time.newInstance(13, 00, 00,00),ConstantsClass.campTeacherActiveStatus));
        lstCampDayTeachers.add(createCampDayTeacher(lstCampDays[0].id,ListOfTeacherAccount[1].id,Time.newInstance(13, 00, 00,00), Time.newInstance(14, 00, 00,00),ConstantsClass.campTeacherActiveStatus));
        lstCampDayTeachers.add(createCampDayTeacher(lstCampDays[1].id,ListOfTeacherAccount[0].id,Time.newInstance(11, 00, 00,00), Time.newInstance(13, 00, 00,00),ConstantsClass.campTeacherActiveStatus));
        lstCampDayTeachers.add(createCampDayTeacher(lstCampDays[1].id,ListOfTeacherAccount[1].id,Time.newInstance(13, 00, 00,00), Time.newInstance(14, 00, 00,00),ConstantsClass.campTeacherActiveStatus));
        lstCampDayTeachers.add(createCampDayTeacher(lstCampDays[2].id,ListOfTeacherAccount[0].id,Time.newInstance(11, 00, 00,00), Time.newInstance(13, 00, 00,00),ConstantsClass.campTeacherActiveStatus));
        lstCampDayTeachers.add(createCampDayTeacher(lstCampDays[2].id,ListOfTeacherAccount[1].id,Time.newInstance(13, 00, 00,00), Time.newInstance(14, 00, 00,00),ConstantsClass.campTeacherActiveStatus));
        lstCampDayTeachers.add(createCampDayTeacher(lstCampDays[3].id,ListOfTeacherAccount[0].id,Time.newInstance(11, 00, 00,00), Time.newInstance(11, 30, 00,00),ConstantsClass.campTeacherActiveStatus));
        lstCampDayTeachers.add(createCampDayTeacher(lstCampDays[4].id,ListOfTeacherAccount[1].id,Time.newInstance(13, 00, 00,00), Time.newInstance(14, 00, 00,00),ConstantsClass.campTeacherActiveStatus));
        lstCampDayTeachers.add(createCampDayTeacher(lstCampDays[5].id,ListOfTeacherAccount[0].id,Time.newInstance(13, 00, 00,00), Time.newInstance(14, 00, 00,00),ConstantsClass.campTeacherActiveStatus));
       lstCampDayTeachers.add(createCampDayTeacher(lstCampDays[0].id,ListOfTeacherAccount[0].id, Time.newInstance(11, 00, 00,00), Time.newInstance(13, 00, 00,00),ConstantsClass.campTeacherInActiveStatus));
       lstCampDayTeachers.add(createCampDayTeacher(lstCampDays[5].id,ListOfTeacherAccount[1].id, Time.newInstance(11, 00, 00,00), Time.newInstance(13, 00, 00,00),ConstantsClass.campTeacherInActiveStatus));
        
        insert lstCampDayTeachers;
        
        list<Camp_Available_Package__c>lstCampPackages = new list<Camp_Available_Package__c>();
        lstCampPackages.add(createCampPackage('1 day package',true,1,lstCamps[0].id,listOfPackage[0].id));
        lstCampPackages.add(createCampPackage('2 day package',false,2,lstCamps[0].id,listOfPackage[0].id));
        lstCampPackages.add(createCampPackage('1 day package',true,1,lstCamps[1].id,listOfPackage[1].id));
        lstCampPackages.add(createCampPackage('2 day package',false,2,lstCamps[1].id,listOfPackage[1].id));
        lstCampPackages.add(createCampPackage('1 day package',true,1,lstCamps[1].id,listOfPackage[0].id));
        lstCampPackages.add(createCampPackage('2 day package',false,2,lstCamps[1].id,listOfPackage[0].id));
        insert lstCampPackages;
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0));
        List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(ListCentre[0].Id,ListOfTeacherAccount[1].Id,listOfCustomerAccount[0].Id,listOfPackage[1].id,dt.addDays(1).format('EEEE'),'Enrolled','Camp',false));
        listOfEnrolment[0].Camp__c =lstCamps[1].id;
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(ListCentre[1].Id,ListOfTeacherAccount[1].Id,listOfCustomerAccount[1].Id,listOfPackage[1].id,dt.addDays(1).format('EEEE'),'Enrolled','Camp',false));
        listOfEnrolment[0].Camp__c =lstCamps[2].id;
        insert  listOfEnrolment;

        //Create Booking Records
        List<Booking__c> listOfcreateBooking = new List<Booking__c>();
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(Null,listOfEnrolment[0].Id,listOfCustomerAccount[0].id,ListCentre[0].Id,listOfPackage[0].id,date.newInstance(system.today().addMonths(1).year(), system.today().addMonths(1).month(), 10),'Pending','Camp Lesson','Regular',false));
        listOfcreateBooking[0].Camp_Id__c = lstCamps[1].id;
        listOfcreateBooking[0].Camp_Days__c = lstCampDays[2].id; 
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(Null,listOfEnrolment[0].Id,listOfCustomerAccount[0].id,ListCentre[0].Id,listOfPackage[0].id,date.newInstance(system.today().addMonths(1).year(), system.today().addMonths(1).month(), 11),'Scheduled','Camp Lesson','Regular',false));
        listOfcreateBooking[0].Camp_Id__c = lstCamps[1].id;
        listOfcreateBooking[0].Camp_Days__c = lstCampDays[3].id; 
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(Null,listOfEnrolment[1].Id,listOfCustomerAccount[1].id,ListCentre[1].Id,listOfPackage[1].id,date.newInstance(system.today().addMonths(1).year(), system.today().addMonths(1).month(), 12),'Pending','Camp Lesson','Regular',false));
        listOfcreateBooking[0].Camp_Id__c = lstCamps[2].id;
        listOfcreateBooking[0].Camp_Days__c = lstCampDays[4].id; 
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(Null,listOfEnrolment[1].Id,listOfCustomerAccount[1].id,ListCentre[1].Id,listOfPackage[1].id,date.newInstance(system.today().addMonths(1).year(), system.today().addMonths(1).month(), 15),'Pending','Camp Lesson','Regular',false));
        listOfcreateBooking[0].Camp_Id__c = lstCamps[2].id;
        listOfcreateBooking[0].Camp_Days__c = lstCampDays[5].id; 
        insert listOfcreateBooking; 
        
        
    }
    public static Camp__c createCamps(String campName, string centerId, Integer earlyDiscount, String campStatus,date earlyDiscountStartDate,date earlyDiscountEndDate){
        Camp__c objCamp = new Camp__c();
        objCamp.Centre__c =centerId;
        objCamp.Early_Bird_Discount__c= EarlyDiscount;
        objCamp.Early_Bird_Start_Date__c=  earlyDiscountStartDate;
        objCamp.Early_Bird_End_Date__c= earlyDiscountEndDate;
        objCamp.Maximum_Age__c= 30;
        objCamp.Camp_Description__c= 'Vaishali Nagar_1';
        objCamp.Minimum_Age__c= 18;
        objCamp.Status__c = campStatus;
        objCamp.name = campName;
        return objCamp;
    } 
    public static Camp_Days__c createCampDays(String campDaysStatus,String campId,Date campDate,time startTime,time endTime){
        Camp_Days__c objCampDays = new Camp_Days__c();
        objCampDays.Camp_Start_Time__c = startTime;
        objCampDays.Camp_End_Time__c = endTime;
        objCampDays.Dates_Of_The_Camp__c = campDate;
        objCampDays.No_of_Students_Enrolled__c = 10;
        objCampDays.Status__c = campDaysStatus;
        objCampDays.Camp_Name__c = campId;
        return objCampDays;
    }
    
    
    public static Camp_Day_Teachers__c createCampDayTeacher(String campDayId ,string teacherId,time startTime,time endTime,string status){
        Camp_Day_Teachers__c objCampDayTeacher = new Camp_Day_Teachers__c();
        objCampDayTeacher.Camp_Teacher__c = teacherId;
        objCampDayTeacher.Start_time__c = startTime;
        objCampDayTeacher.End_Time__c =  endTime;
        objCampDayTeacher.Camp_Day__c = campDayId;
        objCampDayTeacher.Status__c =status;
        return objCampDayTeacher;
    }
    
    public static Camp_Available_Package__c createCampPackage(String campPackageName,Boolean active, Decimal noOfDays,String campNameId,String campPackageId ){
        Camp_Available_Package__c  objCampPackage = new Camp_Available_Package__c();
        objCampPackage.Name = campPackageName;
        objCampPackage.Active__c = active;
        objCampPackage.No_of_days__c = noOfDays;
        objCampPackage.Camp_Name__c = campNameId;
        objCampPackage.Package__c = campPackageId;
        return objCampPackage;
    }
}