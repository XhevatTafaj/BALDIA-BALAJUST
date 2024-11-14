
pageextension 50501 CompanyInformationExt extends "Company Information"
{
    actions
    {
        addfirst(processing)
        {
            action(GetIpInfo)
            {
                Caption = 'Get Ip Info';
                ApplicationArea = All;
                PromotedCategory = Process;
                Promoted = true;
                Image = GetOrder;
                trigger OnAction()
                var
                    Client: HttpClient;
                    HttpRequestMsg: HttpRequestMessage;
                    HttpResponseMsg: HttpResponseMessage;
                    URL: Text;
                    IpInfo: Text;
                begin
                    URL := 'https://ipinfo.io?token=7785454c958947';
                    HttpRequestMsg.SetRequestUri(URL);
                    if not Client.Send(HttpRequestMsg, HttpResponseMsg) then
                        Error('Call failed');
                    HttpResponseMsg.Content.ReadAs(IpInfo);
                    Message(IpInfo);
                end;
            }
        }
    }
}
