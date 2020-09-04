/*
    Name            :   AddCreditNotesControllerTest
    Date            :   22 May 2019
    Author          :   Karan Singh Soni
    Description     :   This test class is used for AddCreditNotesController.
*/
@isTest
public class AddCreditNotesControllerTest {

    public static TestMethod Void invokeAddCreditNotesController(){
        Account objCust = TestUtil.createAccount('Customer', true, true);
        AddCreditNotesController.getReasonListValues(objCust.id);
        AddCreditNotesController.createPayment('30', objCust.id, 'reason', 'otherReason');
    }
}