namespace AvantMoney.ExportDailyMonthly;
using Microsoft.Finance.GeneralLedger.Account;

xmlport 50503 "MonthlyBalanceXMLport1"
{
    Format = VariableText;
    TextEncoding = UTF8;
    Direction = Export;
    TableSeparator = '<NewLine>';
    schema
    {
        textelement(Root)
        {
            tableelement("GLAccount"; "G/L Account")
            {
                textelement("Date")
                {
                    trigger OnBeforePassVariable()
                    var
                        BalanceDate: Date;
                        Value: Text[8];
                    begin
                        BalanceDate := GetBalanceDate(Today());
                        Value := Format(BalanceDate, 0);
                        Date := Value;

                    end;
                }

                fieldelement(Account; GLAccount."No.")
                {
                    trigger OnBeforePassField()
                    var
                        Value: Text[7];
                    begin
                        Value := Format(GLAccount."No.", 7, '0');
                    end;
                }
                textelement("Center")
                {
                    trigger OnBeforePassVariable()
                    var
                        Value: Text[4];
                    begin
                        Value := '001';
                        Center := Format(Value);
                    end;
                }
                textelement("Currency")
                {
                    trigger OnBeforePassVariable()
                    var
                        Value: Text[3];
                    begin
                        Value := 'EUR';
                        Currency := Format(Value);
                    end;
                }

                fieldelement(Balance; GLAccount.Balance)
                {
                    trigger OnBeforePassField()
                    var
                        Value: Text[18];
                    begin
                        Value := FORMAT(GLAccount."Balance", 0, '###########0.00');
                        Value := PadStr(Value, 18, '0');
                    end;
                }
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

                    field("FileName"; 'MONTHLY_BALANCE_' + Format(CALCDATE('<-1M>', Today()), 0, 'yyyyMM') + '.txt')
                    {
                        Caption = 'File Name';
                    }
                }
            }
        }
    }

    procedure GetBalanceDate(CurrentDate: Date): Date
    var
        LastDayPrevMonth: Date;
        DayOfWeek: Integer;
    begin
        LastDayPrevMonth := CALCDATE('<-1M>', CurrentDate);
        DayOfWeek := Date2DWY(LastDayPrevMonth, 1);

        if DayOfWeek = 6 then
            LastDayPrevMonth := CALCDATE('<-1D>', LastDayPrevMonth);
        if DayOfWeek = 7 then
            LastDayPrevMonth := CALCDATE('<-2D>', LastDayPrevMonth);
        exit(LastDayPrevMonth);
    end;
}

