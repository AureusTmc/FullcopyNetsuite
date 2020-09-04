/**
* Name: PianoRentalTestHelper
* Author: Jatin
* Date : 13-March-2020
* Description: this helper class Used to help in all PianoRental test classes
*/
public class PianoRentalTestHelper {
    public static void createPianoRentalData(){
        Firebase_Settings__c objSetting = new Firebase_Settings__c();
        objSetting.Name = 'setting';
        objSetting.Enable_Notifications__c = false;
        insert objSetting;
        
        //Create Country Records
        Country__c objCountry = AureusCalendarControllerTestHelper.createCountryRecord ('Singapore','SGD',true);
        Organisation__c org = new Organisation__c(Name='Test',Country__c=objCountry.id);
        insert org;
        // Create 2 Centre  
        List<Account> ListCentre = new List<Account>();
        ListCentre.add(AureusCalendarControllerTestHelper.createCentre('Aureus Northpoint', objCountry.Id,FALSE));
        ListCentre[0].Organisation__c = org.id;
        ListCentre.add(AureusCalendarControllerTestHelper.createCentre('Aureus AMK Hub', objCountry.Id,FALSE));
        ListCentre[1].Organisation__c = org.id;
        Insert ListCentre; 
        
        //create  Centre_Users__c
        Centre_Users__c objCentre_Users = AureusCalendarControllerTestHelper.createCentreUsers(ListCentre[0].id,true);
        
        // Create Center Working Hours 
        list<Center_Working_Hours__c> listOfCenterWorkingHours= new list<Center_Working_Hours__c>();
        listOfCenterWorkingHours.AddAll(TestUtil.createCenter_Working_Hours(ListCentre[0].id, FALSE,7));
        listOfCenterWorkingHours.AddAll(TestUtil.createCenter_Working_Hours(ListCentre[1].id, FALSE,7));
        insert listOfCenterWorkingHours;
        
        // Create 2 Teachers 
        List<Account> ListOfTeacherAccount = new List<Account>();
        ListOfTeacherAccount.add(testUtil.createAccount('Teacher',false,False));
        ListOfTeacherAccount.add(testUtil.createAccount('Teacher',false,False));
        ListOfTeacherAccount.add(testUtil.createAccount('Teacher',false,False));
        Insert ListOfTeacherAccount; 
        
        // Create Teacher Working Hours 
        List <Teacher_Working_Hour__c> listOfTeacherWorkingHours = new List <Teacher_Working_Hour__c>();
        listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(ListOfTeacherAccount[0].id,ListCentre[0].Id,True,False,7));
        listOfTeacherWorkingHours.addAll(TestUtil.createTeacher_Working_Hour(ListOfTeacherAccount[1].id,ListCentre[1].Id,True,False,7));
        
        // Create Customer
        List<Account> listOfCustomerAccount = new List<Account> ();
        listOfCustomerAccount.add(TestUtil.createAccount('Customer',True,false));
        
        listOfCustomerAccount.add(TestUtil.createAccount('Customer',false,false));
        
        listOfCustomerAccount[0].Centre_Name__c = ListCentre[0].Id;
        listOfCustomerAccount[0].personEmail = 'test1@tmc.com';
        listOfCustomerAccount[0].Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        
        listOfCustomerAccount[1].Centre_Name__c = ListCentre[1].Id;
        listOfCustomerAccount[1].personEmail = 'test2@tmc.com';
        listOfCustomerAccount[1].Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT listOfCustomerAccount;
        
