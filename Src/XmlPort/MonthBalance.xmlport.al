xmlport 50501 "BalajustXMLport"
{
    Format = VariableText;
    TextEncoding = UTF8;
    Direction = Export;
    TableSeparator = '<NewLine>';
    schema
    {
        textelement("BalajustData")
        {
            textelement("Date")
            {
                trigger OnBeforePassVariable()
                var
                    LastMonthDate: Date;
                begin
                    LastMonthDate := CALCDATE('<-1M>', Today());
                    LastMonthDate := CALCDATE('<<1D>', LastMonthDate);
                    Value := Format(LastMonthDate, 0, '<Year><Month><Day>');
                end;
            }
            textelement("Account")
            {
                trigger OnBeforePassVariable()
                begin
                    Value := '1234567';
                end;
            }
            textelement("Center")
            {
                trigger OnBeforePassVariable()
                begin
                    Value := '0001';
                end;
            }
            textelement("Currency")
            {
                trigger OnBeforePassVariable()
                begin
                    Value := 'EUR';
                end;
            }
            textelement("Balance")
            {
                trigger OnBeforePassVariable()
                var
                    BalanceAmount: Decimal;
                    TempBalance: Text[18];
                    BalanceFormatted: Text[18];
                begin
                    BalanceAmount := 123456789012345.67;
                    TempBalance := Format(BalanceAmount, 0, '0.00');

                    BalanceFormatted := PadStr(TempBalance, 18, ' ');

                    Value := BalanceFormatted;
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
                    field("FileName"; 'MONTHLY_BALANCE_' + Format(Today(), 0, '<Year><Month>') + '.txt')
                    {
                        Caption = 'File Name';
                    }
                }
            }
        }
    }

    var
        Value: Text[18];
}
