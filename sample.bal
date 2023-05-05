import ballerina/http;
import ballerina/sql;
import ballerinax/mysql.driver as _;
import ballerinax/mysql;


// Types
type User record {|
     string userName;
     int allowAccess;
     string? endSub?;
|};

// MySQL configuration parameters
configurable string host = ?;
configurable int port = ?;
configurable string user = ?;
configurable string password = ?;
configurable string database = ?;

final mysql:Client mysqlClient = check new (host = host, port = port, user = user, password = password,
                                            database = database);

service /company on new http:Listener(8090) {

    isolated resource function post user(@http:Payload User payload) returns error? {
        sql:ParameterizedQuery insertQuery = `INSERT INTO Users (userName,allowAccess,endSub) VALUES (${payload.userName}, ${payload.allowAccess}, DATE_ADD(now(),interval 5 day))`;
        sql:ExecutionResult _ = check mysqlClient->execute(insertQuery);
    }

    isolated resource function put user(@http:Payload User payload) returns error? {
        sql:ParameterizedQuery updateQuery = `UPDATE  Users SET allowAccess=${payload.allowAccess},
                                             endSub=${payload?.endSub} where
                                             userName= ${payload.userName}`;
        sql:ExecutionResult _ = check mysqlClient->execute(updateQuery);
    }
    
    isolated resource function get users(string userName) returns json|error {
        sql:ParameterizedQuery selectQuery = `select userName,allowAccess,endSub from Users where userName=${userName}`;
        stream <User, sql:Error?> resultStream = mysqlClient->query(selectQuery);
        User[] users = [];

        check from User item in resultStream
            do {
                users.push(item);
            };
        return users;
    }

    isolated resource function delete user(string userName) returns error? {
        sql:ParameterizedQuery deleteQuery = `DELETE FROM Users WHERE userName = ${userName}`;
        sql:ExecutionResult _ = check mysqlClient->execute(deleteQuery);
    }

}
