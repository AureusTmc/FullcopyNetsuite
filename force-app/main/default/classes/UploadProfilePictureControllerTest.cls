/*
Name        :        UploadProfilePictureControllerTest
Date        :        21 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of UploadProfilePictureController.
*/

@isTest
public class UploadProfilePictureControllerTest {
    public static testMethod void UploadProfilePictureControllerTest(){   
        Account objTeach=TestUtil.createAccount('Teacher',False, True);
        Attachment objAttach=TestUtil.createAttachment(objTeach.id, true);
        Attachment getAttach=UploadProfilePictureController.getProfilePicture(objTeach.Id);
        
        Id saveAttach=UploadProfilePictureController.saveAttachment(objTeach.Id,'TestProfile Image','TestContent','image/png');
    }
}