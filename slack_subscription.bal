// Ballerina WebSub Subscriber service, which subscribes to notifications at a Hub.
import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/mime;
import ballerina/websub;

endpoint http:Client clientEndpoint {
    url: "http://localhost:3000"
};

// The endpoint to which the subscriber service is bound.
endpoint websub:Listener websubEP {
    port: 8181
};

@final
string channel = "some channl";

@final
string token = "token";

// Annotations specifying the subscription parameters.
@websub:SubscriberServiceConfig {
    path: "/websub",
    subscribeOnStartUp: true,
    topic: "http://github.com",
    hub: "https://localhost:9191/websub/hub",
    leaseSeconds: 36000,
    secret: "Kslk30SNF2AChs2"
}
service websubSubscriber bind websubEP {

    // Define the resource that accepts the content delivery requests.
    onNotification(websub:Notification notification) {
        match (notification.getPayloadAsString()) {
            string msg =>  slackNotification(untaint msg);                                  
            error e => log:printError("Error retrieving payload as string", err = e);
        }
    }
}

function slackNotification(string body) {
    log: printInfo("WebSub Notification Received: " + body);

    json payload = {
        "channel": channel,
        "text": body,
        "token": token
    };

    var response = clientEndpoint->post("",payload);
      match response {
        http:Response resp => {
            io:println("POST request:");
            var msg = resp.getJsonPayload();
            match msg {
                json jsonPayload => {
                    io:println(jsonPayload);
                }
                error err => {
                    log:printError(err.message, err = err);
                }
            }
        }
        error err => { log:printError(err.message, err = err); }
    }
}




















