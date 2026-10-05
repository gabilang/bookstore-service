import bookstore_service.models;

# Returned when no book exists for a given id.
public type NotFoundError distinct error;

# Thread-safe, in-memory book repository.
public isolated class BookStore {
    private final table<models:Book> key(id) books = table [];
    private int nextId = 1;

    # Adds a book and assigns it a new id.
    #
    # + input - the book details
    # + return - the stored book
    public isolated function add(models:BookInput input) returns models:Book {
        lock {
            models:Book book = {id: self.nextId, ...input.clone()};
            self.books.add(book);
            self.nextId += 1;
            return book.clone();
        }
    }

    # Looks up a book by id.
    #
    # + id - the book id
    # + return - a copy of the book, or a `NotFoundError`
    public isolated function get(int id) returns models:Book|NotFoundError {
        lock {
            models:Book? book = self.books[id];
            if book is () {
                return notFound(id);
            }
            return book.clone();
        }
    }

    # Lists books, optionally filtered by author (case-insensitive).
    #
    # + author - author to filter by, or `()` for all books
    # + return - the matching books ordered by id
    public isolated function list(string? author = ()) returns models:Book[] {
        lock {
            models:Book[] matches = from models:Book book in self.books
                where author is () || book.author.toLowerAscii() == author.toLowerAscii()
                order by book.id
                select book;
            return matches.clone();
        }
    }

    # Replaces the details of an existing book.
    #
    # + id - the book id
    # + input - the new book details
    # + return - the updated book, or a `NotFoundError`
    public isolated function update(int id, models:BookInput input) returns models:Book|NotFoundError {
        lock {
            if !self.books.hasKey(id) {
                return notFound(id);
            }
            models:Book book = {id, ...input.clone()};
            self.books.put(book);
            return book.clone();
        }
    }

    # Removes a book.
    #
    # + id - the book id
    # + return - a `NotFoundError` if no such book exists
    public isolated function remove(int id) returns NotFoundError? {
        lock {
            if self.books.removeIfHasKey(id) is () {
                return notFound(id);
            }
        }
    }

    # Returns the number of stored books.
    #
    # + return - the book count
    public isolated function count() returns int {
        lock {
            return self.books.length();
        }
    }
}

isolated function notFound(int id) returns NotFoundError => error NotFoundError(string `book ${id} not found`);
