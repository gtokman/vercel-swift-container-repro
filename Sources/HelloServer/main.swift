import AnyLanguageModel
import AsyncHTTPClient
import Hummingbird
import JSONSchema
import Logging
import Valkey

// The other modules are imported only so they're compiled and linked, as in the real server.
let environment = Environment()
let router = Router()
router.get("/") { _, _ in "Hello, world!\n" }

let app = Application(
    router: router,
    configuration: .init(address: .hostname(
        environment.get("HOST") ?? "0.0.0.0",
        port: environment.get("PORT").flatMap(Int.init) ?? 8080
    ))
)
try await app.runService()
