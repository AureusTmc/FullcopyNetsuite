@isTest
public class ClashBookingClasstest {
    public static testMethod void invokeClashBooking(){
       Account objCentr=TestUtil.createAccount('Centre',False,true);
         Account objtechr=TestUtil.createAccount('Teacher',False,true);
        List<Booking__c> bkgList = new List<Booking__c>();
          Booking__c objBook = new Booking__c();
        objBook.Center__c=objCentr.Id;
         objBook.Teacher_Account__c=objtechr.Id;
        objBook.Booking_Date__c=date.today().addDays(1);
        objBook.Start_Time__c=Time.newInstance(11,0,0,0);
        objBook.Type__c='Regular';
        objBook.Status__c='Pending';
        bkgList.add(objBook);
        insert objBook;
        
        ClashBookingClass.wrappBooking wrapObj = new ClashBookingClass.wrappBooking(); 
       
        wrapObj.Key=string.valueOf(objBook.Teacher_Account__c)+''+string.valueOf(objBook.Booking_Date__c) +''+string.valueOf(objBook.Start_Time__c);
        wrapObj.bookListing=bkgList;
        wrapObj.NumberRecord=1;   
         
        ClashBookingClass.getBooking(objCentr.Id);
        ClashBookingClass.getDate();
        
        
    }
}