namespace AvantMoney.ExportDailyMonthly;

page 50500 "PTE Daily/Monthly Registers"
{
    ApplicationArea = All;
    Caption = 'Daily/Monthly Registers';
    PageType = List;
    Editable = false;
    SourceTable = "PTE Daily/Monthly Register";
    UsageCategory = History;

    layout
    {
        area(Content)
        {
            repeater(Content1)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the No. field.';
                }
                field("Export File Type"; Rec."Export File Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Export File Type field.';
                }
                field(Identifier; Rec.Identifier)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Identifier field.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Status field.';
                }
                field("Export Date"; Rec."Export Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Export Date field.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the File Name field.';
                }
                field("Exported File"; Rec."Exported File")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Exported File field.';
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Created Date-Time field.';
                }
                field("Created by User"; Rec."Created by User")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Created by User field.';
                }
            }
        }
    }

    actions
    {
        /*   area(Processing)
          {
              action(Export)
              {
                  ApplicationArea = All;
                  Image = Export;

                  trigger OnAction()
                  var
                      FileManagement: Codeunit "File Management";
                      TempBlob: Codeunit "Temp Blob";
                      OutStr: OutStream;
                      InStr: InStream;
                      SaveTitleTxt: Label 'Save File';
                  begin
                      TempBlob.CreateOutStream(OutStr);
                      Rec."File Content".ExportStream(OutStr);

                      TempBlob.CreateInStream(InStr);
                      DownloadFromStream(InStr, SaveTitleTxt, '', FileManagement.GetToFilterText('', Rec."File Name"), Rec."File Name");
                  end;
              }
          } */
        area(Processing)
        {
            action(ExportFileManualy)
            {
                ApplicationArea = All;
                Caption = 'Export File Manualy';
                Image = DefaultFault;
                visible = false;
                ToolTip = 'Exports File Manualy.';

                trigger OnAction()
                var
                    //FileType: enum "ser File Type";
                    LastEntryMo: BigInteger;
                begin
                    //Rec.SetFileContentFromFile(FileType::ACH, '', LastEntryMo);
                end;
            }
            action(ShowFileContent)
            {
                ApplicationArea = All;
                Caption = 'Show File Content';
                Image = DefaultFault;
                ToolTip = 'Show File Content.';

                trigger OnAction()
                begin
                    Rec.ShowFileContent();
                end;
            }
            action(DownloadFileContent)
            {
                ApplicationArea = All;
                Caption = 'Download File Content';
                Image = DefaultFault;
                ToolTip = 'Downloads File Content.';

                trigger OnAction()
                begin
                    Rec.DownloadFileContent();
                end;
            }
            action(UploadFileContent)
            {
                ApplicationArea = All;
                Caption = 'Upload File Content';
                Image = DefaultFault;
                ToolTip = 'Upload File Content.';

                trigger OnAction()
                begin
                    Rec.UploadFileContent()
                end;
            }
        }
    }
}
