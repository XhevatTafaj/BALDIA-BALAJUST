namespace AvantMoney.ExportDailyMonthly;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Calendar;

tableextension 50500 "PTE General Ledger Setup" extends "General Ledger Setup"
{
    fields
    {
        field(50500; "PTE D.M. Account Access Key"; Guid)
        {
            Caption = 'Daily/Monthly Account Access Key';
            DataClassification = EndUserPseudonymousIdentifiers;

            trigger OnValidate()
            begin
                if not IsTemporary() then
                    if "PTE D.M. Account Access Key" <> xRec."PTE D.M. Account Access Key" then
                        xRec.PTEDeletePassword();
            end;
        }
        field(50501; "PTE D.M. Account Name"; Text[250])
        {
            Caption = 'Daily/Monthly Account Name';
            DataClassification = CustomerContent;
        }
        field(50502; "PTE D.M. Account Container"; Text[250])
        {
            Caption = 'Daily/Monthly Account Container';
            DataClassification = CustomerContent;
        }
        field(50503; "PTE Export Calendar Code"; Code[10])
        {
            Caption = 'Export Calendar Code';
            TableRelation = "Base Calendar";
        }
        field(50504; "PTE Upload Files on Container"; Boolean)
        {
            Caption = 'Upload Files on Container';
        }
    }

    trigger OnModify()
    begin
        if IsTemporary() then
            exit;
        if "PTE D.M. Account Access Key" <> xRec."PTE D.M. Account Access Key" then
            xRec.PTEDeletePassword();
    end;

    trigger OnDelete()
    begin
        if IsTemporary() then
            exit;
        PTEDeletePassword();
    end;

    var
        IsolatedStorageMgt: Codeunit "PTE Isolated Storage Mgt.";
        TempUserPassword: Text;
        RecordHasBeenRead: Boolean;

    procedure PTEDeletePassword()
    begin
        if IsTemporary() then begin
            Clear(TempUserPassword);
            exit;
        end;

        begin
            if IsNullGuid("PTE D.M. Account Access Key") then
                exit;
            IsolatedStorageMgt.DeleteStorage(Format("PTE D.M. Account Access Key"), DATASCOPE::Company);
        end;
    end;

    procedure HasPassword(): Boolean
    begin
        exit(PTEGetPassword() <> '');
    end;

    [NonDebuggable]
    procedure SetPassword(PasswordText: Text)
    begin
        if IsTemporary() then begin
            TempUserPassword := PasswordText;
            exit;
        end;

        if IsNullGuid("PTE D.M. Account Access Key") then
            "PTE D.M. Account Access Key" := CreateGuid();
        IsolatedStorageMgt.SetStorage("PTE D.M. Account Access Key", PasswordText, DATASCOPE::Company);
    end;

    [NonDebuggable]
    procedure PTEGetPassword(): Text
    var
        Value: Text;
    begin
        Value := '';
        if IsTemporary() then
            exit(TempUserPassword);

        if not IsNullGuid("PTE D.M. Account Access Key") then
            IsolatedStorageMgt.GetStorage("PTE D.M. Account Access Key", DATASCOPE::Company, Value);

        exit(Value);
    end;
}
