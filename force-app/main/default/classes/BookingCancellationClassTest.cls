@isTest
public class BookingCancellationClassTest {
    public static TestMethod void ChecEnrolment(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,true);
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);  
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c = 'Trial';
        objEnrol.Stage__c = 'Requested';
        insert objENrol;
        //Enrolment__c objEnrol = TestUtil.createEnrolment(true);
        
        BookingCancellationClass.getEnrolment(objENrol.Id); 
        
        Booking__c bkgObj = new Booking__c();
        bkgObj.Student__c=objCustmr.Id;
        bkgObj.Center__c=objCentr.Id;
        bkgObj.Parent__c=objCustmr.Id;
        bkgObj.Booking_Date__c=System.today();
        
        insert bkgObj;
        List<BookingCancellationClass.Wrapperclass> wrpList = new List<BookingCancellationClass.Wrapperclass>();
        BookingCancellationClass.Wrapperclass wrp = new BookingCancellationClass.Wrapperclass();
        wrp.Student=objCustmr.Id;
        wrp.Parent=objCustmr.Id;
        wrp.Center=objCentr.Id;
        wrp.Booking_Date=string.valueof(System.today());
        wrp.Start_Time='13:30:00.000';
        wrp.End_Time='13:30:00.000';
        wrp.Duration='15';
        wrp.Available_Make_up_Units='21';
        wrpList.add(wrp);
        
        BookingCancellationClass.saveBooking(JSON.serialize(wrpList));
        
            
    }
    	 
        

}