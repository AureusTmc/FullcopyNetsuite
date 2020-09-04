/*
Name        :        RegularInvoiceHandlerTest
Date        :        8 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of RegularInvoiceHandler.
*/

@isTest
public class RegularInvoiceHandlerTest {
    
    public static testMethod void invokeRegularInvoiceHandler(){
        List<Enrolment__c> enrolmentList = new List<Enrolment__c>();
        Date firstDate, lastDate;
        firstDate = Date.newInstance(System.today().year(), System.today().month(), 05);
        lastDate = firstDate.addDays(10);
        Account objCustmr = TestUtil.createAccount('Customer',TRUE,FALSE);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
        Firebase_Settings__c objSetting = new Firebase_Settings__c();
        objSetting.Name = 'setting';
        objSetting.Enable_Notifications__c = false;
        insert objSetting;
        Country__c country = new Country__c(); 
        country.Name = 'IN'; 
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0; 
        country.Currency_Code__c = 'INR'; 
        country.Student_Policies_Template_Id__c = 'test'; 
        country.Stripe_Base_Url__c = 'www.test.com'; 
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede'; 
        insert country;
        
        Account objCentr = TestUtil.createAccount('Centre',TRUE,FALSE);
        objCentr.Country__c = country.Id;
        INSERT objCentr;
        
        Account objTeachr = TestUtil.createAccount('Teacher',TRUE,TRUE);
        
        Program__c objProg = TestUtil.createProgram('Active','Piano', TRUE);
        Package__c objPack = TestUtil.createPackage(objProg.Id, objCentr.Id,'30',True);
        
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol.Lesson_Day__c = 'Monday';
        objENrol.Promotional_Period_End_Date__c = lastDate.addDays(-3);
        Enrolment__c objENrol2=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol2.Lesson_Day__c = 'Tuesday';
        objENrol2.Promotional_Period_End_Date__c = lastDate.addDays(-3);
        Enrolment__c objENrol3=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol3.Lesson_Day__c = 'Wednesday';
        objENrol3.Promotional_Period_End_Date__c = lastDate.addDays(-3);
        Enrolment__c objENrol4=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol4.Lesson_Day__c = 'Thursday';
        objENrol4.Promotional_Period_End_Date__c = lastDate.addDays(-3);
        Enrolment__c objENrol5=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol5.Lesson_Day__c = 'Friday';
        objENrol5.Promotional_Period_End_Date__c = lastDate.addDays(-3);
        Enrolment__c objENrol6=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol6.Lesson_Day__c = 'Saturday';
        objENrol6.Promotional_Period_End_Date__c = lastDate.addDays(-3);
        Enrolment__c objENrol7=TestUtil.createEnrolment(objCentr.Id,objTeachr.Id,objCustmr.Id,objPack.id,false);
        objENrol7.Lesson_Day__c = 'Sunday';
        objENrol7.Promotional_Period_End_Date__c = lastDate.addDays(-3);
        
        insert objENrol;
        
        Subscription__C objSub=TestUtil.createSubscription(objCustmr.id,true);
        Subscription_Line_Item__c objSubLine=TestUtil.createSubscriptionLineItem(objSub.id	,false);
        objSubLine.Enrolment__c = objENrol.Id;
        insert objSubLine;
        Invoice__C objInv=TestUtil.createInvoice(objCustmr.id, true);
        Map<String,List<Date>> mapOfDates= new Map<String,List<Date>>();
        DateTime startDt, endDt;
        startDt = DateTime.newInstance(Date.newInstance(System.today().year(), System.today().Month(), 01), Time.newInstance(0, 0, 0, 0));
        endDt =  DateTime.newInstance(startDt.date().addMonths(1).addDays(-1), Time.newInstance(0, 0, 0, 0));
        while(startDt != endDt){
            if(startDt.format('EEEE') == 'Monday'){
                if(mapOfDates.containsKey(startDt.format('EEEE'))){
                    List<Date> dates = mapOfDates.get(startDt.format('EEEE'));
                    dates.add(startDt.date());
                    mapOfDates.put(startDt.format('EEEE'), dates);
                }else{
                    mapOfDates.put(startDt.format('EEEE'),new List<Date> {startDt.date()});                    
                }
                
            }
            startDt =  startDt.addDays(1);                                                    
        }
        
        objSubLine = [SELECT Id,Enrolment__r.recordtype.Name,Enrolment__r.Center__c,Enrolment__r.Center__r.Country__c,Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                      Enrolment__r.Promotional_Period_End_Date__c, Enrolment__r.Lesson_Day__c, 
                      Enrolment__r.Package__r.Unit_Fee__c, Enrolment__r.Package__c, Enrolment__r.Teacher__c 
                      FROM Subscription_Line_Item__c WHERE Id =: objSubLine.Id LIMIT 1];
        RegularInvoiceHandler objRegINV= new RegularInvoiceHandler(objSubLine, firstDate, lastDate);
        
        objRegINV.createInvoiceLineItem(objInv,mapOfDates);
    }
    // added by jatin: 18-mar-2020: for  Paino rental enrolment testing 
    public static testMethod void invokeRegularInvoiceHandlerPainoRental(){
        ClassEditControllerTestHelper.createGroupClassData();
        Date firstDate, lastDate;
        firstDate = Date.newInstance(System.today().year(), System.today().month(), 05);
        lastDate = firstDate.addDays(10);
        List<Invoice__C> listOfInvoice = [select id from invoice__C];
        List<Subscription_Line_Item__c> listOfSubLine = [SELECT Id,Enrolment__r.recordtype.Name,Enrolment__r.Center__c,Enrolment__r.Center__r.Country__c,Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                                      Enrolment__r.Promotional_Period_End_Date__c, Enrolment__r.Lesson_Day__c,Amount__c, 
                                      Enrolment__r.Package__r.Unit_Fee__c, Enrolment__r.Package__c, Enrolment__r.Teacher__c 
                                      FROM Subscription_Line_Item__c LIMIT 1];
        Map<String,List<Date>> mapOfDates= new Map<String,List<Date>>();
        DateTime startDt, endDt;
        startDt = DateTime.newInstance(Date.newInstance(System.today().year(), System.today().Month(), 01), Time.newInstance(0, 0, 0, 0));
        endDt =  DateTime.newInstance(startDt.date().addMonths(1).addDays(-1), Time.newInstance(0, 0, 0, 0));
        while(startDt != endDt){
            if(startDt.format('EEEE') == 'Monday'){
                if(mapOfDates.containsKey(startDt.format('EEEE'))){
                    List<Date> dates = mapOfDates.get(startDt.format('EEEE'));
                    dates.add(startDt.date());
                    mapOfDates.put(startDt.format('EEEE'), dates);
                }else{
                    mapOfDates.put(startDt.format('EEEE'),new List<Date> {startDt.date()});                    
                }
                
            }
            startDt =  startDt.addDays(1);                                                    
        }
        RegularInvoiceHandler objRegINV= new RegularInvoiceHandler(listOfSubLine[0], firstDate, lastDate);
         objRegINV.createInvoiceLineItem(listOfInvoice[0],mapOfDates);
        
    }
    
