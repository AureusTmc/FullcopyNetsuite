/*
Name        :        MonthlyPaymentBatchHelperTest
Date        :        8 April 2019
Remodified  : 		 24 June 2019
Author      :        Karan Singh Soni
Description :        It is the test class of MonthlyPaymentBatchHelper.
*/

@isTest
public class MonthlyPaymentBatchHelperTest {
    public static testmethod void invokeMonthlyPaymentBatchHelper(){
        Account objCustmr=TestUtil.createAccount('Customer',True,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmr.Available_Make_up_Units__c=30;
        insert objCustmr;
		
		DateTime dt = System.today();
        
        Country__c country = new Country__c();
        country.Name = 'SG';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Account objTchr=TestUtil.createAccount('Teacher',false,true);
        //List<Teacher_working_Hour__c> listTwh=TestUtil.createTeacher_Working_Hour(objTchr.Id, objCentr.Id,true,false,7);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',true);
        Package__c objPackMakeup =TestUtil.createPackage(objProg.id,objCentr.id,'60',false);
        objPackMakeup.Type__c = 'Makeup';
        insert objPackMakeup;
        Package__c objNewPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',true);
        
        Enrolment__c objEnrol=TestUtil.createEnrolment(objCentr.id,objTchr.id,objCustmr.id,objPack.id,False);
        objEnrol.Lesson_Day__c= /*dt.format('EEEE')*/'Saturday';
        objEnrol.Stage__c='Enrolled';
        objEnrol.Package_Process_Type__c='Downgrade';
        objEnrol.Package_Process_Status__c='Pending';
        objEnrol.Effective_Date__c=Date.newInstance(System.today().year(),System.today().month(), 05);
        objenrol.New_Package_Id__c=objNewPack.id;
        objenrol.Lesson_Start_time__c = Time.newInstance(13, 00, 00, 00);
        objenrol.Lessons_Start_Date__c = System.today().addDays(-14);
        objenrol.Student__c = objCustmr.Id;
        objenrol.Parent__c = objCustmr.Id;
        insert objEnrol;
        
        //DateTime.newInstance(System.today().year(), System.today().month(), System.today().day());
        List<Booking__c> bookingList = new List<Booking__c>();
        Booking__c objBook= new Booking__c();
        objBook.Center__c=objCentr.id;
        objBook.Is_fifth_booking__c=true;
        objBook.Type__c='Regular';
        objBook.Student__c = objCustmr.Id;
        objBook.Start_Time__c = Time.newInstance(13, 00, 00, 00);
        objBook.End_Time__c =  Time.newInstance(14, 00, 00, 00);
        objBook.Booking_Date__c = System.today().addDays(7);
        objBook.Package__c = objPack.Id;
        objBook.Enrolment__c = objEnrol.Id;
        objBook.Status__c = 'scheduled';
        bookingList.add(objBook);
            
        Booking__c objBook2= new Booking__c();
        objBook2.Center__c=objCentr.id;
        objBook2.Is_fifth_booking__c=true;
        objBook2.Type__c='Regular';
        objBook2.Student__c = objCustmr.Id;
        objBook2.Start_Time__c = Time.newInstance(13, 00, 00, 00);
        objBook2.End_Time__c =  Time.newInstance(14, 00, 00, 00);
        objBook2.Booking_Date__c = System.today();
        objBook2.Package__c = objPack.Id;
        objBook2.Enrolment__c = objEnrol.Id;
        objBook2.Status__c = 'scheduled';
        bookingList.add(objBook2);
        
        Booking__c objBook3= new Booking__c();
        objBook3.Center__c=objCentr.id;
        objBook3.Is_fifth_booking__c=true;
        objBook3.Type__c='Regular';
        objBook3.Student__c = objCustmr.Id;
        objBook3.Start_Time__c = Time.newInstance(13, 00, 00, 00);
        objBook3.End_Time__c =  Time.newInstance(14, 00, 00, 00);
        objBook3.Booking_Date__c = System.today().addDays(14);
        objBook3.Package__c = objPack.Id;
        objBook3.Enrolment__c = objEnrol.Id;
        objBook3.Status__c = 'scheduled';
        bookingList.add(objBook3);
        
        Booking__c objBook4= new Booking__c();
        objBook4.Center__c=objCentr.id;
        objBook4.Is_fifth_booking__c=true;
        objBook4.Type__c='Regular';
        objBook4.Student__c = objCustmr.Id;
        objBook4.Start_Time__c = Time.newInstance(13, 00, 00, 00);
        objBook4.End_Time__c =  Time.newInstance(14, 00, 00, 00);
        objBook4.Booking_Date__c = System.today().addDays(14);
        objBook4.Package__c = objPack.Id;
        objBook4.Enrolment__c = objEnrol.Id;
        objBook4.Status__c = 'scheduled';
        bookingList.add(objBook4);

        Booking__c objBook5= new Booking__c();
        objBook5.Center__c=objCentr.id;
        objBook5.Is_fifth_booking__c=true;
        objBook5.Type__c='Regular';
        objBook5.Student__c = objCustmr.Id;
        objBook5.Start_Time__c = Time.newInstance(13, 00, 00, 00);
        objBook5.End_Time__c =  Time.newInstance(14, 00, 00, 00);
        objBook5.Booking_Date__c = System.today().addDays(7);
        objBook5.Package__c = objPack.Id;
        objBook5.Enrolment__c = objEnrol.Id;
        objBook5.Status__c = 'scheduled';
        bookingList.add(objBook5);
        insert bookingList;
        
        Invoice__C objINV=TestUtil.createInvoice(objCustmr.Id,False);
        objINV.Due_Date__c=Date.today();
        objINV.Status__c='Due';
        objINv.Admin_Fees__c=60;
        objINv.Center__c = objCentr.Id;
        insert objINV;
        
        Invoice_Line_Item__c objINVline=TestUtil.createInvLineItem(objInv.Id,false);
        objINVline.Amount__c=30;
        objINVline.Discount_Amount__c=20;
        objINVline.Is_Deposit__c=false;
        objINVline.Enrolment__c=objEnrol.id;
        objINVline.Booking__c=objBook.Id;
        insert objINVline;
        
        Invoice__C objINV2=TestUtil.createInvoice(objCustmr.Id,False);
        objINV2.Due_Date__c=Date.today();
        objINV2.Status__c='Due';
        objINv2.Admin_Fees__c=60;
        objINV2.Paid_Amount__c = 40;
        objINv.Center__c = objCentr.Id;
        insert objINV2;
        
        Invoice_Line_Item__c objINVline2=TestUtil.createInvLineItem(objInv.Id,false);
        objINVline2.Amount__c=30;
        objINVline2.Discount_Amount__c=20;
        objINVline2.Is_Deposit__c=false;
        objINVline2.Enrolment__c=objEnrol.id;
        objINVline2.Booking__c=objBook.Id;
        insert objINVline2;
        
        list<Invoice__c> listINV = [SELECT Id, Name, Due_Date__c, Status__c, Admin_Fees__c, Total_Amount__c, Parent_Account__c,
                                    Parent_Account__r.Stripe_Customer_Id__c, Subscription__c, Balance_Amount__c, Center__r.Country__r.Id,
                                    Center__r.Country__r.Currency_Code__c, Center__r.Country__r.Stripe_Base_Url__c, Center__r.Country__r.Stripe_Secret_Key__c 
                                    FROM Invoice__c WHERE Id =: new Set<String>{objINV.Id, objINVline2.Id} LIMIT 1] ;
       
        
        test.startTest();
        
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
            
            MonthlyPaymentBatchHelper.getPaymentForInvoices(listINV);
        Test.stopTest();
        
        //@Added on 24 June 2019 Karan #################################################
        MonthlyPaymentBatchHelper.getDateMap(Date.today(), Date.today().addDays(7));
        //##############################################################################
        
        /*MonthlyPaymentBatchHelper.addInvoiceLineItem(objEnrol, objINV, objBook);
        
        objBook.Status__c = 'Canceled';
        objBook.Available_Make_up_Units__c = 60;
        objBook.Make_up_Expiry_Date__c = objBook.Booking_Date__c.addDays(120);
        update objBook;
        
        Enrolment__c enrolObj = [SELECT Id, Parent__c, Parent__r.Available_Make_up_Units__c, package__r.Duration__c, Center__c, Center__r.Name, Student__c, Teacher__c, Lesson_Start_time__c FROM Enrolment__c WHERE Id =: objEnrol.Id LIMIT 1];
        
        Map<Enrolment__c, Date> enrolmentMap = new Map<Enrolment__c, Date>();
        enrolmentMap.put(enrolObj, System.today());
        MonthlyPaymentBatchHelper.createFifthBooking(enrolmentMap);
        List<Enrolment__c> enrolList = new List<Enrolment__c>();
        enrolList.add(enrolObj);
        MonthlyPaymentBatchHelper.DelBookingCancellation(enrolList);
         MonthlyPaymentBatch objMonthpay=new MonthlyPaymentBatch();
        test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        
        DataBase.executeBatch(objMonthpay);
        Test.stopTest();
        
        MonthlyPaymentBatchHelper.getParentBookingMap(enrolmentMap);
        
        MonthlyPaymentBatchHelper.getPaymentForInvoices(listINV);
        MonthlyPaymentBatchHelper.getPackageMap();*/
    }
    
    public static testmethod void invokeMonthlyPaymentBatchHelper1(){
        Account objCustmr=TestUtil.createAccount('Customer',True,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmr.Available_Make_up_Units__c=30;
        insert objCustmr;
		
		DateTime dt = System.today();
        
         Country__c country = new Country__c();
        country.Name = 'SG';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        Account objTchr=TestUtil.createAccount('Teacher',false,true);
        //List<Teacher_working_Hour__c> listTwh=TestUtil.createTeacher_Working_Hour(objTchr.Id, objCentr.Id,true,false,7);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        //Package__c objPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCentr.id,'30',true);
        Package__c objPackMakeup =TestUtil.createPackage(objProg.id,objCentr.id,'60',false);
        objPackMakeup.Type__c = 'Makeup';
        insert objPackMakeup;
        Package__c objNewPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',true);
        
        Enrolment__c objEnrol=TestUtil.createEnrolment(objCentr.id,objTchr.id,objCustmr.id,objPack.id,False);
        objEnrol.Lesson_Day__c= /*dt.format('EEEE')*/'Saturday';
        objEnrol.Stage__c='Enrolled';
        objEnrol.Package_Process_Type__c='Downgrade';
        objEnrol.Package_Process_Status__c='Pending';
        objEnrol.Effective_Date__c=Date.newInstance(System.today().year(),System.today().month(), 05);
        objenrol.New_Package_Id__c=objNewPack.id;
        objenrol.Lesson_Start_time__c = Time.newInstance(13, 00, 00, 00);
        objenrol.Lessons_Start_Date__c = System.today().addDays(-14);
        objenrol.Student__c = objCustmr.Id;
        objenrol.Parent__c = objCustmr.Id;
        insert objEnrol;
        
        //DateTime.newInstance(System.today().year(), System.today().month(), System.today().day());
        List<Booking__c> bookingList = new List<Booking__c>();
        Booking__c objBook= new Booking__c();
        objBook.Center__c=objCentr.id;
        objBook.Is_fifth_booking__c=true;
        objBook.Type__c='Regular';
        objBook.Student__c = objCustmr.Id;
        objBook.Start_Time__c = Time.newInstance(13, 00, 00, 00);
        objBook.End_Time__c =  Time.newInstance(14, 00, 00, 00);
        objBook.Booking_Date__c = System.today().addDays(7);
        objBook.Package__c = objPack.Id;
        objBook.Enrolment__c = objEnrol.Id;
        objBook.Status__c = 'scheduled';
        bookingList.add(objBook);
            
        Booking__c objBook2= new Booking__c();
        objBook2.Center__c=objCentr.id;
        objBook2.Is_fifth_booking__c=true;
        objBook2.Type__c='Regular';
        objBook2.Student__c = objCustmr.Id;
        objBook2.Start_Time__c = Time.newInstance(13, 00, 00, 00);
        objBook2.End_Time__c =  Time.newInstance(14, 00, 00, 00);
        objBook2.Booking_Date__c = System.today();
        objBook2.Package__c = objPack.Id;
        objBook2.Enrolment__c = objEnrol.Id;
        objBook2.Status__c = 'scheduled';
        bookingList.add(objBook2);
        
        Booking__c objBook3= new Booking__c();
        objBook3.Center__c=objCentr.id;
        objBook3.Is_fifth_booking__c=true;
        objBook3.Type__c='Regular';
        objBook3.Student__c = objCustmr.Id;
        objBook3.Start_Time__c = Time.newInstance(13, 00, 00, 00);
        objBook3.End_Time__c =  Time.newInstance(14, 00, 00, 00);
        objBook3.Booking_Date__c = System.today().addDays(14);
        objBook3.Package__c = objPack.Id;
        objBook3.Enrolment__c = objEnrol.Id;
        objBook3.Status__c = 'scheduled';
        bookingList.add(objBook3);
        
        Booking__c objBook4= new Booking__c();
        objBook4.Center__c=objCentr.id;
        objBook4.Is_fifth_booking__c=true;
        objBook4.Type__c='Regular';
        objBook4.Student__c = objCustmr.Id;
        objBook4.Start_Time__c = Time.newInstance(13, 00, 00, 00);
        objBook4.End_Time__c =  Time.newInstance(14, 00, 00, 00);
        objBook4.Booking_Date__c = System.today().addDays(14);
        objBook4.Package__c = objPack.Id;
        objBook4.Enrolment__c = objEnrol.Id;
        objBook4.Status__c = 'scheduled';
        bookingList.add(objBook4);

        Booking__c objBook5= new Booking__c();
        objBook5.Center__c=objCentr.id;
        objBook5.Is_fifth_booking__c=true;
        objBook5.Type__c='Regular';
        objBook5.Student__c = objCustmr.Id;
        objBook5.Start_Time__c = Time.newInstance(13, 00, 00, 00);
        objBook5.End_Time__c =  Time.newInstance(14, 00, 00, 00);
        objBook5.Booking_Date__c = System.today().addDays(7);
        objBook5.Package__c = objPack.Id;
        objBook5.Enrolment__c = objEnrol.Id;
        objBook5.Status__c = 'scheduled';
        bookingList.add(objBook5);
        insert bookingList;
        
         Invoice__C objINV=TestUtil.createInvoice(objCustmr.Id,False);
        objINV.Due_Date__c=Date.today();
        objINV.Status__c='Due';
        objINv.Admin_Fees__c=0;
        objINv.Center__c  = objCentr.Id;
        insert objINV;
        
        Invoice_Line_Item__c objINVline=TestUtil.createInvLineItem(objInv.Id,false);
        objINVline.Amount__c=0;
        objINVline.Discount_Amount__c=0;
        objINVline.Is_Deposit__c=false;
        objINVline.Enrolment__c=objEnrol.id;
        objINVline.Booking__c=objBook.Id;
        insert objINVline;
        
        list<Invoice__c> listINV = [Select Id,Name,Parent_Account__c,Parent_Account__r.PersonContactId,Parent_Account__r.Stripe_Customer_Id__c, 
                                         Total_Amount__c,subscription__c,Balance_Amount__c,Paid_Amount__c,
                                         Parent_Account__r.personEmail,Parent_Account__r.Centre_Name__r.Location__c,
                                         Center__r.Country__c, Center__r.Country__r.Id, Center__r.Country__r.Tax_Rate__c, 
                                         Center__r.Country__r.Currency_Code__c, Center__r.Country__r.Stripe_Base_Url__c, 
                                         Center__r.Country__r.Stripe_Secret_Key__c FROM Invoice__c WHERE Id =: objINV.Id LIMIT 1] ;
       
        
        //test.startTest();
        
            //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(201,'{"paid": true}'));
            
            MonthlyPaymentBatchHelper.getPaymentForInvoices(listINV);
        //Test.stopTest();
    }
    
    
}