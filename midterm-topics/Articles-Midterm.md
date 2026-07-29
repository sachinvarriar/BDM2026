# Midterm Reading List

Reference articles for the BDM 2026 midterm, grouped by topic.
Work through them in order — Section 1 is conceptual background, Sections 2–4 are the SQL you will be asked to write, and Section 5 is the tool for drawing diagrams.

---

## 1. Database Concepts

Background theory. Expect definition and comparison questions on these.

| # | Topic | Link |
|---|---|---|
| 1.1 | **OLAP vs OLTP** — purpose, users, data volume, normalization, response time, backup needs | [GeeksforGeeks: Difference between OLAP and OLTP](https://www.geeksforgeeks.org/dbms/difference-between-olap-and-oltp-in-dbms/) |
| 1.2 | **OLAP vs OLTP** — the same comparison from a cloud-vendor angle; adds data structure (cube vs. table) and processing model | [AWS: The Difference Between OLAP and OLTP](https://aws.amazon.com/compare/the-difference-between-olap-and-oltp/) |
| 1.3 | **Denormalization** — what it is, when to use it, advantages and the redundancy trade-off | [GeeksforGeeks: Denormalization in Databases](https://www.geeksforgeeks.org/dbms/denormalization-in-databases/) |

> **Read 1.1 and 1.2 together.** They cover the same comparison, so use the second to fill gaps in the first rather than reading it cold.

---

## 2. SQL Building Blocks

The vocabulary of SQL — data types, operators, and how commands are classified.

| # | Topic | Link |
|---|---|---|
| 2.1 | **Data types** — numeric, character, date/time, binary; `CHAR` vs `VARCHAR`, `INT` ranges, `DECIMAL` for money | [GeeksforGeeks: SQL Data Types](https://www.geeksforgeeks.org/sql/sql-data-types/) |
| 2.2 | **Operators** — arithmetic, comparison, logical (`AND`/`OR`/`NOT`), and special (`BETWEEN`, `IN`, `LIKE`, `IS NULL`, `EXISTS`) | [GeeksforGeeks: SQL Operators](https://www.geeksforgeeks.org/sql/sql-operators/) |
| 2.3 | **Command categories** — DDL, DQL, DML, DCL, TCL: which command sits in which group | [GeeksforGeeks: DDL, DQL, DML, DCL and TCL Commands](https://www.geeksforgeeks.org/sql/sql-ddl-dql-dml-dcl-tcl-commands/) |

> **Know the five command groups cold.** `CREATE`/`ALTER`/`DROP`/`TRUNCATE` = DDL · `SELECT` = DQL · `INSERT`/`UPDATE`/`DELETE` = DML · `GRANT`/`REVOKE` = DCL · `COMMIT`/`ROLLBACK`/`SAVEPOINT` = TCL

---

## 3. Writing Queries

The core of the practical section. You should be able to write each of these from a plain-English description.

| # | Topic | Link |
|---|---|---|
| 3.1 | **SELECT** — basic syntax, `SELECT *`, `DISTINCT`, and clause order | [GeeksforGeeks: SQL SELECT Query](https://www.geeksforgeeks.org/sql/sql-select-query/) |
| 3.2 | **WHERE** — filtering rows; works with `SELECT`, `UPDATE`, and `DELETE` | [GeeksforGeeks: SQL WHERE Clause](https://www.geeksforgeeks.org/sql/sql-where-clause/) |
| 3.3 | **Aliases** — renaming columns and tables with `AS`; essential once you start joining | [GeeksforGeeks: SQL Aliases](https://www.geeksforgeeks.org/sql/sql-aliases/) |
| 3.4 | **INSERT** — with and without a column list, multiple rows, `INSERT INTO SELECT` | [GeeksforGeeks: SQL INSERT Statement](https://www.geeksforgeeks.org/sql/sql-insert-statement/) |

> **Clause order matters:** `SELECT` → `FROM` → `WHERE` → `GROUP BY` → `ORDER BY` → `LIMIT`

---

## 4. Joins

| # | Topic | Link |
|---|---|---|
| 4.1 | **INNER, LEFT, RIGHT and FULL joins** — what rows each returns and where `NULL`s appear | [GeeksforGeeks: SQL Join (Inner, Left, Right and Full Joins)](https://www.geeksforgeeks.org/sql/sql-join-set-1-inner-left-right-and-full-joins/) |

> **The one-line summary:** `INNER` keeps only matches · `LEFT` keeps everything on the left · `RIGHT` keeps everything on the right · `FULL` keeps everything from both sides. Unmatched columns come back as `NULL`.

---

## 5. ER Diagrams

| # | Topic | Link |
|---|---|---|
| 5.1 | **StarUML ER diagrams** — creating entities, adding columns, marking primary keys, drawing relationships | [StarUML Docs: Entity-Relationship Diagram](https://docs.staruml.io/working-with-additional-diagrams/entity-relationship-diagram) |

> This is **tool documentation**, not a tutorial on ER modelling — read it for how to draw the diagram, not for what to draw. Note that the page uses cardinality (one-to-one, one-to-many, many-to-many), which is **not** required for the midterm.

---

## Class material

Worked examples on the bike rental database used in class:

| File | Covers |
|---|---|
| [bike_rental_schema.sql](../bike_rental_schema.sql) | Table definitions — a live example of the data types in 2.1 |
| [session7.sql](../session7.sql) | `SELECT`, `LIMIT`, `DISTINCT`, aggregate functions |
| [session8.sql](../session8.sql) | `WHERE` predicates and every join type |
| [bike_rental_where_joins.sql](../bike_rental_where_joins.sql) | The same material with fuller comments — the best revision file |
| [session9.sql](../session9.sql) | `GROUP BY`, alone and combined with `WHERE` |

---

## Quick revision checklist

- [ ] I can state three differences between OLAP and OLTP
- [ ] I can explain why denormalization speeds up reads, and what it costs
- [ ] I can pick the right data type for money, for a name, and for a date
- [ ] I can sort every SQL command into DDL / DQL / DML / DCL / TCL
- [ ] I can write a `SELECT` with `WHERE`, `ORDER BY` and `LIMIT`
- [ ] I can write a `GROUP BY` with `COUNT`, `SUM` or `AVG`
- [ ] I can write an `INNER JOIN` and say what `LEFT JOIN` would change
- [ ] I can identify entities from a scenario and draw them in UML notation
