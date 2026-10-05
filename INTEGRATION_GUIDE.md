# Travel Agency Management System (TAMS) - System Integration & Architecture Guide

## 1. System Architecture Overview

TAMS is built using a clean 3-tier architecture ensuring a single source of truth:

```text
                           TAMS SYSTEM
                                │
                ┌───────────────┴───────────────┐
                │                               │
        WEBSITE FRONTEND                 FLUTTER APP
        HTML5 / CSS3 / Vanilla JS        (Preserved for Future Phase)
                │
                │ REST API (JSON)
                ▼
          DJANGO REST FRAMEWORK (DRF)
          - Authentication & Roles
          - Business Rules Engine
          - Tax & Billing Automation
          - Simulated Payment Gateway
                │
                │ Django ORM (psycopg2)
                ▼
          POSTGRESQL DATABASE (tams_db)
```

---

## 2. Technology Stack

- **Frontend**: Vanilla HTML5, CSS3, Modern JavaScript (ES6+ async/await, Fetch API). Preserved existing designs, layouts, and responsive CSS.
- **Backend**: Python 3.13, Django 5.x, Django REST Framework (DRF), `django-cors-headers`.
- **Database**: PostgreSQL 16+ running on port `5432` (`tams_db`).
- **Mobile/App**: Flutter cross-platform mobile client (`lib/`) untouched and preserved for subsequent development phases.

---

## 3. Directory Layout

```text
TAMS/
├── Backend/
│   ├── manage.py
│   ├── .env                       # Environment variables
│   ├── .env.example               # Environment variables template
│   ├── test_e2e_system.py         # End-to-end integration test suite
│   ├── clean_test_data.py         # Test data purging utility
│   │
│   ├── tams/                      # Django project core
│   │   ├── settings.py            # DB, CORS, Auth, Static configuration
│   │   ├── urls.py                # Main router + Template view routing
│   │   └── wsgi.py
│   │
│   ├── accounts/                  # Custom User (ADMIN, STAFF, DRIVER, CUSTOMER), Auth APIs
│   ├── vehicles/                  # Fleet inventory, statuses, daily rates
│   ├── drivers/                   # Driver profiles, license tracking, duty statuses
│   ├── bookings/                  # Customer models, reservation logic, conflict engine
│   ├── duty_slips/                # Dispatch slips, odometer logs, trip lifecycle
│   ├── billing/                   # Invoices, 5% GST tax engine
│   ├── payments/                  # Simulated payment gateway (UPI QR, Card, Cash)
│   ├── maintenance/               # Vehicle service logs & status synchronization
│   ├── reports/                   # PostgreSQL aggregations & CSV exports
│   │
│   ├── static/
│   │   ├── css/                   # Stylesheets for all pages
│   │   └── js/
│   │       └── api.js             # Centralized TAMS_API client
│   │
│   └── templates/                 # 21 Live HTML Templates
│       ├── index.html             # Login & role router
│       ├── register.html          # Customer registration
│       ├── admin-dashboard.html   # Live admin analytics & KPIs
│       ├── fleet-management.html  # Vehicle CRUD & availability
│       ├── driver-management.html # Driver CRUD & license validity
│       ├── manage-bookings.html   # Booking management & status transitions
│       ├── duty-slip-management.html # Dispatch slips & odometer tracking
│       ├── billing.html           # Invoicing, GST tax & payments
│       ├── maintenance.html       # Fleet service orders & status sync
│       ├── reports.html           # Analytics reports & CSV export
│       ├── customer-dashboard.html# Customer portal
│       ├── search-vehicles.html   # Vehicle catalog & search
│       ├── book-vehicle.html      # Reservation form & live pricing
│       ├── my-bookings.html       # Customer bookings & cancellation
│       ├── customer-invoices.html # Customer billing & simulated payments
│       ├── customer-profile.html  # Customer profile edit
│       ├── driver-dashboard.html  # Driver portal & trip actions
│       ├── driver-duty-slips.html # Driver duty slips
│       ├── driver-trips.html      # Trip logs & odometer inputs
│       ├── driver-earnings.html   # Driver earnings breakdown
│       └── driver-profile.html    # Driver profile management
│
└── lib/                           # Flutter mobile codebase (Preserved)
```

