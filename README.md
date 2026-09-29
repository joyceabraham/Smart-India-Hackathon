App Link:https://smart-q-sih.netlify.app/
# Smart Queue System (Real-Time & Blockchain-Audited)

A full-stack, offline-first queue management platform built with **FastAPI** and **Flutter Web**[cite: 1, 3]. Designed for seamless queue flows, real-time counter updates via WebSockets, local offline caching, and immutable audit logging powered by a custom **SHA-256 cryptographic blockchain ledger**[cite: 1, 2, 3].

---

## Features

### User Portal
* **Instant Token Generation**: Book queue tokens with name, phone number, and department assignment.
* **Offline-First Resilience**: Automatically saves tokens locally if network connectivity drops, ensuring continuous booking availability.
* **Auto-Resynchronization**: One-click batch sync endpoints to post buffered offline tokens back to the server upon reconnection.
* **Live Token Status**: Real-time position and status updates directly in the app.

### Staff & Admin View
* **Real-Time Queue Management**: Live WebSocket feeds refresh staff dashboards instantaneously as new tokens are generated or called.
* **Counter Operations**: Advance the line (`Call Next`), skip no-shows, or mark tickets as completed.
* **Live System Metrics**: Monitor total citizens queued, active counters, and token distribution.

### Core Engine & Security
* **Cryptographic SHA-256 Audit Ledger**: Every lifecycle event (`TOKEN_CREATED`, `TOKEN_CALLED`, `TOKEN_SKIPPED`, `OFFLINE_TOKEN_SYNCED`) creates an immutable block linked via cryptographic hash to guarantee tamper-proof audit trails.
* **Instant WebSocket Streaming**: Bi-directional event broadcasts ensure synchronization across all active web clients with sub-second latency.
* **SQLite Persistence**: Powered by SQLAlchemy ORM with absolute pathing to guarantee reliable database transactions.

