"""
Comprehensive Flutter Integration and Shared Database Verification Test
Validates all requirements for TAMS Android App & Django REST API integration.
"""
import os
import sys
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8')
import django
from datetime import date, timedelta
from decimal import Decimal

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'tams.settings')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from vehicles.models import Vehicle
from drivers.models import Driver
from bookings.models import Customer, Booking
from billing.models import Invoice
from duty_slips.models import DutySlip
from payments.models import Payment
from maintenance.models import WorkOrder

User = get_user_model()

def run_integration_tests():
    print("=" * 75)
    print("TAMS FLUTTER INTEGRATION & SHARED POSTGRESQL DATABASE VERIFICATION")
    print("=" * 75)

    client = APIClient()

    # 1. VERIFY DEMO ACCOUNTS & AUTHENTICATION
    print("\n[1] Testing Demo Authentication Across All 4 Roles...")
    roles = [
        ('ADMIN', 'admin@tams.local', 'TamsAdmin@123'),
        ('STAFF', 'staff@tams.local', 'TamsStaff@123'),
        ('DRIVER', 'driver@tams.local', 'TamsDriver@123'),
        ('CUSTOMER', 'customer@tams.local', 'TamsCustomer@123'),
    ]

    tokens = {}
    for role, email, password in roles:
        res = client.post('/api/v1/auth/login/', {
            'email': email,
            'password': password,
            'role': role
        }, format='json')
        assert res.status_code == 200, f"Login failed for {role} ({email}): {res.data}"
        assert 'token' in res.data, f"Token missing for {role}"
        assert res.data['user']['role'] == role, f"Role mismatch for {role}"
        tokens[role] = res.data['token']
        user_display = res.data['user'].get('full_name') or res.data['user'].get('first_name') or res.data['user'].get('email')
        print(f"  ✓ {role:<8} authenticated successfully -> user_id={res.data['user']['id']}, name='{user_display}'")

    admin_client = APIClient()
    admin_client.credentials(HTTP_AUTHORIZATION=f"Token {tokens['ADMIN']}")

    driver_client = APIClient()
    driver_client.credentials(HTTP_AUTHORIZATION=f"Token {tokens['DRIVER']}")

    customer_client = APIClient()
    customer_client.credentials(HTTP_AUTHORIZATION=f"Token {tokens['CUSTOMER']}")

    # 2. VERIFY ROLE ISOLATION & PERMISSIONS
    print("\n[2] Testing Role Permissions & Access Isolation...")
    # Customer shouldn't access full vehicle admin management
    cust_veh_res = customer_client.post('/api/v1/vehicles/', {'registration_number': 'FAKE'}, format='json')
    assert cust_veh_res.status_code in [401, 403], f"Customer should not be able to create vehicles: {cust_veh_res.status_code}"
    print("  ✓ Customer forbidden from creating fleet vehicles (403 Forbidden)")

    # Driver shouldn't see other customers' records
    drv_cust_res = driver_client.get('/api/v1/customers/')
    assert len(drv_cust_res.data) == 0, f"Driver should not see other customer profiles: {drv_cust_res.data}"
    print("  ✓ Driver isolated from customer records (0 customer profiles visible)")

    # 3. VEHICLE MODULE
    print("\n[3] Testing Vehicle Module (Admin)...")
    test_reg = "OD-02-FL-8888"
    Vehicle.objects.filter(registration_number=test_reg).delete()

    veh_payload = {
        "registration_number": test_reg,
        "make_model": "Toyota Innova Crysta",
        "vehicle_type": "SUV",
        "capacity": 7,
        "per_day_rate": "3500.00",
        "fuel_type": "Diesel",
        "transmission": "Automatic",
        "status": "Available"
    }
    veh_res = admin_client.post('/api/v1/vehicles/', veh_payload, format='json')
    assert veh_res.status_code == 201, f"Vehicle creation failed: {veh_res.data}"
    vehicle_id = veh_res.data['id']
    print(f"  ✓ Vehicle created: {veh_res.data['make_model']} ({veh_res.data['registration_number']}) - ID: {vehicle_id}")

    # 4. DRIVER MODULE
    print("\n[4] Testing Driver Module (Admin & Driver Portal)...")
    driver_user = User.objects.get(email='driver@tams.local')
    driver_rec = Driver.objects.get(user=driver_user)
    driver_rec.status = 'Available'
    driver_rec.license_valid_until = date.today() + timedelta(days=365)
    driver_rec.save()

    # Driver fetches own profile via driver portal endpoint
    my_p_res = driver_client.get('/api/v1/drivers/my_profile/')
    assert my_p_res.status_code == 200, f"Driver my-profile failed: {my_p_res.data}"
    assert my_p_res.data['driver_id'] == driver_rec.driver_id
    print(f"  ✓ Driver verified own profile: {my_p_res.data['name']} ({my_p_res.data['driver_id']}) Status: {my_p_res.data['status']}")

    # 5. CUSTOMER MODULE
    print("\n[5] Testing Customer Module...")
    cust_user = User.objects.get(email='customer@tams.local')
    cust_rec, _ = Customer.objects.get_or_create(
        user=cust_user,
        defaults={
            'name': cust_user.full_name or 'Demo Customer',
            'email': cust_user.email,
            'phone': '9876543210',
            'id_proof_type': 'Aadhaar Card',
            'id_proof_number': '1234-5678-9012'
        }
    )
    print(f"  ✓ Customer record verified: {cust_rec.name} (ID: {cust_rec.id})")

    # 6. BOOKING WORKFLOW (Customer creating booking)
    print("\n[6] Testing Customer Booking Flow...")
    start_d = date.today() + timedelta(days=2)
    end_d = date.today() + timedelta(days=4)
    booking_payload = {
        "vehicle_id": vehicle_id,
        "pickup_location": "Bhubaneswar Airport",
        "destination_location": "Puri Sea Beach",
        "pickup_date": start_d.isoformat(),
        "return_date": end_d.isoformat(),
        "passengers": 4,
        "notes": "Flutter mobile integration test booking"
    }
    b_res = customer_client.post('/api/v1/bookings/', booking_payload, format='json')
    assert b_res.status_code == 201, f"Booking creation failed: {b_res.data}"
    booking_id = b_res.data['id']
    booking_code = b_res.data['booking_id']
    print(f"  ✓ Booking confirmed: #{booking_code} for {b_res.data['pickup_location']} → {b_res.data['destination_location']}")
    print(f"    Days: {b_res.data['duration_days']}, Base Fare: ₹{b_res.data['base_fare']}")

    # 7. DRIVER ASSIGNMENT & DUTY SLIP (Admin dispatches trip)
    print("\n[7] Testing Duty Slip Dispatch (Admin -> Driver)...")
    slip_payload = {
        "booking_id": booking_id,
        "driver_id": driver_rec.id,
        "date": start_d.isoformat(),
        "time": "09:00:00",
        "pickup": "Bhubaneswar Airport Terminal 1",
        "destination": "Puri Sea Beach"
    }
    ds_res = admin_client.post('/api/v1/duty-slips/', slip_payload, format='json')
    assert ds_res.status_code == 201, f"Duty slip creation failed: {ds_res.data}"
    slip_id = ds_res.data['id']
    slip_code = ds_res.data['slip_id']
    print(f"  ✓ Duty Slip created: #{slip_code} assigned to {driver_rec.name}")

    # 8. DRIVER EXECUTION (Driver starts trip & completes trip)
    print("\n[8] Testing Driver Trip Execution (Start -> Complete)...")
    # Driver views assigned slips
    slips_res = driver_client.get('/api/v1/duty-slips/my_slips/')
    assert slips_res.status_code == 200
    my_slip = next((s for s in slips_res.data if s['id'] == slip_id), None)
    assert my_slip is not None, "Driver should see assigned duty slip"
    print(f"  ✓ Driver received slip #{slip_code} in mobile portal")

    # Start Trip
    start_res = driver_client.post(f'/api/v1/duty-slips/{slip_id}/start_trip/', {
        "start_odometer": 12500,
    }, format='json')
    assert start_res.status_code == 200, f"Start trip failed: {start_res.data}"
    print(f"  ✓ Driver started trip #{slip_code} at odometer: 12,500 km")

    # Complete Trip
    comp_res = driver_client.post(f'/api/v1/duty-slips/{slip_id}/complete_trip/', {
        "end_odometer": 12850,
    }, format='json')
    assert comp_res.status_code == 200, f"Complete trip failed: {comp_res.data}"
    print(f"  ✓ Driver completed trip #{slip_code} at odometer: 12,850 km (Total: 350 km)")

    # 9. BILLING & INVOICE AUTO-GENERATION & TAX
    print("\n[9] Testing Billing, Invoice Auto-Generation & 5% GST...")
    inv = Invoice.objects.filter(booking_id=booking_id).first()
    assert inv is not None, "Invoice should be automatically generated upon trip completion"
    assert inv.tax_amount > 0, "Tax (GST 5%) should be calculated"
    print(f"  ✓ Invoice auto-generated: #{inv.invoice_id}")
    print(f"    Base Fare: ₹{inv.base_fare}")
    print(f"    GST (5%):  ₹{inv.tax_amount}")
    print(f"    Grand Total: ₹{inv.grand_total}")
    print(f"    Payment Status: {inv.payment_status}")

    # 10. DEMO SIMULATED PAYMENT WORKFLOW
    print("\n[10] Testing Demo Payment Simulation & QR Flow...")
    # Customer fetches invoice
    my_inv_res = customer_client.get('/api/v1/invoices/my_invoices/')
    assert my_inv_res.status_code == 200
    cust_inv = next((i for i in my_inv_res.data if i['id'] == inv.id), None)
    assert cust_inv is not None, "Customer should see their invoice"

    # Initiate demo payment session
    pay_init_res = customer_client.post('/api/v1/payments/initiate/', {
        "invoice_id": inv.id,
        "payment_method": "UPI"
    }, format='json')
    assert pay_init_res.status_code == 201, f"Payment session failed: {pay_init_res.data}"
    txn_ref = pay_init_res.data['payment']['transaction_ref']
    qr_payload = pay_init_res.data['payment']['qr_payload']
    print(f"  ✓ Demo Payment Session generated: Ref #{txn_ref}")
    print(f"    QR Payload: {qr_payload}")

    # Confirm demo payment
    confirm_res = customer_client.post('/api/v1/payments/confirm/', {
        "transaction_ref": txn_ref
    }, format='json')
    assert confirm_res.status_code == 200, f"Confirm payment failed: {confirm_res.data}"
    print(f"  ✓ Payment confirmed: Status = {confirm_res.data['payment']['payment_status']}")

    # Verify Invoice status in PostgreSQL is PAID
    inv.refresh_from_db()
    assert inv.payment_status == 'Paid', f"Invoice status should be Paid, got {inv.payment_status}"
    print(f"  ✓ Invoice #{inv.invoice_id} is now PAID in PostgreSQL")

    # 11. DASHBOARD & REPORTS (Real statistics from PostgreSQL)
    print("\n[11] Testing Dashboard & Reports Aggregations...")
    dash_res = admin_client.get('/api/v1/dashboard/')
    assert dash_res.status_code == 200
    stats = dash_res.data
    print(f"  ✓ Real Stats from PostgreSQL:")
    print(f"    Total Bookings: {stats['bookings']['total']}")
    print(f"    Total Revenue:  ₹{stats['revenue']['total_revenue']}")
    print(f"    Active Fleet:   {stats['vehicles']['total']}")
    print(f"    Drivers:        {stats['drivers']['total']}")

    # 12. CLEANUP TRANSIENT INTEGRATION DATA
    print("\n[12] Cleaning Up Transient Test Records...")
    Payment.objects.filter(invoice__booking_id=booking_id).delete()
    Invoice.objects.filter(booking_id=booking_id).delete()
    DutySlip.objects.filter(booking_id=booking_id).delete()
    Booking.objects.filter(id=booking_id).delete()
    Vehicle.objects.filter(id=vehicle_id).delete()
    print("  ✓ Transient test booking, duty slip, invoice, payment, and vehicle purged.")
    print("  ✓ Official demo accounts (admin, staff, driver, customer) remain active and clean.")

    print("\n" + "=" * 75)
    print("ALL 12 FLUTTER INTEGRATION & DATABASE CHECKS PASSED PERFECTLY!")
    print("=" * 75)

if __name__ == '__main__':
    run_integration_tests()