---

## 4. REST API Endpoint Reference

All REST endpoints are rooted under `/api/v1/`.

| App / Resource | Endpoint | Methods | Description |
|---|---|---|---|
| **Auth** | `/api/v1/auth/login/` | `POST` | Authenticate user; returns Token, user info, role |
| **Auth** | `/api/v1/auth/register/` | `POST` | Register new customer account |
| **Auth** | `/api/v1/auth/me/` | `GET`, `PATCH` | Current logged-in user profile |
| **Auth** | `/api/v1/auth/logout/` | `POST` | Terminate session & invalidate token |
| **Vehicles** | `/api/v1/vehicles/` | `GET`, `POST` | List & filter vehicles; create vehicle |
| **Vehicles** | `/api/v1/vehicles/{id}/` | `GET`, `PUT`, `PATCH`, `DELETE` | Vehicle details, updates, deletion |
| **Drivers** | `/api/v1/drivers/` | `GET`, `POST` | List & filter drivers; create driver |
| **Drivers** | `/api/v1/drivers/{id}/` | `GET`, `PUT`, `PATCH`, `DELETE` | Driver details, updates, deletion |
| **Customers** | `/api/v1/customers/` | `GET`, `POST` | List & search customers; create customer |
| **Customers** | `/api/v1/customers/{id}/` | `GET`, `PUT`, `PATCH`, `DELETE` | Customer details & updates |
| **Bookings** | `/api/v1/bookings/` | `GET`, `POST` | List bookings; create booking (triggers overlap check & invoice auto-gen) |
| **Bookings** | `/api/v1/bookings/my_bookings/` | `GET` | Retrieve bookings belonging to authenticated customer |
| **Bookings** | `/api/v1/bookings/{id}/` | `GET`, `PATCH`, `DELETE` | Booking details, status change, cancellation |
| **Duty Slips** | `/api/v1/duty-slips/` | `GET`, `POST` | Dispatch slips; create assignment with overlap & license validation |
| **Duty Slips** | `/api/v1/duty-slips/my_slips/` | `GET` | Slips assigned to currently authenticated driver |
| **Duty Slips** | `/api/v1/duty-slips/{id}/start_trip/` | `POST` | Start trip, record start odometer; sets vehicle to 'On Trip', driver to 'On Duty' |
| **Duty Slips** | `/api/v1/duty-slips/{id}/complete_trip/` | `POST` | End trip, validate end odometer; restores vehicle & driver to 'Available' |
| **Billing** | `/api/v1/invoices/` | `GET`, `POST` | Invoices list & creation with automated 5% GST computation |
| **Billing** | `/api/v1/invoices/my_invoices/` | `GET` | Invoices for logged-in customer |
| **Payments** | `/api/v1/payments/initiate/` | `POST` | Initiate demo payment session (UPI QR, Card, Cash) |
| **Payments** | `/api/v1/payments/confirm/` | `POST` | Confirm demo payment; marks Payment and Invoice as PAID |
| **Payments** | `/api/v1/payments/cancel/` | `POST` | Cancel demo payment session |
| **Maintenance**| `/api/v1/maintenance/` | `GET`, `POST` | Fleet work orders; syncing vehicle to 'Maintenance' |
| **Maintenance**| `/api/v1/maintenance/{id}/` | `PATCH`, `DELETE` | Update work order; 'Completed' returns vehicle to 'Available' |
| **Reports** | `/api/v1/dashboard/` | `GET` | Live PostgreSQL KPI metrics for admin/staff dashboard |
| **Reports** | `/api/v1/reports/analytics/` | `GET` | 6-month trends, fleet utilization, top drivers & vehicles |
| **Reports** | `/api/v1/reports/export-csv/` | `GET` | Live CSV export for bookings, revenue, fleet, drivers |

