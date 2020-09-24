import { LightningElement, api, track } from "lwc";
import fetchCreditMemoDetails from "@salesforce/apex/RefundCreditMemoController.getCreditMemoDetails";
import RefundCreditMemoRec from "@salesforce/apex/RefundCreditMemoController.refundCreditMemo";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class RefundCreditMemo extends LightningElement {
  @api recordId;
  @track creditMemoWrap;
  showModal = false;
  confirmationMessage = "";
  showConfirmBox = false;
  isLoaded = false;

  showModalBox(event) {
    if (this.showModal) {
      this.showModal = false;
    } else {
      this.error = "";
      this.remarks = "";
      this.confirmationMessage = "";

      fetchCreditMemoDetails({ creditMemoId: this.recordId })
        .then((result) => {
          console.log(JSON.stringify(result));
          this.creditMemoWrap = result;

          if (this.creditMemoWrap.isError) {
            const event = new ShowToastEvent({
              title: "Error",
              message: "Error : " + this.creditMemoWrap.isError,
              variant: "error",
              mode: "dismissable"
            });
            this.dispatchEvent(event);
          } else {
            this.showModal = true;
          }
        })
        .catch((error) => {
          console.log(error);
          this.showModal = false;
          const event = new ShowToastEvent({
            title: "Error",
            message: "Error : " + error.body.message,
            variant: "error",
            mode: "dismissable"
          });
          this.dispatchEvent(event);
        });
    } //END OF show modal if
  }

  handleRemarkChange(event) {
    this.creditMemoWrap.userRemarks = event.target.value;
  }

  handleAmountChange(event) {
    this.creditMemoWrap.userEnterAMount = event.target.value;
  }

  showConfirmBoxfun(event) {
    let isErrorFound = false;
    let userAmnt = this.template.querySelector(".userAmount");
    let userRemarks = this.template.querySelector(".userRemarks");

    //if user entered not a number
    if ( !this.creditMemoWrap.userEnterAMount) {
      
      userAmnt.setCustomValidity("Please input valid amount.");
      userAmnt.reportValidity();
      isErrorFound = true;
    } else if( isNaN(this.creditMemoWrap.userEnterAMount)){
        userAmnt.setCustomValidity("Please input valid amount.");
        userAmnt.reportValidity();
        isErrorFound = true;
    }
    else if ( this.creditMemoWrap.userEnterAMount > this.creditMemoWrap.creditMemoAmnt) {

        userAmnt.setCustomValidity(
            "Entered amount cannot be greater than " + this.creditMemoWrap.creditMemoAmnt);
          userAmnt.reportValidity();
          isErrorFound = true;
    }
    else if (Number(this.creditMemoWrap.userEnterAMount) <= 0) {
      userAmnt.setCustomValidity(
        "Entered amount cannot be lesser or equal to 0 "
      );
      userAmnt.reportValidity();
      isErrorFound = true;
    } else {
      userAmnt.setCustomValidity("");
      userAmnt.reportValidity();
    }

    if ( !this.creditMemoWrap.userRemarks || !this.creditMemoWrap.userRemarks.trim()    ) {
      userRemarks.setCustomValidity("Enter a valid reason.");
      userRemarks.reportValidity();
      isErrorFound = true;
    } else {
      userRemarks.setCustomValidity("");
      userRemarks.reportValidity();
    }

   
    if (!isErrorFound) {
      this.showConfirmBox = !this.showConfirmBox;

      this.confirmationMessage =
        "This will refund " +
        this.creditMemoWrap.creditCurrcyCode +
        " " +
        this.creditMemoWrap.userEnterAMount +
        " amount via stripe. Do you want to continue?";
    }
  } //end of showConfirmBoxfun

  callRefundProcess(event) {
    this.isLoaded = true;
    console.log(JSON.stringify(this.creditMemoWrap));

    RefundCreditMemoRec({
        objCreditMemoJSON:  JSON.stringify(this.creditMemoWrap),
    })
      .then((result) => {
        this.isLoaded = false;

        console.log(result);
        
        if (result === "Success") {
            const event = new ShowToastEvent({
              title: "Success",
              message: "Credit Memo Created",
              variant: "success",
              mode: "dismissable"
            });
            this.dispatchEvent(event);
          } else {
            const event = new ShowToastEvent({
              title: "Error",
              message: "UnExpected Error : " + result,
              variant: "error",
              mode: "dismissable"
            });
            this.dispatchEvent(event);
          }
          this.showModal = false;
          this.isLoaded = false;
          this.showConfirmBox = false;
      })
      .catch((error) => {
        console.log(error);
        const event = new ShowToastEvent({
          title: "Error",
          message: "Unexpected Error : " + error.body.message,
          variant: "error",
          mode: "dismissable"
        });
        this.dispatchEvent(event);
        this.showModal = false;
        this.isLoaded = false;
        this.showConfirmBox = false;
      });
  } //end of callRefundProcess
}
