// The order management HTTP service acting as a Ballerina WebSub Publisher brings up an internal Ballerina WebSub Hub
// at which it will publish updates.
import ballerina/config;
import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/runtime;
import ballerina/websub;

endpoint http:Listener listener {
    port: 9000
};
// Invoke the function that start up a Ballerina WebSub Hub, register the topic
// against which updates will be published, and maintain a reference to the
// returned hub object to publish updates
websub:WebSubHub webSubHub = startHubandRegisterTopics();

// Start up a Ballerina WebSub Hub on port 9191 and register the topic against
// which updates will be published
function startHubandRegisterTopics() returns websub:WebSubHub {
    io:println("Starting up the Ballerina Commit Notifier Service");
    websub:WebSubHub internalHub = websub:startHub(9191,remotePublishingEnabled=true) but {
        websub:HubStartedUpError hubStartedUpErr => hubStartedUpErr.startedUpHub
    };

    // TODO: get from config and iterate registration
    internalHub.registerTopic("https://github.com") but {
        error e => log:printError("Error registering topic", err = e)
    };

    return internalHub;
}

@http:ServiceConfig {
    basePath: "/notifications"
}
service<http:Service> publishNotifications bind listener {
// dumb service
}




