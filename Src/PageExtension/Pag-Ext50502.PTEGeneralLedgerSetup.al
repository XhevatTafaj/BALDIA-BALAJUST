namespace AvantMoney.ExportDailyMonthly;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Security.Encryption;

pageextension 50502 "PTE General Ledger Setup" extends "General Ledger Setup"
{
    layout
    {
        addlast(content)
        {
            group(Daili_MonthlyExport)
            {
                caption = 'Daily/Monthly Export';
                field("PTE D.M. Account Name"; Rec."PTE D.M. Account Name")
                {
                    ToolTip = 'Specifies the value of the Company Account Name field.';
                }
                field(CompanyKeyCtrl; CompanyKey)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                    Caption = 'Company Azure Authentication Key';
                    ToolTip = 'Specifies the value of the Company Account Access Key field.';

                    trigger OnValidate()
                    begin
                        if (CompanyKey <> '') and (not EncryptionEnabled()) then
                            if Confirm(EncryptionIsNotActivatedQst) then
                                PAGE.RunModal(PAGE::"Data Encryption Management");
                        Rec.SetPassword(CompanyKey);
                    end;
                }
                field("PTE D.M. Account Container"; Rec."PTE D.M. Account Container")
                {
                    ToolTip = 'Specifies the value of the Company Account Container field.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CompanyKey := Rec.PTEGetPassword();
    End;

    var
        CompanyKey: Text;
        EncryptionIsNotActivatedQst: Label 'Data encryption is currently not enabled. We recommend that you encrypt data. \Do you want to open the Data Encryption Management window?';
}