@isTest
public class MobileAppUtility {
    @isTest
    public static void init(){
        String centreRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId();
        String customerRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        String packageLessonRecTypeId = Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        String teacherRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        String bookingLessonRecTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        String caseLessonRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId();
        
        Firebase_Settings__c settings = New Firebase_Settings__c(name= 'setting',API_Key__c='Key=AAAAnpwAoa0:APA91bED0q97GSDONF-R-KvOr3ZPQM3Iid5O6Lq00ysF7XvZYwFZ8y2U6kF_loirGYtoNF6rgQPSTQFtYisty4GB_6w5xFf9cXDTRI8eXSulk6KX8cFjCgDEvf7KjnH4tu27V65Y0WEN',
                                                                 Endpoint__c='https://fcm.googleapis.com/fcm/send',Enable_Logs__c=true,Enable_Notifications__c = true);
        insert settings;
       /* Country__c objCountry = new Country__c(Tax_Rate__c =0.1,
                                               Currency_Code__c='HK', 
                                               Country_Name__c='Hong Kong',
                                               Stripe_Base_Url__c ='https://api.stripe.com',
                                               Stripe_Publishable_Key__c ='pk_test_azwvf91l2HFwuNpZer5um2VF006ikhbPbp',
                                               Stripe_Secret_Key__c ='sk_test_TkLMzwMhm5b47IgFMkL76Kb400tQa1w3KF');
        */ Country__c objCountry = new Country__c();
        objCountry.Name = 'SGD';
        objCountry.Country_Name__c = 'Singapore';
        objCountry.Tax_Rate__c = 7.0;
        objCountry.Currency_Code__c = 'SGD';
        objCountry.Student_Policies_Template_Id__c = 'test';
        objCountry.Stripe_Base_Url__c = 'www.test.com';
        objCountry.Stripe_Publishable_Key__c = 'ABC';
        objCountry.Stripe_Secret_Key__c = 'deede';

          insert objCountry; 
        Country__c objCountry2 = new Country__c();
        objCountry2.Name = 'SG';
        objCountry2.Country_Name__c = 'Singapore';
        objCountry2.Tax_Rate__c = 7.0;
        objCountry2.Currency_Code__c = 'SG';
        objCountry2.Student_Policies_Template_Id__c = 'test';
        objCountry2.Stripe_Base_Url__c = 'www.test.com';
        objCountry2.Stripe_Publishable_Key__c = 'ABC';
        objCountry2.Stripe_Secret_Key__c = 'deede';

          insert objCountry2;
        List<Account> listOfaccount = new List<Account>();
        Account centreAccount = new Account(
            Name = 'Aureus Northpoint',
            RecordTypeId = centreRecTypeId,
            Location__c = 'Aureus Northpoint',
            country__C =objCountry.id
        );
        //insert centreAccount;
        listOfaccount.add(centreAccount);
        System.debug(customerRecTypeId);
        Account customerAccount = new Account(
            LastName = 'Singh',
            FirstName = 'Sunny',
            RecordTypeId = customerRecTypeId,
            BillingStreet = '3 Simei Street 6, #04-09 & #06-04',
            BillingCity = 'Singapore',
            BillingPostalCode = '528833',
            BillingCountry = 'Singapore',
            BillingCountryCode = 'SG',
            ShippingCountry = 'Singapore',
            ShippingCountryCode = 'SG',
            Phone = '+6597865325',
            Stripe_Customer_Id__c='sk_test_BQokikJOvBiI2HlWgH4olfQ2',
            PersonMailingCountry = 'Singapore',
            PersonMailingCountryCode = 'SG',
            PersonOtherCountry = 'Singapore',
            PersonOtherCountryCode = 'SG',
            PersonMobilePhone = '+6597865325',
            PersonEmail = 'user@yahoo.com',
            Nationality__c = 'Singapore',
            Gender__c = 'Male',
            Admin_Fees_Required__c = false,
            Person_Email__c = 'user@yahoo.com',
            Travel_Time__c = 30.0,
            Also_a_Student__c = false,
            Instrument__c = 'Piano',
            Location__c ='Aureus Northpoint',
            Customer_Type__c = 'Parent',
            Card_Number__c = '3155',
            Card_Type__c = 'Visa',
            Customer_Email__c = 'user@yahoo.com',
            Customer_Password__c = '41757265757340313233', //Aureus@123
            Centre_Name__c=centreAccount.id,
            //MovedToSage__c = false,
            //CDAC_Contribution__c = false,
            //SINDA_Contribution__c = false,
           // MBMF_Contribution__c = false,
            //EUCF_Contribution__c = false,
            Profile_Pic_URL__c = 'https://aureusacademy--dev.my.salesforce.com/sfc/dist/version/download/?oid=00D0k000000Dsbn&ids=0680k000000l3Kj&d=%2Fa%2F0k00000009Kr%2Fj9MyNFsSO0SKCdoiHWyNG_RC2_i0V0nJNiqu7tMFOqM&asPdf=false',
            Booking_Reminded_Notification__c = false,
            Invoice_Paid_Notification__c = false,
            Enroled__c = false,
            pi__Needs_Score_Synced__pc = false,
            pi__pardot_hard_bounced__pc = false,
            Location_PI__pc = 'Aureus Northpoint',
            Instrument_PI__pc = 'Piano',
            Country_PI__pc = 'India');
        //insert customerAccount;
         listOfaccount.add(customerAccount);
        
        Account studentAccount = new Account(
            LastName = 'ra',
            FirstName = 'Aksha',
            RecordTypeId = customerRecTypeId,
            PersonBirthdate = Date.newInstance(2002,04,15),
            Nationality__c = 'India',
            Gender__c = 'Female',
            Parent__c = customerAccount.id,
            Travel_Time__c = 30.0,
            Also_a_Student__c = false,
            Customer_Type__c = 'Student');
        //insert studentAccount;
         listOfaccount.add(studentAccount);


         Account teacherAccount = new Account(
            LastName = 'Valenzuela',
            FirstName = 'Christeven',
            RecordTypeId = teacherRecTypeId,
            BillingCountry = 'Singapore',
            BillingCountryCode = 'SG',
            PersonEmail = 'christeven@aureusacademy.com.test',
            Status__c = 'Working',
            Admin_Fees_Required__c = false,
            Teacher_Bio__c = 'Christeven is a classical guitarist with many years of experience in  teaching students of various ages and     abilities. He graduated with a Bachelor’s Degree in Music from the University of Santo Tomas and has extensive     performing experience in classical guitar concerts and  radio broadcast performances in the Philippines. He was part of the UST Guitar Octet which performed at the Philippine Embassy in Malaysia. Christeven has competed in both the solo and ensemble category of the Tarrega    Malaysia International Classical Guitar Festival 2016, of which he emerged the 1st runner up. Christeven currently serves on the faculty of Aureus Academy as a Guitar and Ukulele teacher.',
            Major_Instruments_Disciplines__c = 'Guitar;Ukulele',
            Person_Email__c = 'christeven@aureusacademy.com.test',
            Travel_Time__c = 30.0,
            //Employee_Status__c = 'Draft',
            Minor_Instruments_Disciplines__c='Piano');
        //insert teacherAccount;
        listOfaccount.add(teacherAccount);

        Account teacherAccount2 = new Account(
            LastName = 'Valenzuela2',
            FirstName = 'Christeven',
            RecordTypeId = teacherRecTypeId,
            BillingCountry = 'Singapore',
            BillingCountryCode = 'SG',
            PersonEmail = 'christeven2@aureusacademy.com.test',
            Status__c = 'Working',
            Admin_Fees_Required__c = false,
            Teacher_Bio__c = 'Christeven is a classical guitarist with many years of experience in  teaching students of various ages and     abilities. He graduated with a Bachelor’s Degree in Music from the University of Santo Tomas and has extensive     performing experience in classical guitar concerts and  radio broadcast performances in the Philippines. He was part of the UST Guitar Octet which performed at the Philippine Embassy in Malaysia. Christeven has competed in both the solo and ensemble category of the Tarrega    Malaysia International Classical Guitar Festival 2016, of which he emerged the 1st runner up. Christeven currently serves on the faculty of Aureus Academy as a Guitar and Ukulele teacher.',
            Major_Instruments_Disciplines__c = 'Guitar;Ukulele',
            Person_Email__c = 'christeven2@aureusacademy.com.test',
            Travel_Time__c = 30.0,
            //Employee_Status__c = 'Draft',
            Minor_Instruments_Disciplines__c='Piano');
        //insert teacherAccount2;
        listOfaccount.add(teacherAccount2);
        insert listOfaccount;
        Home_Carousel__c home_carousel = new Home_Carousel__c(
            Title__c = 'Aureus Junior Conservatory Choir',
            Description__c = 'Love to sing? Designed for young singers, the Aureus Choir provides its members the chance to experience weekly, professionally conducted group choral sessions.',
            Web_URL__c = 'https://aureusacademy.com/aureus-junior-conservatory-choir',
            Image_URL__c = 'https://aureusacademy.com/aureus-junior-conservatory-choir',
            Sr_No__c = '1',
            country__C =objCountry2.id
        );
            //Unique_SR_NO__c = '1');
        insert home_carousel;
        
        Program__c program = new Program__c(
            Name = 'Guitar Lessons',
            Instrument__c = 'Guitar',
            Scheduling__c = 'Weekly',
            Status__c = 'Active',
            Type__c = 'Individual',
            Billing__c = 'Monthly');
        insert program;
        
        List<Package__c> listOfpackage = new List<Package__c>();
        Package__c packageObj = new Package__c(
            Name = 'Guitar Lessons 4x30 min',
            RecordTypeId = packageLessonRecTypeId,
            Program__c = program.id,
            Package_Fee__c = 219.63,
            Unit_Fee__c = 54.9075,
            Duration__c = '30',
            Deposit_Fee__c = 235.0,
            Registration_Fee__c = 23.36,
            of_Units__c = 4.0,
            Type__c = 'Individual',
            Active__c = true,
            Registration_Discount_Active__c = false,
            Type_of_package__c = 'Normal',
            Location__c = centreAccount.Id);
        //insert packageObj;
        listOfpackage.add(packageObj);
        // makeup package
        Package__c packageObj2 = new Package__c(
            Name = 'Guitar Lessons 4x30 min',
            RecordTypeId = packageLessonRecTypeId,
            Program__c = program.id,
            Package_Fee__c = 219.63,
            Unit_Fee__c = 54.9075,
            Duration__c = '30',
            Deposit_Fee__c = 235.0,
            Registration_Fee__c = 23.36,
            of_Units__c = 4.0,
            Type__c = 'Makeup',
            Active__c = true,
            Registration_Discount_Active__c = false,
            Type_of_package__c = 'Normal',
            Location__c = centreAccount.Id);
        //insert packageObj2;
        listOfpackage.add(packageObj2);
       Package__c packageAdhocObj = new Package__c(
            Name = 'Guitar Lessons 4x30 minAdhoc',
            RecordTypeId = packageLessonRecTypeId,
            Program__c = program.id,
            Package_Fee__c = 219.63,
            Unit_Fee__c = 54.9075,
            Duration__c = '30',
            Deposit_Fee__c = 235.0,
            Registration_Fee__c = 23.36,
            of_Units__c = 4.0,
            Type__c = 'Adhoc',
            Active__c = true,
            Registration_Discount_Active__c = false,
            Type_of_package__c = 'Normal',
            Location__c = centreAccount.Id);
        //insert packageObj;
        listOfpackage.add(packageAdhocObj);
        insert listOfpackage;

        list<Enrolment__c> listOfEnrolment = new list<Enrolment__c>();
        Enrolment__c enrolment = new Enrolment__c(
            Student__c = studentAccount.Id,
            Parent__c = customerAccount.Id,
            Description__c = 'test Pardot sync',
            Package__c = packageObj.id,
            Center__c = centreAccount.Id,
            Trial_Completed__c = false,
            Type__c = 'Regular',
            Stage__c = 'Enrolled',
            Cancellation_Policy_Agreed__c = true,
            I_want_to_receive_latest_newsletter__c = false,
            Teacher__c = teacherAccount.Id,
            Lessons_Start_Date__c = Date.newInstance(2019,07,27),
            Parent_Email__c = 'user@gmail.com',
            Lesson_Day__c = 'Saturday',
            Enrolment_Created_Date__c = DateTime.newInstance(2019,7,25,12,744,44657),
            Total_Deposit_Value__c = 235.0);
        listOfEnrolment.add(enrolment);
        
        Enrolment__c enrolment2 = new Enrolment__c(
            Student__c = studentAccount.Id,
            Parent__c = customerAccount.Id,
            Description__c = 'test Pardot sync',
            Package__c = packageObj.id,
            Center__c = centreAccount.Id,
            Trial_Completed__c = false,
            Type__c = 'Regular',
            Stage__c = 'Enrolled',
            Cancellation_Policy_Agreed__c = true,
            I_want_to_receive_latest_newsletter__c = false,
            Teacher__c = teacherAccount2.Id,
            Lessons_Start_Date__c = Date.newInstance(2019,07,27),
            Parent_Email__c = 'user@gmail.com',
            Lesson_Day__c = 'Saturday',
            Enrolment_Created_Date__c = DateTime.newInstance(2019,7,25,12,744,44657),
            Total_Deposit_Value__c = 235.0
        );
        //insert enrolment2;
        listOfEnrolment.add(enrolment2);
        insert listOfEnrolment;
        //insert enrolment;
        
        List<Booking__c> listofBooking = new List<Booking__c>();
         Booking__c bookingCancel = new Booking__c(
            RecordTypeId = bookingLessonRecTypeId,
            Teacher_Account__c = teacherAccount.Id,
            Start_Time__c = time.newInstance(15, 00,00, 00) ,
            End_Time__c = time.newInstance(16, 00,00, 00),
            Status__c = 'Canceled',
            Student__c = studentAccount.id,
            Type__c = 'Regular',
            Booking_Date__c = Date.newInstance(2019,07,08),
            Package__c = packageObj.Id,
            Enrolment__c = enrolment.Id,
            Cancellation_Reason__c = 'Teacher MC',
            Center__c = centreAccount.Id,
            Individual_Booking__c = false,
            Is_fifth_booking__c = false,
            Canceled_By__c = 'ArpitVijay',
            Canceled_Date__c = DateTime.newInstance(2019,3,7,10,602,36146),
            Parent__c = customerAccount.Id,
            Booking_Time_Text__c = 'Wed,Jul 8 2020 at 3:30 PM',
            Is_Reschedule_Booking__c = false,
            Parent_Email__c = 'user@gmail.com',
         Available_Make_up_Units__c = 30);
        listofBooking.add(bookingCancel);
        
        //insert bookingCancel;
        Booking__c bookingSchedule = new Booking__c(
            RecordTypeId = bookingLessonRecTypeId,
            Teacher_Account__c = teacherAccount.Id,
            Start_Time__c = time.newInstance(15, 00,00, 00) ,
            End_Time__c = time.newInstance(16, 00,00, 00),
            Status__c = 'Scheduled',
            Student__c = studentAccount.id,
            Type__c = 'Regular',
            Booking_Date__c = system.today().addDays(-1),
            Package__c = packageObj.Id,
            Enrolment__c = enrolment.Id,
            Center__c = centreAccount.Id,
            Individual_Booking__c = false,
            Is_fifth_booking__c = false,
            Parent__c = customerAccount.Id,
            Booking_Time_Text__c = 'Wed,Jul 8 2020 at 3:30 PM',
            Is_Reschedule_Booking__c = false,
            Parent_Email__c = 'user@gmail.com');
        listofBooking.add(bookingSchedule);
        
        //insert bookingSchedule;
         Booking__c bookingPending = new Booking__c(
            RecordTypeId = bookingLessonRecTypeId,
            Teacher_Account__c = teacherAccount.Id,
            Start_Time__c = time.newInstance(15, 00,00, 00) ,
            End_Time__c = time.newInstance(16, 00,00, 00),
            Status__c = 'Pending',
            Student__c = studentAccount.id,
            Type__c = 'Regular',
            Booking_Date__c = System.today().addDays(2),//Date.newInstance(2020,07,08),
            Package__c = packageObj.Id,
            Enrolment__c = enrolment.Id,
            Center__c = centreAccount.Id,
            Individual_Booking__c = false,
            Is_fifth_booking__c = false,
            Parent__c = customerAccount.Id,
            Booking_Time_Text__c = 'Wed,Jul 8 2020 at 3:30 PM',
            Is_Reschedule_Booking__c = false,
            Parent_Email__c = 'user@gmail.com');
        //insert bookingPending;
        listofBooking.add(bookingPending);
        Booking__c bookingMakeup = new Booking__c(
            RecordTypeId = bookingLessonRecTypeId,
            Teacher_Account__c = teacherAccount.Id,
            Start_Time__c = time.newInstance(15, 00,00, 00) ,
            End_Time__c = time.newInstance(16, 00,00, 00),
            Status__c = 'Scheduled',
            Student__c = studentAccount.id,
            Type__c = 'Make-up',
            Booking_Date__c = Date.newInstance(2020,07,08),
            Package__c = packageObj.Id,
            Enrolment__c = enrolment.Id,
            Center__c = centreAccount.Id,
            Individual_Booking__c = false,
            Is_fifth_booking__c = false,
            Parent__c = customerAccount.Id,
            Booking_Time_Text__c = 'Wed,Jul 8 2020 at 3:30 PM',
            Is_Reschedule_Booking__c = false,
            Parent_Email__c = 'user@gmail.com',
            Make_up_Utilize_Bookings__c = bookingCancel.id+'-'+bookingCancel.Available_Make_up_Units__c
        );
        //insert bookingMakeup;
        listofBooking.add(bookingMakeup);
        Booking__c objBook = new Booking__c(Student__c = studentAccount.id,
            Package__c = packageObj.Id,
            Enrolment__c = enrolment.Id,
            Center__c = centreAccount.Id);
        objBook.Teacher_Account__c=teacherAccount.Id;
        objBook.RecordTypeId=bookingLessonRecTypeId;
        objBook.Booking_Date__c=date.today().addDays(1);
        objBook.Start_Time__c=Time.newInstance(11,0,0,0);
        objBook.Type__c='Busy';
        objBook.Status__c='Scheduled'; 
        objBook.Booking_Date__c=date.today().addDays(2);
        objBook.Start_Time__c=Time.newInstance(11,0,0,0);
        objBook.End_Time__c=Time.newInstance(12,0,0,0);
        //insert ;
        listofBooking.add(objBook);
        
         Booking__c bookingCancel2 = new Booking__c(
            RecordTypeId = bookingLessonRecTypeId,
            Teacher_Account__c = teacherAccount2.Id,
            Start_Time__c = time.newInstance(15, 00,00, 00) ,
            End_Time__c = time.newInstance(16, 00,00, 00),
            Status__c = 'Canceled',
            Student__c = studentAccount.id,
            Type__c = 'Regular',
            Booking_Date__c = system.today().addDays(1),
            Package__c = packageObj.Id,
            Enrolment__c = enrolment2.Id,
            Cancellation_Reason__c = 'Teacher MC',
            Center__c = centreAccount.Id,
            Individual_Booking__c = false,
            Is_fifth_booking__c = false,
            Canceled_By__c = 'ArpitVijay',
            Canceled_Date__c = DateTime.newInstance(2019,3,7,10,602,36146),
            Parent__c = customerAccount.Id,
            Booking_Time_Text__c = 'Wed,Jul 8 2020 at 3:30 PM',
            Is_Reschedule_Booking__c = false,
            Parent_Email__c = 'user@gmail.com',
         Available_Make_up_Units__c =30,
         Make_up_Expiry_Date__c = system.today());
        //insert bookingCancel2;
        listofBooking.add(bookingCancel2);
       
        
        Booking__c bookingSchedule2 = new Booking__c(
            RecordTypeId = bookingLessonRecTypeId,
            Teacher_Account__c = teacherAccount2.Id,
            Start_Time__c = time.newInstance(15, 00,00, 00) ,
            End_Time__c = time.newInstance(16, 00,00, 00),
            Status__c = 'Scheduled',
            Student__c = studentAccount.id,
            Type__c = 'Regular',
            Booking_Date__c = Date.newInstance(2020,07,08),
            Package__c = packageObj.Id,
            Enrolment__c = enrolment2.Id,
            Center__c = centreAccount.Id,
            Individual_Booking__c = false,
            Is_fifth_booking__c = false,
            Parent__c = customerAccount.Id,
            Booking_Time_Text__c = 'Wed,Jul 8 2020 at 3:30 PM',
            Is_Reschedule_Booking__c = false,
            Parent_Email__c = 'user@gmail.com');
         listofBooking.add(bookingSchedule2);
        //insert bookingSchedule2;
        Booking__c bookingSchedule3 = new Booking__c(
            RecordTypeId = bookingLessonRecTypeId,
            Teacher_Account__c = teacherAccount2.Id,
            Start_Time__c = time.newInstance(15, 00,00, 00) ,
            End_Time__c = time.newInstance(16, 00,00, 00),
            Status__c = 'Scheduled',
            Student__c = studentAccount.id,
            Type__c = 'Regular',
            Booking_Date__c = Date.newInstance(2020,07,08),
            Package__c = packageObj.Id,
            Center__c = centreAccount.Id,
            Individual_Booking__c = false,
            Is_fifth_booking__c = false,
            Parent__c = customerAccount.Id,
            Booking_Time_Text__c = 'Wed,Jul 8 2020 at 3:30 PM',
            Is_Reschedule_Booking__c = false,
            Parent_Email__c = 'user@gmail.com');
        //insert bookingSchedule3;
        listofBooking.add(bookingSchedule3);

        Booking__c bookingPending2 = new Booking__c(
            RecordTypeId = bookingLessonRecTypeId,
            Teacher_Account__c = teacherAccount2.Id,
            Start_Time__c = time.newInstance(15, 00,00, 00) ,
            End_Time__c = time.newInstance(16, 00,00, 00),
            Status__c = 'Pending',
            Student__c = studentAccount.id,
            Type__c = 'Regular',
            Booking_Date__c = Date.newInstance(2020,07,08),
            Package__c = packageObj.Id,
            Enrolment__c = enrolment2.Id,
            Center__c = centreAccount.Id,
            Individual_Booking__c = false,
            Is_fifth_booking__c = false,
            Parent__c = customerAccount.Id,
            Booking_Time_Text__c = 'Wed,Jul 8 2020 at 3:30 PM',
            Is_Reschedule_Booking__c = false,
            Parent_Email__c = 'user@gmail.com'
        );
        //insert bookingPending2;
        listofBooking.add(bookingPending2);

        Booking__c bookingMakeup2 = new Booking__c(
            RecordTypeId = bookingLessonRecTypeId,
            Teacher_Account__c = teacherAccount2.Id,
            Start_Time__c = time.newInstance(15, 00,00, 00) ,
            End_Time__c = time.newInstance(16, 00,00, 00),
            Status__c = 'Scheduled',
            Student__c = studentAccount.id,
            Type__c = 'Make-up',
            Booking_Date__c = Date.newInstance(2020,07,08),
            Package__c = packageObj.Id,
            Enrolment__c = enrolment2.Id,
            Center__c = centreAccount.Id,
            Individual_Booking__c = false,
            Is_fifth_booking__c = false,
            Parent__c = customerAccount.Id,
            Booking_Time_Text__c = 'Wed,Jul 8 2020 at 3:30 PM',
            Is_Reschedule_Booking__c = false,
            Parent_Email__c = 'user@gmail.com',
        Make_up_Utilize_Bookings__c = bookingCancel2.id+'-'+bookingCancel2.Available_Make_up_Units__c);
        //insert bookingMakeup2;
         listofBooking.add(bookingMakeup2);

        Booking__c objBook2 = new Booking__c(Student__c = studentAccount.id,
                                             Package__c = packageObj.Id,
                                             Enrolment__c = enrolment2.Id,
                                             Center__c = centreAccount.Id);
        objBook.Teacher_Account__c=teacherAccount2.Id;
        objBook.RecordTypeId=bookingLessonRecTypeId;
        objBook.Booking_Date__c=date.today().addDays(1);
        objBook.Start_Time__c=Time.newInstance(11,0,0,0);
        objBook.Type__c='Busy';
        objBook.Status__c='Scheduled'; 
        objBook.Booking_Date__c=date.today().addDays(2);
        objBook.Start_Time__c=Time.newInstance(11,0,0,0);
        objBook.End_Time__c=Time.newInstance(12,0,0,0);
        //insert objBook2;
         listofBooking.add(objBook2);
        insert listofBooking;

        list<Invoice__c> listOfInvoice = new list<Invoice__c>();
        Invoice__c invoice = new Invoice__c(
            Parent_Account__c=customerAccount.id,
            Invoice_Date__c = Date.newInstance(2019,06,02),
            Due_Date__c = Date.newInstance(2019,07,10),
            Status__c = 'Due',
            Center__c = centreAccount.Id,
            Total_Invoice_Amount__c = 213.75);
            //MovedToSage__c = false,
            //Voided_on_Sage__c = false);
        //insert invoice;
        listOfInvoice.add(invoice);
        Invoice__c invoice2 = new Invoice__c(
            Parent_Account__c=customerAccount.id,
            Invoice_Date__c = Date.newInstance(2019,07,24),
            Due_Date__c = Date.newInstance(2019,07,10),
            Status__c = 'Paid',
            Center__c = centreAccount.Id,
            Total_Invoice_Amount__c = 213.75);
            //MovedToSage__c = false,
           // Voided_on_Sage__c = false);
        listOfInvoice.add(invoice2);
        insert listOfInvoice;
        //insert invoice2;

        List<Case> listOfcase = new List<case>();
        Case caseObj = new Case(

            AccountId = customerAccount.id,
            Type = 'Ad-Hoc',
            RecordTypeId = caseLessonRecTypeId,
            Status = 'New',
            Subject = 'test',
            Priority = 'Medium',
            Description = 'est',
            IsEscalated = false,
            Closed_by_Self_Service_User__c = false,
            MC_Received__c = false);
        //insert caseObj;
        listOfcase.add(caseObj);
         Case caseObj2 = new Case(
            AccountId = customerAccount.id,
            Type = 'Ad-Hoc',
            RecordTypeId = caseLessonRecTypeId,
            Status = 'New',
            Subject = 'test',
            Priority = 'Medium',
            Description = 'est',
            IsEscalated = false,
            Closed_by_Self_Service_User__c = false,
            MC_Received__c = false);
        //insert caseObj2;
        listOfcase.add(caseObj2);
        //List<Case> listOfCase=NEW List<Case>();
        listOfCase.add(new Case(Enrolment__c=enrolment2.id,RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId(),
                                Status='New',Origin='App',Student_Name__c=customerAccount.Id,AccountId = customerAccount.Id));
        listOfCase.add(new Case(Enrolment__c=enrolment2.id,RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId(),
                                Status='Closed',Origin='App',Student_Name__c=customerAccount.Id,AccountId = customerAccount.Id));
        listOfCase.add(new Case(Enrolment__c=enrolment2.id,RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId(),
                                Status='Open',Origin='App',Student_Name__c=customerAccount.Id,AccountId = customerAccount.Id));
        insert listOfCase;
        List<CaseComment> listOfCaseComment = new List<CaseComment>();
        listOfCaseComment.add(new CaseComment(ParentId =  listOfCase[0].id,CommentBody='test1'));
        listOfCaseComment.add(new CaseComment(ParentId =  listOfCase[2].id,CommentBody='test2'));
        INSERT listOfCaseComment;
        
        Payment__c objpay = new Payment__c();
         objPay.Parent_Account__c = customerAccount.Id;
        objPay.Transaction_ID__c = 'ch_1ElCr3Jja9IPifcSADDUXp23';
        objPay.Payment_Amount__c = 0;
        objPay.RecordTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsDepositRecordType).getRecordTypeId();
        objPay.Invoice__c = invoice2.Id;
        objPay.Payment_Status__c= 'Success';
        insert objPay;
       insert new Mobile_Api_Emails__c(Auto_Generate_Code__c = '1234',Code_Expire_Date__c = datetime.now().addDays(1),Email_Address__c ='user@yahoo.com',name='user@yahoo.com');
        
        
        //teacher working hours
        list<Teacher_Working_Hour__c> listTwh=new List<Teacher_Working_Hour__c>();
        for(integer i=1;i<=10;i++){
            Teacher_Working_Hour__c tw = new Teacher_Working_Hour__c();
            tw.Active__c = true;
            tw.Break_Time__c= False;
            tw.Teacher_Name__c=teacherAccount.Id;
            tw.Center_Name__c=centreAccount.Id;
            tw.Working_Day__c=i==1?'mon':i==2?'tue':i==3?'wed':i==4?'thu':i==5?'fri':i==6?'sat':'sun';
            tw.Start_Time__c=Time.newInstance(7,0,0,0);
            tw.End_Time__c=Time.newInstance(23,0,0,0);
            
            listTwh.add(tw);
        }
        insert listTwh; 
        
