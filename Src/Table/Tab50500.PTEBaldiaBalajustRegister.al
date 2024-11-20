namespace AvantMoney.ExportDailyMonthly;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;
using System.Utilities;

table 50500 "PTE Daily/Monthly Register"
{
    Caption = 'Daily/Monthly Register';
    DataCaptionFields = Identifier, "Created Date-Time";
    DrillDownPageID = "PTE Daily/Monthly Registers";
    LookupPageID = "PTE Daily/Monthly Registers";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(2; Identifier; Text[50])
        {
            Caption = 'Identifier';
            DataClassification = CustomerContent;
        }
        field(3; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
            DataClassification = CustomerContent;
        }
        field(4; "Created by User"; Code[50])
        {
            Caption = 'Created by User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(5; Status; enum "PTE Baldia Balajust Status")
        {
            Caption = 'Status';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(6; "Export Date"; Date)
        {
            Caption = 'Export Date';
            DataClassification = CustomerContent;
        }
        field(7; "Balance Date"; Date)
        {
            Caption = 'Balance Date';
            DataClassification = CustomerContent;
        }
        field(8; "Export File Type"; enum "PTE Export File Type")
        {
            Caption = 'Export File Type';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(9; "File Name"; Text[1024])
        {
            Caption = 'File Name';
            DataClassification = CustomerContent;
        }
        field(10; "Exported File"; Media)
        {
            Caption = 'Exported File';
            DataClassification = CustomerContent;
        }
        field(11; "Error Text"; Text[2048])
        {
            Caption = 'Error Text';
            DataClassification = CustomerContent;
        }
        field(12; "Error Text 2"; Text[2048])
        {
            Caption = 'Error Text 2';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Export File Type", Status, "Export Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        ExportToServerFile: Boolean;
        PaymentsFileNotFoundErr: Label 'The original payment file was not found.\Export a new file from the Payment Journal window.';
        DialogTitle2_Txt: Label 'Download file...';
        ReadingDataSkippedMsg: Label 'Loading field %1 will be skipped because there was an error when reading the data.\To fix the current data, contact your administrator.\Alternatively, you can overwrite the current data by entering data in the field.', Comment = '%1=field caption';
        ErrorMessageMarkedByTxt: Label 'Marked as an error by %1.', Comment = '%1 = User id';
        NoErrorMessageTxt: Label 'There is no error message.';
        EntriesMarkedAsImportedErr: Label 'Entries with the status Exported as Blob cannot be marked as errors.';

    procedure CreateNew(NewIdentifier: Text[50]; FileType: Enum "PTE Export File Type"; ExportDate: Date; BalanceDate: Date)
    begin
        Reset();
        LockTable();
        if FindLast() then;
        Init();
        "No." += 1;
        Identifier := NewIdentifier;
        "Export Date" := ExportDate;
        "Balance Date" := BalanceDate;
        "Export File Type" := FileType;
        "Created Date-Time" := CurrentDateTime;
        "Created by User" := UserId;
        Insert();
    end;

    procedure SetStatus(NewStatus: enum "PTE Baldia Balajust Status")
    begin
        LockTable();
        Find();
        Status := NewStatus;
        Modify();
    end;

    procedure SetFileContent(FileInStream: InStream; pFileName: Text; PerformModification: Boolean)
    var
        MediaDescription: Text;
    begin
        LockTable();
        if PerformModification then
            Find();
        MediaDescription := Format(Rec."No.") + '-' + Format(Rec.FieldNo("Exported File")) + '-' + Format(Rec.FieldName("Exported File"));

        if pFileName <> '' then
            Rec.Validate("File Name", pFileName);
        Rec."Exported File".ImportStream(FileInStream, MediaDescription);
        if PerformModification then
            Modify();
    end;

    procedure DownloadFileContent()
    var
        FileInStream: InStream;
        FileOutStream: OutStream;
        TempFileName: Text;
    begin
        GetFileContentAsStream(FileInStream);
        TempFileName := Rec."File Name";
        if "Exported File".HasValue() then
            DownloadFromStream(FileInStream, DialogTitle2_Txt, '', FileManagement.GetToFilterText('', Rec."File Name"), TempFileName);
    end;

    procedure UploadFileContent()
    var
        FileInStream: InStream;
        TempFileName: Text;
    begin
        TempBlob.CreateInStream(FileInStream);
        UploadIntoStream(DialogTitle2_Txt, '', FileManagement.GetToFilterText('', Rec."File Name"), TempFileName, FileInStream);
        Rec."File Name" := TempFileName;
        Rec."Exported File".ImportStream(FileInStream, Format("No.") + Format(CurrentDateTime()));
        Rec.Modify();
    end;

    procedure GetFileContentAsStream(var FileInStream: InStream)
    var
        FileOutStream: OutStream;
    begin
        Clear(FileInStream);
        if "Exported File".HasValue() then begin
            Clear(TempBlob);
            TempBlob.CreateOutStream(FileOutStream);
            "Exported File".ExportStream(FileOutStream);
            TempBlob.CreateInStream(FileInStream);
        end;
    end;

    procedure ShowFileContent()
    var
        ContentTxt: Text;
    begin
        if not "Exported File".HasValue() then
            exit;

        ContentTxt := GetFileContentAsText(true);
        Message(ContentTxt);
    end;

    procedure GetFileContentAsText(DoNotShowReadingDataSkipped: Boolean) FileContent: Text
    var
        TypeHelper: Codeunit "Type Helper";
        FileInStream: InStream;
    begin
        GetFileContentAsStream(FileInStream);
        if "Exported File".HasValue() then
            if not TypeHelper.TryReadAsTextWithSeparator(FileInStream, TypeHelper.LFSeparator(), FileContent) then
                if not DoNotShowReadingDataSkipped then
                    Message(ReadingDataSkippedMsg, FieldCaption("Exported File"));
    end;

    procedure EnableExportToServerFile()
    begin
        ExportToServerFile := true;
    end;

    procedure SetErrorMessage(ErrorText: Text)
    begin
        SetRecordErrorMessage("Error Text", "Error Text 2", ErrorText);
    end;

    local procedure SetRecordErrorMessage(var ErrorMessageField1: Text[2048]; var ErrorMessageField2: Text[2048]; ErrorText: Text)
    var
        ErrorText2: Text;
    begin
        ErrorMessageField2 := '';
        ErrorMessageField1 := COPYSTR(ErrorText, 1, 2048);
        if STRLEN(ErrorText) > 2048 then begin
            ErrorText2 := COPYSTR(ErrorText, 2049, 4096);
            ErrorMessageField2 := CopyStr(ErrorText2, 1, MaxStrLen(ErrorMessageField2));
        end;
    end;

    procedure GetErrorMessage(): Text
    begin
        exit(GetRecordErrorMessage(Rec."Error Text", Rec."Error Text 2"));
    end;

    local procedure GetRecordErrorMessage(ErrorMessageField1: Text[2048]; ErrorMessageField2: Text[2048]): Text
    begin
        exit(ErrorMessageField1 + ErrorMessageField2);
    end;

    procedure ShowErrorMessage()
    var
        ErrorText: Text;
    begin
        ErrorText := GetErrorMessage();
        IF ErrorText = '' THEN
            ErrorText := NoErrorMessageTxt;
        MESSAGE(ErrorText);
    end;

    procedure MarkAsError()
    var
        ErrorMessage: Text;
    begin
        if Rec."Status" = Rec."Status"::"Exported as Blob" then
            Error(EntriesMarkedAsImportedErr);

        ErrorMessage := StrSubstNo(ErrorMessageMarkedByTxt, UserId);
        OnBeforeMarkAsError(Rec, ErrorMessage);

        Rec."Status" := Rec."Status"::"Error on Export";
        "Error Text" := CopyStr(ErrorMessage, 1, MaxStrLen("Error Text"));
        Modify();
    end;

    // procedure SetErrorCallStack(NewCallStack: Text)
    // var
    //     OutStream: OutStream;
    // begin
    //     "Error Call Stack".CreateOutStream(OutStream, TEXTENCODING::Windows);
    //     OutStream.Write(NewCallStack);
    // end;

    // procedure ShowErrorCallStack()
    // begin
    //     if "Status" = "Status"::"Error on Export" then
    //         Message(GetErrorCallStack());
    // end;

    // procedure GetErrorCallStack(): Text
    // var
    //     TypeHelper: Codeunit "Type Helper";
    //     InStream: InStream;
    // begin
    //     CalcFields("Error Call Stack");
    //     "Error Call Stack".CreateInStream(InStream, TEXTENCODING::Windows);
    //     exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    // end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMarkAsError(var DailyMonthlyRegister: Record "PTE Daily/Monthly Register"; var ErrorMessage: Text)
    begin
    end;
}

