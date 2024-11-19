namespace AvantMoney.ExportDailyMonthly;
using System.IO;
using Microsoft.Foundation.Calendar;
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
        DateRec: Record Date;
        GeneralLedgerSetup: Record "General Ledger Setup";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        DownloadFileToLocal: Boolean;
        ContainerName: Text[2048];
        MessageID: Text[100];
        ErrorMessage: Text;
        DailyBalanceNamePrefixTxt: Label 'DAILY_BALANCE_', Locked = true;
        MonthlyBalanceNamePrefixTxt: Label 'MONTHLY_BALANCE_', Locked = true;
        IsNotWorkingDayErr: Label 'Date = %1 is non working day.', Comment = '%1=Date value';
        FileNotCreatedErr: Label 'File for date = %1 is not created.', Comment = '%1=Date value';
        FileNotUploadedErr: Label 'File for date = %1 is not uploaded on container.', Comment = '%1=Date value';
        DialogTitle2_Txt: Label 'Download file...';


    local procedure ExportDailyFiles()
    var
        DailyMonthlyRegister: Record "PTE Daily/Monthly Register";
    begin
        DailyMonthlyRegister.Reset();
        DailyMonthlyRegister.SetCurrentKey("Export File Type", Status, "Export Date");
        DailyMonthlyRegister.SetRange("Export File Type", DailyMonthlyRegister."Export File Type"::Baldia);
        DailyMonthlyRegister.SetRange("Status", DailyMonthlyRegister.Status::"Exported as Blob");
        if not DailyMonthlyRegister.FindLast() then
            ExportDailyBalanceFileOnAzure(Today)
        else begin
            DateRec.Reset();
            DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
            DateRec.SetRange("Period Start", DailyMonthlyRegister."Export Date", Today());
            if DateRec.FindSet() then
                repeat
                    ExportDailyBalanceFileOnAzure(DateRec."Period Start")
                until DateRec.Next() <> 0;
        end;

        // DailyMonthlyRegister.Reset();
        // DailyMonthlyRegister.SetCurrentKey("Export File Type", Status, "Export Date");
        // DailyMonthlyRegister.SetRange("Export File Type", DailyMonthlyRegister."Export File Type"::Balajust);
        // DailyMonthlyRegister.SetRange("Status", DailyMonthlyRegister.Status::"Exported as Blob");
        // if not DailyMonthlyRegister.FindLast() then
        //     ExportMonthlyBalanceFileOnAzure(Today)
        // else begin
        //     DateRec.Reset();
        //     DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        //     DateRec.SetRange("Period Start", DailyMonthlyRegister."Export Date", CalcDate('<CM>', Today()));
        //     if DateRec.FindSet() then
        //         repeat
        //             ExportMonthlyBalanceFileOnAzure(DateRec."Period Start")
        //         until DateRec.Next() <> 0;
        // end;
    end;

    procedure ExportDailyBalanceFileOnAzure(BalanceDate: Date) Result: Boolean
    var
        GlAccount: record "G/L Account";
        DailyMonthlyRegister: Record "PTE Daily/Monthly Register";
        ABSBlobClient: Codeunit "ABS Blob Client";
        ABSOperationResponse: Codeunit "ABS Operation Response";
        FileName: Text;
        BlobFileName: Text;
        FileContent: BigText;
        XMLPortID: Integer;
        FileCreated: Boolean;
        FileCreatedOnContainer: Boolean;
        IsHandled: Boolean;
        Encoding: TextEncoding;
        FileStatus: enum "PTE Baldia Balajust Status";
        FileType: Enum "PTE Export File Type";
        InStr: InStream;
    begin
        MessageID := DailyBalanceNamePrefixTxt + Format(BalanceDate, 0, '<Year4><Month,2><Day,2>');
        Clear(DailyMonthlyRegister);
        DailyMonthlyRegister.CreateNew(MessageID, FileType);

        GeneralLedgerSetup.GetRecordOnce();
        if IsNonWorkingDay(BalanceDate) then begin
            DailyMonthlyRegister.FindLast();
            ErrorMessage := StrSubstNo(IsNotWorkingDayErr, BalanceDate);
            SetDailyMonthlyRegisterToFileError(DailyMonthlyRegister, FileStatus::"Error on Export", ErrorMessage);
        end;

        Clear(ABSBlobClient);
        Clear(ABSOperationResponse);

        if BalanceDate = 0D then
            BalanceDate := Today;
        XMLPortID := XmlPort::"PTE Baldia Daily Balance";
        BlobFileName := DailyBalanceNamePrefixTxt + Format(BalanceDate, 0, '<Year4><Month,2><Day,2>') + '.txt';
        GlAccount.SetRange("Account Type", GlAccount."Account Type"::Posting);
        GlAccount.SetRange("Date Filter", BalanceDate);

        IsHandled := false;
        OnBeforeExportDailyBalanceFileOnAzure(GlAccount, XMLPortID, Result, BlobFileName, IsHandled);
        if IsHandled then
            exit(Result);

        FileName := BlobFileName;
        FileCreated := GenerateDailyBalanceFile(TempBlob, XMLPortID, GlAccount);
        TempBlob.CreateInStream(InStr);
        if GeneralLedgerSetup."PTE Upload Files on Container" and FileCreated then begin
            InitializeABSBlobClient(ABSBlobClient);
            ABSOperationResponse := ABSBlobClient.DeleteBlob(BlobFileName);
            OnBeforeUploadFileToContainer(ABSBlobClient, ABSOperationResponse, BlobFileName, TempBlob, DailyMonthlyRegister, Result, IsHandled);
            if IsHandled then
                exit(Result);

            FileCreatedOnContainer := UploadFileToContainer(ABSBlobClient, ABSOperationResponse, BlobFileName, InStr);
            if not FileCreatedOnContainer then begin
                DailyMonthlyRegister.FindLast();
                ErrorMessage := StrSubstNo(FileNotUploadedErr, BalanceDate);
                SetDailyMonthlyRegisterToFileError(DailyMonthlyRegister, FileStatus::"Error on Export", ErrorMessage);
            end
        end;

        DailyMonthlyRegister.FindLast();
        if FileCreated then
            SetDailyMonthlyRegisterToFileCreated(DailyMonthlyRegister, InStr, FileStatus::"Exported as Blob", BlobFileName)
        else begin
            ErrorMessage := StrSubstNo(FileNotCreatedErr, BalanceDate);
            SetDailyMonthlyRegisterToFileError(DailyMonthlyRegister, FileStatus::"Error on Export", ErrorMessage);
        end;

        if DownloadFileToLocal and FileCreated then
            DownloadFromStream(InStr, DialogTitle2_Txt, FileManagement.Magicpath(), FileManagement.GetToFilterText('', FileName), FileName);

        exit(DailyMonthlyRegister.Status = DailyMonthlyRegister.Status::"Exported as Blob");
    end;

    procedure ExportMonthlyBalanceFileOnAzure(BalanceDate: Date) Result: Boolean
    var
        GlAccount: record "G/L Account";
        DailyMonthlyRegister: Record "PTE Daily/Monthly Register";
        ABSBlobClient: Codeunit "ABS Blob Client";
        ABSOperationResponse: Codeunit "ABS Operation Response";
        FileName: Text;
        BlobFileName: Text;
        FileContent: BigText;
        XMLPortID: Integer;
        FileCreated: Boolean;
        FileCreatedOnContainer: Boolean;
        IsHandled: Boolean;
        Encoding: TextEncoding;
        FileStatus: enum "PTE Baldia Balajust Status";
        IsDownloaded: Boolean;
    begin
        // GeneralLedgerSetup.GetRecordOnce();
        // Clear(ABSBlobClient);
        // Clear(ABSOperationResponse);

        // if BalanceDate = 0D then
        //     BalanceDate := Today;
        // XMLPortID := XmlPort::"PTE Baldia Daily Balance";
        // BlobFileName := DailyBalanceNamePrefixTxt + Format(Today(), 0, 'YYYYMMDD') + '.txt';
        // GlAccount.SetRange("Account Type", GlAccount."Account Type"::Posting);
        // GlAccount.SetRange("Date Filter", BalanceDate);

        // IsHandled := false;
        // OnBeforeExportDailyBalanceFileOnAzure(GlAccount, XMLPortID, Result, BlobFileName, IsHandled);
        // if IsHandled then
        //     exit(Result);

        // FileName := BlobFileName;
        // FileCreated := GenerateDailyBalanceFile(TempBlob, XMLPortID, GlAccount);
        // if GeneralLedgerSetup."PTE Upload Files on Container" then begin
        //     InitializeABSBlobClient(ABSBlobClient);
        //     ABSOperationResponse := ABSBlobClient.DeleteBlob(BlobFileName);
        //     OnBeforeUploadFileToContainer(ABSBlobClient, ABSOperationResponse, BlobFileName, TempBlob, DailyMonthlyRegister, Result, IsHandled);
        //     if IsHandled then
        //         exit(Result);

        //     FileCreatedOnContainer := UploadFileToContainer(ABSBlobClient, ABSOperationResponse, BlobFileName)
        // end;

        // DailyMonthlyRegister.FindLast();
        // if FileCreated then
        //     SetDailyMonthlyRegisterToFileCreated(DailyMonthlyRegister, TempBlob, FileStatus::"Exported as Blob");

        // exit(DailyMonthlyRegister.Status = DailyMonthlyRegister.Status::"Exported as Blob");

        // // if DownloadFileToLocal then begin
        // //     TempBlob.CreateInStream(InStr);
        // //     IsDownloaded := DownloadFromStream(InStr, FileName, FileManagement.Magicpath(), FileManagement.GetToFilterText('', FileName), FileName);
        // // end;
    end;

    procedure GenerateDailyBalanceFile(var _TempBlob: Codeunit "Temp Blob"; XMLPortID: Integer; var GlAccount: Record "G/L Account"): Boolean
    var
        OutStrL: OutStream;
    begin
        _TempBlob.CreateOutStream(OutStrL);
        XMLPORT.Export(XMLPortID, OutStrL, GlAccount);
        exit(true);
    end;

    local procedure SetDailyMonthlyRegisterToFileCreated(var DailyMonthlyRegister: Record "PTE Daily/Monthly Register"; InStr: InStream; FileStatus: enum "PTE Baldia Balajust Status"; FileName: Text)
    begin
        DailyMonthlyRegister.Status := FileStatus;
        DailyMonthlyRegister.SetFileContent(Instr, FileName);
        //DailyMonthlyRegister.Modify();
    end;

    local procedure SetDailyMonthlyRegisterToFileError(var DailyMonthlyRegister: Record "PTE Daily/Monthly Register"; FileStatus: enum "PTE Baldia Balajust Status"; ErrorMessage: Text)
    begin
        DailyMonthlyRegister.SetStatus(FileStatus);
        DailyMonthlyRegister.SetErrorMessage(ErrorMessage);
        DailyMonthlyRegister.Modify();
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

    local procedure UploadFileToContainer(var ABSBlobClient: Codeunit "ABS Blob Client"; var ABSOperationResponse: Codeunit "ABS Operation Response"; BlobName: Text; InStr: InStream): Boolean;
    begin
        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobStream(BlobName, instr);
        exit(true);
    end;

    procedure FormatBalanceAtDate(BalanceAtDate: Decimal): Text
    var
        BalanceFormated: Text;
        FormatedValue: Text[18];
        i: Integer;
        CharsToAdd: Text;
        Sign: Text;
        DecimalsTxt: Text;
        IntegerTxt: Text;
    begin
        BalanceAtDate := Round(BalanceAtDate, 0.01);
        Sign := Format(BalanceAtDate, 0, '<Sign>');
        DecimalsTxt := FORMAT(BalanceAtDate, 0, '<Decimals,3>');
        IntegerTxt := FORMAT(BalanceAtDate, 0, '<Integer>');
        FormatedValue := IntegerTxt + DecimalsTxt;
        BalanceFormated := Sign + FormatedValue;
        while (StrLen(BalanceFormated) < 18) do begin
            i := i + 1;
            CharsToAdd := PadStr('', i, '0');
            BalanceFormated := Sign + CharsToAdd + FormatedValue;
        end;
        Exit(BalanceFormated);
    end;

    local procedure IsNonWorkingDay(TargetDate: Date): Boolean
    var
        BaseCalendar: record "Base Calendar";
        CurrCalendarChange: Record "Customized Calendar Change";
        Calendar: Record Date;
        CalendarManagement: Codeunit "Calendar Management";
        NonWorkinDay: Boolean;
    begin
        GeneralLedgerSetup.GetRecordOnce();
        GeneralLedgerSetup.TestField("PTE Export Calendar Code");
        BaseCalendar.Get(GeneralLedgerSetup."PTE Export Calendar Code");
        CalendarManagement.SetSource(BaseCalendar, CurrCalendarChange);
        CurrCalendarChange.Date := TargetDate;
        NonWorkinDay := CalendarManagement.IsNonworkingDay(TargetDate, CurrCalendarChange);
        exit(NonWorkinDay);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUploadFileToContainer(var ABSBlobClient: Codeunit "ABS Blob Client"; var ABSOperationResponse: Codeunit "ABS Operation Response"; var BlobName: Text; var TempBlob: Codeunit "Temp Blob"; DailyMonthlyRegister: Record "PTE Daily/Monthly Register"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportDailyBalanceFileOnAzure(var GlAccount: record "G/L Account"; var XMLPortID: Integer; var Result: Boolean; var FileName: Text; var IsHandled: Boolean)
    begin
    end;
}