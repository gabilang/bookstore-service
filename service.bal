import bookstore_service.models;
import bookstore_service.store;

import ballerina/http;

# Port the bookstore service listens on.
configurable int port = 9090;

final store:BookStore bookStore = new;

# REST API for managing a catalog of books.
isolated service http:InterceptableService /books on new http:Listener(port) {

    public function createInterceptors() returns PayloadBindingErrorInterceptor {
        return new;
    }

    # Lists all books, optionally filtered by author.
    #
    # + author - author to filter by (case-insensitive)
    # + return - the matching books
    resource function get .(string? author) returns models:Book[] {
        return bookStore.list(author);
    }

    # Fetches a single book.
    #
    # + id - the book id
    # + return - the book, or 404 if it does not exist
    resource function get [int id]() returns models:Book|http:NotFound {
        models:Book|store:NotFoundError book = bookStore.get(id);
        if book is store:NotFoundError {
            return notFound(book);
        }
        return book;
    }

    # Creates a new book.
    #
    # + book - the book details
    # + return - 201 with the created book, or 400 if the payload is invalid
    resource function post .(models:BookInput book) returns http:Created|http:BadRequest {
        models:ValidationError? invalid = models:validate(book);
        if invalid is models:ValidationError {
            return badRequest(invalid);
        }
        models:Book created = bookStore.add(book);
        return <http:Created>{
            body: created,
            headers: {"Location": string `/books/${created.id}`}
        };
    }

    # Replaces the details of an existing book.
    #
    # + id - the book id
    # + book - the new book details
    # + return - the updated book, 404 if it does not exist, or 400 if the payload is invalid
    resource function put [int id](models:BookInput book) returns models:Book|http:NotFound|http:BadRequest {
        models:ValidationError? invalid = models:validate(book);
        if invalid is models:ValidationError {
            return badRequest(invalid);
        }
        models:Book|store:NotFoundError updated = bookStore.update(id, book);
        if updated is store:NotFoundError {
            return notFound(updated);
        }
        return updated;
    }

    # Deletes a book.
    #
    # + id - the book id
    # + return - 204 on success, or 404 if it does not exist
    resource function delete [int id]() returns http:NoContent|http:NotFound {
        store:NotFoundError? result = bookStore.remove(id);
        if result is store:NotFoundError {
            return notFound(result);
        }
        return http:NO_CONTENT;
    }
}

# Turns request payloads that cannot be bound to `BookInput` into a 400 with an `ErrorResponse` body.
isolated service class PayloadBindingErrorInterceptor {
    *http:ResponseErrorInterceptor;

    remote function interceptResponseError(error err) returns http:BadRequest|error {
        if err is http:PayloadBindingError {
            return badRequest(err);
        }
        // Anything else falls through to the listener's default error handling.
        return err;
    }
}

isolated function notFound(error err) returns http:NotFound => {body: <models:ErrorResponse>{message: err.message()}};

isolated function badRequest(error err) returns http:BadRequest => {body: <models:ErrorResponse>{message: err.message()}};
