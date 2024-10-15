import ballerina/http;

type RetryConfig record {|
    *http:RetryConfig;
|};

configurable RetryConfig testRetryConfig = ?;

http:Client testClient = check new ("testUrl", {
    retryConfig: {
        ...testRetryConfig
    }
});
