# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is the **BrownField Passenger Service System (PSS)** — a learning project demonstrating Java microservices architecture. It consists of five independent Spring Boot services plus two demo projects.

**Stack:** Java 17, Spring Boot 3.1.5, Spring Data JPA, H2 (in-memory database), RabbitMQ (AMQP), Thymeleaf (website), springdoc-openapi 2.2.0.

## Build and Run Commands

Each service is a standalone Maven project. Run commands from within the service directory:

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

Start each in a separate terminal in this order (fares has no RabbitMQ dependency, so start first):

| Service   | Directory  | Port |
|-----------|-----------|------|
| fares     | `fares/`   | 8080 |
| search    | `search/`  | 8090 |
| book      | `book/`    | 8060 |
| checkin   | `checkin/` | 8070 |
| website   | `website/` | 8001 |

**ActiveMQ Classic is required** for `search`, `book`, and `checkin` services. Start ActiveMQ before those three. Default broker URL: `tcp://localhost:61616`, credentials `admin/admin`. Admin console at `http://localhost:8161`.

## Service Architecture

```
[website :8001]  ← Thymeleaf UI (RestTemplate calls other services)
     │
     ├──→ [search :8090]  POST /search/get
     ├──→ [book   :8060]  POST /booking/create, GET /booking/get/{id}
     └──→ [checkin:8070]  POST /checkin/create
              │
              └──→ [fares :8080]  GET /fares/get?flightNumber=&flightDate=
                         (called by book internally)
```

### ActiveMQ Message Flows

- **book → search** via queue `SearchQ`: After a booking is confirmed, `book` sends `{FLIGHT_NUMBER, FLIGHT_DATE, NEW_INVENTORY}` as a JMS `MapMessage` so `search` can decrement its inventory cache.
- **checkin → book** via queue `CheckINQ`: After check-in, `checkin` sends the `bookingId` as a JMS `TextMessage` (String) so `book` can update the booking status to `CHECKED_IN`. Sent as String to avoid JMS `ObjectMessage` serialization trust configuration.
- Queues are auto-created by ActiveMQ on first send — no broker-side configuration required.

### Service Internals Pattern

Each core service follows: `Controller → Component → Repository (Spring Data JPA / H2)`.

- **search**: Stores `Flight` with embedded `Inventory` and `Fares`. `SearchComponent` queries by origin/destination/date and filters out zero-inventory flights. `Receiver` listens on `SearchQ` to update inventory.
- **fares**: Simple lookup service — `GET /fares/get?flightNumber=&flightDate=` returns a `Fare` entity. No messaging.
- **book**: `BookingComponent.book()` validates fare (calls fares service), checks inventory in its local `Inventory` table, saves `BookingRecord` + `Passenger` entities, then publishes to `SearchQ`. `Receiver` listens on `CheckINQ` to update booking status.
- **checkin**: Saves a `CheckInRecord`, then publishes the booking ID to `CheckINQ`.
- **website**: Thymeleaf MVC frontend. Calls other services via `RestTemplate` with hardcoded `localhost` URLs. Uses Spring Security (default auto-config).

### Demo Projects

- **demo_1/**: Basic Spring Boot + Spring Data REST hello-world.
- **demo_1-HATEOAS/**: Same with HATEOAS support added.

## Key Configuration Notes

- All services use H2 in-memory databases — data is lost on restart. No external database setup needed.
- Service URLs are hardcoded in source (`localhost:808x`) — there is no service discovery (no Eureka/Ribbon). If ports change, update the hardcoded URLs in `BookingComponent` and `BrownFieldSiteController`.
- Swagger UI available at `http://localhost:<port>/swagger-ui/index.html` for services with springdoc-openapi.
- Actuator endpoints enabled on all core services.
