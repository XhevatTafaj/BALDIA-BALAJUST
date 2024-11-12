
xmlport 50502 "DailyBalanceXMLport1"
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
                        CurrentDate: Date;
                        Value: Text[8]; // Declare Value as a Text variable
                    begin
                        CurrentDate := Today();
                        Date := Format(CurrentDate, 0, '<Year4><Month,2><Day,2>'); // Assign formatted date to Value
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

                    field("FileName"; 'DAILY_BALANCE_' + Format(Today(), 0, 'yyyyMMdd') + '.txt')
                    {
                        Caption = 'File Name';
                    }
                }
            }
        }
    }
}