    public static testMethod void invokeRegularInvoiceHandlerPainoRental2(){
        PianoRentalTestHelper.createPianoRentalData();
        Date firstDate, lastDate;
        firstDate = Date.newInstance(System.today().year(), System.today().month(), 05);
        lastDate = firstDate.addDays(10);
        List<Invoice__C> listOfInvoice = [select id from invoice__C];
        List<Subscription_Line_Item__c> listOfSubLine = [SELECT Id,Enrolment__r.recordtype.Name,Enrolment__r.Center__c,Enrolment__r.Center__r.Country__c,Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                                      Enrolment__r.Promotional_Period_End_Date__c, Enrolment__r.Lesson_Day__c,Amount__c,Enrolment__r.Termination_request_date__c ,
                                      Enrolment__r.Package__r.Unit_Fee__c, Enrolment__r.Package__c, Enrolment__r.Teacher__c 
                                      FROM Subscription_Line_Item__c LIMIT 1];
        Map<String,List<Date>> mapOfDates= new Map<String,List<Date>>();
        DateTime startDt, endDt;
        startDt = DateTime.newInstance(Date.newInstance(System.today().year(), System.today().Month(), 01), Time.newInstance(0, 0, 0, 0));
        endDt =  DateTime.newInstance(startDt.date().addMonths(1).addDays(-1), Time.newInstance(0, 0, 0, 0));
        while(startDt != endDt){
            if(startDt.format('EEEE') == 'Monday'){
                if(mapOfDates.containsKey(startDt.format('EEEE'))){
                    List<Date> dates = mapOfDates.get(startDt.format('EEEE'));
                    dates.add(startDt.date());
                    mapOfDates.put(startDt.format('EEEE'), dates);
                }else{
                    mapOfDates.put(startDt.format('EEEE'),new List<Date> {startDt.date()});                    
                }
                
            }
            startDt =  startDt.addDays(1);                                                    
        }
        RegularInvoiceHandler objRegINV= new RegularInvoiceHandler(listOfSubLine[0], firstDate, lastDate);
         objRegINV.createInvoiceLineItem(listOfInvoice[0],mapOfDates);
    }
    
    
}