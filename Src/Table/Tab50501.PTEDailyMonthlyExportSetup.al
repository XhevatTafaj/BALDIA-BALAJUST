namespace AvantMoney.ExportDailyMonthly;
using Microsoft.Foundation.Calendar;
table 50501 "PTE Daily/Monthly Export Setup"
{
    DataClassification = CustomerContent;
    Caption = 'Daily/Monthly Export Setup';
    LookupPageId = "PTE Daily/Monthly Export Setup";
    DrillDownPageId = "PTE Daily/Monthly Export Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(2; "Account Access Key"; Guid)
        {
            Caption = 'Daily/Monthly Account Access Key';
            DataClassification = EndUserPseudonymousIdentifiers;

            trigger OnValidate()
            begin
                if not IsTemporary() then
                    if "Account Access Key" <> xRec."Account Access Key" then
                        xRec.DeletePassword("PTE Azure Access Type"::"Account Name");
            end;
        }
        // field(3; "Account Name"; Text[250])
        // {
        //     Caption = 'Daily/Monthly Account Name';
        //     DataClassification = CustomerContent;
        // }
        field(4; "Storage Name"; Text[250])
        {
            Caption = 'Storage Name';
            DataClassification = CustomerContent;
        }
        field(5; "Container Name"; Text[250])
        {
            Caption = 'Container Name';
            DataClassification = CustomerContent;
        }
        field(6; "SAS Token Key"; Guid)
        {
            Caption = 'SAS Token Key';
            DataClassification = EndUserPseudonymousIdentifiers;

            trigger OnValidate()
            begin
                if not IsTemporary() then
                    if "SAS Token Key" <> xRec."SAS Token Key" then
                        xRec.DeletePassword("PTE Azure Access Type"::"SAS Token");
            end;
        }
        field(7; "Blob Service SAS URL"; Text[250])
        {
            Caption = 'Blob Service SAS URL';
            DataClassification = CustomerContent;
        }
        field(8; "Export Calendar Code"; Code[10])
        {
            Caption = 'Export Calendar Code';
            TableRelation = "Base Calendar";
            DataClassification = CustomerContent;
        }
        field(9; "Upload Files on Container"; Boolean)
        {
            Caption = 'Upload Files on Container';
            DataClassification = CustomerContent;
        }
        field(10; "Use Ready SAS"; Boolean)
        {
            Caption = 'Use Ready SAS';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnModify()
    begin
        if IsTemporary() then
            exit;
        if "Account Access Key" <> xRec."Account Access Key" then
            xRec.DeletePassword("PTE Azure Access Type"::"Account Name");
        if "SAS Token Key" <> xRec."SAS Token Key" then
            xRec.DeletePassword("PTE Azure Access Type"::"SAS Token");
    end;

    trigger OnDelete()
    begin
        if IsTemporary() then
            exit;
        DeletePassword("PTE Azure Access Type"::"Account Name");
        DeletePassword("PTE Azure Access Type"::"SAS Token");
    end;

    var
        IsolatedStorageMgt: Codeunit "PTE Isolated Storage Mgt.";
        TempUserPassword: Text;
        RecordHasBeenRead: Boolean;

    procedure DeletePassword(Which: Enum "PTE Azure Access Type")
    begin
        if IsTemporary() then begin
            Clear(TempUserPassword);
            exit;
        end;

        Case Which of
            Which::"Account Name":
                begin
                    if IsNullGuid("Account Access Key") then
                        exit;
                    IsolatedStorageMgt.DeleteStorage(Format("Account Access Key"), DATASCOPE::Company);
                end;
            Which::"SAS Token":
                begin
                    if IsNullGuid("SAS Token Key") then
                        exit;
                    IsolatedStorageMgt.DeleteStorage(Format("SAS Token Key"), DATASCOPE::Company);
                end;
        End;
    end;

    [NonDebuggable]
    procedure HasPassword(Which: Enum "PTE Azure Access Type"): Boolean
    begin
        exit(GetPassword(Which) <> '');
    end;

    [NonDebuggable]
    procedure SetPassword(PasswordText: Text; Which: Enum "PTE Azure Access Type")
    begin
        if IsTemporary() then begin
            TempUserPassword := PasswordText;
            exit;
        end;

        Case Which of
            Which::"Account Name":
                begin
                    if IsNullGuid("Account Access Key") then
                        "Account Access Key" := CreateGuid();
                    IsolatedStorageMgt.SetStorage("Account Access Key", PasswordText, DATASCOPE::Company);
                end;
            Which::"SAS Token":
                begin
                    if IsNullGuid("SAS Token Key") then
                        "SAS Token Key" := CreateGuid();
                    IsolatedStorageMgt.SetStorage("SAS Token Key", PasswordText, DATASCOPE::Company);
                end;
        End;
    end;

    [NonDebuggable]
    procedure GetPassword(Which: Enum "PTE Azure Access Type"): Text
    var
        Value: Text;
    begin
        Value := '';
        if IsTemporary() then
            exit(TempUserPassword);
        Case Which of
            Which::"Account Name":
                if not IsNullGuid("Account Access Key") then
                    IsolatedStorageMgt.GetStorage("Account Access Key", DATASCOPE::Company, Value);
            Which::"SAS Token":
                if not IsNullGuid("SAS Token Key") then
                    IsolatedStorageMgt.GetStorage("SAS Token Key", DATASCOPE::Company, Value);
        End;

        exit(Value);
    end;

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;
}