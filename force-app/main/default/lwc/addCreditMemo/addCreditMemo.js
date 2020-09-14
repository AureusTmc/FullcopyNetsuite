import { LightningElement, api, track } from "lwc";
import fetchCreditMemoDetails from "@salesforce/apex/AddCreditMemoController.getCreditMemoDetails";
import createCreditMemoRec from "@salesforce/apex/AddCreditMemoController.createCreditMemo";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class AddCreditMemo extends LightningElement {
  @api recordId;
  @track creditMemoWrap;
  value = "";
  showModal = false;
  error = "";
  remarks = "";
  confirmationMessage = "";
  showConfirmBox = false;
  userEnteredAmount;
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
      fetchCreditMemoDetails({ invId: this.recordId })
        .then((result) => {
          this.creditMemoWrap = result;
          this.userEnteredAmount = this.creditMemoWrap.invoiceAmount;
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
        })
        .catch((error) => {
          console.log(error);
          this.showModal = false;
          this.error = error;
        });
    }
  }

  showConfirmModalBox(event) {
    if (this.showConfirmBox) {
      this.showConfirmBox = false;
    } else {
      this.showConfirmBox = true;
    }

    if (this.value === "Refund Memo") {
      //  prettier-ignore
      this.confirmationMessage ="This will create a Credit memo ( " +this.value +" ) and also refund " +this.userEnteredAmount +
      " amount via stripe. Do you want to continue?";
    } else {
      //  prettier-ignore
      this.confirmationMessage =
        "This will create a " + this.value + " of amount "+ this.userEnteredAmount +". Do you want to continue?";
    }
  }

  createCreditMemo(event) {
    this.isLoaded = true;
    createCreditMemoRec({
      userAmount: this.userEnteredAmount,
      creditWrap: this.creditMemoWrap,
      creditMode: this.value,
      remarks: this.remarks
    })
      .then((result) => {
        alert(JSON.stringify(result));
        this.isLoaded = false;
        const event = new ShowToastEvent({
          title: "Success",
          message: "Credit Memo Created",
          variant: "success",
          mode: "dismissable"
        });
        this.dispatchEvent(event);
        this.showModal = false;
        this.isLoaded = false;
        this.showConfirmBox = false;
      })
      .catch((error) => {
        console.log(error);
        this.error = error;
        this.isLoaded = false;
      });
  }
  handleAmountChange(event) {
    try {
      this.userEnteredAmount = Number(event.target.value);
    } catch (err) {
      console.log(err.message);
      this.error = err.message;
    }
  }
  handleRemarkChange(event) {
    this.remarks = event.target.value;
    console.log(this.remarks);
    console.log(event.target.value);
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
