/*
Name        :        EnrolmentEmailProcessCntrlTest
Date        :        8th Aug 2019
Author      :        Rajesh Sahu
Description :        It is the test class of EnrolmentEmailProcessCntrl.
*/

@isTest
public class EnrolmentEmailProcessCntrlTest {
	
    public static testMethod void invokeEnrolmentProcessController(){
        ApexPages.currentPage().getParameters().put('email','test@gmail.com');
        ApexPages.currentPage().getParameters().put('es','enrolmentSource');
        ApexPages.currentPage().getParameters().put('country','SG');
        
        EnrolmentEmailProcessCntrl enr = new EnrolmentEmailProcessCntrl();
        enr.redirectToEnrolment();
    }
}