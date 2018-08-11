// The order management HTTP service acting as a Ballerina WebSub Publisher brings up an internal Ballerina WebSub Hub
// at which it will publish updates.
import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/runtime;
import ballerina/websub;

// This is the remote WebSub Hub Endpoint to which registration and publish requests are sent.
endpoint websub:Client websubHubClientEP {
    url: "https://localhost:9191/websub/hub"
};


endpoint http:Listener listener {
    port: 9090
};


@http:ServiceConfig {
    basePath: "/notifications"
}
service<http:Service> publishNotifications bind listener {

    @http:ResourceConfig {
        methods: ["GET", "HEAD"],
        path: "/github"
    }
    discoverPlaceOrder(endpoint caller, http:Request req) {
        io:println("recieved request");
        http:Response response;
        response.statusCode = 202;
        caller->respond(response) but {
            error e => log:printError("Error responding on ordering", err = e)
        };
    }


    // Resource accepting order placement requests
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/github"
    }
    github(endpoint caller, http:Request req) {
        json commitPayload = check req.getJsonPayload();

        io:println("recieved webhook "+ commitPayload.toString());
        // Create the response message indicating success.
        http:Response response;
        response.statusCode = 202;
        caller->respond(response) but {
            error e => log:printError("Error responding to webhook", err = e)
        };

        // Publish the update to the Hub, to notify subscribers
        // TODO: commit notification generate

        string repo_name =
                           commitPayload.repository.full_name.toString();
        string user_name =
                           commitPayload.commit.user.login.toString();
        string commit =

                    commitPayload.commit.body.toString();

        json js = {
            "repo_name": untaint repo_name,
            "user_name": untaint user_name,
            "commit": untaint commit
        };

        // Publish updates to the remote hub.
        io:println("Publishing update to remote Hub:message:"+ js.user_name.toString() + " pushed to repository "+ js.repo_name.toString() + " with the commit message " + js.commit.toString());
        var publishResponse = websubHubClientEP->publishUpdate("http://github.com", 
         "Publishing update to remote Hub:message:"+ js.user_name.toString() + " pushed to repository "+ js.repo_name.toString() + " with the commit message " + js.commit.toString());
        match (publishResponse) {
            error webSubError => io:println("Error notifying hub: "  + webSubError.message, webSubError);
            () => io:println("Update notification successful!");
        }

    }

}
