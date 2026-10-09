# SQL Server Database Growth Alert

Limits a SQL Server database's file growth and uses Database Mail with a SQL Server Agent job to email an alert when the database reaches 3.5 GB of its 4 GB maximum.

> Local lab setup (not a production deployment).

**Stack:** SQL Server, SQL Server Agent, Database Mail (Gmail SMTP)

## How it works

1. **Database Mail** is configured with a Gmail SMTP account (`smtp.gmail.com:587`, SSL) and tested with a test email (`screenshots/01-database-mail-test.png`).
2. **`TestGrowthDB`** is created with size limits: data file 500 MB initial, 4 GB max, 100 MB growth; log file 200 MB initial, 1 GB max, 50 MB growth.
3. A test table is filled with large rows to make the database grow.
4. A **SQL Server Agent job** (`DB_GROWTH_3_5GB_ALERT`) sums the database file sizes from `sys.master_files`. If the total is at least 3584 MB (3.5 GB), it sends an email with `sp_send_dbmail` (`screenshots/02-growth-alert-email.png`).

All SQL is in [`db_growth_alert.sql`](db_growth_alert.sql).

## Setup notes

- Use a Gmail **app password** (never your real password). Put it in the script only when you run it locally, and never commit it.
- SQL Server Agent must be running for the job to execute.

## What I learned

- How `MAXSIZE` and `FILEGROWTH` cap database growth.
- Configuring Database Mail accounts/profiles and testing delivery.
- Building a SQL Server Agent job with a T-SQL step for proactive monitoring.

## Next steps

- Add a recurring schedule so the check runs automatically.
- Alert at several thresholds (for example 70% / 85% / 95%).
- Compare with size limits in MySQL (disk quota) and PostgreSQL (tablespace/filesystem limits).
