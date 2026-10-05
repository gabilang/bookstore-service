# bookstore-service

A small REST API for managing a catalog of books, written in [Ballerina](https://ballerina.io). Books are kept in memory, so there is nothing else to set up and the data resets each time the service restarts.

## Prerequisites

- Ballerina Swan Lake Update 13 (`2201.13.6`). Check with `bal version`.

Ballerina downloads the libraries it needs on the first build.

## Project layout

```
bookstore_service/
├── service.bal                  # HTTP service (/books)
├── tests/service_test.bal       # service tests over HTTP
└── modules/
    ├── models/                  # Book types and input validation
    │   └── tests/
    └── store/                   # in-memory, concurrency-safe book store
        └── tests/
```

## Running the service

```bash
bal run
```

The service listens on port **8090** by default. To use a different port, either pass it on the command line:

```bash
bal run -- -Cport=9095
```

or create a `Config.toml` in the project root (it is git-ignored):

```toml
port = 9095
```

### API

| Method | Path | Success | Errors |
|---|---|---|---|
| `GET` | `/books?author=<name>` | `200` list of books, optionally filtered by author (case-insensitive) | |
| `GET` | `/books/{id}` | `200` the book | `404` |
| `POST` | `/books` | `201` the created book, with a `Location` header | `400` |
| `PUT` | `/books/{id}` | `200` the updated book | `400`, `404` |
| `DELETE` | `/books/{id}` | `204` | `404` |

Request bodies for `POST` and `PUT` look like this:

```json
{"title": "Dune", "author": "Frank Herbert", "year": 1965, "price": 9.99}
```

A body is rejected with `400` if a field is missing or has the wrong type, if `title` or `author` is blank, if `year` is outside 1450 to the current year, or if `price` is negative. Errors from the API come back as `{"message": "..."}`.

### Try it

```bash
curl -i -X POST localhost:8090/books \
  -H 'Content-Type: application/json' \
  -d '{"title":"Dune","author":"Frank Herbert","year":1965,"price":9.99}'

curl localhost:8090/books
curl localhost:8090/books/1
curl "localhost:8090/books?author=frank%20herbert"

curl -X PUT localhost:8090/books/1 \
  -H 'Content-Type: application/json' \
  -d '{"title":"Dune","author":"Frank Herbert","year":1965,"price":14.99}'

curl -i -X DELETE localhost:8090/books/1
```

## Running the tests

```bash
bal test
```

This runs the tests in the root package and in both modules. Each set of tests is tagged with a group, so you can run one at a time:

```bash
bal test --groups models    # validation rules
bal test --groups store     # in-memory store
bal test --groups service   # HTTP API
```

To get a coverage report, run the following and open `target/report/index.html`:

```bash
bal test --code-coverage
```

The service tests start the service on its default port and call it at `http://localhost:8090/books`, so **port 8090 must be free** while they run. A `Config.toml` in the project root does not affect the tests. If you change the default port in `service.bal`, update the URL in `tests/service_test.bal` to match.