        Booking__c objBookPlachoder = new Booking__c(Student__c = studentAccount.id,
                                                     Package__c = packageObj.Id,
                                                     Enrolment__c = enrolment.Id,
                                                     Center__c = centreAccount.Id,
                                                     Category__c = 'Placeholder');
        objBookPlachoder.Teacher_Account__c=teacherAccount.Id;
        objBookPlachoder.RecordTypeId=bookingLessonRecTypeId;
        objBookPlachoder.Booking_Date__c=date.today().addDays(1);
        objBookPlachoder.Start_Time__c=Time.newInstance(11,0,0,0);
        objBookPlachoder.Type__c='Busy';
        objBookPlachoder.Status__c='Scheduled'; 
        objBookPlachoder.Booking_Date__c=date.today().addDays(2);
        objBookPlachoder.Start_Time__c=Time.newInstance(11,0,0,0);
        objBookPlachoder.End_Time__c=Time.newInstance(12,0,0,0);
        insert objBookPlachoder;
        
        list<Fifth_Lesson__c> listOfFifthLesson = new list<Fifth_Lesson__c>();
        listOfFifthLesson.add(new Fifth_Lesson__c(Booking_Date__c=system.today().addDays(2),
                                                  Center__c=centreAccount.Id,
                                                  Start_Time__c =objBook.Start_Time__c,
                                                  End_Time__c = objBook.End_Time__c,
                                                  Enrolment__c = enrolment.id,
                                                  Package__c =packageObj.Id,
                                                  Parent__c =customerAccount.Id,
                                                  Student__c =studentAccount.Id,
                                                  Teacher_Account__c =teacherAccount.id,
                                                  IsActive__c=true));
        listOfFifthLesson.add(new Fifth_Lesson__c(Booking_Date__c=system.today().addDays(-1),
                                                  Center__c=centreAccount.Id,
                                                  Start_Time__c =objBook.Start_Time__c,
                                                  End_Time__c = objBook.End_Time__c,
                                                  Enrolment__c = enrolment2.id,
                                                  Package__c =packageObj.Id,
                                                  Parent__c =customerAccount.Id,
                                                  Student__c =studentAccount.Id,
                                                  Teacher_Account__c =teacherAccount.id,
                                                 IsActive__c = true));
        listOfFifthLesson.add(new Fifth_Lesson__c(Booking_Date__c=system.today().addDays(2),
                                                  Center__c=centreAccount.Id,
                                                  Start_Time__c =objBook.Start_Time__c,
                                                  End_Time__c = objBook.End_Time__c,
                                                  Package__c =packageObj.id,
                                                  Parent__c =customerAccount.Id,
                                                  Student__c =studentAccount.id,
                                                  Teacher_Account__c =teacherAccount.Id,
                                                 IsActive__c = true));
        listOfFifthLesson.add(new Fifth_Lesson__c(Booking_Date__c=system.today().addDays(-1),
                                                  Center__c=objBook.Center__c,
                                                  Start_Time__c =objBook.Start_Time__c,
                                                  End_Time__c = objBook.End_Time__c,
                                                  Enrolment__c = enrolment2.id,
                                                  Package__c =objBook.Package__c,
                                                  Parent__c =customerAccount.Id,
                                                  Student__c =objBook.Student__c,
                                                  Teacher_Account__c =teacherAccount2.Id,
                                                 IsActive__c = false,
                                                 Booking__c  =objBookPlachoder.id));
        listOfFifthLesson.add(new Fifth_Lesson__c(Booking_Date__c=system.today().addDays(-1),
                                                  Center__c=objBook.Center__c,
                                                  Start_Time__c =objBook.Start_Time__c,
                                                  End_Time__c = objBook.End_Time__c,
                                                  Package__c =objBook.Package__c,
                                                  Parent__c =customerAccount.Id,
                                                  Student__c =objBook.Student__c,
                                                  Teacher_Account__c =teacherAccount2.Id,
                                                 IsActive__c = false,
                                                 Booking__c  =objBookPlachoder.id));
        insert listOfFifthLesson;
        
