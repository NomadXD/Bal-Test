import ballerina/http;
import choreo/mediation;
import choreo/mediation.add_header;

string ContentTypeHeaderValue = "application/json";
function handleRequestFlowPolicyResult(http:Response|false|() result, http:Caller caller) returns boolean {
    if result is false {
        http:ListenerError? response = caller->respond(new);
        return true;
    } else if result is http:Response {
        http:ListenerError? response = caller->respond(result);
        return true;
    }
    return false;
}

function 'get__hub_tickets_RequestFlow(http:Caller caller, mediation:Context mediationCtx, http:Request request) returns boolean|error {
    {
        var result = check add_header:addHeader_In(mediationCtx, request, "Content-Type", ContentTypeHeaderValue);

        if handleRequestFlowPolicyResult(result, caller) {
            return true;
        }
    }

    return false;
}
