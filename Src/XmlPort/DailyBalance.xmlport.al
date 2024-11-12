xmlport 50500 "DailyBalanceXMLport"
{
    Format = VariableText;
    TextEncoding = UTF8;
    Direction = Export;
    TableSeparator = '<NewLine>';
    schema
    {

        textelement("Root")
        {
            textelement("Date")
            {
                trigger OnBeforePassVariable()
                var
                    CurrentDate: Date;
                    Value: Text[8];
                begin
                    CurrentDate := Today();
                    Value := Format(CurrentDate, 0, 'yyyyMMdd');
                end;
            }
            textelement("Account")
            {
                trigger OnBeforePassVariable()
                var
                    Value: Text[7];
                begin
                    Value := '1234567';
                end;
            }
            textelement("Center")
            {
                trigger OnBeforePassVariable()
                var
                    Value: Text[4];
                begin
                    Value := '0001';
                end;
            }
            textelement("Currency")
            {
                trigger OnBeforePassVariable()
                var
                    Value: Text[3];
                begin
                    Value := 'EUR';
                end;
            }
            textelement("Balance")
            {
                trigger OnBeforePassVariable()
                var
                    Value: Decimal;
                begin
                    Value := 12345.67;
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
                    // Campo per la data di esportazione
                    field("ExportDate"; Today())
                    {
                        Caption = 'Export Date'; // Etichetta per il campo
                    }

                    // Nome del file dinamico basato sulla data
                    field("FileName"; 'DAILY_BALANCE_' + Format(Today(), 0, 'yyyyMMdd') + '.txt')
                    {
                        Caption = 'File Name'; // Etichetta per il campo
                    }
                }
            }
        }
    }
}
