import { LightningElement, track, api } from "lwc";
import fetchBigEmail from "@salesforce/apex/BigEmailMessageController.fetchBigEmailMessages";

export default class BigEmailMessage extends LightningElement {
  totalEmailMessage = " Archive Emails (0)";
  @track listBigEmailMessage = []; //this will fetch Limited Big Email Messages
  @track listBigEmailMessagePaginated = []; //this will used for the pagination
  @api recordId;
  @track actions = [{ label: "View", name: "view" }];
  @track activeSections = [
    "Information",
    "AddressInformation",
    "MessageContent"
  ];
  @track columns = [
    { label: "S.No", fieldName: "index", initialWidth: 40 },
    { label: "Subject", fieldName: "subject" },
    { label: "From Address", fieldName: "fromAddress" },
    { label: "To Address", fieldName: "toAddress" },
    { label: "Message Date", fieldName: "MessageDate" },
    { type: "action", typeAttributes: { rowActions: this.actions } }
  ];

  intialRecordCount = 5;
  isDataFetchCorrectly = false;
  errorMessage = "";
  tableSpinner = false;
  showRecordModal = false;
  selectedEMailRecord;
  showViewAll = false;
  disablePrev;
  disableNext;
  startPage;
  endPage;
  totalRecords;
  pageSize = 5;

  constructor() {
    super();
    this.tableSpinner = true;
    fetchBigEmail({ limitRec: this.intialRecordCount, recordId: this.recordId })
      .then((result) => {
        console.log(result);
        if (result.length == 1 && result[0].isError.includes("Error : ")) {
          this.errorMessage =
            result[0].isError + ". Please contact Salesforce Administrator.";
        } else if (result.length > 0) {
          this.listBigEmailMessagePaginated = result;
          this.isDataFetchCorrectly = true;

          //to show the record count, incase if records are more than intialRecordCount then show +
          //else just show the record count
          if (
            this.listBigEmailMessagePaginated.length > this.intialRecordCount
          ) {
            this.totalEmailMessage = " Archive Emails (5+)";
            this.listBigEmailMessagePaginated.pop();
            console.log(this.listBigEmailMessagePaginated.length);
          } else {
            this.totalEmailMessage =
              " Archive Emails (" +
              this.listBigEmailMessagePaginated.length +
              ")";
          }
        }
        this.tableSpinner = false;
      })
      .catch((error) => {
        console.log(error);
        this.errorMessage =
          JSON.stringify(error) + ". Please contact Salesforce Administrator.";
        this.tableSpinner = false;
      });
  }

  fetchMoreEmailMessage(event) {
    console.log(this.showViewAll);
    if (this.showViewAll) {
      console.log("ALready Fetched All records");
      return;
    }
    this.tableSpinner = true;
    fetchBigEmail({ limitRec: 0, recordId: this.recordId })
      .then((result) => {
        console.log(result);
        if (result.length == 1 && result[0].isError.includes("Error : ")) {
          this.errorMessage =
            result[0].isError + ". Please contact Salesforce Administrator.";
        } else if (result.length > 0) {
          this.listBigEmailMessage = result;
          this.totalEmailMessage =
            " Archive Emails (" + this.listBigEmailMessage.length + ")";
        }
        this.tableSpinner = false;
        this.showViewAll = true;
        this.startPage = 0;
        this.endPage = this.pageSize - 1;
        this.listBigEmailMessagePaginated = this.listBigEmailMessage.slice(
          0,
          this.pageSize
        );
      })
      .catch((error) => {
        console.log(error);
        this.errorMessage =
          JSON.stringify(error) + ". Please contact Salesforce Administrator.";
        this.tableSpinner = false;
      });
  }
  handleRowAction(event) {
    //5002s000000nHnBAAU
    //https://www.salesforcecodecrack.com/2019/07/lightning-datatable-with-row-actions-in.html
    //https://salesforce.stackexchange.com/questions/219619/search-functionality-in-lightningdatatable
    //https://www.forcetree.com/2019/06/lightning-datatable-client-search.html
    let actionName = event.detail.action.name;
    window.console.log("actionName ====> " + actionName);
    let row = event.detail.row;
    window.console.log("row  ====> " + JSON.stringify(row));
    this.selectedEMailRecord = row;

    console.log(" --> " + JSON.stringify(this.selectedEMailRecord));
    this.showRecordModal = true;
  }
  handleCloseModal(event) {
    this.showRecordModal = false;
  }

  handleNext(event) {
    console.log(this.listBigEmailMessage);
    console.log(this.endPage);
    console.log(this.pageSize);
    console.log(this.endPage + this.pageSize + 1);

    if (this.endPage + 1 >= this.listBigEmailMessage.length) {
      return;
    }
    this.tableSpinner = true;
    this.listBigEmailMessagePaginated = [];
    let recordCounter = 0;

    for (
      var index = this.endPage + 1;
      index < this.endPage + this.pageSize + 1;
      index++
    ) {
      if (this.listBigEmailMessage.length > index) {
        this.listBigEmailMessagePaginated.push(this.listBigEmailMessage[index]);
      }
      recordCounter++;
    }
    console.log(this.listBigEmailMessagePaginated);

    this.startPage = this.startPage + recordCounter;
    this.endPage = this.endPage + recordCounter;
    console.log(this.endPage);
    console.log(this.startPage);
    this.tableSpinner = false;
  }
  handlePrev(event) {
    console.log(this.listBigEmailMessage);
    console.log(this.endPage);
    console.log(this.pageSize);
    console.log(this.startPage);
    console.log(this.startPage - this.pageSize);

    if (this.startPage <= 0) {
      return;
    }
    this.tableSpinner = true;
    this.listBigEmailMessagePaginated = [];
    let recordCounter = 0;

    for (
      var index = this.startPage - this.pageSize;
      index < this.startPage;
      index++
    ) {
      if (index > -1) {
        this.listBigEmailMessagePaginated.push(this.listBigEmailMessage[index]);
        recordCounter++;
      } else {
        this.startPage++;
      }
    }
    this.startPage = this.startPage - recordCounter;
    this.endPage = this.endPage - recordCounter;

    console.log("--> " + this.startPage);
    console.log("--> " + this.endPage);
    this.tableSpinner = false;
  }
}