        // Create Program 
        Program__c objProg=TestUtil.createProgram('Active','Piano',true);
        // Create Package 
        List<Package__c> listOfPackage =new List<Package__c>();
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[0].id,'30','Trial',False)); 
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[0].id,'15','Trial',False));
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[1].id,'45','Trial',False)); 
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[1].id,'60','Trial',False));
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[1].id,'15',ConstantsClass.pakageTypeMakeup,False));
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[0].id,'30',ConstantsClass.pakageTypeMakeup,False));
        insert listOfPackage;
        
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0));
        List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(ListCentre[0].Id,ListOfTeacherAccount[0].Id,listOfCustomerAccount[0].Id,listOfPackage[0].id,dt.format('EEEE'),ConstantsClass.enrollmentPianoTerminationInProgressStage,'Instrument',false));
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(ListCentre[0].Id,ListOfTeacherAccount[1].Id,listOfCustomerAccount[1].Id,listOfPackage[1].id,dt.addDays(1).format('EEEE'),ConstantsClass.enrollmentPianoRentalActiveStage,'Instrument',false));
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(ListCentre[1].Id,ListOfTeacherAccount[1].Id,listOfCustomerAccount[0].Id,listOfPackage[2].id,dt.addDays(1).format('EEEE'),ConstantsClass.enrollmentPianoViewingBookedStage,'Instrument',false));
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(ListCentre[1].Id,ListOfTeacherAccount[0].Id,listOfCustomerAccount[1].Id,listOfPackage[3].id,dt.format('EEEE'),ConstantsClass.enrollmentPianoViewingCompletedStage,'Instrument',false));
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(ListCentre[1].Id,ListOfTeacherAccount[0].Id,listOfCustomerAccount[1].Id,listOfPackage[3].id,dt.format('EEEE'),ConstantsClass.enrollmentPianoTerminationInProgressStage,'Instrument',false));
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(ListCentre[1].Id,ListOfTeacherAccount[0].Id,listOfCustomerAccount[1].Id,listOfPackage[3].id,dt.format('EEEE'),ConstantsClass.enrollmentPianoRentalTerminatedStage,'Instrument',false));
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(ListCentre[1].Id,ListOfTeacherAccount[0].Id,listOfCustomerAccount[1].Id,listOfPackage[3].id,dt.format('EEEE'),ConstantsClass.enrollmentPianoSoldStage,'Instrument',false));
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(ListCentre[1].Id,ListOfTeacherAccount[0].Id,listOfCustomerAccount[1].Id,listOfPackage[3].id,dt.format('EEEE'),ConstantsClass.enrollmentNotInterestedStage,'Instrument',false));
        
        
        listOfEnrolment[0].RecordTypeId=Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get('Instrument Rental').getRecordTypeId();
        listOfEnrolment[1].RecordTypeId=Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get('Instrument Rental').getRecordTypeId();
        listOfEnrolment[2].RecordTypeId=Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get('Instrument Rental').getRecordTypeId();
        listOfEnrolment[3].RecordTypeId=Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get('Instrument Rental').getRecordTypeId();
        listOfEnrolment[4].RecordTypeId=Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get('Instrument Rental').getRecordTypeId();
        listOfEnrolment[5].RecordTypeId=Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get('Instrument Rental').getRecordTypeId();
        listOfEnrolment[6].RecordTypeId=Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get('Instrument Rental').getRecordTypeId();
        listOfEnrolment[7].RecordTypeId=Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get('Instrument Rental').getRecordTypeId();
        
        insert listOfEnrolment;
        
        // Create Resource__c
        List<Resource__c> ListOfResource = New List<Resource__c>();
        ListOfResource.Add(TestUtil.createResource(ListCentre[0].Id,'TstId1',listOfPackage[0].id,FALSE));
        ListOfResource.Add(TestUtil.createResource(ListCentre[0].Id,'TstId2',listOfPackage[1].id,FALSE));
        ListOfResource.Add(TestUtil.createResource(ListCentre[1].Id,'TstId3',listOfPackage[2].id,FALSE));
        ListOfResource.Add(TestUtil.createResource(ListCentre[1].Id,'TstId4',listOfPackage[3].id,FALSE));
        Insert  ListOfResource;
        
        // create Resource_Working_Hour__c
        list<Resource_Working_Hour__c> listRwh= new list<Resource_Working_Hour__c>();
        listRwh.addAll(TestUtil.createResource_Working_Hour(ListCentre[0].Id,ListOfResource[0].Id,false,7)); 
        listRwh.addAll(TestUtil.createResource_Working_Hour(ListCentre[0].Id,ListOfResource[1].Id,false,7)); 
        listRwh.addAll(TestUtil.createResource_Working_Hour(ListCentre[1].Id,ListOfResource[2].Id,false,7)); 
        listRwh.addAll(TestUtil.createResource_Working_Hour(ListCentre[1].Id,ListOfResource[3].Id,false,7)); 
        listRwh[0].Break_Time__c = true;
        Insert listRwh;
        
        //Create Booking Records
        List<Booking__c> listOfcreateBooking = new List<Booking__c>();
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(ListOfTeacherAccount[0].id,listOfEnrolment[0].Id,listOfCustomerAccount[0].id,ListCentre[0].Id,listOfPackage[0].id,date.today(),'Pending','Lesson',ConstantsClass.typePianoViewing,false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(ListOfTeacherAccount[0].id,listOfEnrolment[1].Id,listOfCustomerAccount[0].id,ListCentre[0].Id,listOfPackage[0].id,date.today().addDays(2),'Scheduled','Lesson',ConstantsClass.typePianoViewing,false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(ListOfTeacherAccount[1].id,listOfEnrolment[2].Id,listOfCustomerAccount[1].id,ListCentre[0].Id,listOfPackage[1].id,date.today().addDays(2),'Pending','Lesson',ConstantsClass.typePianoViewing,false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(ListOfTeacherAccount[1].id,listOfEnrolment[3].Id,listOfCustomerAccount[0].id,ListCentre[1].Id,listOfPackage[2].id,date.today().addDays(3),'Pending','Lesson',ConstantsClass.typePianoViewing,false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(ListOfTeacherAccount[0].id,listOfEnrolment[4].Id,listOfCustomerAccount[1].id,ListCentre[1].Id,listOfPackage[3].id,date.today().addDays(4),'Pending','Lesson',ConstantsClass.typePianoViewing,false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(ListOfTeacherAccount[0].id,listOfEnrolment[5].Id,listOfCustomerAccount[1].id,ListCentre[1].Id,listOfPackage[3].id,date.today().addDays(6),'Scheduled','Lesson',ConstantsClass.typePianoViewing,false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(ListOfTeacherAccount[0].id,listOfEnrolment[6].Id,listOfCustomerAccount[1].id,ListCentre[1].Id,listOfPackage[3].id,date.today().addDays(6),'Scheduled','Lesson',ConstantsClass.typePianoViewing,false));
        listOfcreateBooking.add(AureusCalendarControllerTestHelper.createBooking(ListOfTeacherAccount[0].id,listOfEnrolment[7].Id,listOfCustomerAccount[1].id,ListCentre[1].Id,listOfPackage[3].id,date.today().addDays(6),'Scheduled','Lesson',ConstantsClass.typePianoViewing,false));
        
        insert listOfcreateBooking; 
        
        
        // create Subscription__C
        List<Subscription__C> listOfSubscription = New List<Subscription__C>();
        listOfSubscription.add(AureusCalendarControllerTestHelper.createSubscription(listOfCustomerAccount[0].Id,ListCentre[0].id, FALSE));
        listOfSubscription.add(AureusCalendarControllerTestHelper.createSubscription(listOfCustomerAccount[1].Id,ListCentre[1].id, FALSE));
        Insert listOfSubscription;
        
        // create Subscription_Line_Item__c
        List<Subscription_Line_Item__c> listOfSubscLine = new List<Subscription_Line_Item__c>();
        listOfSubscLine.add(AureusCalendarControllerTestHelper.createSubscriptionLineItem(listOfSubscription[0].Id,listOfEnrolment[0].Id, Date.newInstance(System.today().addMonths(1).year(), System.today().month() + 1, 1), False));
        listOfSubscLine[0].Amount__c = 10.2;
        listOfSubscLine[0].Subscription_Start_Date__c= Date.newInstance(System.today().year(), System.today().month(), 1);
        
        listOfSubscLine.add(AureusCalendarControllerTestHelper.createSubscriptionLineItem(listOfSubscription[1].Id,listOfEnrolment[1].Id, Date.newInstance(System.today().addMonths(1).year(), System.today().month() + 1, 1), False));
        listOfSubscLine[1].Amount__c = 10.1;
        listOfSubscLine[1].Subscription_Start_Date__c= Date.newInstance(System.today().year(), System.today().month(), 1);
        insert listOfSubscLine;
         
        
        // create case Records
      /*  List<Case> listOfcase = new List<Case>();
        listOfCase.add(AureusCalendarControllerTestHelper.createCase(listOfEnrolment[0].id,listOfCustomerAccount[0].id,'New','Email',false));
        listOfCase.add(AureusCalendarControllerTestHelper.createCase(listOfEnrolment[1].id,listOfCustomerAccount[1].id,'New','Reschedule',false));
        insert listOfcase;
        */
        List<invoice__c> listOfinvoice = new List<invoice__c>();
        listOfinvoice.add(AureusCalendarControllerTestHelper.createInvoice(listOfCustomerAccount[0].id,ListCentre[0].id,false));
        listOfinvoice[0].Invoice_Type__c = ConstantsClass.recurringInvoiceType;
        listOfinvoice[0].Status__c = ConstantsClass.paidStatus;
        listOfinvoice.add(AureusCalendarControllerTestHelper.createInvoice(listOfCustomerAccount[1].id,ListCentre[1].id,false));
        listOfinvoice[0].Invoice_Type__c = ConstantsClass.recurringInvoiceType;
        listOfinvoice[0].Status__c = ConstantsClass.dueStatus;
        
        insert listOfinvoice;
        
        List<Invoice_Line_Item__c> listOfInvoice_Line_Item = new List<Invoice_Line_Item__c>();
        listOfInvoice_Line_Item.add(AureusCalendarControllerTestHelper.createInvLineItem(listOfinvoice[0].id,10,ListOfTeacherAccount[2].id,date.today().addDays(2),listOfEnrolment[0].id,listOfSubscLine[0].id,listOfPackage[0].id,10.00,false));
        listOfInvoice_Line_Item[0].Is_Deposit__c = false;
        listOfInvoice_Line_Item.add(AureusCalendarControllerTestHelper.createInvLineItem(listOfinvoice[0].id,10,ListOfTeacherAccount[2].id,date.today().addDays(3),listOfEnrolment[0].id,listOfSubscLine[0].id,listOfPackage[0].id,100.00,false));
        listOfInvoice_Line_Item[1].Is_Deposit__c = false;
        listOfInvoice_Line_Item.add(AureusCalendarControllerTestHelper.createInvLineItem(listOfinvoice[1].id,10,ListOfTeacherAccount[1].id,date.today().addDays(2),listOfEnrolment[1].id,listOfSubscLine[1].id,listOfPackage[1].id,10.00,false));
        listOfInvoice_Line_Item[2].Is_Deposit__c = false;
        listOfInvoice_Line_Item.add(AureusCalendarControllerTestHelper.createInvLineItem(listOfinvoice[1].id,10,ListOfTeacherAccount[1].id,date.today().addDays(2),listOfEnrolment[1].id,listOfSubscLine[1].id,listOfPackage[1].id,100.00,false));
        listOfInvoice_Line_Item[3].Is_Deposit__c = false;
        insert listOfInvoice_Line_Item;    
        
        List<Payment__c> listOfPayment = new List<Payment__c>();
        listOfPayment.add(AureusCalendarControllerTestHelper.createPayment(listOfCustomerAccount[0].id,listOfinvoice[0].id,false));
        insert listOfPayment;
        
        
        
        
    }
}