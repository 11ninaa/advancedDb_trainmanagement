# Schedura

PostgreSQL database for an Italian railway platform. It stores companies, trains, stations, routes, trips, staff, passengers, reservations, payments, and tickets.

The scripts were written and run in DataGrip against a PostgreSQL database.

People in this repository are synthetic. There are no passwords, API keys, tokens, or database credentials.

## Layout

| File | Purpose |
| --- | --- |
| `ddl.sql` | Tables, keys, and checks |
| `FINALTABLEPERSON.csv` | 1,000,000 generated people |
| `dml.sql` | Companies, stations, trains, trips, reservations, payments, tickets, and the other rows |
| `views.sql` | Operational and analytical views |
| `functions.sql` | Queries wrapped as functions (free seats, revenue, passenger lookup) |
| `procedures.sql` | Selling a ticket, cancelling a reservation, delays, platform and staff changes |
| `triggers.sql` | Seat clashes, overlapping shifts, reservation status, payment timestamps |
| `advanced_topics.sql` | Range partitioning for trips, payments, and tickets |
| `generatingdata.py` | Builds `FINALTABLEPERSON.csv` |
| `train_travelers_female_names.csv` | First names used for women |
| `train_travelers_male_names.csv` | First names used for men |
| `surnames.csv` | Surnames |

## Load order

Run these against an empty PostgreSQL database, in this order:

1. `ddl.sql`
2. Load people (the later scripts read `Person`):

```sql
COPY Person (EMBG, first_name, last_name, gender, nationality, phone_number, email)
FROM 'FINALTABLEPERSON.csv'
WITH (FORMAT csv, HEADER true);
```

3. `dml.sql`
4. `views.sql`
5. `functions.sql`
6. `procedures.sql`
7. `triggers.sql`
8. `advanced_topics.sql`

`advanced_topics.sql` renames `Train Trip`, `Payment`, and `Ticket` and rebuilds them as partitioned tables. Run it last.

`Person.email` is `VARCHAR(40)`. Some generated addresses are longer than 40 characters, so widen that column before the `COPY` if those rows should be kept.

## Generating the people file

`generatingdata.py` reads the three name lists and writes `FINALTABLEPERSON.csv`. It uses only the Python standard library.

```text
python generatingdata.py
```

Each row is a random 13-digit `EMBG`, a first name, a surname, gender, a country code, a random phone number, and an email shaped like `name.surname123@gmail.com`. The domains are public mailbox providers. The addresses are not real accounts.

The four companies in `dml.sql` (Trenitalia, Italo, Trenord, EAV) use public customer-service phone numbers and emails. Those are not private contacts.
