import { LightningElement, api, track } from "lwc";
import fetchCreditMemoDetails from "@salesforce/apex/AddCreditMemoController.getCreditMemoDetails";
import createCreditMemoRec from "@salesforce/apex/AddCreditMemoController.createCreditMemo";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

//CH01 9&12 Oct 2020 Karan Singh : Incase of Refund, message should be -> ex "$20 refunded successfully via Stripe."
export default class AddCreditMemo extends LightningElement {
  @api recordId;
  @track creditMemoWrap;
  value = "";
  showModal = false;
  remarks = "";
  confirmationMessage = "";
  showConfirmBox = false;
  isLoaded = false;

  // prettier-ignore
  @track options = [
{ label: "Refund Memo", value: "Refund Memo", disabled: true, checked : false },
{ label: "Credit Memo (Future Adj)", value: "Credit Memo (Future Adj)", disabled: true,checked : false },
{ label: "Credit Memo (Invoice Cancellation)", value: "Credit Memo (Invoice Cancellation)", disabled: true,checked : false }
];

  showModalBox(event) {
    if (this.showModal) {
      this.showModal = false;
    } else {
      this.error = "";
      this.remarks = "";
      this.confirmationMessage = "";
      fetchCreditMemoDetails({ invId: this.recordId })
        .then((result) => {
          console.log(JSON.stringify(result));
          this.creditMemoWrap = result;

          if (this.creditMemoWrap.existCreditMemo) {
            const event = new ShowToastEvent({
              title: "Error",
              message:
                "Already Created Credit Memo for this Invoice : " +
                this.creditMemoWrap.existCreditMemo,
              variant: "error",
              mode: "dismissable"
            });
            this.dispatchEvent(event);
          } else if( this.creditMemoWrap.invoiceAmount == 0){

            const event = new ShowToastEvent({
              title: "Error",
              message:
                "Invoice does not have sufficient amount for adding credit memo",
              variant: "error",
              mode: "dismissable"
            });
            this.dispatchEvent(event);

          }else {
            this.showModal = true;
            this.options.forEach((opt) => {
              if (
                opt.value === "Credit Memo (Future Adj)" &&
                this.creditMemoWrap.invoiceStatus === "Paid"
              ) {
                opt.checked = true;
                opt.disabled = false;
                this.value = opt.value;
              } else if (
                opt.value === "Refund Memo" &&
                this.creditMemoWrap.invoiceStatus === "Paid"
              ) {
                opt.checked = false;
                opt.disabled = false;
              } else if (
                opt.value === "Credit Memo (Invoice Cancellation)" &&
                this.creditMemoWrap.invoiceStatus === "Due"
              ) {
                opt.checked = true;
                opt.disabled = false;
                this.value = opt.value;
              }
            });
          }
        })
        .catch((error) => {
          console.log(error);
          this.showModal = false;
          this.error = error;
        });
    }
  }

  showConfirmModalBox(event) {
    /*instead of output , it will be read only field
  if (isNaN(this.userEnteredAmount)) {
    let userAmnt = this.template.querySelector(".userAmount");
    userAmnt.setCustomValidity("Please input valid amount.");
    userAmnt.reportValidity();
    return;
  } */
    if (!this.remarks || !this.remarks.trim()) {
      let userRemarks = this.template.querySelector(".userRemarks");
      userRemarks.setCustomValidity("Enter a valid reason.");
      userRemarks.reportValidity();

      return;
    }
    /*instead of output , it will be read only field
  if (Number(this.userEnteredAmount) > this.creditMemoWrap.invoiceAmount) {
    return;
  } else if (Number(this.userEnteredAmount) < 0) {
    return;
  }*/

    if (this.showConfirmBox) {
      this.showConfirmBox = false;
    } else {
      this.showConfirmBox = true;
    }

    if (this.value === "Refund Memo") {
      //  prettier-ignore
      this.confirmationMessage ="This will create a Credit memo ( " +this.value +" ) and also refund "+ this.creditMemoWrap.invoiceCurrcyCode+" "+this.creditMemoWrap.invoiceAmount +
    " amount via stripe. Do you want to continue?";
    } else {
      //  prettier-ignore
      this.confirmationMessage =
      "This will create a " + this.value + " of amount "+ this.creditMemoWrap.invoiceCurrcyCode+" "+ this.creditMemoWrap.invoiceAmount +". Do you want to continue?";
    }
  }

  createCreditMemo(event) {
    this.isLoaded = true;
    console.log(JSON.stringify(this.creditMemoWrap));
    createCreditMemoRec({
      creditWrapJson: JSON.stringify(this.creditMemoWrap),
      creditMode: this.value,
      remarks: this.remarks
    })
      .then((result) => {
        this.isLoaded = false;

        if (result === "success") {

          //CH01 Start -  added this creteria
          if( this.value == "Refund Memo" ){

            const event = new ShowToastEvent({
              title: "Success",
              message: this.creditMemoWrap.invoiceCurrcyCode + ' ' + this.creditMemoWrap.invoiceAmount +' refunded successfully via Stripe.',
              variant: "success",
              mode: "dismissable"
            });
            this.dispatchEvent(event);

          }//CH01 end
          else{

            const event = new ShowToastEvent({
              title: "Success",
              message: "Credit Memo Created",
              variant: "success",
              mode: "dismissable"
            });
            this.dispatchEvent(event);

          }
          
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
          message: "UnExpected Error : " + error.body.message,
          variant: "error",
          mode: "dismissable"
        });
        this.dispatchEvent(event);
        this.showModal = false;
        this.isLoaded = false;
        this.showConfirmBox = false;
      });
  }
  /*
  handleAmountChange(event) {
    try {
      this.userEnteredAmount = Number(event.target.value);
    } catch (err) {
      console.log(err.message);
      this.error = err.message;
    }
  }*/
  handleRemarkChange(event) {
    this.remarks = event.target.value;
  }
  handleChange(event) {
    this.value = event.target.dataset.value;
    this.options.forEach((opt) => {
      if (opt.value === this.value) {
        opt.checked = true;
      } else {
        opt.checked = false;
      }
    });
  }
}