---

## 5. Core Business Rules Implemented

1. **Vehicle Availability & Maintenance Lockout**:
   - A vehicle with status `Maintenance` or `Unavailable` cannot be selected or reserved.
2. **Booking Date Overlap Prevention**:
   - When a booking is submitted, DRF validates against existing `Pending` or `Confirmed` bookings for that vehicle. Overlapping date ranges are rejected with HTTP 400 Bad Request.
3. **Driver License & Assignment Overlap Checks**:
   - Duty slips verify that the assigned driver's license expiration date is >= duty date.
   - Duty slips verify that the driver does not already have an active/upcoming assignment on that day.
4. **Trip Lifecycle & Status Synchronization**:
   - Starting a trip (`/start_trip/`) requires start odometer and automatically sets the vehicle to `On Trip` and driver to `On Duty`.
   - Completing a trip (`/complete_trip/`) requires end odometer (validates end >= start), completes the duty slip and linked booking, and restores the vehicle and driver to `Available`.
5. **Billing & Tax Engine**:
   - `Taxable Amount = Base Fare - Discount`
   - `Tax Amount = Taxable Amount × 0.05` (5% GST)
   - `Grand Total = Taxable Amount + Tax Amount`
   - The backend is the sole authority on financial amounts.
6. **Simulated Payment System**:
   - No external real bank gateway (No Razorpay / Stripe).
   - Generates demo QR code string with transaction reference, invoice code, amount, and explicit `SIMULATED DEMO ONLY` label.
   - Payment confirmation triggers invoice status transition to `Paid` only after backend validation.

---

## 6. How to Run the Project

### Prerequisites
- Python 3.10+
- PostgreSQL 14+ running on port `5432` with database `tams_db`

### Step 1: Database Setup
In PostgreSQL (psql or pgAdmin):
```sql
CREATE DATABASE tams_db;
```

### Step 2: Install Python Dependencies
```bash
cd Backend
py -m pip install -r requirements.txt  # Or: pip install django djangorestframework django-cors-headers psycopg2-binary
```

### Step 3: Run Database Migrations
```bash
py manage.py makemigrations
py manage.py migrate
```

### Step 4: Run System Tests
Verify that all 10 end-to-end integration test steps pass cleanly:
```bash
py test_e2e_system.py
```

### Step 5: Start the Django Development Server
To allow both local browser/desktop and physical mobile devices (over USB or Wi-Fi) to connect:
```bash
py manage.py runserver 0.0.0.0:8000
```

### Step 6: Connecting Physical Mobile Devices (Android / iOS)
1. **USB Connection (Recommended & Fastest)**:
   - Connect phone to PC via USB cable with USB Debugging enabled.
   - Run the port forwarding command in terminal:
     ```bash
     C:\Android\sdk\platform-tools\adb.exe reverse tcp:8000 tcp:8000
     ```
   - In the TAMS app (tap Settings icon on Login or Register screen), select:
     `http://127.0.0.1:8000/api/v1`
2. **Wi-Fi Connection (Same Network)**:
   - Ensure phone and PC are connected to the same Wi-Fi network.
   - In the TAMS app, select or enter your PC's Wi-Fi IP address:
     `http://10.106.1.72:8000/api/v1`

### Step 7: Access the Web Application
Open your browser and navigate to:
```text
http://127.0.0.1:8000/
```

### Default Credentials
- **Admin**: `admin@tams.com` / `admin123`
- New customers can register at `http://127.0.0.1:8000/register.html` or directly from the mobile app!

---

## 7. Environment Configuration (.env)

Located in `Backend/.env`:
```ini
DJANGO_SECRET_KEY=django-insecure-tams-travel-agency-mgmt-sys-2026-key-prod-ready
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

DB_NAME=tams_db
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=localhost
DB_PORT=5432

TAX_RATE=0.05
CORS_ALLOWED_ORIGINS=http://localhost:8000,http://127.0.0.1:8000
```
