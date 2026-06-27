# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the **BrownField Passenger Service System (PSS)** — a learning project demonstrating Java microservices architecture. It consists of five independent Spring Boot services plus two demo projects.

**Stack:** Java 21, Spring Boot 3.5.15, Spring Data JPA, H2 (in-memory database), ActiveMQ Classic (JMS), Thymeleaf (website), springdoc-openapi 2.8.15.

## Build and Run Commands

Each service is a standalone Maven project with no parent pom. Run commands from within the service directory:

```bash
# Build (skip tests)
cd <service-dir>
mvn clean package -DskipTests

# Run
mvn spring-boot:run

# Run tests
mvn test

# Run a single test class
mvn test -Dtest=ApplicationTests
```

### Starting All Services

Start each in a separate terminal. **Start ActiveMQ Classic first** before launching `search`, `book`, or `checkin`.

| Service   | Directory   | Port |
|-----------|-------------|------|
| fares     | `fares/`    | 8080 |
| search    | `search/`   | 8090 |
| book      | `book/`     | 8060 |
| checkin   | `checkin/`  | 8070 |
| website   | `website/`  | 8001 |

ActiveMQ Classic default broker URL: `tcp://localhost:61616`, credentials `admin/admin`. Admin console at `http://localhost:8161`.

## Service Architecture

```
[website :8001]  ← Thymeleaf UI (RestTemplate calls other services directly)
     │
     ├──→ [search :8090]  POST /search/get
     ├──→ [book   :8060]  POST /booking/create, GET /booking/get/{id}
     └──→ [checkin:8070]  POST /checkin/create

[book] ──→ [fares :8080]  GET /fares/get?flightNumber=&flightDate=
                           (called internally by BookingComponent, not website)
```

### ActiveMQ Message Flows

- **book → search** via queue `SearchQ`: After a booking is confirmed, `book` sends `{FLIGHT_NUMBER, FLIGHT_DATE, NEW_INVENTORY}` as a JMS `MapMessage` so `search` can decrement its inventory cache.
- **checkin → book** via queue `CheckINQ`: After check-in, `checkin` sends the `bookingId` as a JMS `TextMessage` (String) so `book` can update the booking status to `CHECKED_IN`. Sent as String to avoid JMS `ObjectMessage` serialization trust configuration.
- Queues are auto-created by ActiveMQ on first send — no broker-side configuration required.

### Service Internals Pattern

Each core service follows: `Controller → Component → Repository (Spring Data JPA / H2)`.

- **search** (`com.brownfield.pss.search`): Stores `Flight` with embedded `Inventory` and `Fares`. `SearchComponent` queries by origin/destination/date and filters out flights where inventory count is negative. `Receiver` listens on `SearchQ` to update inventory.
- **fares** (`com.brownfield.pss.fares`): Simple lookup — `GET /fares/get?flightNumber=&flightDate=` returns a `Fare` entity. No messaging. No ActiveMQ dependency.
- **book** (`com.brownfield.pss.book`): `BookingComponent.book()` validates fare (calls fares service at `localhost:8080`), checks its own local `Inventory` table, saves `BookingRecord` + `Passenger` entities, then publishes to `SearchQ`. `Receiver` listens on `CheckINQ` to update booking status to `CHECKED_IN`. Note: `book` has its own separate `Inventory` table — distinct from search's inventory.
- **checkin** (`com.brownfield.pss.checkin`): Saves a `CheckInRecord`, then publishes the booking ID to `CheckINQ`.
- **website** (`com.brownfield.pss.client`): Thymeleaf MVC frontend. Calls other services via `RestTemplate` with hardcoded `localhost` URLs (`BrownFieldSiteController`). Spring Security is on the classpath with default auto-config — login page appears with username `user` and auto-generated password printed to console at startup.

### Demo Projects

- **demo_1/**: Basic Spring Boot + Spring Data REST hello-world.
- **demo_1-HATEOAS/**: Same with HATEOAS support added.

## Key Configuration Notes

- All services use H2 in-memory databases — data is lost on restart. No external database setup needed.
- Service URLs are hardcoded (`localhost:808x`) — no service discovery. If ports change, update hardcoded URLs in `BookingComponent` (`localhost:8080` for fares) and `BrownFieldSiteController` (`localhost:8090`, `8060`, `8070`).
- Swagger UI: `http://localhost:<port>/swagger-ui/index.html` for all core services.
- Actuator endpoints enabled on all core services.
