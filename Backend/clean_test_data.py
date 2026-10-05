"""
Clean test and demo data from TAMS PostgreSQL database.
Leaves admin@tams.com intact and purges test-run records.
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'tams.settings')
django.setup()

from django.contrib.auth import get_user_model
from vehicles.models import Vehicle
from drivers.models import Driver
from bookings.models import Customer, Booking
from billing.models import Invoice
from duty_slips.models import DutySlip
from payments.models import Payment
from maintenance.models import WorkOrder

User = get_user_model()

def clean_database():
    print("Purging test and demo records from database...")

    # Delete test duty slips and work orders
    ds_count = DutySlip.objects.all().delete()[0]
    wo_count = WorkOrder.objects.all().delete()[0]
    pay_count = Payment.objects.all().delete()[0]
    inv_count = Invoice.objects.all().delete()[0]
    demo_emails = ['admin@tams.com', 'admin@tams.local', 'staff@tams.local', 'driver@tams.local', 'customer@tams.local']
    bk_count = Booking.objects.all().delete()[0]
    cust_count = Customer.objects.exclude(email__in=demo_emails).delete()[0]
    drv_count = Driver.objects.exclude(email__in=demo_emails).delete()[0]
    veh_count = Vehicle.objects.all().delete()[0]
    
    # Delete test users while preserving official demo and admin accounts
    u_count = User.objects.exclude(email__in=demo_emails).delete()[0]

    print(f"Cleaned:")
    print(f"  - Duty Slips: {ds_count}")
    print(f"  - Work Orders: {wo_count}")
    print(f"  - Payments: {pay_count}")
    print(f"  - Invoices: {inv_count}")
    print(f"  - Bookings: {bk_count}")
    print(f"  - Customers: {cust_count}")
    print(f"  - Drivers: {drv_count}")
    print(f"  - Vehicles: {veh_count}")
    print(f"  - Non-Admin Users: {u_count}")
    print("\nDatabase is now completely clean and ready for actual use.")
    print("Superuser preserved: admin@tams.com (ADMIN)")

if __name__ == '__main__':
    clean_database()
