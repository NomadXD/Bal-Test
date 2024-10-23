import choreo/mediation;
import ballerina/log;
import ballerina/url;
import ballerina/http;

listener http:Listener ep0 = new (9090, timeout = 0);

service /aftersales on ep0 {
    resource function get hub/tickets(http:Caller caller, http:Request request) returns error? {
        map<mediation:PathParamValue> pathParams = {};
        mediation:Context originalCtx = mediation:createImmutableMediationContext("get", ["hub", "tickets"], pathParams, request.getQueryParams());
        mediation:Context mediationCtx = mediation:createMutableMediationContext(originalCtx, ["hub", "tickets"], pathParams, request.getQueryParams());
        http:Response? backendResponse = ();
        removeHostHeader(request);
        do {
            if check get__hub_tickets_RequestFlow(caller, mediationCtx, request) {
                return;
            }

            string|error incomingEnvHeader = request.getHeader("X-ENV");
            if (incomingEnvHeader is string && incomingEnvHeader === "sandbox") {
                request.removeHeader("X-ENV");
                backendResponse = check sandboxEP->execute(mediationCtx.httpMethod(), (check mediationCtx.resourcePath().resolve(pathParams)) + buildQuery(mediationCtx.queryParams()), request, targetType = http:Response);
            } else {
                backendResponse = check backendEP->execute(mediationCtx.httpMethod(), (check mediationCtx.resourcePath().resolve(pathParams)) + buildQuery(mediationCtx.queryParams()), request, targetType = http:Response);
            }

            check caller->respond(backendResponse);
        } on fail var e {
            http:Response errFlowResponse = createDefaultErrorResponse(e);
            error err = e;
            check caller->respond(errFlowResponse);
        }
    }
}

configurable string Endpoint = "https://abctesrt.requestcatcher.com/test";
configurable string SandboxEndpoint = "https://abctesrt.requestcatcher.com/test";
configurable map<string> AdvancedSettings = {};

final http:Client backendEP = check new (Endpoint, config = {
    // secureSocket: {
    //     enable: check boolean:fromString("true"),
    //     cert: "/home/ballerina/ca.pem",
    //     verifyHostName: AdvancedSettings.hasKey("verifyHostname") ? check boolean:fromString(AdvancedSettings.get("verifyHostname")) : true
    // },
    timeout: 300,
    httpVersion: AdvancedSettings.hasKey("httpVersion") ? <http:HttpVersion>(<anydata>AdvancedSettings.get("httpVersion")) : "2.0"
});
final http:Client sandboxEP = check new (SandboxEndpoint, config = {
    // secureSocket: {
    //     enable: check boolean:fromString("false"),
    //     cert: "/home/ballerina/sand_ca.pem",
    //     verifyHostName: AdvancedSettings.hasKey("verifyHostname") ? check boolean:fromString(AdvancedSettings.get("verifyHostname")) : true
    // },
    timeout: 300,
    httpVersion: AdvancedSettings.hasKey("httpVersion") ? <http:HttpVersion>(<anydata>AdvancedSettings.get("httpVersion")) : "2.0"
});

function createDefaultErrorResponse(error err) returns http:Response {
    http:Response resp = new;
    log:printError(err.message(), (), err.stackTrace(), details = err.detail().toString());
    resp.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
    return resp;
}

function buildQuery(map<string[]> params) returns string {
    if (params.length() == 0) {
        return "";
    }

    string qParamStr = "?";

    foreach [string, string[]] [name, val] in params.entries() {
        foreach string item in val {
            string encoded = urlEncodeUtf8(item);
            qParamStr += string `${name}=${encoded}&`;
        }
    }

    return qParamStr.substring(0, qParamStr.length() - 1);
}

function buildRestParamPath(string[] pathSegments) returns string {
    return pathSegments.reduce(
        function(string path, string segment) returns string => string `${path}/${segment}`, "");
}

function urlEncodeUtf8(any value) returns string {
    string strValue = value.toString();
    string|error encoded = url:encode(strValue, "UTF-8");
    if encoded is error {
        log:printError("Unreachable error. Error occurred while URL encoding", 'error = encoded, keyValues = {"value": strValue});
        return strValue;
    }
    return encoded;
}

function removeHostHeader(http:Request request) {
    request.removeHeader("Host");
    request.removeHeader(":authority");
}
