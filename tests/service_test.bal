import bookstore_service.models;

import ballerina/http;
import ballerina/test;

final http:Client bookClient = check new ("http://localhost:9091/books");

final models:BookInput dune = {title: "Dune", author: "Frank Herbert", year: 1965, price: 9.99};
final models:BookInput neuromancer = {title: "Neuromancer", author: "William Gibson", year: 1984, price: 7.50};

int duneId = -1;

@test:Config {groups: ["service"]}
function testCreateBook() returns error? {
    http:Response response = check bookClient->/.post(dune);
    test:assertEquals(response.statusCode, http:STATUS_CREATED);

    models:Book created = check (check response.getJsonPayload()).cloneWithType();
    test:assertTrue(created.id > 0);
    test:assertEquals(created.title, dune.title);
    test:assertEquals(check response.getHeader("Location"), string `/books/${created.id}`);
    duneId = created.id;
}

@test:Config {groups: ["service"]}
function testCreateInvalidBookReturnsBadRequest() returns error? {
    http:Response response = check bookClient->/.post({title: "", author: "Frank Herbert", year: 1965, price: 9.99});
    test:assertEquals(response.statusCode, http:STATUS_BAD_REQUEST);
    test:assertEquals(check response.getJsonPayload(), {message: "title must not be empty"});
}

@test:Config {groups: ["service"]}
function testCreateMalformedPayloadReturnsBadRequest() returns error? {
    http:Response response = check bookClient->/.post({title: "Dune", author: "Frank Herbert", price: 9.99});
    test:assertEquals(response.statusCode, http:STATUS_BAD_REQUEST);
    test:assertEquals(check response.getJsonPayload(),
            {message: "data binding failed: required field 'year' not present in JSON"});
}

@test:Config {groups: ["service"], dependsOn: [testCreateBook]}
function testGetBook() returns error? {
    models:Book book = check bookClient->/[duneId];
    test:assertEquals(book, {id: duneId, ...dune});
}

@test:Config {groups: ["service"]}
function testGetMissingBookReturnsNotFound() returns error? {
    http:Response response = check bookClient->/[999];
    test:assertEquals(response.statusCode, http:STATUS_NOT_FOUND);
    test:assertEquals(check response.getJsonPayload(), {message: "book 999 not found"});
}

@test:Config {groups: ["service"], dependsOn: [testCreateBook]}
function testListAndFilterBooks() returns error? {
    http:Response response = check bookClient->/.post(neuromancer);
    test:assertEquals(response.statusCode, http:STATUS_CREATED);

    models:Book[] all = check bookClient->/;
    test:assertTrue(all.length() >= 2);

    models:Book[] gibson = check bookClient->/(author = "william gibson");
    test:assertEquals(gibson.map(b => b.title), ["Neuromancer"]);
}

@test:Config {groups: ["service"], dependsOn: [testGetBook, testListAndFilterBooks]}
function testUpdateBook() returns error? {
    models:Book updated = check bookClient->/[duneId].put({title: "Dune", author: "Frank Herbert", year: 1965, price: 14.99});
    test:assertEquals(updated.price, 14.99d);

    models:Book fetched = check bookClient->/[duneId];
    test:assertEquals(fetched.price, 14.99d);
}

@test:Config {groups: ["service"]}
function testUpdateMissingBookReturnsNotFound() returns error? {
    http:Response response = check bookClient->/[999].put(dune);
    test:assertEquals(response.statusCode, http:STATUS_NOT_FOUND);
}

@test:Config {groups: ["service"], dependsOn: [testUpdateBook]}
function testDeleteBook() returns error? {
    http:Response response = check bookClient->/[duneId].delete();
    test:assertEquals(response.statusCode, http:STATUS_NO_CONTENT);

    http:Response afterDelete = check bookClient->/[duneId];
    test:assertEquals(afterDelete.statusCode, http:STATUS_NOT_FOUND);
}

@test:Config {groups: ["service"]}
function testDeleteMissingBookReturnsNotFound() returns error? {
    http:Response response = check bookClient->/[999].delete();
    test:assertEquals(response.statusCode, http:STATUS_NOT_FOUND);
}
