namespace AvantMoney.ExportDailyMonthly;
using System.IO;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Azure.Storage;
using Microsoft.Finance.GeneralLedger.Account;
using System.Utilities;

codeunit 50500 "PTE Daily/Monthly Export"
{
    trigger OnRun()
    begin
        ExportDailyFiles();
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        DownloadFileToLocal: Boolean;
        ContainerName: Text[2048];
        DailyBalanceNamePrefixTxt: Label 'DAILY_BALANCE_', Locked = true;
        MonthlyBalanceNamePrefixTxt: Label 'MONTHLY_BALANCE_', Locked = true;

    local procedure ExportDailyFiles()
    var
        myInt: Integer;
    begin

    end;

    procedure ExportDailyBalanceFileOnAzure(BalanceDate: Date) Result: Boolean
    var
        GlAccount: record "G/L Account";
        CreditTransferRegister: Record "PTE Daily/Monthly Register";
        ABSBlobClient: Codeunit "ABS Blob Client";
        ABSOperationResponse: Codeunit "ABS Operation Response";
        FileName: Text;
        BlobFileName: Text;
        FileContent: BigText;
        XMLPortID: Integer;
        FileCreated: Boolean;
        IsHandled: Boolean;
        Encoding: TextEncoding;
        IsDownloaded: Boolean;
    begin
        GeneralLedgerSetup.GetRecordOnce();
        Clear(ABSBlobClient);
        Clear(ABSOperationResponse);

        if BalanceDate = 0D then
            BalanceDate := Today;
        XMLPortID := XmlPort::"PTE Baldia Daily Balance";
        BlobFileName := DailyBalanceNamePrefixTxt + Format(Today(), 0, 'YYYYMMDD') + '.txt';
        GlAccount.SetRange("Account Type", GlAccount."Account Type"::Posting);
        GlAccount.SetRange("Date Filter", BalanceDate);

        IsHandled := false;
        OnBeforeExtport(GlAccount, XMLPortID, Result, BlobFileName, IsHandled);
        if IsHandled then
            exit(Result);

        InitializeABSBlobClient(ABSBlobClient);
        ABSOperationResponse := ABSBlobClient.DeleteBlob(BlobFileName);
        GenerateDailyBalanceFile(TempBlob, XMLPortID, GlAccount);
        UploadFileToContainer(ABSBlobClient, ABSOperationResponse, BlobFileName);

        FileName := BlobFileName;
        CreditTransferRegister.FindLast();
        OnBeforeBLOBExportToAzureBlobStorage(TempBlob, CreditTransferRegister, FileCreated, IsHandled);

        if FileCreated then
            SetCreditTransferRegisterToFileCreated(CreditTransferRegister, TempBlob);

        //exit(CreditTransferRegister.Status = CreditTransferRegister.Status::"File Created");

        if DownloadFileToLocal then begin
            TempBlob.CreateInStream(InStr);
            IsDownloaded := DownloadFromStream(InStr, FileName, FileManagement.Magicpath(), FileManagement.GetToFilterText('', FileName), FileName);
        end;
    end;

    procedure GenerateDailyBalanceFile(var _TempBlob: Codeunit "Temp Blob"; XMLPortID: Integer; var GlAccount: Record "G/L Account")
    var
        OutStrL: OutStream;
    begin
        _TempBlob.CreateOutStream(OutStrL);
        XMLPORT.Export(XMLPortID, OutStrL, GlAccount);
    end;

    local procedure SetCreditTransferRegisterToFileCreated(var CreditTransferRegister: Record "PTE Daily/Monthly Register"; var TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        //CreditTransferRegister.Status := CreditTransferRegister.Status::"File Created";
        RecordRef.GetTable(CreditTransferRegister);
        TempBlob.ToRecordRef(RecordRef, CreditTransferRegister.FieldNo("Exported File"));
        RecordRef.SetTable(CreditTransferRegister);
        CreditTransferRegister.Modify();
    end;

    procedure EnableDownloadFileToLocal()
    begin
        DownloadFileToLocal := true;
    end;

    local procedure InitializeABSBlobClient(var ABSBlobClient: Codeunit "ABS Blob Client")
    var
        StorageServiceAuthorization: Codeunit "Storage Service Authorization";
        Authorization: Interface "Storage Service Authorization";
        AccountAccesKey: Text;
        AccountName: Text[250];
    begin
        GeneralLedgerSetup.GetRecordOnce();
        GeneralLedgerSetup.TestField("PTE D.M. Account Name");
        GeneralLedgerSetup.TestField("PTE D.M. Account Access Key");
        GeneralLedgerSetup.TestField("PTE D.M. Account Container");

        AccountName := GeneralLedgerSetup."PTE D.M. Account Name";
        ContainerName := GeneralLedgerSetup."PTE D.M. Account Container";
        AccountAccesKey := GeneralLedgerSetup.PTEGetPassword();

        Authorization := StorageServiceAuthorization.CreateSharedKey(SecretText.SecretStrSubstNo('%1', AccountAccesKey));
        ABSBlobClient.Initialize(AccountName, ContainerName, Authorization);
    end;

    local procedure UploadFileToContainer(var ABSBlobClient: Codeunit "ABS Blob Client"; var ABSOperationResponse: Codeunit "ABS Operation Response"; BlobName: Text)
    var
        Instr: Instream;
        Outstr: OutStream;
    begin
        TempBlob.CreateInStream(Instr);

        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobStream(BlobName, instr);

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBLOBExportToAzureBlobStorage(var TempBlob: Codeunit "Temp Blob"; CreditTransferRegister: Record "PTE Daily/Monthly Register"; var FieldCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExtport(var GlAccount: record "G/L Account"; var XMLPortID: Integer; var Result: Boolean; var FileName: Text; var IsHandled: Boolean)
    begin
    end;
}