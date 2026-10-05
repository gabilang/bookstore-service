import ballerina/test;
import bookstore_service.models;

final models:BookInput dune = {title: "Dune", author: "Frank Herbert", year: 1965, price: 9.99};
final models:BookInput messiah = {title: "Dune Messiah", author: "Frank Herbert", year: 1969, price: 8.99};
final models:BookInput neuromancer = {title: "Neuromancer", author: "William Gibson", year: 1984, price: 7.50};

BookStore bookStore = new;

@test:BeforeEach
function resetStore() {
    bookStore = new;
}

@test:Config {groups: ["store"]}
function testAddAssignsIncrementingIds() {
    models:Book first = bookStore.add(dune);
    models:Book second = bookStore.add(neuromancer);
    test:assertEquals(first.id, 1);
    test:assertEquals(second.id, 2);
    test:assertEquals(first.title, "Dune");
    test:assertEquals(bookStore.count(), 2);
}

@test:Config {groups: ["store"]}
function testGetExistingBook() returns error? {
    models:Book added = bookStore.add(dune);
    models:Book fetched = check bookStore.get(added.id);
    test:assertEquals(fetched, added);
}

@test:Config {groups: ["store"]}
function testGetMissingBookReturnsNotFound() {
    models:Book|NotFoundError result = bookStore.get(42);
    if result !is NotFoundError {
        test:assertFail("expected NotFoundError");
    }
    test:assertEquals(result.message(), "book 42 not found");
}

@test:Config {groups: ["store"]}
function testGetReturnsCopy() returns error? {
    models:Book added = bookStore.add(dune);
    models:Book fetched = check bookStore.get(added.id);
    fetched.title = "Changed";
    models:Book refetched = check bookStore.get(added.id);
    test:assertEquals(refetched.title, "Dune");
}

@test:Config {groups: ["store"]}
function testListAllBooks() {
    _ = bookStore.add(dune);
    _ = bookStore.add(neuromancer);
    _ = bookStore.add(messiah);
    test:assertEquals(bookStore.list().map(b => b.id), [1, 2, 3]);
}

@test:Config {groups: ["store"]}
function testListFiltersByAuthorIgnoringCase() {
    _ = bookStore.add(dune);
    _ = bookStore.add(neuromancer);
    _ = bookStore.add(messiah);
    models:Book[] herbert = bookStore.list("frank herbert");
    test:assertEquals(herbert.map(b => b.title), ["Dune", "Dune Messiah"]);
    test:assertEquals(bookStore.list("Nobody"), []);
}

@test:Config {groups: ["store"]}
function testUpdateExistingBook() returns error? {
    models:Book added = bookStore.add(dune);
    models:Book updated = check bookStore.update(added.id, {title: "Dune", author: "Frank Herbert", year: 1965, price: 12.50});
    test:assertEquals(updated.id, added.id);
    test:assertEquals(updated.price, 12.50d);
    test:assertEquals((check bookStore.get(added.id)).price, 12.50d);
}

@test:Config {groups: ["store"]}
function testUpdateMissingBookReturnsNotFound() {
    test:assertTrue(bookStore.update(7, dune) is NotFoundError);
    test:assertEquals(bookStore.count(), 0);
}

@test:Config {groups: ["store"]}
function testRemoveExistingBook() {
    models:Book added = bookStore.add(dune);
    test:assertEquals(bookStore.remove(added.id), ());
    test:assertEquals(bookStore.count(), 0);
    test:assertTrue(bookStore.get(added.id) is NotFoundError);
}

@test:Config {groups: ["store"]}
function testRemoveMissingBookReturnsNotFound() {
    test:assertTrue(bookStore.remove(99) is NotFoundError);
}
