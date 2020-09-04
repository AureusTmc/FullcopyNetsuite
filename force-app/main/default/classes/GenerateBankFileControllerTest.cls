@isTest
public class GenerateBankFileControllerTest{
    @isTest
    public static void unitTest(){
        Test.StartTest();
        GenerateBankFileController obj = new GenerateBankFileController();
        obj.getMonthList();
        obj.getYearList();
        obj.getOrganisationList();
        obj.generate();
        Test.StopTest();
    }
}