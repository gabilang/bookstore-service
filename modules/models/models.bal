import ballerina/time;

# Earliest publication year accepted (roughly the advent of the printing press).
public const int MIN_YEAR = 1450;

# Payload used to create or update a book.
#
# + title - title of the book
# + author - author of the book
# + year - year of publication
# + price - price of the book
public type BookInput record {|
    string title;
    string author;
    int year;
    decimal price;
|};

# A book stored in the catalog.
#
# + id - unique identifier assigned by the store
public type Book record {|
    readonly int id;
    *BookInput;
|};

# Body returned by the service for error responses.
#
# + message - human-readable error message
public type ErrorResponse record {|
    string message;
|};

# Returned when a `BookInput` fails validation.
public type ValidationError distinct error;

# Validates a book payload.
#
# + book - the payload to validate
# + return - a `ValidationError` describing the first failed rule, or `()` if the payload is valid
public isolated function validate(BookInput book) returns ValidationError? {
    if book.title.trim().length() == 0 {
        return error ValidationError("title must not be empty");
    }
    if book.author.trim().length() == 0 {
        return error ValidationError("author must not be empty");
    }
    int currentYear = time:utcToCivil(time:utcNow()).year;
    if book.year < MIN_YEAR || book.year > currentYear {
        return error ValidationError(string `year must be between ${MIN_YEAR} and ${currentYear}`);
    }
    if book.price < 0d {
        return error ValidationError("price must not be negative");
    }
}
