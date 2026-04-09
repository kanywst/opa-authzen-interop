# opa-authzen-interop

An OPA + Rego PDP implementation for the [OpenID AuthZEN interop](https://authzen-interop.net/) Todo scenario.
The AuthZEN API endpoints are provided by [opa-authzen-plugin](https://github.com/kanywst/opa-authzen-plugin).

- **Spec:** [Authorization API 1.0](https://openid.github.io/authzen/)
- **Interop site:** [authzen-interop.net](https://authzen-interop.net)
- **Test harness:** [openid/authzen/interop/authzen-todo-backend](https://github.com/openid/authzen/tree/main/interop/authzen-todo-backend)

## Usage

### Quick start

```bash
make test
```

This runs Rego unit tests, starts the PDP via Docker Compose, runs integration tests, and stops the PDP.

To run only the Rego unit tests (no Docker required):

```bash
make rego-test
```

### Running the AuthZEN interop test harness

Start the PDP, then use the [authzen-todo-backend](https://github.com/openid/authzen/tree/main/interop/authzen-todo-backend) test harness:

```bash
make up

git clone https://github.com/openid/authzen.git
cd authzen/interop/authzen-todo-backend
yarn install && yarn build

# authorization-api-1_0-01: single evaluation
yarn test http://localhost:8181 authorization-api-1_0-01 console
```

### Using the binary (development)

```bash
# clone the plugin
git clone https://github.com/kanywst/opa-authzen-plugin.git
cd opa-authzen-plugin && make build

# clone the interop
git clone https://github.com/kanywst/opa-authzen-interop.git
cd opa-authzen-interop

# run the tests
./scripts/start-pdp.sh
./scripts/test-local.sh
```

## Test results

All tests pass.

<details>
<summary>test-local.sh output</summary>

```
=== AuthZEN Interop Test Suite ===
PDP URL: http://localhost:8181

--- Rick Sanchez (admin, evil_genius) ---
PASS can_read_user subject=CiRmZDA2MTRk... -> N/A
PASS can_read_user subject=CiRmZDA2MTRk... -> N/A
PASS can_read_todos subject=CiRmZDA2MTRk... -> N/A
PASS can_create_todo subject=CiRmZDA2MTRk... -> N/A
PASS can_update_todo subject=CiRmZDA2MTRk... -> rick@the-citadel.com
PASS can_update_todo subject=CiRmZDA2MTRk... -> morty@the-citadel.com
PASS can_delete_todo subject=CiRmZDA2MTRk... -> rick@the-citadel.com
PASS can_delete_todo subject=CiRmZDA2MTRk... -> morty@the-citadel.com

--- Morty Smith (editor) ---
PASS can_read_user subject=CiRmZDE2MTRk... -> N/A
PASS can_read_user subject=CiRmZDE2MTRk... -> N/A
PASS can_read_todos subject=CiRmZDE2MTRk... -> N/A
PASS can_create_todo subject=CiRmZDE2MTRk... -> N/A
PASS can_update_todo subject=CiRmZDE2MTRk... -> rick@the-citadel.com
PASS can_update_todo subject=CiRmZDE2MTRk... -> morty@the-citadel.com
PASS can_delete_todo subject=CiRmZDE2MTRk... -> rick@the-citadel.com
PASS can_delete_todo subject=CiRmZDE2MTRk... -> morty@the-citadel.com

--- Summer Smith (editor) ---
PASS can_read_user subject=CiRmZDI2MTRk... -> N/A
PASS can_read_user subject=CiRmZDI2MTRk... -> N/A
PASS can_read_todos subject=CiRmZDI2MTRk... -> N/A
PASS can_create_todo subject=CiRmZDI2MTRk... -> N/A
PASS can_update_todo subject=CiRmZDI2MTRk... -> rick@the-citadel.com
PASS can_update_todo subject=CiRmZDI2MTRk... -> summer@the-smiths.com
PASS can_delete_todo subject=CiRmZDI2MTRk... -> rick@the-citadel.com
PASS can_delete_todo subject=CiRmZDI2MTRk... -> summer@the-smiths.com

--- Beth Smith (viewer) ---
PASS can_read_user subject=CiRmZDM2MTRk... -> N/A
PASS can_read_user subject=CiRmZDM2MTRk... -> N/A
PASS can_read_todos subject=CiRmZDM2MTRk... -> N/A
PASS can_create_todo subject=CiRmZDM2MTRk... -> N/A
PASS can_update_todo subject=CiRmZDM2MTRk... -> rick@the-citadel.com
PASS can_update_todo subject=CiRmZDM2MTRk... -> beth@the-smiths.com
PASS can_delete_todo subject=CiRmZDM2MTRk... -> rick@the-citadel.com
PASS can_delete_todo subject=CiRmZDM2MTRk... -> beth@the-smiths.com

--- Jerry Smith (viewer) ---
PASS can_read_user subject=CiRmZDQ2MTRk... -> N/A
PASS can_read_user subject=CiRmZDQ2MTRk... -> N/A
PASS can_read_todos subject=CiRmZDQ2MTRk... -> N/A
PASS can_create_todo subject=CiRmZDQ2MTRk... -> N/A
PASS can_update_todo subject=CiRmZDQ2MTRk... -> rick@the-citadel.com
PASS can_update_todo subject=CiRmZDQ2MTRk... -> jerry@the-smiths.com
PASS can_delete_todo subject=CiRmZDQ2MTRk... -> rick@the-citadel.com
PASS can_delete_todo subject=CiRmZDQ2MTRk... -> jerry@the-smiths.com

--- Batch Evaluations ---
PASS [batch] can_update_todo subject=CiRmZDA2MTRk... evaluations=2
PASS [batch] can_update_todo subject=CiRmZDE2MTRk... evaluations=2
PASS [batch] can_update_todo subject=CiRmZDQ2MTRk... evaluations=2

=== Results ===
Total: 43  Pass: 43  Fail: 0  Error: 0
All tests passed!
```

</details>

## Todo scenario

5 users (Rick & Morty themed) and 5 authorization actions. See [Todo interop scenario](https://authzen-interop.net/docs/scenarios/todo-1.1/) for request/response details.

| Action            | admin (Rick) | editor (Morty, Summer) | viewer (Beth, Jerry) |
| ----------------- | :----------: | :--------------------: | :------------------: |
| `can_read_user`   |    allow     |         allow          |        allow         |
| `can_read_todos`  |    allow     |         allow          |        allow         |
| `can_create_todo` |    allow     |         allow          |       **deny**       |
| `can_update_todo` | allow (any)  |    allow (own only)    |       **deny**       |
| `can_delete_todo` | allow (any)  |    allow (own only)    |       **deny**       |

## Endpoints

| Endpoint           | Path                                     | Status      |
| ------------------ | ---------------------------------------- | ----------- |
| Evaluation         | `POST /access/v1/evaluation`             | implemented |
| Evaluations(batch) | `POST /access/v1/evaluations`            | implemented |
| PDP Metadata       | `GET /.well-known/authzen-configuration` | implemented |

## References

- [OpenID AuthZEN Working Group](https://openid.net/wg/authzen/)
- [Authorization API 1.0 spec](https://openid.github.io/authzen/)
- [AuthZEN Interop Results](https://authzen-interop.net)
- [openid/authzen](https://github.com/openid/authzen)
- [opa-authzen-plugin](https://github.com/kanywst/opa-authzen-plugin)
