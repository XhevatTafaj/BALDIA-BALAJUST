namespace AvantMoney.ExportDailyMonthly;
using System.Security.Encryption;
page 50501 "PTE Daily/Monthly Export Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "PTE Daily/Monthly Export Setup";
    DeleteAllowed = false;
    InsertAllowed = false;
    Caption = 'Daily/Monthly Export Setup';

    layout
    {
        area(Content)
        {
            group(General)
            {
                caption = 'General';

                field("Account Name"; Rec."Account Name")
                {
                    ApplicationArea = All;
                    //Visible = not UseReadySAS;
                    Editable = not UseReadySAS;
                    ToolTip = 'Specifies the value of the Company Account Name field.';
                }
                field(AccountAccessKeyCtrl; AccountAccessKey)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                    //Visible = not UseReadySAS;
                    Editable = not UseReadySAS;
                    Caption = 'Account Access Key';
                    ToolTip = 'Specifies the value of the Account Access Key field.';

                    trigger OnValidate()
                    begin
                        if (AccountAccessKey <> '') and (not EncryptionEnabled()) then
                            if Confirm(EncryptionIsNotActivatedQst) then
                                PAGE.RunModal(PAGE::"Data Encryption Management");
                        Rec.SetPassword(AccountAccessKey, "PTE Azure Access Type"::"Account Name");
                    end;
                }
                field("Storage Name"; Rec."Storage Name")
                {
                    ToolTip = 'Specifies the value of the Storage Name field.';
                }
                field("Container Name"; Rec."Container Name")
                {
                    ToolTip = 'Specifies the value of the Container Name field.';
                }
                field(SasTokenKeyCtrl; SasTokenKey)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                    Caption = 'SAS Token Key';
                    //Visible = UseReadySAS;
                    Editable = UseReadySAS;
                    ToolTip = 'Specifies the value of the SAS Token Key field.';

                    trigger OnValidate()
                    begin
                        if (SasTokenKey <> '') and (not EncryptionEnabled()) then
                            if Confirm(EncryptionIsNotActivatedQst) then
                                PAGE.RunModal(PAGE::"Data Encryption Management");
                        Rec.SetPassword(SasTokenKey, "PTE Azure Access Type"::"SAS Token");
                    end;
                }
                field("Blob Service SAS URL"; Rec."Blob Service SAS URL")
                {
                    ToolTip = 'Specifies the value of the Blob Service SAS URL field.';
                    ApplicationArea = All;
                }
                field("Use Ready SAS"; Rec."Use Ready SAS")
                {
                    ToolTip = 'Specifies the value of the Use Ready SAS field.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UseReadySAS := Rec."Use Ready SAS";
                        CurrPage.Update(true);
                    end;
                }
                field("Export Calendar Code"; Rec."Export Calendar Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Export Calendar Code field.';
                }
                field("Upload Files on Container"; Rec."Upload Files on Container")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Upload Files on Container field.';
                }
            }
        }
    }


    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        AccountAccessKey := Rec.GetPassword("PTE Azure Access Type"::"Account Name");
        SasTokenKey := Rec.GetPassword("PTE Azure Access Type"::"SAS Token");
    End;

    trigger OnAfterGetCurrRecord()
    begin
        UseReadySAS := Rec."Use Ready SAS";
    end;

    var
        AccountAccessKey: Text;
        SasTokenKey: Text;
        UseReadySAS: Boolean;
        EncryptionIsNotActivatedQst: Label 'Data encryption is currently not enabled. We recommend that you encrypt data. \Do you want to open the Data Encryption Management window?';
}