# bookstore-service

A Ballerina REST service for managing a catalog of books, served at `/books`.

## Running

```bash
bal run
```

The service listens on the `port` configurable, which defaults to `9090`.

## Testing

```bash
bal test
```

The service tests call the service on whatever `port` is set to, so they need no
`Config.toml`. To run them on another port, set `port` in `tests/Config.toml`.
