
namespace AvantMoney.ExportDailyMonthly;
using Microsoft.Finance.GeneralLedger.Account;
using System.Utilities;

xmlport 50502 "PTE Daily Balance"
{
    Format = VariableText;
    TextEncoding = UTF8;
    Direction = Export;
    TableSeparator = '<NewLine>';

    schema
    {
        textelement(Root)
        {
            tableelement(GLAccount; "G/L Account")
            {
                CalcFields = "Balance at Date";
                textelement(DateOfTheBalance)
                {
                    trigger OnBeforePassVariable()
                    begin
                        DateOfTheBalance := Format(BalanceDate, 0, '<Year4><Month,2><Day,2>');
                    end;
                }
                fieldelement(Account; GLAccount."No.")
                {
                }
                textelement(CenterValue)
                {
                    trigger OnBeforePassVariable()
                    begin
                        CenterValue := '0001';
                    end;
                }
                textelement(CurrencyValue)
                {
                    trigger OnBeforePassVariable()
                    begin
                        CurrencyValue := 'EUR';
                    end;
                }
                textelement(BalanceAtDate)
                {
                    trigger OnBeforePassVariable()
                    var
                        BalanceFormated: Text;
                        FormatedValue: Text[18];
                        i: Integer;
                        CharsToAdd: Text;
                    begin
                        BalanceAtDate := DailyMonthlyExport.FormatBalanceAtDate(GLAccount."Balance at Date");
                    end;
                }

                trigger OnPreXmlItem()
                begin
                    GetBalanceDate();
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            area(content)
            {
                group("BalanceExportGroup")
                {
                    field("ExportDate"; Today())
                    {
                        Caption = 'Export Date';
                    }

                    field("FileName"; 'DAILY_BALANCE_' + Format(Today(), 0, 'yyyyMMdd') + '.txt')
                    {
                        Caption = 'File Name';
                    }
                }
            }
        }
    }

    var
        DateRec: Record Date;
        DailyMonthlyExport: Codeunit "PTE Daily/Monthly Export";
        BalanceDate: Date;

    local procedure GetBalanceDate()
    begin
        if GLAccount.GetFilter("Date Filter") = '' then begin
            GLAccount.SetRange("Date Filter", Today());
            BalanceDate := Today();
            exit;
        end;

        DateRec.Reset();
        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetFilter("Period Start", GLAccount.GetFilter("Date Filter"));
        if not DateRec.FindLast() then
            BalanceDate := Today()
        else
            BalanceDate := DateRec."Period Start";
    end;
}