       Mobile_Notification__c log = new Mobile_Notification__c(Customer_Name__c = customerAccount.id, Title__c = 'Test', Body__c = 'bodymsg', Status__c = 'status');
        insert log;


        // create Subscription__C
        List<Subscription__C> listOfSubscription = New List<Subscription__C>();
        listOfSubscription.add(createSubscription(customerAccount.Id,centreAccount.id, FALSE));
        listOfSubscription.add(createSubscription(customerAccount.Id,centreAccount.id, FALSE));
        Insert listOfSubscription;
        
        // create Subscription_Line_Item__c
        List<Subscription_Line_Item__c> listOfSubscLine = new List<Subscription_Line_Item__c>();
        listOfSubscLine.add(createSubscriptionLineItem(listOfSubscription[0].Id,listOfEnrolment[0].Id, Date.newInstance(System.today().year(), System.today().month() + 1, 1), False));
        listOfSubscLine.add(createSubscriptionLineItem(listOfSubscription[0].Id,listOfEnrolment[0].Id, Date.newInstance(System.today().year(), System.today().month() + 1, 1).AddDays(1), False));
        listOfSubscLine.add(createSubscriptionLineItem(listOfSubscription[1].Id,listOfEnrolment[1].Id, Date.newInstance(System.today().year(), System.today().month() + 1, 1).AddDays(2), False));
        listOfSubscLine.add(createSubscriptionLineItem(listOfSubscription[1].Id,listOfEnrolment[1].Id, Date.newInstance(System.today().year(), System.today().month() + 1, 1).AddDays(3), False));
        insert listOfSubscLine;


    }
    
       public static Subscription__C createSubscription(string custmrId,String centerid, Boolean isDml){
        Subscription__C objSubs=new Subscription__C();
        objSubs.Parent__c=custmrId;
        objSubs.Center__c = centerid;
        objSubs.Subscription_Start_Date__c = date.today();
        if(isDml)
            insert objSubs;
        return objSubs;
        
    }
    public static Subscription_Line_Item__c createSubscriptionLineItem(string subscriptId,String ENrolId,Date nextBillDate,Boolean isDml){
        Subscription_Line_Item__C objSLI=new Subscription_Line_Item__C();
        objSLI.Subscription__c=subscriptId;
        objSLI.Enrolment__c = ENrolId;
        objSLI.Next_Bill_Date__c= nextBillDate;
        
        if(isDml)
            insert objSLI;
        return objSLI;    
    }
    
}