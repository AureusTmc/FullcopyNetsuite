/*
Name        :        AureusCalendarControllerTestHelper
Date        :        04-Nov-2019 
Author      :        Jatin
Description :        It is the Helper class for create data AureusCalendarControllerTest.
*/
public class AureusCalendarControllerTestHelper {
    public static void createCalenderData(){
        Firebase_Settings__c objSetting = new Firebase_Settings__c();
        objSetting.Name = 'setting';
        objSetting.Enable_Notifications__c = false;
        insert objSetting;
        
        //Create Country Records
        Country__c objCountry = createCountryRecord ('Singapore','SGD',true);
        
        //updated by @nishi 17 sep 2020
      	Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Aureus Academy Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = objCountry.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
        Insert organisationRecord;  
       
        // Create 2 Centre  
        List<Account> ListCentre = new List<Account>();
        ListCentre.add(createCentre('Aureus Northpoint', objCountry.Id,FALSE));
        ListCentre.add(createCentre('Aureus AMK Hub', objCountry.Id,FALSE));
         //updated by @nishi 17 sep 2020
        ListCentre[0].Organisation__c = organisationRecord.id;
        ListCentre[0].Organisation_Sharing__c ='Aureus Academy Singapore';
        ListCentre[1].Organisation__c = organisationRecord.id;
        ListCentre[1].Organisation_Sharing__c ='Aureus Academy Singapore';
        Insert ListCentre; 
        
        //create  Centre_Users__c
         Centre_Users__c objCentre_Users = createCentreUsers(ListCentre[0].id,true);
        
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
        listOfPackage.Add(createPackage(objProg.id,ListCentre[0].id,'30','Trial',False)); 
        listOfPackage.Add(createPackage(objProg.id,ListCentre[0].id,'15','Trial',False));
        listOfPackage.Add(createPackage(objProg.id,ListCentre[1].id,'45','Trial',False)); 
        listOfPackage.Add(createPackage(objProg.id,ListCentre[1].id,'60','Trial',False));
        listOfPackage.Add(createPackage(objProg.id,ListCentre[1].id,'15',ConstantsClass.pakageTypeMakeup,False));
        listOfPackage.Add(createPackage(objProg.id,ListCentre[0].id,'30',ConstantsClass.pakageTypeMakeup,False));
         listOfPackage[0].Package_Fee__c = 100;
        listOfPackage[0].Deposit_Fee__c = 100;
        listOfPackage[1].Package_Fee__c = 200;
        listOfPackage[2].Package_Fee__c = 300;
        listOfPackage[3].Package_Fee__c = 400;
        listOfPackage[1].Deposit_Fee__c = 200;
        listOfPackage[2].Deposit_Fee__c = 300;
        listOfPackage[3].Deposit_Fee__c = 400;
        insert listOfPackage;
        
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0));
        List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
        listOfEnrolment.Add(createEnrolment(ListCentre[0].Id,ListOfTeacherAccount[0].Id,listOfCustomerAccount[0].Id,listOfPackage[0].id,dt.format('EEEE'),'Enrolled','Regular',false));
        listOfEnrolment.Add(createEnrolment(ListCentre[0].Id,ListOfTeacherAccount[1].Id,listOfCustomerAccount[1].Id,listOfPackage[1].id,dt.addDays(1).format('EEEE'),'Enrolled','Regular',false));
        listOfEnrolment.Add(createEnrolment(ListCentre[1].Id,ListOfTeacherAccount[1].Id,listOfCustomerAccount[0].Id,listOfPackage[2].id,dt.addDays(1).format('EEEE'),'Enrolled','Regular',false));
        listOfEnrolment.Add(createEnrolment(ListCentre[1].Id,ListOfTeacherAccount[0].Id,listOfCustomerAccount[1].Id,listOfPackage[3].id,dt.format('EEEE'),'Enrolled','Regular',false));
         listOfEnrolment.Add(createEnrolment(ListCentre[1].Id,ListOfTeacherAccount[0].Id,listOfCustomerAccount[1].Id,listOfPackage[3].id,dt.format('EEEE'),'Cancelled','Trial',false));
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
        listOfcreateBooking.add(createBooking(ListOfTeacherAccount[0].id,listOfEnrolment[0].Id,listOfCustomerAccount[0].id,ListCentre[0].Id,listOfPackage[0].id,date.today(),'Pending','Lesson','Regular',false));
        listOfcreateBooking.add(createBooking(ListOfTeacherAccount[0].id,listOfEnrolment[0].Id,listOfCustomerAccount[0].id,ListCentre[0].Id,listOfPackage[0].id,date.today().addDays(2),'Scheduled','Lesson','busy',false));
        
        listOfcreateBooking.add(createBooking(ListOfTeacherAccount[1].id,listOfEnrolment[1].Id,listOfCustomerAccount[1].id,ListCentre[0].Id,listOfPackage[1].id,date.today().addDays(2),'Pending','Lesson','Regular',false));
        listOfcreateBooking.add(createBooking(ListOfTeacherAccount[1].id,listOfEnrolment[2].Id,listOfCustomerAccount[0].id,ListCentre[1].Id,listOfPackage[2].id,date.today().addDays(3),'Pending','Lesson','Regular',false));
        listOfcreateBooking.add(createBooking(ListOfTeacherAccount[0].id,listOfEnrolment[3].Id,listOfCustomerAccount[1].id,ListCentre[1].Id,listOfPackage[3].id,date.today().addDays(4),'Pending','Lesson','Regular',false));
        listOfcreateBooking.add(createBooking(ListOfTeacherAccount[0].id,listOfEnrolment[3].Id,listOfCustomerAccount[1].id,ListCentre[1].Id,listOfPackage[3].id,date.today().addDays(6),'Scheduled','Lesson','Make-up',false));
        
        insert listOfcreateBooking;
        
        // create Subscription__C
        List<Subscription__C> listOfSubscription = New List<Subscription__C>();
        listOfSubscription.add(createSubscription(listOfCustomerAccount[0].Id,ListCentre[0].id, FALSE));
        listOfSubscription.add(createSubscription(listOfCustomerAccount[1].Id,ListCentre[1].id, FALSE));
        Insert listOfSubscription;
        
        // create Subscription_Line_Item__c
        List<Subscription_Line_Item__c> listOfSubscLine = new List<Subscription_Line_Item__c>();
        listOfSubscLine.add(createSubscriptionLineItem(listOfSubscription[0].Id,listOfEnrolment[0].Id, Date.newInstance(System.today().year(), System.today().month() + 1, 1), False));
        listOfSubscLine.add(createSubscriptionLineItem(listOfSubscription[0].Id,listOfEnrolment[0].Id, Date.newInstance(System.today().year(), System.today().month() + 1, 1).AddDays(1), False));
        listOfSubscLine.add(createSubscriptionLineItem(listOfSubscription[1].Id,listOfEnrolment[1].Id, Date.newInstance(System.today().year(), System.today().month() + 1, 1).AddDays(2), False));
        listOfSubscLine.add(createSubscriptionLineItem(listOfSubscription[1].Id,listOfEnrolment[1].Id, Date.newInstance(System.today().year(), System.today().month() + 1, 1).AddDays(3), False));
        insert listOfSubscLine;
        
        
        // create Fifth_Lesson__c records
        List<Fifth_Lesson__c>  listOfFifthLesson = new List<Fifth_Lesson__c>();
        listOfFifthLesson.add(createFifthLesson(date.newInstance(2019, 10, 29),ListCentre[0].id, listOfEnrolment[0].id,listOfPackage[0].id,listOfCustomerAccount[0].id, ListOfTeacherAccount[0].id,False));
        listOfFifthLesson.add(createFifthLesson(date.newInstance(2019, 10, 29),ListCentre[0].Id,listOfEnrolment[1].Id,listOfPackage[1].id,listOfCustomerAccount[1].id,ListOfTeacherAccount[1].id,False));
        listOfFifthLesson.add(createFifthLesson(date.newInstance(2019, 10, 29),ListCentre[1].Id,listOfEnrolment[2].Id,listOfPackage[2].id,listOfCustomerAccount[0].id,ListOfTeacherAccount[1].id,False));
        listOfFifthLesson.add(createFifthLesson(date.newInstance(2019, 10, 29),ListCentre[1].Id,listOfEnrolment[3].Id,listOfPackage[3].id,listOfCustomerAccount[1].id,ListOfTeacherAccount[0].id,False));
        insert listOfFifthLesson;
        
        // create case Records
        List<Case> listOfcase = new List<Case>();
        listOfCase.add(createCase(listOfEnrolment[0].id,listOfCustomerAccount[0].id,'New','Email',false));
        listOfCase.add(createCase(listOfEnrolment[1].id,listOfCustomerAccount[0].id,'New','cancel',false));
        listOfCase.add(createCase(listOfEnrolment[2].id,listOfCustomerAccount[1].id,'New','Reschedule',false));
        listOfCase.add(createCase(listOfEnrolment[3].id,listOfCustomerAccount[1].id,'New','Make-Up',false));
        insert listOfcase;
        
        List<invoice__c> listOfinvoice = new List<invoice__c>();
        listOfinvoice.add(AureusCalendarControllerTestHelper.createInvoice(listOfCustomerAccount[0].id,ListCentre[0].id,false));
        insert listOfinvoice;
        
        List<Invoice_Line_Item__c> listOfInvoice_Line_Item = new List<Invoice_Line_Item__c>();
        listOfInvoice_Line_Item.add(AureusCalendarControllerTestHelper.createInvLineItem(listOfinvoice[0].id,10,ListOfTeacherAccount[2].id,date.today().addDays(2),listOfEnrolment[0].id,listOfSubscLine[0].id,listOfPackage[0].id,1.00,false));
        listOfInvoice_Line_Item.add(AureusCalendarControllerTestHelper.createInvLineItem(listOfinvoice[0].id,10,ListOfTeacherAccount[2].id,date.today().addDays(3),listOfEnrolment[0].id,listOfSubscLine[1].id,listOfPackage[1].id,1.00,false));
        insert listOfInvoice_Line_Item;    
        
        List<Payment__c> listOfPayment = new List<Payment__c>();
        listOfPayment.add(createPayment(listOfCustomerAccount[0].id,listOfinvoice[0].id,false));
        insert listOfPayment;
        
        
        
        // Create Package 
        List<Package__c> listOfGroupPackage =new List<Package__c>();
        listOfGroupPackage.Add(createPackage(objProg.id,ListCentre[0].id,'30',ConstantsClass.packageTypeGroup,False)); 
        listOfGroupPackage.Add(createPackage(objProg.id,ListCentre[0].id,'15',ConstantsClass.packageTypeGroup,False));
        listOfGroupPackage.Add(createPackage(objProg.id,ListCentre[1].id,'45',ConstantsClass.packageTypeGroup,False)); 
        listOfGroupPackage.Add(createPackage(objProg.id,ListCentre[1].id,'60',ConstantsClass.packageTypeGroup,False));
       
        insert listOfGroupPackage;
        
        List<Class__c > GroupClassList = new List<Class__C>();
         GroupClassList.add(createGroupClass('test Group Class',listOfPackage[0].id,ListCentre[0].Id,objProg.id,date.today(),date.today().addYears(1),Time.newInstance(11,0,0,0),Time.newInstance(11,30,0,0),ListOfTeacherAccount[0].Id,false));
         GroupClassList.add(createGroupClass('test Group Class',listOfPackage[2].id,ListCentre[1].Id,objProg.id,date.today(),date.today().addYears(1),Time.newInstance(12,0,0,0),Time.newInstance(12,45,0,0),ListOfTeacherAccount[1].Id,false));
         insert GroupClassList;
        
         List<Enrolment__c> listOfGroupEnrolment = new List<Enrolment__c>();
         listOfGroupEnrolment.Add(createEnrolment(ListCentre[0].Id,ListOfTeacherAccount[0].Id,listOfCustomerAccount[0].Id,listOfGroupPackage[0].id,dt.format('EEEE'),'Enrolled',ConstantsClass.enrolGroupType,false));
         listOfGroupEnrolment[0].Class__C = GroupClassList[0].id;
         listOfGroupEnrolment.Add(createEnrolment(ListCentre[0].Id,ListOfTeacherAccount[1].Id,listOfCustomerAccount[1].Id,listOfGroupPackage[1].id,dt.addDays(1).format('EEEE'),'Enrolled',ConstantsClass.enrolGroupType,false));
         listOfGroupEnrolment[1].Class__C = GroupClassList[1].id;
         insert listOfGroupEnrolment;
        
        Map<string,Map<Date,Booking__c>> mapOfEffectiveDateGroupClass = New   Map<string,Map<Date,Booking__c>>();
         Map<Date,Booking__c> mapOfEffectiveDateGroupLesson = New  Map<Date,Booking__c>();
         
         for(Booking__c objBook : [SELECT Id, Package__c,package__r.Duration__c,Booking_Date__c,Booking__c.Class__c FROM Booking__c 
                                   WHERE (Class__c =:GroupClassList[0].id OR Class__c =:GroupClassList[1].id) And type__c != 'Busy']){
                                       mapOfEffectiveDateGroupLesson = New  Map<Date,Booking__c>();
                                       if(mapOfEffectiveDateGroupClass.containsKey(objBook.Class__c)){
                                           mapOfEffectiveDateGroupLesson = mapOfEffectiveDateGroupClass.get(objBook.Class__c);
                                       }
                                       mapOfEffectiveDateGroupLesson.put(objBook.Booking_Date__c ,objBook);
                                       mapOfEffectiveDateGroupClass.put(objBook.id ,mapOfEffectiveDateGroupLesson);
                                       system.debug('@@mapOfEffectiveDateGroupLesson'+objBook.Booking_Date__c);
                                   }
        //Create Booking Records
        List<Booking__c> listOfcreateGroupBooking = new List<Booking__c>();
         for(Enrolment__c  enrolmentObj:listOfGroupEnrolment){					
             if(mapOfEffectiveDateGroupClass.containsKey(enrolmentObj.Class__c)){
                 mapOfEffectiveDateGroupLesson = mapOfEffectiveDateGroupClass.get(enrolmentObj.Class__c);
                 system.debug('mapOfEffectiveDateGroupLesson'+mapOfEffectiveDateGroupLesson);
                 system.debug('enrolmentObj.Class__c'+enrolmentObj.Class__c);
                 if(mapOfEffectiveDateGroupLesson!= null && mapOfEffectiveDateGroupLesson.size() > 0 ){
                     for(date effectiveDate : mapOfEffectiveDateGroupLesson.keySet()){
                         if(effectiveDate.day() <= 28 && mapOfEffectiveDateGroupLesson.containsKey(effectiveDate)){
                             Booking__c bookingObj = new Booking__c();
                             bookingObj = AureusCalendarControllerTestHelper.createBooking(enrolmentObj.Teacher__c,enrolmentObj.Id,enrolmentObj.student__c,enrolmentObj.Center__c,
                                                                                                           enrolmentObj.package__c,effectiveDate,'Pending',
                                                                                           ConstantsClass.groupLessonBookingRecordType,ConstantsClass.groupLessonTypeBooking,false);
                             bookingObj.Group_Class__c = mapOfEffectiveDateGroupLesson.get(effectiveDate).id;
                             listOfcreateGroupBooking.add(bookingObj);
                         }
                     }
                 }
             }
         }
          listOfcreateGroupBooking.add(createBooking(ListOfTeacherAccount[0].id,listOfGroupEnrolment[0].Id,listOfCustomerAccount[0].id,ListCentre[0].Id,listOfPackage[0].id,date.today().addDays(2),
                                                'Scheduled', ConstantsClass.groupLessonBookingRecordType,'busy',false));
        
        
         if(listOfcreateGroupBooking.size() > 0){
             System.debug('@@bookingsToInsert'+listOfcreateGroupBooking);
             insert  listOfcreateGroupBooking;
             System.debug('@@bookingsToInsert'+listOfcreateGroupBooking);
         }
    }
    
     
    
    
     //Creating payment object
    public static Payment__c createPayment( String prntId,string invoiceId, Boolean isDml){
        Payment__c objpay = new Payment__c();
        objPay.Parent_Account__c = prntId;
        objPay.Transaction_ID__c = 'ch_1ElCr3Jja9IPifcSADDUXp23';
        objPay.Payment_Amount__c = 100;
        objPay.RecordTypeId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
        objPay.Invoice__c = invoiceId;
        if(isDml)
            insert objPay;
        return objPay;
    }
    
    public static invoice__c createInvoice(string parentId, string centerId,Boolean isDml){
        Invoice__c  objectOfInvoice = new Invoice__c(Status__c=ConstantsClass.paidStatus, 
                                                     Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                                     Invoice_Date__c =system.today(), 
                                                     Stripe_charge_id__c ='ch_1AxWbTFytruJp2FXW6iuRd1X',
                                                     Parent_Account__c = parentId, 
                                                     Center__c=centerId);
        if(isDMl)
            insert objectOfInvoice;
        return objectOfInvoice;
    }
    public static Invoice_Line_Item__c createInvLineItem(String invId,decimal totalAmount,string teacherId,date effectiveDate,string objEnrolId,string subLineItemId,string packageId,decimal gstAmount,boolean IsDml){
        Invoice_Line_Item__c objInvlineItm = new Invoice_Line_Item__c(invoice__c = invId,
                                                                      Amount__c = totalAmount, 
                                                                      Teacher_Id__c = teacherId,
                                                                      Month__c= effectiveDate,
                                                                      Enrolment__c =objEnrolId, 
                                                                      Subscription_line_item__c = subLineItemId,
                                                                      Package__c= packageId ,
                                                                      Is_Deposit__c = true,
                                                                      GST_Amount__c = gstAmount);
        if(IsDml)
            insert objInvlineItm;
        return objInvLineItm;
    }
    public static Package__c createPackage(Id progId, Id centrId,String Duration,string type,Boolean isDml){
        Package__c pack=new Package__c();
        pack.RecordTypeId =Schema.SObjectType.Package__C.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId(); 
        pack.Name='Piano';
        pack.Program__c=progId;
        pack.Location__c=centrId;
        pack.Duration__c=Duration;
        pack.Package_Fee__c=05.00;
        pack.Active__c=true;
        pack.Unit_Fee__c=05.00;
        pack.Registration_Fee__c=08.00;
        pack.Deposit_Fee__c=80.00;
        pack.Type__c=type;
        pack.Type_of_package__c = 'Normal';
        if(isDml){
            insert pack; 
        }
        return pack;
    }    
    public static Class__c createGroupClass(String groupClassName,String packageId,string centerId,string programId, date startDate,Date endDate,Time startTime,Time endTime,string teacherId,Boolean isDml){
        Class__c objClass = new Class__c(Centre_Name__c = centerId,
                                         Program__c = programId,
                                         Class_Date__c = startDate,
                                         Class_Start_Date__c = startDate,
                                         Class_End_Date__c = endDate,
                                         End_Time__c = endTime,
                                         Start_Time__c = startTime,
                                         Minimum_age__c = 10,
                                         Class_Type__c ='Group Theory Lesson',
                                         Total_Capacity__c =20,
                                         Package__c = packageId,
                                         Maximum_age__c = 20,
                                        Active__c = TRUE); 
        
        if(isDml)
            insert objClass;
        return objClass;
       
    }
    
    public static Centre_Users__c createCentreUsers(string centerId, Boolean isDml){
        Centre_Users__c centerUserObj = new Centre_Users__c();
        centerUserObj.Designation__c = 'Centre Manager';
        centerUserObj.Centre_Name__c = centerId;
        centerUserObj.User_Name__c = UserInfo.getUserId();
        if(isDml)
            insert centerUserObj;
        return centerUserObj;
    }
    public static Subscription__C createSubscription(string custmrId,String centerid, Boolean isDml){
        Subscription__C objSubs=new Subscription__C();
        objSubs.Parent__c=custmrId;
        objSubs.Center__c = centerid;
        objSubs.Subscription_Start_Date__c = date.today();
        objSubs.Next_Bill_Date__c = date.today().addMonths(1);
        
        if(isDml)
            insert objSubs;
        return objSubs;
        
    }
    
    public static case createCase(String objEnrolId, string customerId,string Status,string Origin,Boolean isDml){
        Case objCase=new Case();
        objCase.Enrolment__c=objEnrolId;
        objcase.RecordTypeId=Schema.SObjectType.case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        objCase.Status=Status;
        objCase.Origin=Origin;
        objCase.AccountId=customerId;
        if(isDml)
            insert objCase;
        return objCase;
    }
    public static Fifth_Lesson__c createFifthLesson(Date BookingDate,string centerId,String objEnrolId,string packageId,string customerId, STring teacherId, Boolean isDml){
        Fifth_Lesson__c  objFifthLesson = new Fifth_Lesson__c(Booking_Date__c=BookingDate, Center__c=centerId,
                                                              End_Time__c=time.newInstance(10, 0, 0, 0),
                                                              Enrolment__c=objEnrolId,
                                                              Package__c=packageId, 
                                                              Start_Time__c= time.newInstance(10, 30, 0, 0), 
                                                              Student__c=customerId, 
                                                              Teacher_Account__c=teacherId, 
                                                              Remarks__c='40',
                                                              IsActive__c=FALSE ,
                                                              Parent__c=customerId); 
        if(isDML)
            insert objFifthLesson;
        return objFifthLesson;
    }
    
    public static Subscription_Line_Item__c createSubscriptionLineItem(string subscriptId,String ENrolId,Date nextBillDate,Boolean isDml){
        Subscription_Line_Item__C objSLI=new Subscription_Line_Item__C();
        objSLI.Subscription__c=subscriptId;
        objSLI.Enrolment__c = ENrolId;
        objSLI.Next_Bill_Date__c= nextBillDate;
        
        objSLI.Status__c='Active';
        if(isDml)
            insert objSLI;
        return objSLI;    
    }
    
    // Create country Record
    public static Country__c createCountryRecord(String countryName,string currencyCode,Boolean isCreate){
        Country__c country = new Country__c();
        country.Name = currencyCode;
        country.Country_Name__c = countryName;
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = currencyCode;
        country.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
        country.Stripe_Base_Url__c ='https://api.stripe.com';
        country.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
        country.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
        if(isCreate){
            insert country;
        }
        return country;
    }
    
    //Create Center Account Record
    public static Account createCentre(String centreName,Id countryId,Boolean isDML){
        Account objCentreAcc = new Account();
        objCentreAcc.RecordTypeId =Schema.SObjectType.Account.getRecordTypeInfosByName().get('Centre').getRecordTypeId(); 
        objCentreAcc.name=centreName;
        objCentreAcc.CentreName_Cust__c=centreName; 
        objCentreAcc.Travel_Time__c=60.00;
        objCentreAcc.Location__c=centreName;
        objCentreAcc.Center_Email__c='rajesh@techmatrixconsulting.com';
        objCentreAcc.Country__c = countryId;
        // update @nishi jain 17 09 2020
        objCentreAcc.Organisation_Sharing__c ='Aureus Academy Singapore';
        objCentreAcc.Centre_Status__c = ConstantsClass.activeStatus;
        // set values here
        if(isDml){
            insert objCentreAcc;
        }
        return objCentreAcc;
    }
    
    public static Enrolment__c createEnrolment(string cntrId,string tchrId,String custmrId,String packId,String lessonDay,String enrollmentStage,String enrollmentType,boolean isDml){
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
        objEnrol.Lesson_Day__c = lessonDay;
        objEnrol.Type__c=enrollmentType;
        objEnrol.Stage__c = enrollmentStage;
        if(isDml)
            insert objEnrol;
        return objEnrol;
    }
    public static Booking__c createBooking(Id teacherID,Id EnrolmentId, Id StudentId, Id centerId,Id packageId, Date BookingDate,String Bookingstatus, String recTypeName,String bookType,Boolean isDml){
        
        Booking__c objBook = new Booking__c();
        objBook.Teacher_Account__c=teacherId;
        objBook.RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(recTypeName).getRecordTypeId();
        objBook.Booking_Date__c=BookingDate;
        objBook.Start_Time__c=Time.newInstance(11,0,0,0);
        objBook.End_Time__c =Time.newInstance(11,30,0,0); 
        objBook.Type__c=bookType;
        objBook.Status__c=Bookingstatus;
        objBook.Enrolment__c=(EnrolmentId != null?EnrolmentId: null);
        objBook.Student__c=(StudentId != null ? StudentId : null);
        objBook.Parent__c=(StudentId != null ? StudentId : null);
        objBook.Available_Make_up_Units__c = 0;
        objBook.center__c = (centerId != null ? centerId : null);
        objBook.Package__c = (packageId  != null ? packageId : null);
        objBook.Organisation_Sharing__c ='Aureus Academy Singapore';
        objBook.Country_Sharing__c ='Singapore';
        
        if(isDml){
            insert objBook;
        }
        return objBook;
        
    }
}