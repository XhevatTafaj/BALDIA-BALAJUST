
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
                        Value := Format(GLAccount."No.", 7, '0');
                    end;
                }
                /* textelement("Center")
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
                } */

                textelement("Balance")
                {
                    trigger OnBeforePassVariable()
                    var
                        GLEntryRec: Record "G/L Entry";
                        BalanceAmount: Decimal;
                        Value: Text[18];
                    begin
                        BalanceAmount := 0;
                        GLEntryRec.SetRange("G/L Account No.", GLAccount."No.");
                        if GLEntryRec.FindSet() then
                            repeat
                                BalanceAmount += GLEntryRec."Amount";
                            until GLEntryRec.Next() = 0;

                        Value := FORMAT(ROUND(BalanceAmount, 0.01), 0, '###########0.00');
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
