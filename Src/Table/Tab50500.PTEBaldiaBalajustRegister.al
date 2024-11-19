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
        field(2; Identifier; Text[100])
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
        field(7; "Export File Type"; enum "PTE Export File Type")
        {
            Caption = 'Export File Type';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(8; "File Name"; Text[1024])
        {
            Caption = 'File Name';
            DataClassification = CustomerContent;
        }
        field(9; "Exported File"; Media)
        {
            Caption = 'Exported File';
            DataClassification = CustomerContent;
        }
        field(10; "Error Text"; Text[2048])
        {
            Caption = 'Error Text';
            DataClassification = CustomerContent;
        }
        field(11; "Error Text 2"; Text[2048])
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
        PaymentsFileNotFoundErr: Label 'The original payment file was not found.\Export a new file from the Payment Journal window.';
        DialogTitle2_Txt: Label 'Download file...';
        ReadingDataSkippedMsg: Label 'Loading field %1 will be skipped because there was an error when reading the data.\To fix the current data, contact your administrator.\Alternatively, you can overwrite the current data by entering data in the field.', Comment = '%1=field caption';

        ExportToServerFile: Boolean;

    procedure CreateNew(NewIdentifier: Text[100]; FileType: Enum "PTE Export File Type")
    begin
        Reset();
        LockTable();
        if FindLast() then;
        Init();
        "No." += 1;
        Identifier := NewIdentifier;
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

    procedure SetFileContent(FileInStream: InStream; pFileName: Text)
    var
        MediaDescription: Text;
    begin
        LockTable();
        Find();
        MediaDescription := Format(Rec."No.") + '-' + Format(Rec.FieldNo("Exported File")) + '-' + Format(Rec.FieldName("Exported File"));

        if pFileName <> '' then
            Rec.Validate("File Name", pFileName);
        Rec."Exported File".ImportStream(FileInStream, MediaDescription);
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
}

