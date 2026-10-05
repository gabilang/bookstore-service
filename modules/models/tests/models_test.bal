import ballerina/test;
import ballerina/time;

@test:Config {groups: ["models"]}
function testValidBookPasses() {
    test:assertEquals(validate(bookWith()), ());
}

@test:Config {groups: ["models"]}
function testBoundaryYearsAndZeroPriceAreValid() {
    int currentYear = time:utcToCivil(time:utcNow()).year;
    test:assertEquals(validate(bookWith(year = MIN_YEAR)), ());
    test:assertEquals(validate(bookWith(year = currentYear)), ());
    test:assertEquals(validate(bookWith(price = 0)), ());
}

@test:Config {groups: ["models"], dataProvider: invalidBooks}
function testInvalidBookIsRejected(BookInput book, string expectedMessage) {
    ValidationError? result = validate(book);
    if result is () {
        test:assertFail("expected a ValidationError");
    }
    test:assertTrue(result.message().startsWith(expectedMessage),
            string `unexpected message: ${result.message()}`);
}

function invalidBooks() returns map<[BookInput, string]> {
    return {
        "blank title": [bookWith(title = "   "), "title must not be empty"],
        "blank author": [bookWith(author = ""), "author must not be empty"],
        "year too old": [bookWith(year = MIN_YEAR - 1), "year must be between"],
        "year in future": [bookWith(year = 3000), "year must be between"],
        "negative price": [bookWith(price = -1), "price must not be negative"]
    };
}

// Builds a valid book, overriding only the fields a test cares about.
function bookWith(string title = "Dune", string author = "Frank Herbert", int year = 1965, decimal price = 9.99)
        returns BookInput => {title, author, year, price};
