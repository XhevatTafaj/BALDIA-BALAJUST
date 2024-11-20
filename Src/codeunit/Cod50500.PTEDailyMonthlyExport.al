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
        ExportDailyMonthlyFiles();
    end;

    var
        DateRec: Record Date;
        GeneralLedgerSetup: Record "General Ledger Setup";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        DownloadFileToLocal: Boolean;
        ContainerName: Text[2048];
        MessageID: Text[50];
        ErrorMessage: Text;
        DailyBalanceNamePrefixTxt: Label 'DAILY_BALANCE_', Locked = true;
        MonthlyBalanceNamePrefixTxt: Label 'MONTHLY_BALANCE_', Locked = true;
        IsNotWorkingDayErr: Label 'Date = %1 is non working day.', Comment = '%1=Date value';
        FileNotCreatedErr: Label 'File for date = %1 is not created.', Comment = '%1=Date value';
        FileNotUploadedErr: Label 'File for date = %1 is not uploaded on container.', Comment = '%1=Date value';
        DialogTitle2_Txt: Label 'Download file...';


    procedure ExportDailyMonthlyFiles()
    var
        DailyMonthlyRegister: Record "PTE Daily/Monthly Register";
        FileType: Enum "PTE Export File Type";
        XMLPortID: Integer;
        DateDict: Dictionary of [Integer, Date];
        DayIndex: Integer;
        TargetDate: Date;
    begin
        XMLPortID := XmlPort::"PTE Daily Balance";
        DailyMonthlyRegister.Reset();
        DailyMonthlyRegister.SetCurrentKey("Export File Type", Status, "Export Date");
        DailyMonthlyRegister.SetRange("Export File Type", DailyMonthlyRegister."Export File Type"::Baldia);
        DailyMonthlyRegister.SetRange("Status", DailyMonthlyRegister.Status::"Exported as Blob");
        if not DailyMonthlyRegister.FindLast() then
            ExportAccountsBalanceFileOnAzure(Today(), FileType::Baldia, XMLPortID)
        else begin
            DateRec.Reset();
            DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
            DateRec.SetRange("Period Start", DailyMonthlyRegister."Export Date", Today());
            if DateRec.FindSet() then
                repeat
                    ExportAccountsBalanceFileOnAzure(DateRec."Period Start", FileType::Baldia, XMLPortID)
                until DateRec.Next() = 0;
        end;

        Clear(DateDict);
        XMLPortID := XmlPort::"PTE Monthly Balance";
        DateRec.Reset();
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetFilter("Period Start", '%1..', CalcDate('<-CM>', Today()));
        if DateRec.FindSet() then
            repeat
                if not IsNonWorkingDay(DateRec."Period Start") then begin
                    DayIndex := DayIndex + 1;
                    DateDict.Add(DayIndex, DateRec."Period Start");
                end;
            until (DateRec.Next() = 0) or (DayIndex >= 5);

        DayIndex := 0;
        foreach DayIndex in DateDict.Keys() do begin
            TargetDate := DateDict.Get(DayIndex);
            ExportAccountsBalanceFileOnAzure(TargetDate, FileType::Balajust, XMLPortID)
        end;
    end;

    procedure ExportDailyBalanceFileOnAzure(BalanceDate: Date)
    var
        FileType: Enum "PTE Export File Type";
        XMLPortID: Integer;
    begin
        XMLPortID := XmlPort::"PTE Daily Balance";
        ExportAccountsBalanceFileOnAzure(BalanceDate, FileType::Baldia, XMLPortID);
    end;

    procedure ExportMonthlyBalanceFileOnAzure(TargetDate: Date)
    var
        FileType: Enum "PTE Export File Type";
        XMLPortID: Integer;
    begin
        XMLPortID := XmlPort::"PTE Monthly Balance";
        ExportAccountsBalanceFileOnAzure(TargetDate, FileType::Balajust, XMLPortID);
    end;

    local procedure ExportAccountsBalanceFileOnAzure(TargetDate: Date; FileType: Enum "PTE Export File Type"; XMLPortID: Integer) Result: Boolean
    var
        GlAccount: record "G/L Account";
        DailyMonthlyRegister: Record "PTE Daily/Monthly Register";
        ABSBlobClient: Codeunit "ABS Blob Client";
        ABSOperationResponse: Codeunit "ABS Operation Response";
        FileName: Text;
        BlobFileName: Text;
        FileContent: BigText;
        FileCreated: Boolean;
        FileCreatedOnContainer: Boolean;
        IsHandled: Boolean;
        Encoding: TextEncoding;
        FileStatus: enum "PTE Baldia Balajust Status";
        BalanceDate: Date;
        InStr: InStream;
    begin
        if TargetDate = 0D then
            TargetDate := Today();

        case FileType of
            FileType::Baldia:
                begin
                    BalanceDate := TargetDate;
                    BlobFileName := DailyBalanceNamePrefixTxt + Format(BalanceDate, 0, '<Year4><Month,2><Day,2>') + '.txt';
                    MessageID := DailyBalanceNamePrefixTxt + Format(BalanceDate, 0, '<Year4><Month,2><Day,2>');
                end;
            FileType::Balajust:
                begin
                    BalanceDate := GetPreviousMonthLastWorkingDate(TargetDate);
                    BlobFileName := MonthlyBalanceNamePrefixTxt + Format(BalanceDate, 0, '<Year4><Month,2><Day,2>') + '.txt';
                    MessageID := MonthlyBalanceNamePrefixTxt + Format(BalanceDate, 0, '<Year4><Month,2><Day,2>');
                end;
        end;

        Clear(DailyMonthlyRegister);
        DailyMonthlyRegister.CreateNew(MessageID, FileType, TargetDate, BalanceDate);

        GeneralLedgerSetup.GetRecordOnce();
        if IsNonWorkingDay(TargetDate) then begin
            DailyMonthlyRegister.FindLast();
            ErrorMessage := StrSubstNo(IsNotWorkingDayErr, TargetDate);
            SetDailyMonthlyRegisterToFileError(DailyMonthlyRegister, FileStatus::"Error on Export", ErrorMessage);
        end;

        Clear(ABSBlobClient);
        Clear(ABSOperationResponse);

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
                ErrorMessage := StrSubstNo(FileNotUploadedErr, TargetDate);
                SetDailyMonthlyRegisterToFileError(DailyMonthlyRegister, FileStatus::"Error on Export", ErrorMessage);
            end
        end;

        DailyMonthlyRegister.FindLast();
        if FileCreated then begin
            if FileCreatedOnContainer then
                FileStatus := FileStatus::"Exported as Blob"
            else
                FileStatus := FileStatus::"Exported Localy";
            SetDailyMonthlyRegisterToFileCreated(DailyMonthlyRegister, InStr, FileStatus, BlobFileName)
        end else begin
            ErrorMessage := StrSubstNo(FileNotCreatedErr, TargetDate);
            SetDailyMonthlyRegisterToFileError(DailyMonthlyRegister, FileStatus::"Error on Export", ErrorMessage);
        end;

        if DownloadFileToLocal and FileCreated then
            DownloadFromStream(InStr, DialogTitle2_Txt, FileManagement.Magicpath(), FileManagement.GetToFilterText('', FileName), FileName);

        exit(DailyMonthlyRegister.Status = DailyMonthlyRegister.Status::"Exported as Blob");
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
        DailyMonthlyRegister.SetFileContent(Instr, FileName, false);
        DailyMonthlyRegister.Modify();
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

    local procedure GetPreviousMonthLastWorkingDate(TargetDate: Date) LastWorkingDay: Date
    var
        PreviousMonthLastDate: Date;
    begin
        PreviousMonthLastDate := CalcDate('<-CM-1D>', TargetDate);
        if not IsNonWorkingDay(PreviousMonthLastDate) then
            exit(PreviousMonthLastDate);

        while IsNonWorkingDay(PreviousMonthLastDate) do begin
            PreviousMonthLastDate := PreviousMonthLastDate - 1;
        end;
        LastWorkingDay := PreviousMonthLastDate;
        exit(LastWorkingDay);
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