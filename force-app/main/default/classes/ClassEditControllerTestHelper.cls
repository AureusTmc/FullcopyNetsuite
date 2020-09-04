/*
Name        :        ClassEditControllerTestHelper
Date        :        11 -Mar- 2020 
Author      :        Jatin
Description :        This helper class for all group test classes records creation.
*/
public class ClassEditControllerTestHelper {
    public static void createGroupClassData(){
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
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[0].id,'30',ConstantsClass.packageTypeGroup,False)); 
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[0].id,'15',ConstantsClass.packageTypeGroup,False));
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[1].id,'45',ConstantsClass.packageTypeGroup,False)); 
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[1].id,'60',ConstantsClass.packageTypeGroup,False));
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[1].id,'60','Home',False));
        listOfPackage.Add(AureusCalendarControllerTestHelper.createPackage(objProg.id,ListCentre[0].id,'30','Home',False));
        listOfPackage[0].Package_Fee__c = 100;
        listOfPackage[1].Package_Fee__c = 200;
        listOfPackage[2].Package_Fee__c = 300;
        listOfPackage[3].Package_Fee__c = 400;
        listOfPackage[4].Package_Fee__c =500;
        listOfPackage[5].Package_Fee__c =100;
        insert listOfPackage;
        DateTime dt = DateTime.newInstance(date.today(), Time.newInstance(0,0,0,0));
        List<Class__c > GroupClassList = new List<Class__C>();
        GroupClassList.add(AureusCalendarControllerTestHelper.createGroupClass('test Group Class1',listOfPackage[0].id,ListCentre[0].Id,objProg.id,date.today(),date.today().addYears(1),Time.newInstance(11,0,0,0),Time.newInstance(11,30,0,0),ListOfTeacherAccount[0].Id,false));
        GroupClassList.add(AureusCalendarControllerTestHelper.createGroupClass('test Group Class2',listOfPackage[2].id,ListCentre[1].Id,objProg.id,date.today(),date.today().addYears(1),Time.newInstance(12,0,0,0),Time.newInstance(12,45,0,0),ListOfTeacherAccount[1].Id,false));
        GroupClassList.add(AureusCalendarControllerTestHelper.createGroupClass('test Group Class3',listOfPackage[1].id,ListCentre[1].Id,objProg.id,date.today(),date.today().addYears(1),Time.newInstance(13,0,0,0),Time.newInstance(13,15,0,0),ListOfTeacherAccount[1].Id,false));
        GroupClassList.add(AureusCalendarControllerTestHelper.createGroupClass('test Group Class4',listOfPackage[3].id,ListCentre[1].Id,objProg.id,date.today(),date.today().addYears(1),Time.newInstance(14,0,0,0),Time.newInstance(15,0,0,0),ListOfTeacherAccount[1].Id,false));
        insert GroupClassList;
        
        List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(ListCentre[0].Id,ListOfTeacherAccount[0].Id,listOfCustomerAccount[0].Id,listOfPackage[0].id,dt.format('EEEE'),'Enrolled',ConstantsClass.enrolGroupType,false));
        listOfEnrolment[0].Class__C = GroupClassList[0].id;
        listOfEnrolment.Add(AureusCalendarControllerTestHelper.createEnrolment(ListCentre[0].Id,ListOfTeacherAccount[1].Id,listOfCustomerAccount[1].Id,listOfPackage[1].id,dt.addDays(1).format('EEEE'),'Enrolled',ConstantsClass.enrolGroupType,false));
        listOfEnrolment[1].Class__C = GroupClassList[1].id;
        insert listOfEnrolment;
        Map<string,Map<Date,Booking__c>> mapOfEffectiveDateGroupClass = New   Map<string,Map<Date,Booking__c>>();
        Map<Date,Booking__c> mapOfEffectiveDateGroupLesson = New  Map<Date,Booking__c>();
        
        for(Booking__c objBook : [SELECT Id, Package__c,package__r.Duration__c,Booking_Date__c,Booking__c.Class__c FROM Booking__c 
                                  WHERE (Class__c =:GroupClassList[0].id OR Class__c =:GroupClassList[1].id) And type__c != 'Busy']){
                                      mapOfEffectiveDateGroupLesson = New  Map<Date,Booking__c>();
                                      if(mapOfEffectiveDateGroupClass.containsKey(objBook.Class__c)){
                                          mapOfEffectiveDateGroupLesson = mapOfEffectiveDateGroupClass.get(objBook.Class__c);
                                      }
                                      mapOfEffectiveDateGroupLesson.put(objBook.Booking_Date__c ,objBook);
                                      mapOfEffectiveDateGroupClass.put(objBook.class__C ,mapOfEffectiveDateGroupLesson);
                                  }
        //Create Booking Records
        List<Booking__c> listOfcreateGroupBooking = new List<Booking__c>();
        for(Enrolment__c  enrolmentObj:listOfEnrolment){					
            if(mapOfEffectiveDateGroupClass.containsKey(enrolmentObj.Class__c)){
                mapOfEffectiveDateGroupLesson = mapOfEffectiveDateGroupClass.get(enrolmentObj.Class__c);
                system.debug('!!mapOfEffectiveDateGroupLesson'+mapOfEffectiveDateGroupLesson);
                system.debug('!!enrolmentObj.Class__c'+enrolmentObj.Class__c);
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
        listOfcreateGroupBooking.add(AureusCalendarControllerTestHelper.createBooking(ListOfTeacherAccount[0].id,listOfEnrolment[0].Id,listOfCustomerAccount[0].id,ListCentre[0].Id,listOfPackage[0].id,date.today().addDays(6),
                                                                                      'Scheduled',ConstantsClass.groupLessonBookingRecordType,'Make-up',false));
        
        insert  listOfcreateGroupBooking;
        
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
        
        
        
        // create Subscription__C
        List<Subscription__C> listOfSubscription = New List<Subscription__C>();
        listOfSubscription.add(AureusCalendarControllerTestHelper.createSubscription(listOfCustomerAccount[0].Id,ListCentre[0].id, FALSE));
        listOfSubscription.add(AureusCalendarControllerTestHelper.createSubscription(listOfCustomerAccount[1].Id,ListCentre[1].id, FALSE));
        Insert listOfSubscription;
        
        // create Subscription_Line_Item__c
        List<Subscription_Line_Item__c> listOfSubscLine = new List<Subscription_Line_Item__c>();
        listOfSubscLine.add(AureusCalendarControllerTestHelper.createSubscriptionLineItem(listOfSubscription[0].Id,listOfEnrolment[0].Id, Date.newInstance(System.today().year(), System.today().month() + 1, 1), False));
        listOfSubscLine.add(AureusCalendarControllerTestHelper.createSubscriptionLineItem(listOfSubscription[1].Id,listOfEnrolment[1].Id, Date.newInstance(System.today().year(), System.today().month() + 1, 1), False));
        insert listOfSubscLine;
        
        
        // create case Records
        List<Case> listOfcase = new List<Case>();
        listOfCase.add(AureusCalendarControllerTestHelper.createCase(listOfEnrolment[0].id,listOfCustomerAccount[0].id,'New','Email',false));
        listOfCase.add(AureusCalendarControllerTestHelper.createCase(listOfEnrolment[1].id,listOfCustomerAccount[1].id,'New','Reschedule',false));
        insert listOfcase;
        
        List<invoice__c> listOfinvoice = new List<invoice__c>();
        listOfinvoice.add(AureusCalendarControllerTestHelper.createInvoice(listOfCustomerAccount[0].id,ListCentre[0].id,false));
        insert listOfinvoice;
        
        List<Invoice_Line_Item__c> listOfInvoice_Line_Item = new List<Invoice_Line_Item__c>();
        listOfInvoice_Line_Item.add(AureusCalendarControllerTestHelper.createInvLineItem(listOfinvoice[0].id,10,ListOfTeacherAccount[2].id,date.today().addDays(2),listOfEnrolment[0].id,listOfSubscLine[0].id,listOfPackage[0].id,1.00,false));
        listOfInvoice_Line_Item.add(AureusCalendarControllerTestHelper.createInvLineItem(listOfinvoice[0].id,10,ListOfTeacherAccount[2].id,date.today().addDays(3),listOfEnrolment[0].id,listOfSubscLine[1].id,listOfPackage[1].id,1.00,false));
        insert listOfInvoice_Line_Item;    
        
        List<Payment__c> listOfPayment = new List<Payment__c>();
        listOfPayment.add(AureusCalendarControllerTestHelper.createPayment(listOfCustomerAccount[0].id,listOfinvoice[0].id,false));
        insert listOfPayment;
    }
}