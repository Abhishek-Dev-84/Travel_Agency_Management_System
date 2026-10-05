"""
End-to-End System Integration and Business Logic Verification Script for TAMS.
Validates the entire workflow against Django backend and PostgreSQL database.
"""
import os
import sys
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

def run_tests():
    print("=" * 70)
    print("STARTING TAMS END-TO-END SYSTEM VALIDATION")
    print("=" * 70)

    # Clean up prior test runs
    cust_email = "testcustomer_testrun@example.com"
    cust_phone = "9876543210"
    test_reg = "OD-02-TZ-9999"
    test_d_id = "DRV-999"
    test_d_phone = "9871122334"
    test_d_lic = "OD-2018-987654"

    DutySlip.objects.filter(booking__customer__email=cust_email).delete()
    WorkOrder.objects.filter(vehicle__registration_number=test_reg).delete()
    Payment.objects.filter(invoice__booking__customer__email=cust_email).delete()
    Invoice.objects.filter(booking__customer__email=cust_email).delete()
    Booking.objects.filter(customer__email=cust_email).delete()
    Customer.objects.filter(email=cust_email).delete()
    Customer.objects.filter(phone=cust_phone).delete()
    Driver.objects.filter(driver_id=test_d_id).delete()
    Driver.objects.filter(phone=test_d_phone).delete()
    Driver.objects.filter(phone="9876543211").delete()
    Driver.objects.filter(license_number=test_d_lic).delete()
    Driver.objects.filter(license_number="OD02-2021-9876543").delete()
    Vehicle.objects.filter(registration_number=test_reg).delete()
    User.objects.filter(email=cust_email).delete()

    client = APIClient()

    # 1. AUTHENTICATION & USERS
    print("\n[1] Testing Authentication & Users...")
    admin_user = User.objects.filter(email='admin@tams.com').first()
    assert admin_user is not None, "Admin user should exist."
    assert admin_user.role == 'ADMIN', "Admin user role should be ADMIN."

    # Login as admin
    login_res = client.post('/api/v1/auth/login/', {
        'email': 'admin@tams.com',
        'password': 'admin123',
        'role': 'ADMIN'
    }, format='json')
    assert login_res.status_code == 200, f"Admin login failed: {login_res.data}"
    admin_token = login_res.data['token']
    client.credentials(HTTP_AUTHORIZATION=f'Token {admin_token}')
    print("  [OK] Admin login successful. Token acquired.")

    # Register new customer
    reg_res = client.post('/api/v1/auth/register/', {
        'name': 'Pooja Verma',
        'email': cust_email,
        'password': 'CustomerPassword123!',
        'phone': cust_phone,
        'address': 'Bhubaneswar, Odisha'
    }, format='json')
    assert reg_res.status_code == 201, f"Customer registration failed: {reg_res.data}"
    print(f"  [OK] Customer registered successfully: {cust_email}")

    # 2. VEHICLE CRUD & AVAILABILITY
    print("\n[2] Testing Vehicle CRUD & Status Rules...")
    veh_res = client.post('/api/v1/vehicles/', {
        'registration_number': test_reg,
        'make_model': 'Mahindra Scorpio-N',
        'vehicle_type': 'SUV',
        'capacity': 7,
        'fuel_type': 'Diesel',
        'per_day_rate': '3500.00',
        'status': 'Available'
    }, format='json')
    assert veh_res.status_code == 201, f"Vehicle creation failed: {veh_res.data}"
    vehicle_id = veh_res.data['id']
    print(f"  [OK] Vehicle created: {veh_res.data['make_model']} ({test_reg}), Rate: Rs. 3500/day")

    # 3. DRIVER CRUD & LICENSE VALIDATION
    print("\n[3] Testing Driver CRUD & License Expiry...")
    drv_res = client.post('/api/v1/drivers/', {
        'driver_id': test_d_id,
        'name': 'Bikram Jena',
        'phone': test_d_phone,
        'email': 'bikram.driver@tams.in',
        'license_number': test_d_lic,
        'license_expiry': str(date.today() + timedelta(days=365)), # Valid for 1 year
        'experience_years': 6,
        'status': 'Available'
    }, format='json')
    assert drv_res.status_code == 201, f"Driver creation failed: {drv_res.data}"
    driver_id = drv_res.data['id']
    print(f"  [OK] Driver created: {drv_res.data['name']} (ID: {test_d_id}), License valid.")

    # 4. BOOKING CREATION & CONFLICT OVERLAP PREVENTION
    print("\n[4] Testing Booking Creation & Overlap Conflict Detection...")
    today = date.today()
    start_d1 = today + timedelta(days=5)
    end_d1 = today + timedelta(days=7) # (7 - 5) + 1 = 3 days

    booking_res = client.post('/api/v1/bookings/', {
        'customer_name': 'Pooja Verma',
        'customer_phone': '9876543210',
        'customer_email': cust_email,
        'vehicle_id': vehicle_id,
        'pickup_location': 'Bhubaneswar Airport',
        'destination_location': 'Puri Marine Drive',
        'pickup_date': str(start_d1),
        'return_date': str(end_d1),
        'passengers': 4
    }, format='json')
    assert booking_res.status_code == 201, f"Booking creation failed: {booking_res.data}"
    booking_id = booking_res.data['id']
    booking_ref = booking_res.data['booking_id']
    fare = Decimal(booking_res.data['base_fare'])
    assert fare == Decimal('10500.00'), f"Expected fare 3500 * 3 = 10500, got {fare}"
    print(f"  [OK] Booking confirmed: {booking_ref}, Fare calculated: Rs. {fare}")

    # Overlapping booking attempt (must fail with conflict HTTP 400)
    conflict_start = today + timedelta(days=6)
    conflict_end = today + timedelta(days=7)
    conflict_res = client.post('/api/v1/bookings/', {
        'customer_name': 'Another Customer',
        'customer_phone': '9123456780',
        'vehicle_id': vehicle_id,
        'pickup_location': 'Cuttack',
        'destination_location': 'Puri',
        'pickup_date': str(conflict_start),
        'return_date': str(conflict_end)
    }, format='json')
    assert conflict_res.status_code == 400, "Overlapping booking should have failed with status 400."
    print("  [OK] Overlapping booking prevented by backend validation.")

    # 5. INVOICE AUTO-GENERATION & TAX CALCULATION (5% GST)
    print("\n[5] Testing Invoice Auto-Generation & 5% GST Tax Calculation...")
    invoice = Invoice.objects.filter(booking_id=booking_id).first()
    assert invoice is not None, "Invoice should have been generated automatically for booking."
    expected_tax = round((invoice.base_fare - invoice.discount) * Decimal('0.05'), 2)
    expected_grand_total = (invoice.base_fare - invoice.discount) + expected_tax
    assert invoice.tax_amount == expected_tax, f"Expected tax {expected_tax}, got {invoice.tax_amount}"
    assert invoice.grand_total == expected_grand_total, f"Expected grand total {expected_grand_total}, got {invoice.grand_total}"
    assert invoice.payment_status == Invoice.PaymentStatus.UNPAID, "New invoice should be UNPAID."
    print(f"  [OK] Invoice {invoice.invoice_id} verified:")
    print(f"    - Base Fare: Rs. {invoice.base_fare}")
    print(f"    - Discount: Rs. {invoice.discount}")
    print(f"    - GST (5%): Rs. {invoice.tax_amount}")
    print(f"    - Grand Total: Rs. {invoice.grand_total}")
    print(f"    - Status: {invoice.payment_status}")

    # 6. DRIVER ASSIGNMENT & DUTY SLIP GENERATION
    print("\n[6] Testing Duty Slip Creation & Driver Assignment...")
    slip_res = client.post('/api/v1/duty-slips/', {
        'booking_id': booking_id,
        'driver_id': driver_id,
        'vehicle_id': vehicle_id,
        'date': str(start_d1),
        'time': '08:30:00',
        'pickup': 'Bhubaneswar Airport',
        'destination': 'Puri Marine Drive',
        'customer_name': 'Pooja Verma',
        'customer_phone': '9876543210',
        'payout': '2500.00',
        'start_odometer': 14200
    }, format='json')
    assert slip_res.status_code == 201, f"Duty slip creation failed: {slip_res.data}"
    slip_id = slip_res.data['id']
    slip_ref = slip_res.data['slip_id']
    print(f"  [OK] Duty Slip generated: {slip_ref} with start odometer 14,200 km")

    # 7. TRIP LIFECYCLE (START TRIP & COMPLETE TRIP)
    print("\n[7] Testing Trip Lifecycle (Start & Complete with Odometer)...")
    # Start trip
    start_res = client.post(f'/api/v1/duty-slips/{slip_id}/start_trip/', {
        'start_odometer': 14205
    }, format='json')
    assert start_res.status_code == 200, f"Start trip failed: {start_res.data}"
    
    # Verify vehicle and driver status
    veh_obj = Vehicle.objects.get(id=vehicle_id)
    drv_obj = Driver.objects.get(id=driver_id)
    assert veh_obj.status == Vehicle.Status.ON_TRIP, f"Vehicle should be On Trip, got {veh_obj.status}"
    assert drv_obj.status == Driver.Status.ON_DUTY, f"Driver should be On Duty, got {drv_obj.status}"
    print(f"  [OK] Trip started: Vehicle status is '{veh_obj.status}', Driver status is '{drv_obj.status}'")

    # Complete trip
    complete_res = client.post(f'/api/v1/duty-slips/{slip_id}/complete_trip/', {
        'end_odometer': 14380 # 175 km traveled
    }, format='json')
    assert complete_res.status_code == 200, f"Complete trip failed: {complete_res.data}"
    
    veh_obj.refresh_from_db()
    drv_obj.refresh_from_db()
    assert veh_obj.status == Vehicle.Status.AVAILABLE, f"Vehicle should be Available, got {veh_obj.status}"
    assert drv_obj.status == Driver.Status.AVAILABLE, f"Driver should be Available, got {drv_obj.status}"
    slip_obj = DutySlip.objects.get(id=slip_id)
    assert slip_obj.status == DutySlip.Status.COMPLETED, "Duty slip should be COMPLETED"
    print(f"  [OK] Trip completed: End odometer 14,380 km. Vehicle and Driver returned to 'Available'.")

    # 8. SIMULATED PAYMENT WORKFLOW (INITIATE -> CONFIRM)
    print("\n[8] Testing Simulated Payment Flow (UPI / Card / Cash)...")
    init_res = client.post('/api/v1/payments/initiate/', {
        'invoice_id': invoice.id,
        'payment_method': 'UPI'
    }, format='json')
    assert init_res.status_code == 201, f"Payment initiation failed: {init_res.data}"
    pay_data = init_res.data['payment']
    payment_id = pay_data['payment_id']
    txn_ref = pay_data['transaction_ref']
    assert pay_data['is_demo'] is True, "Must be flagged as simulation."
    assert 'qr_payload' in pay_data, "QR payload must be returned for demo UPI payment."
    print(f"  [OK] Demo Payment Session initialized: Ref {txn_ref}, ID: {payment_id}, Status: {pay_data['payment_status']}")
    print("  [OK] Demo QR Payload generated and verified.")

    # Confirm Payment
    conf_res = client.post('/api/v1/payments/confirm/', {
        'payment_id': payment_id
    }, format='json')
    assert conf_res.status_code == 200, f"Payment confirmation failed: {conf_res.data}"
    
    # Verify invoice status in DB
    invoice.refresh_from_db()
    assert invoice.payment_status == Invoice.PaymentStatus.PAID, f"Invoice should be PAID, got {invoice.payment_status}"
    pay_obj = Payment.objects.get(payment_id=payment_id)
    assert pay_obj.payment_status == Payment.PaymentStatus.PAID, f"Payment should be PAID, got {pay_obj.payment_status}"
    print(f"  [OK] Payment confirmed by backend. Invoice {invoice.invoice_id} is now PAID.")

    # 9. MAINTENANCE WORK ORDER & VEHICLE SYNC
    print("\n[9] Testing Maintenance Work Order & Vehicle Status Sync...")
    wo_res = client.post('/api/v1/maintenance/', {
        'vehicle_id': vehicle_id,
        'service_type': 'Brake Pad Replacement & Inspection',
        'issue_description': 'Front brake pads worn down past 3mm safety limit.',
        'garage_name': 'Maruti Authorized Service',
        'estimated_cost': '4500.00',
        'scheduled_date': str(today),
        'status': 'In Service'
    }, format='json')
    assert wo_res.status_code == 201, f"Work order creation failed: {wo_res.data}"
    wo_id = wo_res.data['id']

    veh_obj.refresh_from_db()
    assert veh_obj.status == Vehicle.Status.MAINTENANCE, f"Vehicle should be Maintenance, got {veh_obj.status}"
    print(f"  [OK] Work order created. Vehicle status automatically updated to '{veh_obj.status}'.")

    # Complete work order
    wo_update_res = client.patch(f'/api/v1/maintenance/{wo_id}/', {
        'status': 'Completed'
    }, format='json')
    assert wo_update_res.status_code == 200
    veh_obj.refresh_from_db()
    assert veh_obj.status == Vehicle.Status.AVAILABLE, f"Vehicle should return to Available, got {veh_obj.status}"
    print(f"  [OK] Work order completed. Vehicle status restored to '{veh_obj.status}'.")

    # 10. REAL DATABASE REPORTING & CSV EXPORT
    print("\n[10] Testing Reports API (PostgreSQL Aggregation & CSV Export)...")
    dash_res = client.get('/api/v1/dashboard/')
    assert dash_res.status_code == 200, f"Dashboard failed: {dash_res.data}"
    v_stats = dash_res.data['vehicles']
    rev_stats = dash_res.data['revenue']
    print(f"  [OK] Dashboard Live DB Aggregations:")
    print(f"    - Total Revenue: Rs. {rev_stats['total_revenue']}")
    print(f"    - Total Bookings: {dash_res.data['bookings']['total']}")
    print(f"    - Active Fleet: {v_stats['available']} / {v_stats['total']}")

    rep_res = client.get('/api/v1/reports/analytics/')
    assert rep_res.status_code == 200, f"Reports analytics failed: {rep_res.data}"
    kpis = rep_res.data['kpis']
    print(f"  [OK] Reports KPIs from PostgreSQL:")
    print(f"    - Total Revenue: Rs. {kpis['total_revenue']}")
    print(f"    - Total Bookings: {kpis['total_bookings']}")
    print(f"    - Active Customers: {kpis['active_customers']}")

    csv_res = client.get('/api/v1/reports/export-csv/?type=bookings')
    assert csv_res.status_code == 200
    assert 'text/csv' in csv_res['Content-Type']
    print("  [OK] CSV Export functional and verified.")

    print("\n" + "=" * 70)
    print("ALL INTEGRATION TESTS PASSED PERFECTLY!")
    print("=" * 70)

if __name__ == '__main__':
    run_tests()
